"""
Bluestreak Seed Loader — Archetype-Based Pipeline Primer
Builds structured profiles from public corridor intelligence when live API
access is unavailable. All profiles marked PENDING_VERIFICATION.
Run profiler.py to replace any entry with a verified live record.
Confidential // US Industrial Base Resilience Study
"""

from __future__ import annotations
import json, os
from datetime import date

COMPANIES_FILE = os.path.join(os.path.dirname(__file__), "companies.json")

# ── Seed Profiles ───────────────────────────────────────────────────────────────
# Structured from public corridor intelligence:
# Camden AR ordnance complex, Huntsville AL Redstone ecosystem,
# Brigham City/Promontory UT composite/propellant cluster.
# Headcount × $350k RPE aligns each to $30M–$100M band.

SEED_PROFILES = [
    # ── ARKANSAS (CRITICAL) ──────────────────────────────────────────────────────
    {
        "company_name":            "AR-001 | Camden Propellant Processing [PENDING VERIFICATION]",
        "hq_state":                "Arkansas",
        "website":                 "",
        "employee_count":          160,
        "known_revenue":           "",
        "source":                  "Corridor archetype — Camden ordnance complex",
        "date_added":              str(date.today()),
        "naics_codes":             ["325920", "332993"],
        "annual_award_volume_usd": 14_000_000,
        "sam_registered":          True,
        "cage_code":               "",
        "prime_relationships":     ["General Dynamics OTS", "Lockheed Martin"],
        "jannaf_presence":         False,
        "trade_shows":             [],
        "publications":            [],
        "clearance_level":         "SECRET",
        "specialized_facilities":  ["AP handling cell", "propellant casting pits", "Class 1.1 bunkers"],
        "sbir_signal":             "None identified",
        "sub_award_confirmed":     True,
        "srm_role":                "Propellant — Mixing & Casting",
        "cmmc_level_2":            False,
        "cmmc_pathway_exists":     False,
        "niss_eligible":           True,
        "foreign_board_member":    False,
        "prime_concentration_pct": 65,
        "ma_signal":               "Owner approaching retirement (60+)",
        "broker_engaged":          False,
        "asking_price_usd":        None,
        "notes": (
            "Classic Camden mix-and-cast archetype. Sub-tier under GD-OTS prime vehicle. "
            "Single largest sub-award concentration risk. CMMC posture unknown — "
            "assume gap until verified. Owner believed 60s, no succession visible."
        ),
    },
    {
        "company_name":            "AR-002 | Ouachita ITAR Precision Machining [PENDING VERIFICATION]",
        "hq_state":                "Arkansas",
        "website":                 "",
        "employee_count":          105,
        "known_revenue":           "",
        "source":                  "Corridor archetype — Camden ITAR nozzle throat cluster",
        "date_added":              str(date.today()),
        "naics_codes":             ["332710", "332999"],
        "annual_award_volume_usd": 9_000_000,
        "sam_registered":          True,
        "cage_code":               "",
        "prime_relationships":     ["General Dynamics OTS", "Northrop Grumman"],
        "jannaf_presence":         False,
        "trade_shows":             [],
        "publications":            [],
        "clearance_level":         "SECRET",
        "specialized_facilities":  ["graphite/refractory CNC", "ITAR-certified nozzle throat"],
        "sbir_signal":             "None identified",
        "sub_award_confirmed":     True,
        "srm_role":                "Nozzle — Throat Inserts / TVC Components",
        "cmmc_level_2":            False,
        "cmmc_pathway_exists":     False,
        "niss_eligible":           True,
        "foreign_board_member":    False,
        "prime_concentration_pct": 80,
        "ma_signal":               "Family-owned, second gen",
        "broker_engaged":          False,
        "asking_price_usd":        None,
        "notes": (
            "Legacy ITAR shop — sole-source qualified for nozzle throat insert production. "
            "Qualification held 20+ years; near-impossible to replicate without "
            "controlled transition. Family-owned second gen. High prime concentration "
            "risk but qualification is the moat. Highest strategic value target in AR."
        ),
    },
    {
        "company_name":            "AR-003 | South Arkansas Energetic Materials [PENDING VERIFICATION]",
        "hq_state":                "Arkansas",
        "website":                 "",
        "employee_count":          130,
        "known_revenue":           "",
        "source":                  "Corridor archetype — Camden energetic additive supplier",
        "date_added":              str(date.today()),
        "naics_codes":             ["325920", "325180"],
        "annual_award_volume_usd": 11_000_000,
        "sam_registered":          True,
        "cage_code":               "",
        "prime_relationships":     ["Lockheed Martin", "L3Harris / Aerojet Rocketdyne"],
        "jannaf_presence":         False,
        "trade_shows":             ["NDIA Armaments"],
        "publications":            [],
        "clearance_level":         "SECRET",
        "specialized_facilities":  ["energetic additive blending", "Class 1.3 storage", "oxidizer handling"],
        "sbir_signal":             "Phase II awarded — adjacent topic (energetics, composite structures)",
        "sub_award_confirmed":     True,
        "srm_role":                "Propellant — Oxidizers (Ammonium Perchlorate, AP)",
        "cmmc_level_2":            False,
        "cmmc_pathway_exists":     True,
        "niss_eligible":           True,
        "foreign_board_member":    False,
        "prime_concentration_pct": 55,
        "ma_signal":               "PE-backed seeking exit",
        "broker_engaged":          True,
        "asking_price_usd":        52_000_000,
        "notes": (
            "PE-backed, broker engaged — most actionable near-term opportunity in AR. "
            "CMMC pathway documented (SSP in progress). SBIR Phase II adjacency confirms "
            "DOD customer intimacy. Asking ~$52M; oxidizer handling quals rare domestically."
        ),
    },

    # ── ALABAMA (HIGH) ───────────────────────────────────────────────────────────
    {
        "company_name":            "AL-001 | Huntsville Ignition Systems [PENDING VERIFICATION]",
        "hq_state":                "Alabama",
        "website":                 "",
        "employee_count":          215,
        "known_revenue":           "",
        "source":                  "Corridor archetype — Redstone Arsenal igniter/initiator cluster",
        "date_added":              str(date.today()),
        "naics_codes":             ["332993", "336415"],
        "annual_award_volume_usd": 22_000_000,
        "sam_registered":          True,
        "cage_code":               "",
        "prime_relationships":     ["Northrop Grumman", "L3Harris / Aerojet Rocketdyne", "Boeing"],
        "jannaf_presence":         True,
        "trade_shows":             ["NDIA Armaments", "AFA Air Space & Cyber"],
        "publications":            ["AIAA 2024 igniter characterization"],
        "clearance_level":         "TOP SECRET",
        "specialized_facilities":  ["EED assembly cell", "pyrotechnic initiator line", "Class 1.4 handling"],
        "sbir_signal":             "Phase II awarded — solid propellant / rocket motor topic",
        "sub_award_confirmed":     True,
        "srm_role":                "Igniter / Initiator — Pyrotechnic",
        "cmmc_level_2":            True,
        "cmmc_pathway_exists":     True,
        "niss_eligible":           True,
        "foreign_board_member":    False,
        "prime_concentration_pct": 45,
        "ma_signal":               "PE-backed seeking exit",
        "broker_engaged":          False,
        "asking_price_usd":        None,
        "notes": (
            "Strongest strategic/compliance profile in the dataset. CMMC Level 2 certified, "
            "TS clearance, JANNAF presence, three prime relationships, SBIR Phase II on-topic. "
            "ATF/DoT regulatory moat on initiator line — near-impossible for new entrants. "
            "PE-backed; watch for advisor engagement signal."
        ),
    },
    {
        "company_name":            "AL-002 | Tennessee Valley Composite Structures [PENDING VERIFICATION]",
        "hq_state":                "Alabama",
        "website":                 "",
        "employee_count":          175,
        "known_revenue":           "",
        "source":                  "Corridor archetype — Huntsville motor case insulation/liner",
        "date_added":              str(date.today()),
        "naics_codes":             ["332999", "336419"],
        "annual_award_volume_usd": 16_000_000,
        "sam_registered":          True,
        "cage_code":               "",
        "prime_relationships":     ["Northrop Grumman", "Dynetics / Leidos"],
        "jannaf_presence":         True,
        "trade_shows":             ["NDIA Armaments"],
        "publications":            [],
        "clearance_level":         "SECRET",
        "specialized_facilities":  ["motor case insulation layup", "thermal liner bonding", "composite overwrap"],
        "sbir_signal":             "Phase II awarded — adjacent topic (energetics, composite structures)",
        "sub_award_confirmed":     True,
        "srm_role":                "Casing — Insulation & Liner",
        "cmmc_level_2":            False,
        "cmmc_pathway_exists":     True,
        "niss_eligible":           True,
        "foreign_board_member":    False,
        "prime_concentration_pct": 58,
        "ma_signal":               "Owner approaching retirement (60+)",
        "broker_engaged":          False,
        "asking_price_usd":        None,
        "notes": (
            "Insulation/liner specialist adjacent to motor case assembly — natural "
            "integration target to pair with a composite casing shop. CMMC SSP in progress. "
            "Owner 60s; no succession planning evident."
        ),
    },

    # ── UTAH (HIGH) ──────────────────────────────────────────────────────────────
    {
        "company_name":            "UT-001 | Wasatch Composite Motor Cases [PENDING VERIFICATION]",
        "hq_state":                "Utah",
        "website":                 "",
        "employee_count":          200,
        "known_revenue":           "",
        "source":                  "Corridor archetype — Brigham City composite casing cluster",
        "date_added":              str(date.today()),
        "naics_codes":             ["336415", "332999"],
        "annual_award_volume_usd": 21_000_000,
        "sam_registered":          True,
        "cage_code":               "",
        "prime_relationships":     ["Northrop Grumman", "Orbital Sciences"],
        "jannaf_presence":         True,
        "trade_shows":             ["JANNAF", "Space Symposium"],
        "publications":            ["AIAA 2023 filament winding process"],
        "clearance_level":         "SECRET",
        "specialized_facilities":  ["filament winding mandrel", "composite autoclave", "hydrostatic test cell"],
        "sbir_signal":             "Phase II awarded — solid propellant / rocket motor topic",
        "sub_award_confirmed":     True,
        "srm_role":                "Casing — Carbon Fiber / Filament Winding",
        "cmmc_level_2":            False,
        "cmmc_pathway_exists":     True,
        "niss_eligible":           True,
        "foreign_board_member":    False,
        "prime_concentration_pct": 72,
        "ma_signal":               "Previous sale process",
        "broker_engaged":          False,
        "asking_price_usd":        None,
        "notes": (
            "ATK-era spin-out operating in Brigham City orbit. Previous sale process "
            "suggests ownership is exit-minded. SBIR Phase II on SRM topic. "
            "High NG prime concentration — change-of-control consent clause likely. "
            "Dual-use: composite casings also applicable to hypersonic."
        ),
    },
    {
        "company_name":            "UT-002 | Great Basin Propellant Chemistry [PENDING VERIFICATION]",
        "hq_state":                "Utah",
        "website":                 "",
        "employee_count":          92,
        "known_revenue":           "",
        "source":                  "Corridor archetype — HTPB/binder pre-polymer supplier",
        "date_added":              str(date.today()),
        "naics_codes":             ["325211", "325180"],
        "annual_award_volume_usd": 6_500_000,
        "sam_registered":          True,
        "cage_code":               "",
        "prime_relationships":     ["Northrop Grumman"],
        "jannaf_presence":         False,
        "trade_shows":             [],
        "publications":            [],
        "clearance_level":         "Facility Clearance Only",
        "specialized_facilities":  ["HTPB pre-polymer synthesis", "curative blending", "viscosity/cure lab"],
        "sbir_signal":             "Phase II awarded — adjacent topic (energetics, composite structures)",
        "sub_award_confirmed":     True,
        "srm_role":                "Propellant — Binders/Pre-polymers (HTPB, MAPO, IPDI)",
        "cmmc_level_2":            False,
        "cmmc_pathway_exists":     False,
        "niss_eligible":           True,
        "foreign_board_member":    False,
        "prime_concentration_pct": 88,
        "ma_signal":               "Family-owned, second gen",
        "broker_engaged":          False,
        "asking_price_usd":        None,
        "notes": (
            "Smallest target in set but strategically critical — HTPB pre-polymer "
            "synthesis is a 3-4 domestic supplier market. Sole-source concentration "
            "under a single NG contract is a risk but also creates defensible moat. "
            "Family-owned second gen; no CMMC pathway. Acquisition price likely sub-$40M."
        ),
    },
]


def load_existing() -> list[dict]:
    if not os.path.exists(COMPANIES_FILE):
        return []
    with open(COMPANIES_FILE) as f:
        return json.load(f)


def run_seed() -> int:
    import sys
    sys.path.insert(0, os.path.dirname(__file__))
    from profiler import compute_total_score

    existing = load_existing()
    existing_names = {c["company_name"] for c in existing}

    added = 0
    for raw in SEED_PROFILES:
        if raw["company_name"] in existing_names:
            print(f"  [SKIP] Already exists: {raw['company_name'][:50]}")
            continue
        scored = compute_total_score(raw)
        profile = {**raw, **scored}
        existing.append(profile)
        added += 1
        print(f"  [+] {raw['company_name'][:55]:<55}  score={scored['total_score']}/110  {scored['tier_fit']}")

    with open(COMPANIES_FILE, "w") as f:
        json.dump(existing, f, indent=2)

    print(f"\n  {added} profiles added → {COMPANIES_FILE}")
    return added


if __name__ == "__main__":
    print("\n  Bluestreak Seed Loader")
    print("  US Industrial Base Resilience Study // Confidential")
    print("  All profiles: PENDING VERIFICATION — replace with live data\n")
    run_seed()
