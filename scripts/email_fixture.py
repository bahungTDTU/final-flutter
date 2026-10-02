"""Local-only QA harness: TLS SMTP sink + fixture code reader + isolated backend.

Not a mail provider. It never forwards mail or serves real-user codes. Use only
disposable @example.test addresses. Production backend imports neither this script
nor the fixture code endpoint. Certificate/key and database stay in ignored tmp/.
"""
import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from backend.app import create_app
from backend.email_delivery import SmtpDelivery, SmtpSettings
from backend.tests.smtp_sink import MailSink, make_certificate
import uvicorn


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--allow-code-endpoint', action='store_true', required=True)
    args = parser.parse_args()
    if not args.allow_code_endpoint:
        raise RuntimeError('Fixture code endpoint must be explicitly enabled')
    state = ROOT / 'tmp' / 'email-fixture'
    cert, key = make_certificate(state)
    with MailSink(cert, key, port=8025) as sink:
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_):
                pass

            def do_GET(self):
                parsed = urlparse(self.path)
                values = parse_qs(parsed.query)
                email, kind = values.get('email', [''])[0], values.get('kind', [''])[0]
                code = sink.code(email, kind) if email.endswith('@example.test') and kind in ('verify', 'reset') else None
                if parsed.path == '/health':
                    data, status = {'fixture_only': True, 'received': len(sink.messages)}, 200
                elif parsed.path == '/code' and self.headers.get('X-Email-Fixture') == 'local-test-only' and code:
                    data, status = {'code': code}, 200
                else:
                    data, status = {'detail': 'Fixture code unavailable'}, 404
                self.send_response(status)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Cache-Control', 'no-store')
                self.end_headers()
                self.wfile.write(json.dumps(data).encode())

        reader = ThreadingHTTPServer(('127.0.0.1', 8026), Handler)
        Thread(target=reader.serve_forever, daemon=True).start()
        app = create_app(state / 'fixture.sqlite3', email_delivery=SmtpDelivery(SmtpSettings(
            'localhost', 8025, 'sender@example.test', ca_file=str(cert))))
        print('QA fixture only: API8011 / TLS SMTP8025 / code reader8026. No external delivery.', flush=True)
        try:
            uvicorn.run(app, host='127.0.0.1', port=8011, access_log=False, log_level='warning')
        finally:
            reader.shutdown()
            reader.server_close()


if __name__ == '__main__':
    main()
