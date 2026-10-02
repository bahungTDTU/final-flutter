"""Loopback SMTP fixture for protocol/TLS tests, never imported by production app."""
import re
import shutil
import socketserver
import ssl
import subprocess
import threading
from email import policy
from email.parser import BytesParser
from pathlib import Path


def make_certificate(folder):
    folder = Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    cert, key = folder / 'localhost-cert.pem', folder / 'localhost-key.pem'
    openssl = shutil.which('openssl') or 'C:/Program Files/Git/usr/bin/openssl.exe'
    if not Path(openssl).is_file():
        raise RuntimeError('OpenSSL is required for local TLS test certificates')
    subprocess.run([openssl, 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
                    '-keyout', str(key), '-out', str(cert), '-days', '1', '-subj', '/CN=localhost',
                    '-addext', 'subjectAltName=DNS:localhost,IP:127.0.0.1'],
                   check=True, capture_output=True, timeout=15)
    return cert, key


class SinkHandler(socketserver.StreamRequestHandler):
    def handle(self):
        sink = self.server.sink
        self.connection.settimeout(5)
        tls = False

        def start_tls():
            self.connection = sink.context.wrap_socket(self.connection, server_side=True)
            self.rfile = self.connection.makefile('rb')
            self.wfile = self.connection.makefile('wb')

        def reply(value):
            self.wfile.write(value.encode('ascii') + b'\r\n')
            self.wfile.flush()

        try:
            if sink.implicit:
                start_tls()
                tls = True
            reply('220 localhost fixture')
            recipient = None
            while True:
                line = self.rfile.readline(8192)
                if not line:
                    return
                command = line.decode('ascii', errors='replace').strip()
                verb = command.split(' ', 1)[0].upper()
                if verb in ('EHLO', 'HELO'):
                    reply('250-localhost')
                    if not tls and sink.offer_starttls:
                        reply('250-STARTTLS')
                    if tls:
                        reply('250-AUTH PLAIN')
                    reply('250 SIZE 65536')
                elif verb == 'STARTTLS' and sink.offer_starttls and not tls:
                    reply('220 Begin TLS')
                    start_tls()
                    tls = True
                elif verb == 'AUTH':
                    sink.auth_encrypted.append(tls)
                    reply('235 Authenticated' if tls else '530 TLS required')
                elif verb == 'MAIL':
                    reply('250 Sender accepted' if tls else '530 TLS required')
                elif verb == 'RCPT':
                    recipient = command.split(':', 1)[1].strip().strip('<>')
                    reply('550 Recipient refused' if sink.reject else '250 Recipient accepted')
                elif verb == 'DATA':
                    reply('354 End with dot')
                    chunks = []
                    while True:
                        part = self.rfile.readline(8192)
                        if part == b'.\r\n':
                            break
                        if not part or sum(map(len, chunks)) + len(part) > 65536:
                            return
                        chunks.append(part[1:] if part.startswith(b'..') else part)
                    message = BytesParser(policy=policy.default).parsebytes(b''.join(chunks))
                    sink.messages.append({'recipient': recipient, 'message': message, 'tls': tls})
                    reply('250 Message accepted')
                elif verb == 'QUIT':
                    reply('221 Bye')
                    return
                elif verb in ('RSET', 'NOOP'):
                    reply('250 OK')
                else:
                    reply('502 Not implemented')
        except (OSError, ssl.SSLError):
            pass


class MailSink:
    def __init__(self, cert, key, *, port=0, implicit=False, offer_starttls=True, reject=False):
        self.context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        self.context.load_cert_chain(cert, key)
        self.implicit, self.offer_starttls, self.reject = implicit, offer_starttls, reject
        self.messages, self.auth_encrypted = [], []
        self.server = socketserver.ThreadingTCPServer(('127.0.0.1', port), SinkHandler)
        self.server.daemon_threads = True
        self.server.sink = self
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *_):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=5)

    def code(self, recipient, kind):
        for record in reversed(self.messages):
            if record['recipient'] == recipient:
                body = record['message'].get_content()
                if ('xác minh' if kind == 'verify' else 'đặt lại') in body:
                    return re.search(r'\n\n([A-Za-z0-9_-]{43})\n', body)[1]
        return None
