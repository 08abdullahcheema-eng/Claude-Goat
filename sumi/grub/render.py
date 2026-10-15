# Build step for the Sumi GRUB themes (run by sumi-login.nix, not by hand).
# Fills {{F:font}} with the real GRUB name of fonts/<font>.pf2 and {{DIR}} with the
# folder prefix, writes <theme>/theme.txt for each theme and theme.txt (sumi) at the top.
import os, re, struct, sys

out = sys.argv[1]

def pf2_name(path):
    with open(path, "rb") as f:
        data = f.read()
    pos = 0
    while pos + 8 <= len(data):
        tag = data[pos:pos + 4]
        size = struct.unpack(">I", data[pos + 4:pos + 8])[0]
        if tag == b"NAME":
            return data[pos + 8:pos + 8 + size].split(b"\0")[0].decode()
        if tag == b"DATA":
            break
        pos += 8 + size
    raise SystemExit("no NAME in " + path)

names = {}
for f in os.listdir(os.path.join(out, "fonts")):
    if f.endswith(".pf2"):
        names[f[:-4]] = pf2_name(os.path.join(out, "fonts", f))
        print(f"{f[:-4]:16} -> {names[f[:-4]]}")

def render(src, prefix):
    s = open(src, encoding="utf-8").read()
    s = re.sub(r"\{\{F:([\w-]+)\}\}", lambda m: names[m.group(1)], s)
    return s.replace("{{DIR}}", prefix)

themes = [d for d in sorted(os.listdir(out)) if os.path.isfile(os.path.join(out, d, "theme.txt.in"))]
for t in themes:
    src = os.path.join(out, t, "theme.txt.in")
    open(os.path.join(out, t, "theme.txt"), "w", encoding="utf-8").write(render(src, ""))
open(os.path.join(out, "theme.txt"), "w", encoding="utf-8").write(render(os.path.join(out, "yoru", "theme.txt.in"), "yoru/"))
for t in themes:
    os.remove(os.path.join(out, t, "theme.txt.in"))
print("themes:", " ".join(themes))
