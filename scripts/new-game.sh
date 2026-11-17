#!/usr/bin/env bash
# Usage: scripts/new-game.sh <slug> "<Game Name>" "<idea>"
set -euo pipefail
cd "$(dirname "$0")/.."

slug="${1:?slug required}"
name="${2:-$slug}"
idea="${3:-}"
dest="games/$slug"

if [ -e "$dest" ]; then
  echo "error: $dest already exists" >&2
  exit 1
fi

cp -r template "$dest"
find "$dest" -type f \( -name '*.luau' -o -name '*.json' \) -print0 |
  xargs -0 sed -i "s/__GAME_NAME__/$name/g; s/__GAME_SLUG__/$slug/g"

cp docs/SPEC_TEMPLATE.md "$dest/SPEC.md"
sed -i "s/<Game Name>/$name/" "$dest/SPEC.md"

cat > "$dest/DECISIONS.md" <<EOF
# $name — decisions made without asking

| Decision | Why |
|---|---|
EOF

cat > "$dest/README.md" <<EOF
# $name
by Chiken Studios

## How to play
TBD

## How to publish
1. Download \`$slug.rbxl\` from the latest GitHub Actions run (Artifacts), or run
   \`rojo build games/$slug -o $slug.rbxl\`.
2. Open it in Roblox Studio → File → Publish to Roblox.
3. Game Settings → Security → turn on **Studio Access to API Services** (for saving).

## Charlie TODO
- [ ] Create Game Passes / Dev Products and paste their IDs into \`src/shared/Config.luau\`
EOF

mkdir -p "$dest/notes" "$dest/inspiration"
touch "$dest/inspiration/.gitkeep"
printf '# Open questions\n\n' > "$dest/QUESTIONS.md"
NAME="$name" SLUG="$slug" IDEA="$idea" python3 - "$dest/status.json" <<'PY'
import json, os, sys, time
now = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
data = {
    "name": os.environ["NAME"], "slug": os.environ["SLUG"], "idea": os.environ["IDEA"],
    "stage": "research", "created": now, "updated": now,
    "branches": {"gameplay": "waiting", "graphics": "waiting", "ui": "waiting"},
    "log": [{"time": now, "from": "charlie", "to": "rnd", "text": os.environ["IDEA"] or "New game"}],
}
open(sys.argv[1], "w").write(json.dumps(data, indent=2) + "\n")
PY
echo "Created $dest"
