import pytest

from scripts.release_preflight import validate_api_url


@pytest.mark.parametrize('url', [
    'http://api.notetogether.vn', 'https://localhost', 'https://127.0.0.1',
    'https://[::1]', 'https://10.0.2.2', 'https://192.168.1.2',
    'https://169.254.169.254', 'https://example.com', 'https://api.example.org',
    'https://fixture.notetogether.vn', 'https://api.test', 'https://api.local',
    'https://user:secret@api.notetogether.vn', 'https://api.notetogether.vn/fixture',
    'https://api.notetogether.vn?key=secret', 'https://api.notetogether.vn#token',
    'https://api.notetogether.vn:8042', 'https://api.notetogether.vn:bad',
    'https://127.1', 'https://2130706433', 'https://api..notetogether.vn',
])
def test_reject_local_fixture_or_credentialed_production_origin(url):
    with pytest.raises(ValueError):
        validate_api_url(url)


def test_accept_https_origin_without_contacting_it():
    assert validate_api_url('https://api.notetogether.vn/') == 'https://api.notetogether.vn'
