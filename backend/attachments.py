"""Private, bounded attachments. Authorization is checked again at commit/read/replay."""
import hashlib
import json
import re
import unicodedata
from io import BytesIO
from urllib.parse import quote
from uuid import UUID

from fastapi import Depends, HTTPException, Query, Request, Response
from fastapi.concurrency import run_in_threadpool
from PIL import Image, ImageOps, UnidentifiedImageError

MAX_BYTES = 20 * 1024 * 1024
METADATA_COLUMNS = 'id,name,kind,media_type,size,created_at'
FILE_TYPES = {'.pdf': 'application/pdf', '.txt': 'text/plain', '.csv': 'text/csv', '.zip': 'application/zip'}


def filename(value):
    name = unicodedata.normalize('NFC', value.strip())
    if not name or len(name) > 160 or '/' in name or '\\' in name or any(unicodedata.category(c).startswith('C') for c in name):
        raise HTTPException(422, 'Invalid attachment filename')
    return name


def normalize(data, name, kind, content_type):
    if not data:
        raise HTTPException(422, 'Empty attachment')
    extension = '.' + name.rsplit('.', 1)[-1].lower()
    if kind == 'image':
        expected = {'.png': 'PNG', '.jpg': 'JPEG', '.jpeg': 'JPEG'}.get(extension)
        if not expected or content_type != ('image/png' if expected == 'PNG' else 'image/jpeg'):
            raise HTTPException(415, 'Images must be PNG or JPEG')
        if len(data) > 10 * 1024 * 1024:
            raise HTTPException(413, 'Image limit is 10 MiB')
        try:
            with Image.open(BytesIO(data), formats=['PNG', 'JPEG']) as image:
                if image.format != expected or image.width * image.height > 16_000_000 or max(image.size) > 8192 or getattr(image, 'n_frames', 1) != 1:
                    raise HTTPException(422, 'Invalid image dimensions or animation')
                image.verify()
            with Image.open(BytesIO(data), formats=['PNG', 'JPEG']) as image:
                image.load()
                image = ImageOps.exif_transpose(image)
                image.thumbnail((2048, 2048), Image.Resampling.LANCZOS)
                clean = Image.new('RGBA', image.size)
                clean.paste(image.convert('RGBA'))
                output = BytesIO()
                clean.save(output, format='PNG')
                return output.getvalue(), 'image/png'
        except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError):
            raise HTTPException(422, 'Invalid or damaged image') from None
    if kind == 'video':
        if extension != '.mp4' or content_type != 'video/mp4':
            raise HTTPException(415, 'Videos must be MP4')
        # Validate bounded ISO BMFF container structure, not every codec/sample.
        offset, boxes = 0, set()
        while offset < len(data):
            if len(data) - offset < 8:
                raise HTTPException(422, 'Damaged MP4 container')
            size, box = int.from_bytes(data[offset:offset+4], 'big'), data[offset+4:offset+8]
            header = 8
            if size == 1:
                if len(data) - offset < 16:
                    raise HTTPException(422, 'Damaged MP4 container')
                size, header = int.from_bytes(data[offset+8:offset+16], 'big'), 16
            elif size == 0:
                size = len(data) - offset
            if size < header or offset + size > len(data):
                raise HTTPException(422, 'Damaged MP4 container')
            if offset == 0 and (box != b'ftyp' or size < 16):
                raise HTTPException(422, 'Missing MP4 file type')
            boxes.add(box)
            offset += size
        if not {b'ftyp', b'moov', b'mdat'} <= boxes:
            raise HTTPException(422, 'Incomplete MP4 container')
        return data, 'video/mp4'
    if kind != 'file' or extension not in FILE_TYPES or content_type != FILE_TYPES[extension]:
        raise HTTPException(415, 'Files must be PDF, TXT, CSV or ZIP')
    if extension == '.pdf' and not data.startswith(b'%PDF-') or extension == '.zip' and not data.startswith((b'PK\x03\x04', b'PK\x05\x06')):
        raise HTTPException(422, 'File signature does not match its type')
    if extension in ('.txt', '.csv'):
        try:
            text = data.decode('utf-8-sig')
            if '\0' in text:
                raise ValueError()
        except (UnicodeError, ValueError):
            raise HTTPException(422, 'Text files must be UTF-8 without NUL') from None
    # General files are never executed, extracted, rendered or served inline.
    return data, FILE_TYPES[extension]


def install_attachment_routes(app, db, authenticate, access, now):
    def metadata(row):
        return {key: row[key] for key in ('id', 'name', 'kind', 'media_type', 'size', 'created_at')}

    @app.get('/notes/{note_id}/attachments')
    def listing(note_id: str, identity=Depends(authenticate)):
        with db() as conn:
            access(conn, note_id, identity)
            return [metadata(row) for row in conn.execute(
                f'SELECT {METADATA_COLUMNS} FROM attachments WHERE note_id=? AND data IS NOT NULL ORDER BY created_at,id', (note_id,))]

    @app.post('/notes/{note_id}/attachments/{attachment_id}')
    async def upload(note_id: str, attachment_id: str, request: Request,
                     name: str = Query(max_length=160), kind: str = Query(pattern='^(image|video|file)$'), identity=Depends(authenticate)):
        try:
            UUID(attachment_id)
        except ValueError:
            raise HTTPException(422, 'Attachment ID must be a UUID') from None
        name = filename(name)
        with db() as conn:
            access(conn, note_id, identity, 'edit')
        data = bytearray()
        async for chunk in request.stream():
            if len(data) + len(chunk) > MAX_BYTES:
                raise HTTPException(413, 'Attachment limit is 20 MiB')
            data.extend(chunk)
        content_type = request.headers.get('content-type', '').split(';')[0].lower()
        fingerprint = hashlib.sha256(json.dumps([note_id, name, kind, content_type], ensure_ascii=False).encode() + b'\0' + data).hexdigest()
        canonical, media_type = await run_in_threadpool(normalize, bytes(data), name, kind, content_type)
        with db() as conn:
            access(conn, note_id, identity, 'edit')
            old = conn.execute(f'SELECT {METADATA_COLUMNS},note_id,created_by,fingerprint,data IS NOT NULL AS present FROM attachments WHERE id=?', (attachment_id,)).fetchone()
            if old:
                if old['note_id'] != note_id or old['created_by'] != identity[0] or old['fingerprint'] != fingerprint:
                    raise HTTPException(409, 'Attachment ID reused with different data')
                if not old['present']:
                    raise HTTPException(409, 'Attachment was deleted; refresh before retrying')
                return metadata(old)
            count, size = conn.execute('SELECT COUNT(*),COALESCE(SUM(size),0) FROM attachments WHERE note_id=? AND data IS NOT NULL', (note_id,)).fetchone()
            if count >= 10 or size + len(canonical) > 100 * 1024 * 1024:
                raise HTTPException(413, 'Note limit is 10 attachments / 100 MiB')
            conn.execute('INSERT INTO attachments VALUES (?,?,?,?,?,?,?,?,?,?,?)',
                         (attachment_id, note_id, identity[0], name, kind, media_type, len(canonical), now(), fingerprint, canonical, 0))
            return metadata(conn.execute(f'SELECT {METADATA_COLUMNS} FROM attachments WHERE id=?', (attachment_id,)).fetchone())

    @app.get('/notes/{note_id}/attachments/{attachment_id}')
    def download(note_id: str, attachment_id: str, request: Request, identity=Depends(authenticate)):
        with db() as conn:
            access(conn, note_id, identity)
            row = conn.execute('SELECT * FROM attachments WHERE id=? AND note_id=? AND data IS NOT NULL', (attachment_id, note_id)).fetchone()
            if not row:
                raise HTTPException(404, 'Attachment unavailable')
            data = bytes(row['data'])
            headers = {'Cache-Control': 'private, no-store', 'X-Content-Type-Options': 'nosniff',
                       'Content-Security-Policy': "default-src 'none'; sandbox", 'Accept-Ranges': 'bytes',
                       'Content-Disposition': "attachment; filename=download; filename*=UTF-8''" + quote(row['name'])}
            requested = request.headers.get('range')
            if requested:
                match = re.fullmatch(r'bytes=(\d*)-(\d*)', requested)
                if not match or not any(match.groups()):
                    raise HTTPException(416, 'Invalid byte range', headers={'Content-Range': f'bytes */{len(data)}'})
                first, last = match.groups()
                start = int(first) if first else max(0, len(data) - int(last))
                end = min(int(last), len(data) - 1) if first and last else len(data) - 1
                if start > end or start >= len(data):
                    raise HTTPException(416, 'Invalid byte range', headers={'Content-Range': f'bytes */{len(data)}'})
                headers['Content-Range'] = f'bytes {start}-{end}/{len(data)}'
                return Response(data[start:end+1], status_code=206, media_type=row['media_type'], headers=headers)
            return Response(data, media_type=row['media_type'], headers=headers)

    @app.delete('/notes/{note_id}/attachments/{attachment_id}')
    def delete(note_id: str, attachment_id: str, identity=Depends(authenticate)):
        with db() as conn:
            access(conn, note_id, identity, 'edit')
            row = conn.execute('SELECT id FROM attachments WHERE id=? AND note_id=?', (attachment_id, note_id)).fetchone()
            if not row:
                raise HTTPException(404, 'Attachment unavailable')
            conn.execute('UPDATE attachments SET data=NULL,size=0,deleted=1 WHERE id=?', (attachment_id,))
        return {'ok': True}
