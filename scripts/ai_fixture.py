"""Explicit loopback-only AI double for browser/native transport QA, never an LLM."""
import argparse
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import uvicorn
from backend.app import create_app


class FixtureProvider:
    mode = 'test-double'
    model = 'fixture-not-an-llm'

    def generate(self, kind, question, sources):
        if kind == 'summary':
            return {'summary': 'Kết quả fixture kiểm thử, không phải LLM: ' + sources[0]['context'][:400]}
        return {'sufficient': True,
                'answer': 'Kết quả fixture kiểm thử, không phải LLM. Nguồn demo: ' +
                          ' | '.join(s['context'][:250] for s in sources),
                'citations': [f'S{i+1}' for i in range(len(sources))]}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--allow-test-provider', action='store_true', required=True)
    args = parser.parse_args()
    app = create_app(ROOT / 'tmp/ai-fixture.sqlite3', ai_provider=FixtureProvider())
    # Both UI test origins and fixtures stay localhost. No access logging of body/tokens.
    print('LOCAL TEST DOUBLE on 8012. No Gemini request, no production claim.', flush=True)
    uvicorn.run(app, host='127.0.0.1', port=8012, access_log=False)
