"""Versioned rich text in the existing content field; never render client HTML."""
import json
import re
from urllib.parse import urlparse

PREFIX = 'NTDOC1:'
BOOL_ATTRIBUTES = {'bold', 'italic', 'underline', 'strike', 'inline-code', 'code-block', 'blockquote', 'small'}
STRING_ATTRIBUTES = {'font', 'size', 'color', 'background', 'link', 'list', 'align', 'direction', 'script', 'line-height'}
INT_ATTRIBUTES = {'header', 'indent'}


def document_delta(content):
    if not content.startswith(PREFIX):
        return None
    ops = json.loads(content[len(PREFIX):])
    if not isinstance(ops, list) or not ops:
        raise ValueError('Invalid rich document')
    for op in ops:
        if (not isinstance(op, dict) or not isinstance(op.get('insert'), str) or not op['insert']
                or set(op) - {'insert', 'attributes'}):
            raise ValueError('Rich document supports text inserts only')
        attrs = op.get('attributes', {})
        if not isinstance(attrs, dict):
            raise ValueError('Invalid rich attributes')
        for key, value in attrs.items():
            if key in BOOL_ATTRIBUTES and type(value) is bool:
                continue
            if key == 'header' and type(value) is int and 1 <= value <= 6:
                continue
            if key == 'indent' and type(value) is int and 0 <= value <= 8:
                continue
            if key not in STRING_ATTRIBUTES or not isinstance(value, str):
                raise ValueError('Unsupported rich attribute')
            if len(value) > 2000:
                raise ValueError('Rich attribute too long')
            if key == 'link':
                link = urlparse(value.strip())
                if not ((link.scheme in ('http', 'https') and link.netloc)
                        or (link.scheme == 'mailto' and link.path)):
                    raise ValueError('Unsupported link scheme')
            elif key in ('color', 'background') and not re.fullmatch(r'#[0-9a-fA-F]{6,8}', value):
                raise ValueError('Invalid rich color')
            elif key == 'align' and value not in ('left', 'center', 'right', 'justify'):
                raise ValueError('Invalid alignment')
            elif key == 'list' and value not in ('bullet', 'ordered', 'checked', 'unchecked'):
                raise ValueError('Invalid list')
            elif key == 'direction' and value not in ('ltr', 'rtl'):
                raise ValueError('Invalid direction')
            elif key == 'script' and value not in ('super', 'sub'):
                raise ValueError('Invalid script')
            elif key == 'size' and not (value in ('small', 'large', 'huge')
                    or value.isdigit() and 8 <= int(value) <= 72):
                raise ValueError('Invalid font size')
            elif key == 'line-height' and not (re.fullmatch(r'\d+(\.\d+)?', value)
                    and 1 <= float(value) <= 3):
                raise ValueError('Invalid line height')
            elif key == 'font' and not value:
                raise ValueError('Invalid font')
    if not ops[-1]['insert'].endswith('\n'):
        raise ValueError('Rich document must end with newline')
    return ops


def validate_content(content):
    document_delta(content)
    return content


def plain_content(content):
    try:
        ops = document_delta(content)
    except (ValueError, TypeError):
        return content  # Preserve malformed legacy data instead of deleting it.
    if ops is None:
        return content
    return ''.join(op['insert'] for op in ops)[:-1]
