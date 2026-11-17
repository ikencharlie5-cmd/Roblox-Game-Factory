#!/usr/bin/env bash
# Usage: scripts/new-game.sh <slug> "<Game Name>"
set -euo pipefail
cd "$(dirname "$0")/.."

slug="${1:?slug required}"
name="${2:-$slug}"
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

echo "Created $dest"
