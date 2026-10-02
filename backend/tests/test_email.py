import sqlite3
from dataclasses import replace

import pytest
from fastapi.testclient import TestClient

from backend.app import create_app
from backend.email_delivery import DisabledDelivery, SmtpDelivery, SmtpSettings, delivery_from_environment
from backend.tests.mail_support import RecordingDelivery
from backend.tests.smtp_sink import MailSink, make_certificate


@pytest.fixture(scope='module')
def tls_files(tmp_path_factory):
    return make_certificate(tmp_path_factory.mktemp('smtp-tls'))


@pytest.mark.parametrize('implicit', [False, True])
def test_real_tls_smtp_delivers_utf8_code_and_auth_only_after_tls(tls_files, implicit):
    cert, key = tls_files
    with MailSink(cert, key, implicit=implicit) as sink:
        settings = SmtpSettings('localhost', sink.port, 'sender@example.test',
                                security='ssl' if implicit else 'starttls', ca_file=str(cert),
                                username='fixture-user', password='fixture-password')
        smtp = SmtpDelivery(settings)
        code = 'x' * 43
        assert smtp.send('recipient@example.test', 'verify', code) == 'smtp_accepted'
        assert sink.code('recipient@example.test', 'verify') == code
        assert sink.messages[0]['tls'] is True
        assert sink.auth_encrypted == [True]
        assert 'xác minh' in str(sink.messages[0]['message']['Subject'])
        assert 'fixture-password' not in repr(settings)


def test_smtp_missing_starttls_untrusted_certificate_and_refused_recipient_fail_closed(tls_files):
    cert, key = tls_files
    for options in [dict(offer_starttls=False), dict(reject=True), {}]:
        with MailSink(cert, key, **options) as sink:
            cfg = SmtpSettings('localhost', sink.port, 'sender@example.test',
                               username='fixture-user', password='fixture-password', ca_file=str(cert))
            if not options:
                cfg = replace(cfg, ca_file=None)
            assert SmtpDelivery(cfg).send('recipient@example.test', 'verify', 'x' * 43) == 'delivery_failed'
            assert sink.messages == []
            if options.get('offer_starttls') is False or not options:
                assert sink.auth_encrypted == []


def test_environment_is_disabled_by_default_and_rejects_insecure_or_partial_config():
    assert isinstance(delivery_from_environment({}), DisabledDelivery)
    for values in [{'SMTP_SECURITY': 'none'}, {'SMTP_USERNAME': 'user'}, {'SMTP_PORT': '0'},
                   {'SMTP_FROM': 'from@example.test\r\nBcc: stolen@example.test'}]:
        with pytest.raises(ValueError):
            delivery_from_environment({'SMTP_HOST': 'localhost', 'SMTP_FROM': 'from@example.test', **values})


def register(client, email='person@example.test'):
    return client.post('/auth/register', json={'email': email, 'name': 'Test',
        'password': 'safe-password-123', 'confirmation': 'safe-password-123'})


def test_api_codes_survive_restart_and_reset_revokes_old_sessions(tls_files, tmp_path):
    cert, key = tls_files
    database = tmp_path / 'smtp.sqlite3'
    with MailSink(cert, key) as sink:
        transport = SmtpDelivery(SmtpSettings('localhost', sink.port, 'sender@example.test', ca_file=str(cert)))
        app = create_app(database, email_delivery=transport)
        with TestClient(app) as client:
            result = register(client).json()
            assert result['email_delivery'] == 'smtp_accepted'
            assert result['user']['verified'] is False
            assert not hasattr(app.state, 'mailbox')
            headers = {'Authorization': 'Bearer ' + result['token']}
            code = sink.code('person@example.test', 'verify')
            assert code not in str(result)
            with sqlite3.connect(database) as conn:
                assert code not in str(conn.execute('SELECT * FROM email_tokens').fetchall())
            assert client.post('/auth/resend', headers=headers).status_code == 429
        with TestClient(create_app(database, email_delivery=transport)) as client:
            assert client.post('/auth/verify', json={'token': code}).status_code == 200
            assert client.get('/me', headers=headers).json()['verified'] is True
            assert client.post('/auth/verify', json={'token': code}).status_code == 400
            assert client.post('/auth/forgot', json={'email': 'person@example.test'}).json()['email_delivery'] == 'requested'
            reset = sink.code('person@example.test', 'reset')
            assert client.post('/auth/reset/check', json={'token': code}).status_code == 400
            assert client.post('/auth/reset/check', json={'token': reset}).status_code == 200
            assert client.post('/auth/reset/check', json={'token': reset}).status_code == 200
            assert client.post('/auth/reset', json={'token': reset, 'password': 'next-password-123', 'confirmation': 'next-password-123'}).json() == {'ok': True, 'login_required': True}
            assert client.get('/me', headers=headers).status_code == 401
            assert client.post('/auth/reset/check', json={'token': reset}).status_code == 400
            assert client.post('/auth/login', json={'email': 'person@example.test', 'password': 'next-password-123'}).status_code == 200


def test_failed_delivery_keeps_account_usable_resend_replaces_code_and_no_enumeration(tmp_path):
    transport = RecordingDelivery()
    transport.fail = True
    app = create_app(tmp_path / 'failure.sqlite3', email_delivery=transport)
    with TestClient(app) as client:
        result = register(client).json()
        assert result['email_delivery'] == 'delivery_failed'
        headers = {'Authorization': 'Bearer ' + result['token']}
        assert client.get('/notes', headers=headers).status_code == 200
        assert client.post('/auth/forgot', json={'email': 'person@example.test'}).json() == client.post('/auth/forgot', json={'email': 'absent@example.test'}).json()
        for email in ['person@example.test', 'absent@example.test']:
            assert client.post('/auth/forgot', json={'email': email}).status_code == 429
        with sqlite3.connect(app.state.database) as conn:
            conn.execute("UPDATE attempts SET blocked_until=0 WHERE scope LIKE 'verify:%'")
        transport.fail = False
        assert client.post('/auth/resend', headers=headers).json()['email_delivery'] == 'test_only'
        old = transport.messages[-1]['token']
        with sqlite3.connect(app.state.database) as conn:
            conn.execute("UPDATE attempts SET blocked_until=0 WHERE scope LIKE 'verify:%'")
        client.post('/auth/resend', headers=headers)
        assert client.post('/auth/verify', json={'token': old}).status_code == 400
        assert client.post('/auth/verify', json={'token': transport.messages[-1]['token']}).status_code == 200
        assert client.post('/auth/resend', headers=headers).json()['email_delivery'] == 'already_verified'
        assert client.post('/auth/resend').status_code == 401
        assert register(client, 'person@example.test\nBcc: stolen@example.test').status_code == 422


def test_disabled_app_never_retains_raw_tokens(tmp_path):
    app = create_app(tmp_path / 'disabled.sqlite3', email_delivery=DisabledDelivery())
    with TestClient(app) as client:
        assert register(client).json()['email_delivery'] == 'not_configured'
        assert not hasattr(app.state, 'mailbox')
        assert client.post('/auth/forgot', json={'email': 'person@example.test'}).json()['email_delivery'] == 'not_configured'
        assert client.get('/health').json()['email_delivery'] == 'not_configured'
