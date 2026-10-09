#!/usr/bin/env python3
"""Claude Code usage for the Sumi agents panel. Prints one JSON object."""
import glob, json, os, sys, time, datetime as dt, urllib.request, subprocess

HOME = os.path.expanduser("~")
CACHE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "sumi-agents-limits.json")
DAYS_DE = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

def limits():
    """5-hour and weekly utilisation from the Claude OAuth usage endpoint (cached 3 min)."""
    try:
        if time.time() - os.path.getmtime(CACHE) < 180:
            with open(CACHE) as f:
                return json.load(f)
    except Exception:
        pass
    out = {"ok": False}
    try:
        with open(os.path.join(HOME, ".claude", ".credentials.json")) as f:
            cred = json.load(f).get("claudeAiOauth", {})
        out["plan"] = (cred.get("subscriptionType") or "").capitalize()
        req = urllib.request.Request(
            "https://api.anthropic.com/api/oauth/usage",
            headers={"Authorization": "Bearer " + cred["accessToken"],
                     "anthropic-beta": "oauth-2025-04-20",
                     "Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=4) as r:
            data = json.load(r)
        for key, name in (("five_hour", "five"), ("seven_day", "week")):
            w = data.get(key) or {}
            if w.get("utilization") is not None:
                out[name] = {"pct": float(w["utilization"]), "resets": w.get("resets_at") or ""}
        out["ok"] = "five" in out
    except Exception as e:
        out["error"] = type(e).__name__
    try:
        with open(CACHE, "w") as f:
            json.dump(out, f)
    except Exception:
        pass
    return out

def tokens():
    today = dt.date.today()
    start = today - dt.timedelta(days=6)
    days = {start + dt.timedelta(days=i): {"cache": 0, "input": 0, "output": 0, "models": {}} for i in range(7)}
    seen = set()
    sessions = set()
    cutoff = time.time() - 8 * 86400
    for path in glob.glob(os.path.join(HOME, ".claude", "projects", "*", "*.jsonl")):
        try:
            if os.path.getmtime(path) < cutoff:
                continue
            with open(path, errors="ignore") as f:
                for line in f:
                    if '"usage"' not in line:
                        continue
                    try:
                        o = json.loads(line)
                    except Exception:
                        continue
                    msg = o.get("message") or {}
                    u = msg.get("usage")
                    ts = o.get("timestamp")
                    if not u or not ts:
                        continue
                    key = (msg.get("id"), o.get("requestId"))
                    if key in seen:
                        continue
                    seen.add(key)
                    d = dt.datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().date()
                    if d not in days:
                        continue
                    sessions.add(o.get("sessionId") or path)
                    b = days[d]
                    b["cache"] += int(u.get("cache_read_input_tokens") or 0) + int(u.get("cache_creation_input_tokens") or 0)
                    b["input"] += int(u.get("input_tokens") or 0)
                    b["output"] += int(u.get("output_tokens") or 0)
                    model = (msg.get("model") or "other")
                    fam = next((m for m in ("opus", "sonnet", "haiku", "fable") if m in model), "other")
                    b["models"][fam] = b["models"].get(fam, 0) + int(u.get("output_tokens") or 0) + int(u.get("input_tokens") or 0)
        except Exception:
            continue
    out = []
    for d in sorted(days):
        b = days[d]
        out.append({"date": d.isoformat(), "label": DAYS_DE[d.weekday()], "dateLabel": d.strftime("%d.%m."),
                    "cache": b["cache"], "input": b["input"], "output": b["output"], "models": b["models"]})
    return out, len(sessions)

def running():
    try:
        r = subprocess.run(["pgrep", "-c", "-x", "claude"], capture_output=True, text=True)
        return int(r.stdout.strip() or 0)
    except Exception:
        return 0

def main():
    res = {"installed": os.path.isdir(os.path.join(HOME, ".claude"))}
    res.update(limits())
    res["days"], res["sessions"] = tokens()
    res["weekTotal"] = sum(d["cache"] + d["input"] + d["output"] for d in res["days"])
    res["running"] = running()
    json.dump(res, sys.stdout)

if __name__ == "__main__":
    main()
