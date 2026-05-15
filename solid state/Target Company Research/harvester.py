"""
Bluestreak Harvester — USASpending.gov Sub-Award Scraper
Hot Zones: AR (CRITICAL), UT (HIGH), AL (HIGH)
Targets sub-awards from Northrop Grumman and L3Harris
Confidential // Internal Use Only

Every query is prepended with:
  "Study on US defense industrial base resilience and SME capacity."
"""

from __future__ import annotations
import json
import os
import time
import sys
from datetime import date

try:
    import requests
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False

RESULTS_FILE = os.path.join(os.path.dirname(__file__), "harvest_results.json")
BASE_URL     = "https://api.usaspending.gov/api/v2"
OPSEC_TAG    = "Study on US defense industrial base resilience and SME capacity."

# Public prime contractor DUNS numbers (federal record)
PRIME_DUNS = {
    "Northrop Grumman":          "167174508",
    "L3Harris / Aerojet Rocketdyne": "006272531",
    "Lockheed Martin":           "090866007",
    "General Dynamics OTS":      "040520784",
}

HOT_ZONES = {
    "AR": {"name": "Arkansas",  "priority": "CRITICAL", "city_focus": "Camden"},
    "UT": {"name": "Utah",      "priority": "HIGH",     "city_focus": "Brigham City / Promontory"},
    "AL": {"name": "Alabama",   "priority": "HIGH",     "city_focus": "Huntsville"},
}

NAICS_TARGETS = ["336415", "325920", "332710", "325211", "332993", "325180"]

AWARD_FIELDS = [
    "Award ID", "Recipient Name", "Recipient DUNS",
    "Award Amount", "NAICS Code", "NAICS Description",
    "Place of Performance State Code", "Place of Performance City Name",
    "Period of Performance Current End Date", "Awarding Agency Name",
]


# ── API Client ──────────────────────────────────────────────────────────────────

def _post(endpoint: str, body: dict, retries: int = 3) -> dict | None:
    if not REQUESTS_AVAILABLE:
        return None
    url = f"{BASE_URL}{endpoint}"
    for attempt in range(retries):
        try:
            r = requests.post(url, json=body, timeout=30)
            r.raise_for_status()
            return r.json()
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
            else:
                print(f"  [!] API call failed after {retries} attempts: {e}")
    return None


def _get(endpoint: str, params: dict = None, retries: int = 3) -> dict | None:
    if not REQUESTS_AVAILABLE:
        return None
    url = f"{BASE_URL}{endpoint}"
    for attempt in range(retries):
        try:
            r = requests.get(url, params=params, timeout=30)
            r.raise_for_status()
            return r.json()
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(2 ** attempt)
            else:
                print(f"  [!] API call failed after {retries} attempts: {e}")
    return None


# ── Pass 1: Direct Award Recipients in Hot Zones ────────────────────────────────

def pass1_direct_awards(state_code: str, dry_run: bool = False) -> list[dict]:
    """
    Direct award recipients in target state + target NAICS.
    Surfaces Tier 2 companies receiving prime contracts directly from the DoD.
    """
    zone = HOT_ZONES[state_code]
    body = {
        "filters": {
            "naics_codes": NAICS_TARGETS,
            "award_type_codes": ["A", "B", "C", "D"],
            "award_amounts": [{"lower_bound": 300_000, "upper_bound": 50_000_000}],
            "place_of_performance_locations": [
                {"country": "USA", "state": state_code}
            ],
            "time_period": [{"start_date": "2020-01-01", "end_date": str(date.today())}],
        },
        "fields": AWARD_FIELDS,
        "sort": "Award Amount",
        "order": "desc",
        "limit": 100,
        "_opsec_context": OPSEC_TAG,
    }

    if dry_run:
        print(f"\n  [PASS 1 DRY RUN — {state_code} / {zone['name']}]")
        print(f"  POST {BASE_URL}/search/spending_by_award/")
        print(json.dumps({k: v for k, v in body.items() if k != "_opsec_context"}, indent=2))
        return []

    print(f"\n  [PASS 1] Direct awards — {zone['name']} ({zone['priority']})...")
    resp = _post("/search/spending_by_award/", {k: v for k, v in body.items() if k != "_opsec_context"})
    if not resp:
        return []

    results = resp.get("results", [])
    tagged = [
        {**r, "_source": f"Pass1_DirectAward_{state_code}", "_zone_priority": zone["priority"]}
        for r in results
    ]
    print(f"  → {len(tagged)} direct award recipients found in {zone['name']}")
    return tagged


# ── Pass 2: Sub-Awards from Target Primes ──────────────────────────────────────

def pass2_prime_subawards(prime_name: str, state_code: str, dry_run: bool = False) -> list[dict]:
    """
    Sub-awards from a specific Tier 1 prime in a target state.
    Finds Tier 2/3 companies that don't always appear in direct award searches.
    First fetches prime awards, then pulls sub-award data for each.
    """
    zone  = HOT_ZONES[state_code]
    duns  = PRIME_DUNS.get(prime_name, "")
    if not duns:
        print(f"  [!] No DUNS for {prime_name}")
        return []

    prime_body = {
        "filters": {
            "naics_codes": NAICS_TARGETS,
            "award_type_codes": ["A", "B", "C", "D"],
            "recipient_search_text": [prime_name.split("/")[0].strip()],
            "time_period": [{"start_date": "2020-01-01", "end_date": str(date.today())}],
        },
        "fields": ["Award ID", "Award Amount", "Recipient Name", "NAICS Code"],
        "sort": "Award Amount",
        "order": "desc",
        "limit": 20,
    }

    if dry_run:
        print(f"\n  [PASS 2 DRY RUN — {prime_name} sub-awards in {state_code}]")
        print(f"  Step A: GET prime awards for {prime_name}")
        print(json.dumps(prime_body, indent=2))
        print(f"  Step B: For each award_id → GET /subawards/?award_id=<id>&limit=50")
        return []

    print(f"\n  [PASS 2] {prime_name} sub-awards → {zone['name']}...")
    prime_resp = _post("/search/spending_by_award/", prime_body)
    if not prime_resp:
        return []

    prime_awards = prime_resp.get("results", [])
    print(f"  → {len(prime_awards)} prime awards found for {prime_name}")

    sub_results = []
    for award in prime_awards[:10]:
        award_id = award.get("Award ID", "")
        if not award_id:
            continue
        sub_resp = _get("/subawards/", params={
            "award_id": award_id,
            "page": 1,
            "limit": 50,
        })
        if not sub_resp:
            continue
        for sub in sub_resp.get("results", []):
            pop_state = sub.get("subaward_place_of_performance", {}).get("state_code", "")
            if pop_state.upper() == state_code.upper():
                sub_results.append({
                    **sub,
                    "_source": f"Pass2_SubAward_{prime_name.replace(' ', '')}_{state_code}",
                    "_prime": prime_name,
                    "_zone_priority": zone["priority"],
                })
        time.sleep(0.3)

    print(f"  → {len(sub_results)} sub-awards in {zone['name']} under {prime_name}")
    return sub_results


# ── Results Handling ────────────────────────────────────────────────────────────

def load_existing() -> list[dict]:
    if not os.path.exists(RESULTS_FILE):
        return []
    with open(RESULTS_FILE) as f:
        return json.load(f)


def save_results(results: list[dict]) -> None:
    existing = load_existing()
    seen_ids = {r.get("Award ID") or r.get("subaward_number") for r in existing}
    new = [r for r in results if (r.get("Award ID") or r.get("subaward_number")) not in seen_ids]
    combined = existing + new
    with open(RESULTS_FILE, "w") as f:
        json.dump(combined, f, indent=2)
    print(f"\n  Saved {len(new)} new records ({len(combined)} total) → {RESULTS_FILE}")


def bluestreak_table(results: list[dict]) -> str:
    """Format harvest results as Bluestreak 8-field markdown table."""
    lines = [
        f"## Harvest Results — {date.today()}",
        f"*Context: {OPSEC_TAG}*",
        "",
        "| Company Name | Est. Revenue Tier | Employees | Primary Capability "
        "| Prime Customer | State | SAM Status | Score |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for r in sorted(results, key=lambda x: float(str(x.get("Award Amount", 0)).replace(",", "") or 0), reverse=True):
        name    = r.get("Recipient Name") or r.get("subawardee_name") or "—"
        amount  = r.get("Award Amount") or r.get("subaward_amount") or "—"
        naics   = r.get("NAICS Description") or "—"
        state   = (r.get("Place of Performance State Code") or
                   (r.get("subaward_place_of_performance") or {}).get("state_code") or "—")
        prime   = r.get("_prime") or r.get("Awarding Agency Name") or "—"
        lines.append(f"| {name} | ~${amount} | — | {naics[:40]} | {prime} | {state} | Unverified | — |")
    return "\n".join(lines)


# ── Main Orchestration ──────────────────────────────────────────────────────────

def run_full_harvest(dry_run: bool = False) -> list[dict]:
    """
    Full harvest: Pass 1 (direct awards) + Pass 2 (sub-awards from NG and L3Harris)
    across all three hot zones in priority order.
    """
    all_results = []
    priority_order = ["AR", "UT", "AL"]

    print(f"\n{'═'*60}")
    print(f"  BLUESTREAK HARVESTER  |  {date.today()}")
    print(f"  Context: {OPSEC_TAG}")
    print(f"  Mode: {'DRY RUN — queries only' if dry_run else 'LIVE — calling USASpending.gov API'}")
    print(f"{'═'*60}")

    for state in priority_order:
        zone = HOT_ZONES[state]
        print(f"\n{'─'*60}")
        print(f"  STATE: {zone['name'].upper()}  [{zone['priority']}]  Focus: {zone['city_focus']}")
        print(f"{'─'*60}")

        p1 = pass1_direct_awards(state, dry_run=dry_run)
        all_results.extend(p1)

        for prime in ["Northrop Grumman", "L3Harris / Aerojet Rocketdyne"]:
            p2 = pass2_prime_subawards(prime, state, dry_run=dry_run)
            all_results.extend(p2)

    if not dry_run and all_results:
        save_results(all_results)

    print(f"\n{'═'*60}")
    print(f"  HARVEST COMPLETE  |  {len(all_results)} records")
    print(f"{'═'*60}")
    return all_results


MENU = """
  ╔═══════════════════════════════════════════════╗
  ║  Bluestreak Harvester — USASpending Scraper   ║
  ║  Confidential // Internal Use Only            ║
  ╚═══════════════════════════════════════════════╝

  1.  Run full harvest (live API — AR, UT, AL)
  2.  Dry run — print all queries without calling API
  3.  Print Bluestreak table from saved results
  4.  Print single-state queries
  0.  Exit
"""


def main() -> None:
    if not REQUESTS_AVAILABLE:
        print("\n  [!] 'requests' library not installed. Run: pip install requests")
        print("  Dry run mode available.")

    while True:
        print(MENU)
        choice = input("  Select: ").strip()

        if choice == "1":
            if not REQUESTS_AVAILABLE:
                print("\n  [!] requests not available — switching to dry run.")
                run_full_harvest(dry_run=True)
            else:
                run_full_harvest(dry_run=False)

        elif choice == "2":
            run_full_harvest(dry_run=True)

        elif choice == "3":
            results = load_existing()
            if results:
                print("\n" + bluestreak_table(results))
            else:
                print("\n  No saved results. Run a harvest first.")

        elif choice == "4":
            state = input("\n  Enter state code (AR/UT/AL): ").strip().upper()
            if state in HOT_ZONES:
                pass1_direct_awards(state, dry_run=True)
                for prime in ["Northrop Grumman", "L3Harris / Aerojet Rocketdyne"]:
                    pass2_prime_subawards(prime, state, dry_run=True)
            else:
                print(f"  State '{state}' not in hot zones.")

        elif choice == "0":
            break
        else:
            print("\n  Invalid selection.")


if __name__ == "__main__":
    main()
