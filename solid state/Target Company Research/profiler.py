"""
Solid State Propellant Rocket — Tier 2/3 Supplier Acquisition Profiler
Confidential // Internal Use Only
"""

import json
import csv
import os
from datetime import date

DATA_FILE = os.path.join(os.path.dirname(__file__), "companies.json")

NAICS_TARGETS = {
    "336415": "Guided Missile & Space Vehicle Propulsion Units",
    "325920": "Explosives Manufacturing (AP, energetic materials)",
    "332710": "Screw Machine / Precision Machined Parts (nozzle throats, inserts)",
    "325211": "Plastics & Synthetic Resin Mfg (HTPB, polymer binders)",
    "332993": "Ammunition (non-small arms) / Propellant Mfg",
    "325180": "Inorganic Chemicals (Oxidizers, Ammonium Perchlorate)",
    "336419": "Other Guided Missile / Space Vehicle Parts",
    "332999": "Misc. Fabricated Metal (Casings, Nozzles)",
    "541330": "Engineering Services — Defense/Propulsion",
    "336411": "Aircraft Manufacturing (propulsion-adjacent)",
}

SRM_STACK_ROLES = [
    "Propellant — Binders/Pre-polymers (HTPB, MAPO, IPDI)",
    "Propellant — Oxidizers (Ammonium Perchlorate, AP)",
    "Propellant — Energetic Additives (RDX, HMX, Al powder)",
    "Propellant — Mixing & Casting",
    "Casing — Carbon Fiber / Filament Winding",
    "Casing — Specialty Steel / Metal",
    "Casing — Insulation & Liner",
    "Nozzle — Carbon-Carbon / Graphite Ablative",
    "Nozzle — Throat Inserts / TVC Components",
    "Igniter / Initiator — Pyrotechnic",
    "Igniter / Initiator — Electrical",
    "Test & Measurement — Hot Fire / Ballistic",
    "Other / Multi-role",
]

SBIR_SIGNALS = [
    "None identified",
    "Phase I only",
    "Phase II awarded — solid propellant / rocket motor topic",
    "Phase II awarded — adjacent topic (energetics, composite structures)",
    "Phase III / direct-to-program (strongest signal)",
]

TIER1_PRIMES = [
    "Northrop Grumman",
    "Aerojet Rocketdyne",
    "L3Harris",
    "Nammo",
    "Chemring",
    "BAE Systems",
    "General Dynamics",
    "Raytheon / RTX",
]

CLEARANCE_LEVELS = ["None", "Facility Clearance Only", "SECRET", "TOP SECRET", "TS/SCI"]

MA_SIGNALS = [
    "None identified",
    "Owner approaching retirement (60+)",
    "PE-backed seeking exit",
    "Investment banker engaged",
    "Previous sale process",
    "Publicly listed (small cap)",
    "Family-owned, second gen",
]


# ── Scoring Engine ──────────────────────────────────────────────────────────────

def score_naics(naics_codes: list[str]) -> tuple[int, str]:
    matches = [c for c in naics_codes if c in NAICS_TARGETS]
    if len(matches) >= 2:
        return 20, f"Strong — {len(matches)} target NAICS matched: {', '.join(matches)}"
    elif len(matches) == 1:
        return 12, f"Partial — 1 target NAICS matched: {matches[0]}"
    else:
        return 0, "No target NAICS codes matched"


def score_gov_contracts(annual_award_volume_usd: float) -> tuple[int, str]:
    """Annual federal award volume as a proxy for defense exposure."""
    if annual_award_volume_usd >= 20_000_000:
        return 20, f"High — ${annual_award_volume_usd:,.0f}/yr in federal awards"
    elif annual_award_volume_usd >= 8_000_000:
        return 14, f"Moderate — ${annual_award_volume_usd:,.0f}/yr in federal awards"
    elif annual_award_volume_usd >= 2_000_000:
        return 7, f"Low — ${annual_award_volume_usd:,.0f}/yr in federal awards"
    else:
        return 0, f"Minimal or no federal contract presence"


def estimate_revenue(headcount: int) -> tuple[bool, float]:
    """
    A&D manufacturing RPE: $250k–$450k depending on facility automation.
    Mid-point $350k used for sweet-spot scoring.
    $30M–$100M band = 85–286 employees.
    """
    RPE_MID = 350_000
    est_rev = headcount * RPE_MID
    in_band = 30_000_000 <= est_rev <= 100_000_000
    return in_band, est_rev


def score_revenue_proxy(employee_count: int, annual_awards: float) -> tuple[int, str]:
    """
    A&D manufacturing RPE: $250k–$450k, mid $350k.
    Sweet spot: 85–286 employees maps to $30M–$100M.
    Award proxy: gov contracts typically 40–70% of Tier 2/3 revenue.
    """
    RPE_LOW, RPE_MID, RPE_HIGH = 250_000, 350_000, 450_000
    est_low  = employee_count * RPE_LOW
    est_mid  = employee_count * RPE_MID
    est_high = employee_count * RPE_HIGH

    award_proxy = (annual_awards / 0.55) if annual_awards > 0 else 0

    mid_in_band    = 30_000_000 <= est_mid  <= 100_000_000
    range_in_band  = est_low   <= 100_000_000 and est_high >= 30_000_000
    award_in_band  = 30_000_000 <= award_proxy <= 100_000_000

    if mid_in_band and award_in_band:
        return 20, (
            f"Strong — RPE mid ${est_mid/1e6:.1f}M ({employee_count} FTEs @ $350k) "
            f"+ award proxy ${award_proxy/1e6:.1f}M — both in band"
        )
    elif mid_in_band:
        return 15, (
            f"RPE mid ${est_mid/1e6:.1f}M in band — "
            f"award proxy ${award_proxy/1e6:.1f}M {'in band' if award_in_band else 'outside band'}"
        )
    elif range_in_band and award_in_band:
        return 12, (
            f"Partial — RPE range ${est_low/1e6:.1f}M–${est_high/1e6:.1f}M clips band, "
            f"award proxy ${award_proxy/1e6:.1f}M aligned"
        )
    elif range_in_band or award_in_band:
        return 6, (
            f"Marginal — RPE mid ${est_mid/1e6:.1f}M, "
            f"award proxy ${award_proxy/1e6:.1f}M — one signal near band"
        )
    else:
        return 2, f"Weak — RPE mid ${est_mid/1e6:.1f}M likely outside $30M–$100M band"


def score_prime_relationships(primes: list[str]) -> tuple[int, str]:
    known = [p for p in primes if any(t.lower() in p.lower() for t in TIER1_PRIMES)]
    if len(known) >= 2:
        return 15, f"Confirmed Tier 2 — {len(known)} prime relationships: {', '.join(known)}"
    elif len(known) == 1:
        return 10, f"Single prime relationship: {known[0]}"
    elif primes:
        return 5, f"Unverified prime relationships listed"
    else:
        return 0, "No prime contractor relationships identified"


def score_industry_presence(jannaf: bool, trade_shows: list[str], publications: list[str]) -> tuple[int, str]:
    score = 0
    notes = []
    if jannaf:
        score += 6
        notes.append("JANNAF presence confirmed")
    if trade_shows:
        score += min(len(trade_shows) * 2, 4)
        notes.append(f"Trade shows: {', '.join(trade_shows)}")
    if publications:
        score += 2
        notes.append(f"Published: {', '.join(publications)}")
    score = min(score, 10)
    return score, "; ".join(notes) if notes else "No industry presence documented"


def score_clearance(clearance: str, specialized_facilities: list[str]) -> tuple[int, str]:
    clearance_scores = {"None": 0, "Facility Clearance Only": 2, "SECRET": 6, "TOP SECRET": 9, "TS/SCI": 10}
    base = clearance_scores.get(clearance, 0)
    facility_bonus = min(len(specialized_facilities) * 2, 4)
    score = min(base + facility_bonus, 10)
    notes = f"Clearance: {clearance}"
    if specialized_facilities:
        notes += f" | Facilities: {', '.join(specialized_facilities)}"
    return score, notes


def score_sbir(signal: str, sub_award_confirmed: bool) -> tuple[int, str]:
    """
    SBIR Phase II/III is a smoking gun for Tier 3 tech providers in the $35M–$100M band.
    Sub-award confirmation from a Tier 1 prime elevates score further.
    """
    signal_scores = {
        "None identified": 0,
        "Phase I only": 2,
        "Phase II awarded — solid propellant / rocket motor topic": 8,
        "Phase II awarded — adjacent topic (energetics, composite structures)": 5,
        "Phase III / direct-to-program (strongest signal)": 10,
    }
    score = signal_scores.get(signal, 0)
    if sub_award_confirmed:
        score = min(score + 3, 10)
    notes = signal
    if sub_award_confirmed:
        notes += " | Sub-award from Tier 1 confirmed"
    return score, notes


def score_ma_readiness(signal: str, broker_engaged: bool, asking_price_usd: float | None) -> tuple[int, str]:
    signal_scores = {
        "None identified": 1,
        "Owner approaching retirement (60+)": 4,
        "PE-backed seeking exit": 5,
        "Investment banker engaged": 5,
        "Previous sale process": 4,
        "Publicly listed (small cap)": 3,
        "Family-owned, second gen": 3,
    }
    score = signal_scores.get(signal, 1)
    if broker_engaged:
        score = min(score + 1, 5)
    notes = signal
    if broker_engaged:
        notes += " | Broker/advisor engaged"
    if asking_price_usd:
        notes += f" | Asking: ${asking_price_usd:,.0f}"
    return score, notes


def compute_total_score(profile: dict) -> dict:
    s1, n1 = score_naics(profile["naics_codes"])
    s2, n2 = score_gov_contracts(profile["annual_award_volume_usd"])
    s3, n3 = score_revenue_proxy(profile["employee_count"], profile["annual_award_volume_usd"])
    s4, n4 = score_prime_relationships(profile["prime_relationships"])
    s5, n5 = score_industry_presence(profile["jannaf_presence"], profile["trade_shows"], profile["publications"])
    s6, n6 = score_clearance(profile["clearance_level"], profile["specialized_facilities"])
    s7, n7 = score_sbir(profile.get("sbir_signal", "None identified"), profile.get("sub_award_confirmed", False))
    s8, n8 = score_ma_readiness(profile["ma_signal"], profile["broker_engaged"], profile.get("asking_price_usd"))

    total = s1 + s2 + s3 + s4 + s5 + s6 + s7 + s8

    return {
        "total_score": total,
        "tier_fit": tier_label(total),
        "breakdown": {
            "naics_alignment":        {"score": s1, "max": 20, "notes": n1},
            "gov_contract_presence":  {"score": s2, "max": 20, "notes": n2},
            "revenue_proxy":          {"score": s3, "max": 20, "notes": n3},
            "prime_relationships":    {"score": s4, "max": 15, "notes": n4},
            "industry_presence":      {"score": s5, "max": 10, "notes": n5},
            "clearance_facilities":   {"score": s6, "max": 10, "notes": n6},
            "sbir_signal":            {"score": s7, "max": 10, "notes": n7},
            "ma_readiness":           {"score": s8, "max":  5, "notes": n8},
        },
    }


def tier_label(score: int) -> str:
    if score >= 85:
        return "PRIORITY — Strong Acquisition Candidate"
    elif score >= 65:
        return "QUALIFIED — Warrants Deep Dive"
    elif score >= 45:
        return "WATCH — Monitor & Verify"
    else:
        return "LOW FIT — Insufficient Alignment"


# ── Data Layer ──────────────────────────────────────────────────────────────────

def load_companies() -> list[dict]:
    if not os.path.exists(DATA_FILE):
        return []
    with open(DATA_FILE) as f:
        return json.load(f)


def save_companies(companies: list[dict]) -> None:
    with open(DATA_FILE, "w") as f:
        json.dump(companies, f, indent=2)


# ── CLI Interface ───────────────────────────────────────────────────────────────

def prompt(label: str, default: str = "") -> str:
    val = input(f"  {label}{f' [{default}]' if default else ''}: ").strip()
    return val if val else default


def prompt_list(label: str) -> list[str]:
    raw = input(f"  {label} (comma-separated, or leave blank): ").strip()
    return [x.strip() for x in raw.split(",") if x.strip()]


def prompt_float(label: str, default: float = 0.0) -> float:
    raw = input(f"  {label} [{default}]: ").strip()
    try:
        return float(raw.replace(",", "").replace("$", "")) if raw else default
    except ValueError:
        return default


def prompt_int(label: str, default: int = 0) -> int:
    raw = input(f"  {label} [{default}]: ").strip()
    try:
        return int(raw.replace(",", "")) if raw else default
    except ValueError:
        return default


def prompt_bool(label: str) -> bool:
    raw = input(f"  {label} (y/n) [n]: ").strip().lower()
    return raw in ("y", "yes")


def prompt_choice(label: str, options: list[str]) -> str:
    print(f"\n  {label}:")
    for i, opt in enumerate(options, 1):
        print(f"    {i}. {opt}")
    raw = input("  Select number: ").strip()
    try:
        idx = int(raw) - 1
        if 0 <= idx < len(options):
            return options[idx]
    except ValueError:
        pass
    return options[0]


def add_company() -> None:
    print("\n" + "═" * 60)
    print("  NEW COMPANY PROFILE")
    print("═" * 60)

    company_name = prompt("Company Name")
    if not company_name:
        print("  [!] Company name required.")
        return

    print("\n── Basic Info ──")
    hq_state       = prompt("HQ State/Location")
    website        = prompt("Website (optional)")
    employee_count = prompt_int("Estimated Employee Count", 0)
    known_revenue  = prompt("Known Revenue (if available, e.g. $45M, else leave blank)", "")
    source         = prompt("How identified (e.g. USASpending, JANNAF, referral)")

    print("\n── Identifier 1: NAICS Codes ──")
    print("  Target codes:", ", ".join(NAICS_TARGETS.keys()))
    naics_codes = prompt_list("Enter company NAICS code(s)")

    print("\n── Identifier 2: Government Contracts ──")
    annual_award_volume_usd = prompt_float("Estimated Annual Federal Award Volume ($USD)", 0)
    sam_registered = prompt_bool("Registered in SAM.gov?")
    cage_code = prompt("CAGE Code (if known)", "")

    print("\n── Identifier 3: Revenue Proxy ──")
    print(f"  [Auto-calculated from employee count + award volume]")

    print("\n── Identifier 4: Prime Contractor Relationships ──")
    print("  Known Tier 1 primes:", ", ".join(TIER1_PRIMES))
    prime_relationships = prompt_list("Prime relationships (known or suspected)")

    print("\n── Identifier 5: Industry Presence ──")
    jannaf_presence = prompt_bool("JANNAF Propulsion Meeting presence confirmed?")
    trade_shows     = prompt_list("Other trade shows / conferences")
    publications    = prompt_list("Technical papers / publications")

    print("\n── Identifier 6: Facility & Clearance ──")
    clearance_level        = prompt_choice("Clearance Level", CLEARANCE_LEVELS)
    specialized_facilities = prompt_list("Specialized facilities (e.g. propellant mixing, hot fire test, composite layup)")

    print("\n── Identifier 7: SBIR / STTR Signal ──")
    sbir_signal        = prompt_choice("SBIR/STTR Signal", SBIR_SIGNALS)
    sub_award_confirmed = prompt_bool("Sub-award from Tier 1 prime confirmed in FPDS/USASpending?")

    print("\n── SRM Stack Role ──")
    srm_role = prompt_choice("Primary role in SRM stack", SRM_STACK_ROLES)

    print("\n── Identifier 8: M&A Readiness ──")
    ma_signal      = prompt_choice("M&A Readiness Signal", MA_SIGNALS)
    broker_engaged = prompt_bool("Investment banker or broker engaged?")
    asking_price   = prompt_float("Asking price or valuation discussed ($USD, 0 if unknown)", 0)

    print("\n── Qualitative Notes ──")
    notes = prompt("Additional notes / red flags / upside")

    raw_profile = {
        "company_name":            company_name,
        "hq_state":                hq_state,
        "website":                 website,
        "employee_count":          employee_count,
        "known_revenue":           known_revenue,
        "source":                  source,
        "date_added":              str(date.today()),
        "naics_codes":             naics_codes,
        "annual_award_volume_usd": annual_award_volume_usd,
        "sam_registered":          sam_registered,
        "cage_code":               cage_code,
        "prime_relationships":     prime_relationships,
        "jannaf_presence":         jannaf_presence,
        "trade_shows":             trade_shows,
        "publications":            publications,
        "clearance_level":         clearance_level,
        "specialized_facilities":  specialized_facilities,
        "sbir_signal":             sbir_signal,
        "sub_award_confirmed":     sub_award_confirmed,
        "srm_role":                srm_role,
        "ma_signal":               ma_signal,
        "broker_engaged":          broker_engaged,
        "asking_price_usd":        asking_price if asking_price > 0 else None,
        "notes":                   notes,
    }

    scored = compute_total_score(raw_profile)
    profile = {**raw_profile, **scored}

    companies = load_companies()
    companies.append(profile)
    save_companies(companies)

    print("\n" + "═" * 60)
    print(f"  PROFILE SAVED: {company_name}")
    print(f"  TOTAL SCORE:   {scored['total_score']} / 100")
    print(f"  ASSESSMENT:    {scored['tier_fit']}")
    print("═" * 60)


def list_companies() -> None:
    companies = load_companies()
    if not companies:
        print("\n  No companies profiled yet.")
        return

    sorted_cos = sorted(companies, key=lambda x: x["total_score"], reverse=True)

    print("\n" + "═" * 60)
    print(f"  {'#':<4} {'Company':<30} {'Score':>5}  Assessment")
    print("─" * 60)
    for i, c in enumerate(sorted_cos, 1):
        print(f"  {i:<4} {c['company_name']:<30} {c['total_score']:>5}  {c['tier_fit']}")
    print("═" * 60)


def view_profile(name_fragment: str) -> None:
    companies = load_companies()
    matches = [c for c in companies if name_fragment.lower() in c["company_name"].lower()]

    if not matches:
        print(f"\n  No company matching '{name_fragment}' found.")
        return

    c = matches[0]
    print("\n" + "═" * 60)
    print(f"  {c['company_name'].upper()}")
    print(f"  HQ: {c['hq_state']}  |  Employees: {c['employee_count']}  |  Added: {c['date_added']}")
    if c.get("known_revenue"):
        print(f"  Known Revenue: {c['known_revenue']}")
    print(f"  Source: {c['source']}")
    print(f"\n  SCORE: {c['total_score']} / 100  —  {c['tier_fit']}")
    print("\n  Score Breakdown:")
    for key, val in c["breakdown"].items():
        bar = "█" * val["score"] + "░" * (val["max"] - val["score"])
        print(f"    {key:<24} {val['score']:>2}/{val['max']}  {bar}")
        print(f"                             {val['notes']}")
    if c.get("notes"):
        print(f"\n  Notes: {c['notes']}")
    print("═" * 60)


def export_csv() -> None:
    companies = load_companies()
    if not companies:
        print("\n  Nothing to export.")
        return

    export_path = os.path.join(os.path.dirname(__file__), "target_export.csv")
    fieldnames = [
        "company_name", "hq_state", "employee_count", "known_revenue",
        "total_score", "tier_fit", "srm_role", "naics_codes",
        "annual_award_volume_usd", "sam_registered", "cage_code",
        "prime_relationships", "jannaf_presence", "clearance_level",
        "sbir_signal", "sub_award_confirmed",
        "ma_signal", "broker_engaged", "asking_price_usd",
        "source", "date_added", "notes",
    ]

    with open(export_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for c in sorted(companies, key=lambda x: x["total_score"], reverse=True):
            row = {**c}
            row["naics_codes"] = ", ".join(c.get("naics_codes", []))
            row["prime_relationships"] = ", ".join(c.get("prime_relationships", []))
            writer.writerow(row)

    print(f"\n  Exported {len(companies)} companies to: {export_path}")


def rescore_all() -> None:
    """Recalculate scores for all profiles (useful after scoring model updates)."""
    companies = load_companies()
    if not companies:
        print("\n  No companies to rescore.")
        return
    for c in companies:
        scored = compute_total_score(c)
        c["total_score"] = scored["total_score"]
        c["tier_fit"] = scored["tier_fit"]
        c["breakdown"] = scored["breakdown"]
    save_companies(companies)
    print(f"\n  Rescored {len(companies)} profiles.")


# ── Main Menu ───────────────────────────────────────────────────────────────────

MENU = """
  ╔══════════════════════════════════════════╗
  ║  SOLID STATE — Tier 2/3 Target Profiler  ║
  ║  Confidential // Internal Use Only       ║
  ╚══════════════════════════════════════════╝

  1.  Add new company profile
  2.  List all companies (ranked by score)
  3.  View detailed profile
  4.  Export to CSV
  5.  Rescore all profiles
  0.  Exit
"""


def main() -> None:
    while True:
        print(MENU)
        choice = input("  Select: ").strip()

        if choice == "1":
            add_company()
        elif choice == "2":
            list_companies()
        elif choice == "3":
            name = input("\n  Enter company name (or fragment): ").strip()
            view_profile(name)
        elif choice == "4":
            export_csv()
        elif choice == "5":
            rescore_all()
        elif choice == "0":
            print("\n  Exiting. All data saved.\n")
            break
        else:
            print("\n  Invalid selection.")


if __name__ == "__main__":
    main()
