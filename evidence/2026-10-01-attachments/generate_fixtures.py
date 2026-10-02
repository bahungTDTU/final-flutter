"""Optional QA-only fixtures. Default output is ignored tmp, not frozen evidence."""
from pathlib import Path
import argparse
import subprocess

from PIL import Image
import imageio_ffmpeg

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, default=Path('tmp/attachments-fixtures'))
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
Image.new('RGB', (320, 180), 'teal').save(args.output / 'attachment-fixture.png')
(args.output / 'attachment-fixture.txt').write_bytes(b'NoteTogether private attachment fixture.\r\n')
subprocess.run([
    imageio_ffmpeg.get_ffmpeg_exe(), '-hide_banner', '-loglevel', 'error', '-y',
    '-f', 'lavfi', '-i', 'testsrc=size=320x180:rate=15', '-t', '2',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-movflags', '+faststart',
    str(args.output / 'attachment-fixture.mp4'),
], check=True)
print(f'QA fixtures written to {args.output.resolve()}')
