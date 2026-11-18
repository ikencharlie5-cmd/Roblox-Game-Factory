#!/usr/bin/env python3
"""Turn a game's Rojo project into Luau chunks that recreate every script in Studio
(via the Studio MCP `execute_luau` tool). Used when Rojo can't connect.

Usage: python3 scripts/studio_sync.py <slug> [max_chunk_bytes] [--only path1,path2]
  --only: sync just these repo files (relative to games/<slug>/), no wipe. Good for small fixes.
Writes build/studio-sync/<slug>/chunk_NN.luau — run each one with execute_luau (Edit).
Chunk 00 deletes the old synced folders first so the result matches the repo exactly.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SERVICE_ROOTS = {"ReplicatedStorage", "ServerScriptService", "StarterPlayer", "ServerStorage",
                 "ReplicatedFirst", "StarterGui", "Workspace", "Lighting", "SoundService"}


def classify(path: Path):
    name = path.name
    for ext in (".luau", ".lua"):
        if name.endswith(".server" + ext):
            return name[: -len(".server" + ext)], "Script"
        if name.endswith(".client" + ext):
            return name[: -len(".client" + ext)], "LocalScript"
        if name.endswith(ext):
            return name[: -len(ext)], "ModuleScript"
    return None, None


def walk(node: dict, inst_path: list, base: Path, out: list, roots: list):
    if "$path" in node:
        src = base / node["$path"]
        roots.append("/".join(inst_path))
        add_dir(src, inst_path, out)
    for key, child in node.items():
        if key.startswith("$") or not isinstance(child, dict):
            continue
        walk(child, inst_path + [key], base, out, roots)


def add_dir(d: Path, inst_path: list, out: list):
    for f in sorted(d.iterdir()):
        if f.is_dir():
            init = next((f / n for n in ("init.luau", "init.lua") if (f / n).exists()), None)
            if init:
                out.append({"path": inst_path + [f.name], "class": "ModuleScript", "src": init.read_text()})
            else:
                out.append({"path": inst_path + [f.name], "class": "Folder", "src": None})
            add_dir(f, inst_path + [f.name], out)
        else:
            name, cls = classify(f)
            if cls and not name.startswith("init"):
                out.append({"path": inst_path + [name], "class": cls, "src": f.read_text(), "file": str(f)})


def long_string(s: str) -> str:
    level = 1
    while ("]" + "=" * level + "]") in s:
        level += 1
    eq = "=" * level
    return f"[{eq}[\n{s}]{eq}]"


HELPER = """local function at(path, class)
\tlocal parent = game
\tfor i, name in path do
\t\tlocal last = i == #path
\t\tlocal child = parent:FindFirstChild(name)
\t\tif i == 1 then child = game:GetService(name) end
\t\tif last and child and child.ClassName ~= class then child:Destroy(); child = nil end
\t\tif not child then
\t\t\tchild = Instance.new(if last then class else "Folder")
\t\t\tchild.Name = name
\t\t\tchild.Parent = parent
\t\tend
\t\tparent = child
\tend
\treturn parent
end
local n = 0
local function put(path, class, src)
\tlocal inst = at(path, class)
\tif src then (inst :: any).Source = src end
\tn += 1
end
"""


def main():
    args = [a for a in sys.argv[1:]]
    only = None
    if "--only" in args:
        i = args.index("--only")
        only = set(args[i + 1].split(","))
        del args[i:i + 2]
    slug = args[0]
    limit = int(args[1]) if len(args) > 1 else 60000
    base = ROOT / "games" / slug
    project = json.loads((base / "default.project.json").read_text())
    items, roots = [], []
    walk(project["tree"], [], base, items, roots)
    if only is not None:
        items = [it for it in items if it.get("file") and str(Path(it["file"]).relative_to(base)) in only]
        roots = []

    outdir = ROOT / "build" / "studio-sync" / slug
    outdir.mkdir(parents=True, exist_ok=True)
    for old in outdir.glob("chunk_*.luau"):
        old.unlink()

    chunks, cur = [], []
    size = 0
    for it in items:
        path_lua = "{" + ", ".join(json.dumps(x) for x in it["path"]) + "}"
        src_lua = long_string(it["src"]) if it["src"] is not None else "nil"
        line = f"put({path_lua}, {json.dumps(it['class'])}, {src_lua})\n"
        if cur and size + len(line) > limit:
            chunks.append(cur)
            cur, size = [], 0
        cur.append(line)
        size += len(line)
    if cur:
        chunks.append(cur)

    wipe = "".join(
        f'do local p = game:GetService("{r.split("/")[0]}") for _, nm in {{{", ".join(json.dumps(x) for x in r.split("/")[1:])}}} do p = p and p:FindFirstChild(nm) end if p and p ~= game:GetService("{r.split("/")[0]}") then p:Destroy() end end\n'
        for r in roots
    )
    for i, c in enumerate(chunks):
        body = HELPER + (wipe if i == 0 else "") + "".join(c) + f'return "chunk {i + 1}/{len(chunks)}: " .. n .. " items"\n'
        (outdir / f"chunk_{i:02d}.luau").write_text(body)
    print(f"{len(items)} items -> {len(chunks)} chunk(s) in {outdir.relative_to(ROOT)}")
    for i in range(len(chunks)):
        print(f"  chunk_{i:02d}.luau {(outdir / f'chunk_{i:02d}.luau').stat().st_size} bytes")


if __name__ == "__main__":
    main()
