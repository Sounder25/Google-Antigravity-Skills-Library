"""
Anonymized Search Query Generator — Solid State Propellant SRM Supply Chain
Confidential // Internal Use Only

Produces ready-to-use search strings and API parameters for:
  - USASpending.gov (federal awards + sub-awards)
  - SBIR.gov (Phase II/III awards)
  - SAM.gov (entity registrations by NAICS)
  - LinkedIn headcount heuristics

NO client names, acquisition intent, or deal-specific language is embedded
in any generated query. All terms are capability/NAICS-neutral.
"""

from __future__ import annotations
import json

# ── Target NAICS Codes ──────────────────────────────────────────────────────────
NAICS_PRIMARY   = ["336415", "325920"]
NAICS_SECONDARY = ["332993", "325180", "336419", "332999", "541330"]
NAICS_ALL       = NAICS_PRIMARY + NAICS_SECONDARY

# ── SRM Capability Keyword Banks ────────────────────────────────────────────────
KEYWORDS = {
    "propellant_binders": [
        "HTPB", "hydroxyl-terminated polybutadiene", "MAPO",
        "IPDI", "isocyanate curative", "pre-polymer synthesis",
        "binder system", "energetic binder",
    ],
    "oxidizers": [
        "ammonium perchlorate", "AP oxidizer", "ammonium nitrate",
        "perchlorate manufacturing", "oxidizer processing",
        "Class 1.1 explosives", "Class 1.3 propellant",
    ],
    "energetic_additives": [
        "aluminum powder", "RDX", "HMX", "CL-20",
        "energetic material", "energetic filler",
        "nano-aluminum", "metal fuel additive",
    ],
    "propellant_processing": [
        "propellant casting", "propellant mixing", "grain casting",
        "solid rocket motor", "SRM propellant", "tactical rocket motor",
        "grain geometry", "slurry casting", "propellant formulation",
    ],
    "casings_composite": [
        "filament winding", "carbon fiber overwrap",
        "composite pressure vessel", "COPV", "motor casing",
        "rocket casing composite", "wet winding", "dry winding",
        "fiber placement", "Type IV vessel",
    ],
    "casings_metal": [
        "D6AC steel", "maraging steel", "high-strength steel casing",
        "motor case forging", "flow forming", "spin forming",
        "pressure vessel steel", "4130 alloy steel",
    ],
    "nozzles": [
        "carbon-carbon nozzle", "graphite ablative", "throat insert",
        "nozzle throat", "ablative nozzle", "C/C composite",
        "carbon phenolic", "TVC nozzle", "flex seal",
    ],
    "igniters": [
        "igniter assembly", "initiator", "pyrotechnic igniter",
        "EED", "electro-explosive device", "squib",
        "booster charge", "pyrogen igniter", "initiating device",
    ],
    "test_measurement": [
        "static fire test", "hot fire test", "ballistic evaluation",
        "strand burner", "bomb calorimeter", "aging test propellant",
        "propellant characterization", "burn rate measurement",
    ],
}

# ── Tier 1 Primes (for sub-award filtering) ─────────────────────────────────────
PRIME_DUNS = {
    "Northrop Grumman":    "167174508",
    "Aerojet Rocketdyne":  "004147910",
    "L3Harris":            "006272531",
    "BAE Systems":         "195198537",
    "General Dynamics":    "040520784",
}

PRIME_AWARD_ID_PREFIXES = ["N00024", "FA8650", "W31P4Q", "W15QKN", "DAAH"]


# ── Query Builders ──────────────────────────────────────────────────────────────

def usaspending_naics_params(primary_only: bool = False) -> dict:
    """
    Parameters for USASpending.gov /api/v2/search/spending_by_award/
    Returns JSON body ready for POST request.
    Targets NAICS codes with $0–$50M award range (proxy for $35M–$100M revenue).
    """
    naics = NAICS_PRIMARY if primary_only else NAICS_ALL
    return {
        "filters": {
            "naics_codes": naics,
            "award_type_codes": ["A", "B", "C", "D"],
            "award_amounts": [{"lower_bound": 500_000, "upper_bound": 50_000_000}],
            "recipient_location_scope": "domestic",
        },
        "fields": [
            "Award ID", "Recipient Name", "Recipient DUNS",
            "Award Amount", "NAICS Code", "NAICS Description",
            "Place of Performance State Code", "Period of Performance Current End Date",
        ],
        "sort": "Award Amount",
        "order": "desc",
        "limit": 100,
    }


def usaspending_subaward_params(prime_duns: str | None = None) -> dict:
    """
    Sub-award search — surfaces Tier 2/3 recipients under Tier 1 prime contracts.
    If prime_duns is None, iterates across all known primes.
    """
    base = {
        "filters": {
            "award_type_codes": ["A", "B", "C", "D"],
            "naics_codes": NAICS_ALL,
        },
        "fields": [
            "Sub-Award ID", "Sub-Awardee Name", "Sub-Awardee DUNS",
            "Sub-Award Amount", "Prime Award Recipient Name",
            "Prime Award ID", "NAICS Code",
        ],
        "subaward_type": "procurement",
        "sort": "Sub-Award Amount",
        "order": "desc",
        "limit": 100,
    }
    if prime_duns:
        base["filters"]["recipient_id"] = prime_duns
    return base


def sbir_search_queries() -> list[dict]:
    """
    Keyword sets for SBIR.gov advanced search.
    Each entry is a self-contained search pass — run them independently.
    """
    return [
        {
            "label": "Solid Propellant Motor — Direct",
            "keywords": "solid propellant rocket motor",
            "phase": "2",
            "agency": "DOD",
            "notes": "Strongest signal. Phase II awardees in this topic are prime Tier 3 targets.",
        },
        {
            "label": "Tactical Rocket Motor",
            "keywords": "tactical rocket motor propellant",
            "phase": "2",
            "agency": "DOD",
            "notes": "Covers ATACMS, GMLRS, and similar tactical SRM supply chains.",
        },
        {
            "label": "Ammonium Perchlorate / Oxidizer",
            "keywords": "ammonium perchlorate oxidizer processing",
            "phase": "2",
            "agency": "DOD",
            "notes": "Tier 3 chemical suppliers. Very few exist domestically — high value targets.",
        },
        {
            "label": "HTPB Binder / Pre-polymer",
            "keywords": "HTPB hydroxyl terminated polybutadiene binder",
            "phase": "2",
            "agency": "DOD",
            "notes": "Specialty chemical Tier 3. Often sub-$50M but strategic.",
        },
        {
            "label": "Filament Wound Motor Casing",
            "keywords": "filament wound composite motor casing pressure vessel",
            "phase": "2",
            "agency": "DOD",
            "notes": "Composite casing Tier 2/3. Strong overlap with commercial COPV market.",
        },
        {
            "label": "Carbon-Carbon Nozzle / Ablative",
            "keywords": "carbon carbon ablative nozzle throat",
            "phase": "2",
            "agency": "DOD",
            "notes": "Nozzle Tier 2/3. Dual-use: also used in hypersonic TPS.",
        },
        {
            "label": "Igniter / Initiator",
            "keywords": "pyrotechnic igniter initiator electro-explosive",
            "phase": "2",
            "agency": "DOD",
            "notes": "Igniter Tier 3. Highly regulated, few qualified suppliers.",
        },
        {
            "label": "Phase III Direct — Propulsion",
            "keywords": "solid rocket propulsion motor grain",
            "phase": "3",
            "agency": "DOD",
            "notes": "Phase III = already commercialized. These companies are actively billing primes.",
        },
    ]


def sam_gov_entity_search() -> list[dict]:
    """
    SAM.gov entity search parameters per NAICS.
    Filter to active registrations, US-based, size standard ≤ 1,000 employees.
    """
    searches = []
    for naics in NAICS_ALL:
        searches.append({
            "naics_code": naics,
            "entity_type": "2L",
            "registration_status": "Active",
            "country_code": "USA",
            "size_standard_filter": "small_or_other_than_small",
            "url_template": f"https://sam.gov/search?index=ei&naicsCode={naics}&entityType=2L&q=",
        })
    return searches


def linkedin_headcount_heuristics() -> dict:
    """
    LinkedIn Sales Navigator / search heuristics for revenue-band proxying.
    Defense manufacturing: $150k–$250k revenue per FTE.
    Target band $35M–$100M → 140–670 FTEs (use 150–600 as search range).
    """
    return {
        "headcount_band": {"min": 150, "max": 600},
        "industries": [
            "Defense & Space",
            "Aviation & Aerospace",
            "Industrial Machinery",
            "Chemicals",
        ],
        "keywords_any": [kw for group in KEYWORDS.values() for kw in group[:2]],
        "geography": "United States",
        "notes": (
            "Run separate passes per SRM_STACK capability cluster. "
            "Cross-reference headcount hits against SAM.gov for CAGE code confirmation. "
            "Do NOT include acquisition language in any search string."
        ),
    }


def capability_keyword_search_strings() -> list[dict]:
    """
    Pre-built anonymized search strings for web/database searches.
    Safe for use in any public search tool — no acquisition intent embedded.
    """
    strings = []
    for category, keywords in KEYWORDS.items():
        primary = keywords[:3]
        query = " OR ".join(f'"{kw}"' for kw in primary)
        strings.append({
            "category": category,
            "search_string": f'({query}) "defense" "US" site:sam.gov OR site:usaspending.gov',
            "plain_search": f'{" ".join(primary)} defense manufacturer United States',
            "naics_hint": NAICS_ALL,
        })
    return strings


# ── Report Output ───────────────────────────────────────────────────────────────

def print_report() -> None:
    print("\n" + "═" * 70)
    print("  SOLID STATE PROPELLANT SRM — ANONYMIZED SEARCH QUERY PACKAGE")
    print("  Confidential // Internal Use Only")
    print("═" * 70)

    print("\n[1] USASpending.gov — Direct NAICS Award Search")
    print(json.dumps(usaspending_naics_params(), indent=2))

    print("\n[2] USASpending.gov — Sub-Award Search (Tier 2/3 via Prime)")
    print(json.dumps(usaspending_subaward_params(), indent=2))

    print("\n[3] SBIR.gov — Phase II/III Keyword Passes")
    for q in sbir_search_queries():
        print(f"\n  [{q['label']}]")
        print(f"    Keywords : {q['keywords']}")
        print(f"    Phase    : {q['phase']}  |  Agency: {q['agency']}")
        print(f"    Notes    : {q['notes']}")

    print("\n[4] SAM.gov — Entity Registration Searches by NAICS")
    for s in sam_gov_entity_search():
        print(f"  NAICS {s['naics_code']} → {s['url_template']}")

    print("\n[5] LinkedIn Headcount Heuristics")
    h = linkedin_headcount_heuristics()
    print(f"  Headcount band : {h['headcount_band']['min']}–{h['headcount_band']['max']} FTEs")
    print(f"  Industries     : {', '.join(h['industries'])}")
    print(f"  Note           : {h['notes']}")

    print("\n[6] Capability Keyword Search Strings (Anonymized)")
    for s in capability_keyword_search_strings():
        print(f"\n  [{s['category']}]")
        print(f"    Web query  : {s['search_string']}")
        print(f"    Plain text : {s['plain_search']}")

    print("\n" + "═" * 70)


if __name__ == "__main__":
    print_report()
