#!/usr/bin/env python3
"""Apply exact-text edits to a game's repo files AND emit Luau that applies the same edits to
the matching scripts in Studio (run the output with the Studio MCP execute_luau, Edit mode).

Usage: python3 scripts/studio_patch.py <slug> <patch.json>
patch.json: [{"file": "src/client/UI/SideBar.luau", "old": "...", "new": "..."}, ...]
  - "old" must occur exactly once in the file. Use "old": null + "new": "<full text>" to create
    or replace a whole file (sent in full to Studio).
Writes build/studio-patch/<slug>.luau and prints its size.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import studio_sync  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent


def inst_path_for(slug: str, rel: str):
    base = ROOT / "games" / slug
    project = json.loads((base / "default.project.json").read_text())
    items, roots = [], []
    studio_sync.walk(project["tree"], [], base, items, roots)
    for it in items:
        if it.get("file") and str(Path(it["file"]).relative_to(base)) == rel:
            return it["path"], it["class"]
    # init.luau folder modules
    p = Path(rel)
    if p.name in ("init.luau", "init.lua"):
        for it in items:
            if it["class"] == "ModuleScript" and it.get("file") is None and it["src"] is not None:
                pass
    raise SystemExit(f"no instance for {rel}")


def main():
    slug, patch_file = sys.argv[1], sys.argv[2]
    edits = json.loads(Path(patch_file).read_text())
    base = ROOT / "games" / slug
    lua = [
        "local function find(path)\n\tlocal p = game:GetService(path[1])\n"
        "\tfor i = 2, #path do p = p:FindFirstChild(path[i]); assert(p, 'missing ' .. path[i]) end\n\treturn p\nend\n",
        "local function rep(inst, a, b)\n\tlocal s = inst.Source\n\tlocal i, j = string.find(s, a, 1, true)\n"
        "\tassert(i, inst.Name .. ': text not found: ' .. string.sub(a, 1, 60))\n"
        "\tinst.Source = string.sub(s, 1, i - 1) .. b .. string.sub(s, j + 1)\nend\n",
        "local n = 0\n",
    ]
    for e in edits:
        f = base / e["file"]
        if e.get("old") is None:
            f.parent.mkdir(parents=True, exist_ok=True)
            f.write_text(e["new"])
            path, cls = inst_path_for(slug, e["file"])
            path_lua = "{" + ", ".join(json.dumps(x) for x in path) + "}"
            lua.append(
                "do\n\tlocal parent = game:GetService(" + json.dumps(path[0]) + ")\n"
                f"\tfor i, nm in {path_lua} do if i > 1 then local c = parent:FindFirstChild(nm)"
                f" if not c then c = Instance.new(i == #{path_lua} and {json.dumps(cls)} or 'Folder') c.Name = nm"
                " c.Parent = parent end parent = c end end\n"
                f"\tparent.Source = {studio_sync.long_string(e['new'])}\n\tn += 1\nend\n"
            )
            continue
        text = f.read_text()
        if text.count(e["old"]) != 1:
            raise SystemExit(f"{e['file']}: 'old' found {text.count(e['old'])} times: {e['old'][:60]!r}")
        f.write_text(text.replace(e["old"], e["new"]))
        path, _ = inst_path_for(slug, e["file"])
        path_lua = "{" + ", ".join(json.dumps(x) for x in path) + "}"
        lua.append(
            f"rep(find({path_lua}), {studio_sync.long_string(e['old'])}, {studio_sync.long_string(e['new'])})\nn += 1\n"
        )
    lua.append('return "applied " .. n .. " edits"\n')
    out = ROOT / "build" / "studio-patch" / f"{slug}.luau"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("".join(lua))
    print(f"{len(edits)} edits applied to repo -> {out.relative_to(ROOT)} ({out.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
