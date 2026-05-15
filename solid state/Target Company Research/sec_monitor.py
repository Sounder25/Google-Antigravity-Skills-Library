"""
SEC EDGAR Divestiture Monitor — Project Bluestreak
Watches 8-K and 10-K filings from Tier 1 primes for propulsion/energetics
divestiture signals. A Tier 1 prime filing divestiture language = highest-confidence
acquisition signal — non-core propulsion units entering the market.
Confidential // Internal Use Only
"""

from __future__ import annotations
import json
import os
import time
from datetime import date, timedelta
from urllib.parse import urlencode

try:
    import requests
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False

WATCH_FILE   = os.path.join(os.path.dirname(__file__), "sec_watch_log.json")
EDGAR_EFTS   = "https://efts.sec.gov/LATEST/search-index"
EDGAR_SEARCH = "https://efts.sec.gov/LATEST/search-index"
OPSEC_TAG    = "Study on US defense industrial base resilience and SME capacity."

# Tier 1 prime CIK numbers (SEC public record)
PRIME_CIK = {
    "Northrop Grumman":    "1133421",
    "L3Harris Technologies": "1039101",
    "Lockheed Martin":     "936468",
    "General Dynamics":    "40533",
    "RTX / Raytheon":      "101829",
    "Anduril Industries":  "",
}

# Terms that individually flag a divestiture event
TRIGGER_TERMS = [
    "divestiture",
    "discontinued operations",
    "strategic sale",
    "sale of subsidiary",
    "disposal of business",
    "divest",
    "spin-off",
    "carve-out",
]

# Propulsion/energetics context words — filing must contain at least one
PROPULSION_CONTEXT = [
    "propulsion",
    "energetics",
    "solid rocket",
    "rocket motor",
    "propellant",
    "munitions",
    "ordnance",
    "missile systems",
    "aerospace systems",
    "defense systems",
]

# Filing types to monitor
FILING_TYPES = ["8-K", "10-K"]

# Lookback window (days) for fresh alerts
DEFAULT_LOOKBACK_DAYS = 90


# ── EDGAR EFTS Query Builder ────────────────────────────────────────────────────

def build_edgar_query(trigger: str, context: str, form: str,
                      cik: str = "", lookback_days: int = DEFAULT_LOOKBACK_DAYS) -> dict:
    """
    Builds a parameterized EDGAR full-text search query.
    Combines trigger term + propulsion context to reduce false positives.
    """
    start = (date.today() - timedelta(days=lookback_days)).isoformat()
    q = f'"{trigger}" "{context}"'
    params = {
        "q":         q,
        "forms":     form,
        "dateRange": "custom",
        "startdt":   start,
        "enddt":     str(date.today()),
    }
    if cik:
        params["entity"] = cik
    return {
        "url":    EDGAR_EFTS,
        "params": params,
        "query":  q,
        "form":   form,
        "start":  start,
    }


def build_all_queries(lookback_days: int = DEFAULT_LOOKBACK_DAYS) -> list[dict]:
    """Generate the full cross-product of trigger × context × filing type × prime."""
    queries = []

    high_value_pairs = [
        ("divestiture",              "propulsion"),
        ("divestiture",              "solid rocket"),
        ("divestiture",              "energetics"),
        ("discontinued operations",  "propulsion"),
        ("discontinued operations",  "rocket motor"),
        ("strategic sale",           "aerospace systems"),
        ("strategic sale",           "propellant"),
        ("sale of subsidiary",       "munitions"),
        ("sale of subsidiary",       "missile systems"),
        ("spin-off",                 "defense systems"),
        ("carve-out",                "propulsion"),
        ("divest",                   "solid rocket"),
    ]

    for trigger, context in high_value_pairs:
        for form in FILING_TYPES:
            # Broad search (all filers)
            queries.append({
                **build_edgar_query(trigger, context, form, lookback_days=lookback_days),
                "_prime": "ALL",
                "_priority": "HIGH" if form == "8-K" else "MODERATE",
            })
            # Prime-specific searches (CIK-targeted)
            for prime, cik in PRIME_CIK.items():
                if cik:
                    queries.append({
                        **build_edgar_query(trigger, context, form, cik=cik,
                                            lookback_days=lookback_days),
                        "_prime": prime,
                        "_priority": "CRITICAL" if form == "8-K" else "HIGH",
                    })

    return queries


# ── Live Monitor ────────────────────────────────────────────────────────────────

def run_monitor(lookback_days: int = DEFAULT_LOOKBACK_DAYS,
                dry_run: bool = False) -> list[dict]:
    """Execute all EDGAR queries and collect filings with divestiture signals."""
    queries = build_all_queries(lookback_days)
    hits: list[dict] = []

    print(f"\n{'═'*60}")
    print(f"  SEC EDGAR DIVESTITURE MONITOR  |  {date.today()}")
    print(f"  Context: {OPSEC_TAG}")
    print(f"  Lookback: {lookback_days} days  |  Queries: {len(queries)}")
    print(f"  Mode: {'DRY RUN' if dry_run else 'LIVE'}")
    print(f"{'═'*60}")

    seen: set[str] = set()

    for i, q in enumerate(queries, 1):
        label = f"[{q['_prime']}] {q['form']} — {q['query']}"

        if dry_run:
            url_str = q["url"] + "?" + urlencode(q["params"])
            print(f"  Q{i:>3}: {url_str}")
            continue

        if not REQUESTS_AVAILABLE:
            print(f"  [!] requests not available. Run: pip install requests")
            break

        try:
            r = requests.get(q["url"], params=q["params"], timeout=20)
            r.raise_for_status()
            data = r.json()
        except Exception as e:
            print(f"  [!] {label} — {e}")
            time.sleep(1)
            continue

        filings = data.get("hits", {}).get("hits", [])
        for f in filings:
            src  = f.get("_source", {})
            uid  = src.get("file_date", "") + src.get("period_of_report", "") + src.get("entity_name", "")
            if uid in seen:
                continue
            seen.add(uid)

            hit = {
                "entity_name":    src.get("entity_name", "—"),
                "form_type":      src.get("form_type", q["form"]),
                "filed_date":     src.get("file_date", "—"),
                "period":         src.get("period_of_report", "—"),
                "trigger_terms":  q["query"],
                "prime_match":    q["_prime"],
                "priority":       q["_priority"],
                "edgar_url":      f"https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK={src.get('entity_id','')}&type={q['form']}&dateb=&owner=include&count=40",
                "excerpt":        src.get("description", "")[:200],
                "date_captured":  str(date.today()),
            }
            hits.append(hit)
            print(f"  ⚑ HIT [{hit['priority']}] {hit['entity_name']} | {hit['form_type']} | {hit['filed_date']}")
            print(f"       Terms: {hit['trigger_terms']}")

        time.sleep(0.5)

    if not dry_run and hits:
        _save_watch_log(hits)

    print(f"\n  Monitor complete. {len(hits)} new divestiture signals found.")
    return hits


def _save_watch_log(new_hits: list[dict]) -> None:
    existing = []
    if os.path.exists(WATCH_FILE):
        with open(WATCH_FILE) as f:
            existing = json.load(f)
    combined = existing + new_hits
    with open(WATCH_FILE, "w") as f:
        json.dump(combined, f, indent=2)
    print(f"  Saved {len(new_hits)} new signals → {WATCH_FILE}")


def load_watch_log() -> list[dict]:
    if not os.path.exists(WATCH_FILE):
        return []
    with open(WATCH_FILE) as f:
        return json.load(f)


def print_alert_table() -> None:
    log = load_watch_log()
    if not log:
        print("\n  No signals in watch log. Run monitor first.")
        return

    critical = [h for h in log if h.get("priority") == "CRITICAL"]
    high     = [h for h in log if h.get("priority") == "HIGH"]
    moderate = [h for h in log if h.get("priority") == "MODERATE"]

    print(f"\n{'═'*70}")
    print(f"  SEC EDGAR WATCH LOG  |  {len(log)} signals  |  {date.today()}")
    print(f"{'═'*70}")

    for label, group in [("CRITICAL", critical), ("HIGH", high), ("MODERATE", moderate)]:
        if not group:
            continue
        print(f"\n  [{label}]")
        for h in group:
            print(f"  • {h['entity_name']:<35} {h['form_type']:<6} {h['filed_date']}")
            print(f"    Terms: {h['trigger_terms']}")
            if h.get("excerpt"):
                print(f"    Excerpt: {h['excerpt'][:100]}...")

    print(f"\n{'═'*70}")


def print_query_manifest() -> None:
    """Print the full query plan — useful for manual execution or review."""
    queries = build_all_queries()
    print(f"\n  SEC EDGAR Query Manifest — {len(queries)} queries")
    print(f"  Context: {OPSEC_TAG}\n")

    critical_q = [q for q in queries if q["_prime"] != "ALL" and q["_priority"] in ("CRITICAL", "HIGH")]
    for q in critical_q[:20]:
        url = q["url"] + "?" + urlencode(q["params"])
        print(f"  [{q['_priority']}] [{q['_prime']}] {q['form']} → {url}")


MENU = """
  ╔══════════════════════════════════════════════╗
  ║  SEC EDGAR Divestiture Monitor               ║
  ║  Project Bluestreak // Internal Use Only     ║
  ╚══════════════════════════════════════════════╝

  1.  Run live monitor (EDGAR EFTS API — last 90 days)
  2.  Run with custom lookback window
  3.  Dry run — print all queries without calling API
  4.  Print alert table (saved signals)
  5.  Print query manifest
  0.  Exit
"""


def main() -> None:
    while True:
        print(MENU)
        choice = input("  Select: ").strip()

        if choice == "1":
            run_monitor(lookback_days=90, dry_run=not REQUESTS_AVAILABLE)

        elif choice == "2":
            try:
                days = int(input("  Lookback days (e.g. 365): ").strip())
            except ValueError:
                days = 90
            run_monitor(lookback_days=days, dry_run=not REQUESTS_AVAILABLE)

        elif choice == "3":
            run_monitor(dry_run=True)

        elif choice == "4":
            print_alert_table()

        elif choice == "5":
            print_query_manifest()

        elif choice == "0":
            break
        else:
            print("\n  Invalid selection.")


if __name__ == "__main__":
    main()
