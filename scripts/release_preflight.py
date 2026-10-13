"""Validate a production API origin locally; no network calls or secrets printed."""
import argparse
import ipaddress
import re
from urllib.parse import urlsplit


def validate_api_url(value):
    try:
        url = urlsplit(value)
        host = (url.hostname or '').lower().rstrip('.')
        port = url.port
    except ValueError:
        raise ValueError('Invalid API URL') from None
    if (url.scheme != 'https' or not host or url.username is not None
            or url.password is not None or url.query or url.fragment
            or url.path not in ('', '/') or port not in (None, 443)):
        raise ValueError('Production requires an HTTPS origin on port443 without credentials, path or query')
    try:
        address = ipaddress.ip_address(host)
    except ValueError:
        address = None
    if address is not None:
        if not address.is_global:
            raise ValueError('Production API cannot use a local/private/reserved address')
    elif ('.' not in host or not re.fullmatch(r'[a-z0-9.-]+', host)
          or all(re.fullmatch(r'(?:[0-9]+|0x[0-9a-f]+)', part) for part in host.split('.'))
          or any(not part or len(part) > 63 or part.startswith('-') or part.endswith('-')
                 for part in host.split('.'))
          or host.endswith(('.localhost', '.local', '.internal', '.test', '.invalid', '.example'))
          or host in ('example.com', 'example.net', 'example.org')
          or any(host.endswith('.' + domain) for domain in ('example.com', 'example.net', 'example.org'))
          or re.search(r'(^|[.-])(fixture|localhost|placeholder)([.-]|$)', host)):
        raise ValueError('Production API cannot use a local, placeholder or fixture hostname')
    return value.rstrip('/')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--api-url', required=True)
    args = parser.parse_args()
    try:
        validate_api_url(args.api_url)
    except ValueError as error:
        parser.error(str(error))
    print('PASS production API origin syntax/public-address guard; DNS/TLS/reachability not tested')


if __name__ == '__main__':
    main()
