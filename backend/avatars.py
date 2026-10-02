"""Bounded image decoding, metadata-free PNGs and authenticated SQLite storage."""
from io import BytesIO

from fastapi import Depends, HTTPException, Query, Request, Response
from fastapi.concurrency import run_in_threadpool
from PIL import Image, ImageOps, UnidentifiedImageError

MAX_BYTES = 2 * 1024 * 1024


def normalize_image(data, content_type):
    expected = {'image/png': 'PNG', 'image/jpeg': 'JPEG'}.get(content_type)
    if not expected:
        raise HTTPException(415, 'Use PNG or JPEG')
    try:
        with Image.open(BytesIO(data), formats=['PNG', 'JPEG']) as image:
            if image.format != expected or image.width * image.height > 16_000_000 or max(image.size) > 8192 or getattr(image, 'n_frames', 1) != 1:
                raise HTTPException(422, 'Invalid image type, dimensions or animation')
            image.verify()
        with Image.open(BytesIO(data), formats=['PNG', 'JPEG']) as image:
            image.load()
            image = ImageOps.exif_transpose(image)
            image.thumbnail((512, 512), Image.Resampling.LANCZOS)
            clean = Image.new('RGBA', image.size)
            clean.paste(image.convert('RGBA'))
            output = BytesIO()
            clean.save(output, format='PNG')
            normalized = output.getvalue()
            if len(normalized) > 1024 * 1024:
                raise HTTPException(422, 'Normalized image is too large')
            return normalized
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError):
        raise HTTPException(422, 'Invalid or damaged image') from None


def install_avatar_routes(app, db, authenticate, validate_session, profile):
    def replace(identity, revision, data):
        with db() as conn:
            validate_session(conn, identity)
            row = conn.execute('SELECT revision FROM avatars WHERE user_id=?', (identity[0],)).fetchone()
            current = row['revision'] if row else 0
            if current != revision:
                raise HTTPException(409, {'message': 'Avatar changed; refresh before retrying', 'revision': current})
            conn.execute('INSERT INTO avatars VALUES (?,?,?) ON CONFLICT(user_id) DO UPDATE SET revision=excluded.revision,data=excluded.data',
                         (identity[0], current + 1, data))
            return profile(conn, identity[0])

    @app.post('/me/avatar')
    async def upload(request: Request, base_revision: int = Query(ge=0), identity=Depends(authenticate)):
        content_type = request.headers.get('content-type', '').split(';')[0].lower()
        if content_type not in ('image/png', 'image/jpeg'):
            raise HTTPException(415, 'Use PNG or JPEG')
        data = bytearray()
        async for chunk in request.stream():
            if len(data) + len(chunk) > MAX_BYTES:
                raise HTTPException(413, 'Avatar limit is 2 MiB')
            data.extend(chunk)
        normalized = await run_in_threadpool(normalize_image, bytes(data), content_type)
        return replace(identity, base_revision, normalized)

    @app.get('/me/avatar')
    def download(revision: int | None = Query(default=None, ge=0), identity=Depends(authenticate)):
        with db() as conn:
            validate_session(conn, identity)
            row = conn.execute('SELECT * FROM avatars WHERE user_id=?', (identity[0],)).fetchone()
            if not row or row['data'] is None:
                raise HTTPException(404, 'Avatar unavailable')
            if revision is not None and revision != row['revision']:
                raise HTTPException(409, 'Avatar changed; refresh profile')
            return Response(bytes(row['data']), media_type='image/png', headers={
                'Cache-Control': 'private, no-store', 'X-Content-Type-Options': 'nosniff',
                'Content-Disposition': 'inline; filename="avatar.png"'})

    @app.delete('/me/avatar')
    def delete(base_revision: int = Query(ge=0), identity=Depends(authenticate)):
        return replace(identity, base_revision, None)
