"""SMTP transport. No mailbox, token logging or plaintext fallback in the app."""
import re
import smtplib
import ssl
from dataclasses import dataclass, field
from email.message import EmailMessage
from email.utils import formatdate, make_msgid


def valid_email(value):
    return len(value) <= 254 and bool(re.fullmatch(
        r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", value))


class DisabledDelivery:
    mode = 'not_configured'

    def send(self, recipient, kind, token):
        return 'not_configured'


@dataclass(frozen=True)
class SmtpSettings:
    host: str
    port: int
    sender: str
    security: str = 'starttls'
    username: str = field(default='', repr=False)
    password: str = field(default='', repr=False)
    ca_file: str | None = None
    timeout: float = 3

    def __post_init__(self):
        if (not self.host or self.security not in ('starttls', 'ssl') or
                not 1 <= self.port <= 65535 or not valid_email(self.sender) or
                bool(self.username) != bool(self.password) or not 1 <= self.timeout <= 6):
            raise ValueError('Invalid SMTP configuration')


class SmtpDelivery:
    mode = 'smtp'

    def __init__(self, settings):
        self.settings = settings

    def send(self, recipient, kind, token):
        if not valid_email(recipient) or kind not in ('verify', 'reset'):
            return 'delivery_failed'
        action = 'xác minh tài khoản' if kind == 'verify' else 'đặt lại mật khẩu'
        message = EmailMessage()
        message['From'] = self.settings.sender
        message['To'] = recipient
        message['Subject'] = 'NoteTogether - Mã ' + action
        message['Date'] = formatdate(localtime=False)
        message['Message-ID'] = make_msgid()
        message.set_content(
            f'Mã {action} NoteTogether:\n\n{token}\n\n'
            'Mã dùng một lần, hết hạn sau 30 phút.\n'
            'Mở NoteTogether trên Web hoặc Android, chọn Kích hoạt / đặt lại và nhập mã này.\n'
            'Nếu bạn không yêu cầu, hãy bỏ qua email. Không chia sẻ mã với người khác.\n')
        cfg = self.settings
        try:
            context = ssl.create_default_context(cafile=cfg.ca_file)
            if cfg.security == 'ssl':
                connection = smtplib.SMTP_SSL(cfg.host, cfg.port, timeout=cfg.timeout, context=context)
            else:
                connection = smtplib.SMTP(cfg.host, cfg.port, timeout=cfg.timeout)
            with connection as smtp:
                smtp.ehlo()
                if cfg.security == 'starttls':
                    smtp.starttls(context=context)
                    smtp.ehlo()
                if cfg.username:
                    smtp.login(cfg.username, cfg.password)
                rejected = smtp.send_message(message)
                if rejected:
                    return 'delivery_failed'
            return 'smtp_accepted'
        except (OSError, smtplib.SMTPException, ValueError):
            # Never include provider exceptions: they can contain addresses/credentials.
            return 'delivery_failed'


def delivery_from_environment(env):
    host = env.get('SMTP_HOST', '').strip()
    if not host:
        return DisabledDelivery()
    security = env.get('SMTP_SECURITY', 'starttls')
    return SmtpDelivery(SmtpSettings(
        host=host, port=int(env.get('SMTP_PORT', '465' if security == 'ssl' else '587')),
        sender=env.get('SMTP_FROM', ''), security=security,
        username=env.get('SMTP_USERNAME', ''), password=env.get('SMTP_PASSWORD', ''),
        ca_file=env.get('SMTP_CA_FILE') or None, timeout=float(env.get('SMTP_TIMEOUT', '3'))))
