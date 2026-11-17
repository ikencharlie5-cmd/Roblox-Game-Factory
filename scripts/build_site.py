#!/usr/bin/env python3
"""Collects every game's status + docs and the inspiration files into _site/ for GitHub Pages."""
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "_site"
IMG = {".png", ".jpg", ".jpeg", ".gif", ".webp"}
DOCS = ["SPEC.md", "QUESTIONS.md", "DECISIONS.md", "CHECK_REPORT.md", "SIGNOFF.md", "README.md"]


def read(p: Path) -> str:
    return p.read_text(errors="replace") if p.exists() else ""


def collect_inspo(folder: Path, url_prefix: str):
    items = []
    if not folder.exists():
        return items
    for f in sorted(folder.iterdir()):
        if f.name.startswith(".") or f.name == "README.md" or not f.is_file():
            continue
        dest = OUT / url_prefix / f.name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(f, dest)
        kind = "image" if f.suffix.lower() in IMG else "text" if f.suffix.lower() in {".md", ".txt"} else "file"
        items.append({
            "name": f.name,
            "url": f"{url_prefix}/{f.name}",
            "kind": kind,
            "text": read(f)[:2000] if kind == "text" else "",
        })
    return items


def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir()
    shutil.copytree(ROOT / "site", OUT, dirs_exist_ok=True)

    games = []
    for d in sorted((ROOT / "games").glob("*/")):
        status_file = d / "status.json"
        if not status_file.exists():
            continue
        g = json.loads(status_file.read_text())
        g["docs"] = {name: read(d / name) for name in DOCS if (d / name).exists()}
        g["docs"]["RESEARCH.md"] = read(d / "research" / "RESEARCH.md")
        g["notes"] = {f.stem: read(f) for f in sorted((d / "notes").glob("*.md"))}
        g["inspiration"] = collect_inspo(d / "inspiration", f"inspo/{d.name}")
        games.append(g)
    games.sort(key=lambda g: g.get("updated", ""), reverse=True)

    data = {"games": games, "inspiration": collect_inspo(ROOT / "inspiration", "inspo/_global")}
    (OUT / "data.json").write_text(json.dumps(data, indent=1))
    print(f"Built _site with {len(games)} game(s)")


if __name__ == "__main__":
    main()
