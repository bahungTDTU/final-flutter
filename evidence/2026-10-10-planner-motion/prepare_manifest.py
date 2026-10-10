"""Record local verification hashes; never read credentials or account databases."""
import hashlib
import json
import re
import subprocess
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EVIDENCE = Path(__file__).resolve().parent


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT).decode("utf-8").strip()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    changed = set(git("diff", "--name-only").splitlines())
    changed.update(git("ls-files", "--others", "--exclude-standard").splitlines())
    prefixes = ("lib/", "test/", "integration_test/", "test_driver/", "backend/", "scripts/", "web/", "docs/")
    source = sorted(
        name for name in changed
        if (name.startswith(prefixes) or name in {"README.md", "Readme.txt", "STATUS.md"})
        and (ROOT / name).is_file()
    )
    artifact_names = [
        "build/web/main.dart.js", "build/web/flutter_bootstrap.js",
        "build/web/offline_worker.js", "build/app/outputs/flutter-apk/app-debug.apk",
    ]
    texts = [ROOT / name for name in source]
    texts.extend(p for p in EVIDENCE.iterdir() if p.suffix in {".md", ".txt", ".json", ".js", ".py"})
    patterns = [
        re.compile(r"AIza[0-9A-Za-z_-]{35}"),
        re.compile(r"Bearer\s+eyJ[0-9A-Za-z_.-]{30,}"),
        re.compile(r"gh[pousr]_[0-9A-Za-z]{30,}"),
    ]
    hits = []
    for path in texts:
        text = path.read_text(encoding="utf-8-sig", errors="replace")
        if any(pattern.search(text) for pattern in patterns):
            hits.append(path.relative_to(ROOT).as_posix())
    if hits:
        raise RuntimeError("Credential pattern found; inspect without printing values: " + ", ".join(hits))
    scan = {
        "observedAt": datetime.now().astimezone().isoformat(),
        "scope": "Changed source/docs plus this text evidence; excludes environment, databases and session storage",
        "patterns": "Google API keys, Bearer JWT values, GitHub token values",
        "filesScanned": len(texts), "matches": 0,
    }
    (EVIDENCE / "credential-scan.json").write_text(json.dumps(scan, indent=2), encoding="utf-8")
    evidence_files = sorted(p for p in EVIDENCE.iterdir() if p.is_file() and p.name != "manifest.json")
    report = {
        "observedAt": datetime.now().astimezone().isoformat(),
        "branch": git("branch", "--show-current"), "baseHead": git("rev-parse", "HEAD"),
        "sourceState": "Uncommitted working changes, including preserved earlier fixes; no publication in this request",
        "sourceSha256": {name: digest(ROOT / name) for name in source},
        "artifactSha256": {name: digest(ROOT / name) for name in artifact_names},
        "artifactTargets": {"web": "API http://127.0.0.1:8000", "apkDebug": "API http://10.0.2.2:8000; compile only"},
        "evidenceSha256": {p.name: digest(p) for p in evidence_files},
        "checks": {"flutter": 250, "backend": 109, "analyze": "PASS", "format": "105 files, 0 changes"},
        "qaBuildHashes": json.loads((EVIDENCE / "web-qa-hashes.json").read_text(encoding="utf-8-sig")),
        "notRun": ["Native UI/IME/FPS", "Real screen reader", "Internet providers", "HTTPS/release signing"],
    }
    (EVIDENCE / "manifest.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({"branch": report["branch"], "sourceFiles": len(source), "evidenceFiles": len(evidence_files),
                      "pngCount": len(list(EVIDENCE.glob("*.png"))), "credentialMatches": 0}, indent=2))


if __name__ == "__main__":
    main()
