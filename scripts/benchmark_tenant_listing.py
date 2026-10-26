"""Isolated in-memory SQLite measurement; no network/provider or private data."""
import argparse
import json
from pathlib import Path
import statistics
import sys
import time
from datetime import datetime, timezone

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from backend.tests.test_listing_scaling import listing_fixture, add_unrelated, measured_listing

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
if args.output.exists():
    parser.error('Output already exists; preserve prior evidence')
results = []
for unrelated in (0, 20000):
    conn = listing_fixture()
    try:
        add_unrelated(conn, unrelated)
        measured_listing(conn)
        times = []
        for _ in range(11):
            start = time.perf_counter()
            rows, ticks = measured_listing(conn)
            times.append((time.perf_counter() - start) * 1000)
        results.append({'unrelated_notes': unrelated, 'visible_notes': len(rows),
                        'median_ms': round(statistics.median(times), 3),
                        'sqlite_steps_approx': ticks * 100})
    finally:
        conn.close()
output = {'date_utc': datetime.now(timezone.utc).isoformat(),
          'target': 'in-memory SQLite projection, 11 runs after warmup; not HTTP/FPS/load',
          'results': results}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(output, indent=2), encoding='utf-8')
print(json.dumps(output))
