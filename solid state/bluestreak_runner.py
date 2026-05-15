"""
Project Bluestreak — Orchestration Runner
US Defense Industrial Base Mapping: SRM Tier 2/3 Supply Chain
Confidential // Internal Use Only

Loads bluestreak_config.json and executes the full sourcing pipeline:
  - State-targeted, OPSEC-compliant search query generation
  - Geographic cluster analysis for each target state
  - Target Identification Matrix in Bluestreak output schema
  - SEC EDGAR divestiture signal queries
  - SBIR Phase II/III seed list by state
"""

from __future__ import annotations
import json
import os
from datetime import date

CONFIG_FILE    = os.path.join(os.path.dirname(__file__), "bluestreak_config.json")
COMPANIES_FILE = os.path.join(os.path.dirname(__file__), "Target Company Research", "companies.json")
OUTPUT_DIR     = os.path.join(os.path.dirname(__file__), "Target Company Research")


# ── Config Loader ───────────────────────────────────────────────────────────────

def load_config() -> dict:
    with open(CONFIG_FILE) as f:
        return json.load(f)


def load_companies() -> list[dict]:
    if not os.path.exists(COMPANIES_FILE):
        return []
    with open(COMPANIES_FILE) as f:
        return json.load(f)


# ── Geographic Cluster Intelligence ────────────────────────────────────────────

STATE_CLUSTERS = {
    "Utah": {
        "srm_significance": "CRITICAL",
        "rationale": (
            "Promontory, UT is the geographic center of US solid propellant production. "
            "Northrop Grumman's Propulsion Systems division (ATK legacy) operates the "
            "largest SRM facility in the world here. Tier 2/3 ecosystem is deep — "
            "composite casing shops, propellant chemical suppliers, and test services "
            "are clustered within 60 miles of Brigham City."
        ),
        "anchor_primes": ["Northrop Grumman (Promontory)", "Orbital Sciences (Promontory)"],
        "hot_naics": ["336415", "325920", "325211"],
        "target_cities": ["Brigham City", "Ogden", "Clearfield", "Salt Lake City"],
        "known_capability_clusters": [
            "Composite motor casings (filament winding)",
            "HTPB pre-polymer processing",
            "Ammonium perchlorate handling / reprocessing",
            "Grain casting and cure operations",
            "Ballistic test instrumentation",
        ],
        "sbir_search_tip": (
            "Filter SBIR.gov by State=UT, Phase=II, keywords='solid propellant' OR "
            "'rocket motor grain'. Expect 15-30 historical awards from Thiokol/ATK-era "
            "spin-outs still operating in the region."
        ),
    },
    "Alabama": {
        "srm_significance": "HIGH",
        "rationale": (
            "Redstone Arsenal (Huntsville) is the Army's primary missile development "
            "center. Large Tier 2/3 ecosystem exists for tactical SRM programs "
            "(HIMARS, ATACMS, Javelin). The Missile Defense Agency and NASA MSFC "
            "both drive significant propulsion subcontracting locally."
        ),
        "anchor_primes": ["Boeing (Huntsville)", "Dynetics / Leidos", "SAIC", "Torch Technologies"],
        "hot_naics": ["336415", "332710", "541330"],
        "target_cities": ["Huntsville", "Decatur", "Madison", "Albertville"],
        "known_capability_clusters": [
            "Precision machined nozzle components",
            "Igniter and initiator assemblies",
            "Propulsion system integration / test",
            "Motor case insulation and liner",
            "Engineering services — SRM analysis",
        ],
        "sbir_search_tip": (
            "Filter SBIR.gov by State=AL, Phase=II, keywords='tactical missile' OR "
            "'solid rocket motor' OR 'igniter'. Huntsville SBIR ecosystem is prolific — "
            "expect 40+ relevant awards."
        ),
    },
    "Arkansas": {
        "srm_significance": "HIGH",
        "rationale": (
            "Camden, AR hosts one of the largest ordnance manufacturing complexes in "
            "the US. General Dynamics OTS operates a major artillery and rocket motor "
            "facility here. Camden's industrial base includes multiple Tier 2/3 "
            "energetic material processors and propellant component manufacturers "
            "that exist nowhere else domestically."
        ),
        "anchor_primes": ["General Dynamics OTS (Camden)", "Lockheed Martin (Camden)"],
        "hot_naics": ["325920", "332993", "325180"],
        "target_cities": ["Camden", "Arkadelphia", "El Dorado", "Hope"],
        "known_capability_clusters": [
            "Energetic material synthesis and processing",
            "Propellant grain manufacturing",
            "Ammonium perchlorate supply chain",
            "Explosive component manufacturing",
            "Warhead and fuze integration",
        ],
        "sbir_search_tip": (
            "Camden-area companies rarely win SBIR directly — prioritize USASpending "
            "sub-award search under GD-OTS and LM contract vehicles. SAM.gov NAICS "
            "325920 + State=AR will surface the most relevant entities."
        ),
    },
    "Virginia": {
        "srm_significance": "MODERATE",
        "rationale": (
            "Northern Virginia and Hampton Roads host defense engineering services "
            "firms, systems integrators, and propulsion analysis houses that act as "
            "Tier 2 intermediaries. Virginia Beach and Norfolk have naval propulsion "
            "supply chain overlap. Several SBIR Phase III companies near DC beltway "
            "are transitioning propellant tech to production."
        ),
        "anchor_primes": ["Raytheon (Falls Church)", "Leidos (Reston)", "Booz Allen Hamilton"],
        "hot_naics": ["541330", "336415", "336419"],
        "target_cities": ["Radford", "Sterling", "Reston", "Virginia Beach", "Manassas"],
        "known_capability_clusters": [
            "Propulsion systems engineering services",
            "SRM performance modeling and simulation",
            "Nozzle TVC actuator components",
            "Composite structure design / analysis",
            "Radford — ATK Radford Army Ammunition Plant (AP, double-base propellants)",
        ],
        "sbir_search_tip": (
            "Radford, VA is critical — the Radford Army Ammunition Plant supplies "
            "nitrocellulose and smokeless powder. Filter SBIR State=VA + 'propellant' "
            "OR 'nozzle' OR 'TVC'. Also check SEC EDGAR for Radford-adjacent entities."
        ),
    },
    "Mississippi": {
        "srm_significance": "MODERATE",
        "rationale": (
            "John C. Stennis Space Center (Bay St. Louis) is a major propulsion test "
            "facility. While Tier 1 testing dominates, a cluster of specialized test "
            "services, instrumentation, and propellant characterization firms operate "
            "in the surrounding area. Acquisition of a test-capable facility here "
            "provides immediate program leverage."
        ),
        "anchor_primes": ["Aerojet Rocketdyne (Stennis)", "NASA SSC contractors"],
        "hot_naics": ["541330", "336415", "332710"],
        "target_cities": ["Bay St. Louis", "Hancock County", "Gulfport", "Picayune"],
        "known_capability_clusters": [
            "Static fire test services",
            "Propellant ballistic characterization",
            "Hot fire instrumentation and data acquisition",
            "Composite nozzle fabrication",
            "Environmental / aging test services",
        ],
        "sbir_search_tip": (
            "Filter SBIR State=MS, Phase=II, keywords='propellant' OR 'hot fire' OR "
            "'static test'. Smaller universe — expect 5-12 relevant awards. "
            "Cross-reference with Stennis Space Center vendor databases."
        ),
    },
}


# ── OPSEC Query Packaging ───────────────────────────────────────────────────────

BLOCKED_KEYWORDS = ["Acquisition", "Takeover", "Due Diligence", "Client Name Redacted",
                    "M&A", "merger", "acqui-hire", "buyout", "LOI", "term sheet"]

PERSONA_HEADER = (
    "Search context: Industrial base research for defense manufacturing capacity "
    "assessment. Queries are structured to identify domestic manufacturing capabilities "
    "and supplier concentration in the solid rocket motor sector."
)


def sanitize_query(query: str) -> str:
    for kw in BLOCKED_KEYWORDS:
        if kw.lower() in query.lower():
            raise ValueError(f"OPSEC violation — blocked keyword '{kw}' in query: {query}")
    return query


def build_state_queries(config: dict) -> dict[str, dict]:
    naics = config["search_parameters"]["naics_codes"]
    keywords = config["search_parameters"]["keyword_clusters"]
    states = config["project_metadata"]["hq_regions"]
    rev_min = config["project_metadata"]["target_revenue_range"]["min"]
    rev_max = config["project_metadata"]["target_revenue_range"]["max"]

    queries = {}
    for state in states:
        cluster = STATE_CLUSTERS.get(state, {})
        hot = cluster.get("hot_naics", naics)

        usaspending = {
            "endpoint": "https://api.usaspending.gov/api/v2/search/spending_by_award/",
            "method": "POST",
            "body": {
                "filters": {
                    "naics_codes": hot,
                    "award_type_codes": ["A", "B", "C", "D"],
                    "award_amounts": [{"lower_bound": 300_000, "upper_bound": 40_000_000}],
                    "place_of_performance_scope": "domestic",
                    "place_of_performance_locations": [{"country": "USA", "state": state[:2].upper()}],
                },
                "fields": ["Recipient Name", "Recipient DUNS", "Award Amount",
                           "NAICS Code", "NAICS Description", "Award ID",
                           "Period of Performance Current End Date"],
                "sort": "Award Amount",
                "order": "desc",
                "limit": 100,
            },
        }

        sbir = {
            "url": "https://www.sbir.gov/sbirsearch/award/all",
            "params": {
                "f[0]": f"program:SBIR",
                "f[1]": "phase:Phase II",
                "f[2]": f"state:{state}",
                "f[3]": "agency:DOD",
            },
            "keyword_passes": [sanitize_query(kw) for kw in keywords],
            "tip": cluster.get("sbir_search_tip", ""),
        }

        sam = [
            {
                "naics": n,
                "url": f"https://sam.gov/search?index=ei&naicsCode={n}&q=&stateOfIncorporation={state[:2].upper()}",
            }
            for n in hot
        ]

        emp_min = int((rev_min * 0.40) / 200_000)
        emp_max = int((rev_max * 0.70) / 150_000)

        linkedin = {
            "headcount_range": f"{emp_min}–{emp_max} employees",
            "location_filter": state,
            "industry_filters": ["Defense & Space", "Aviation & Aerospace", "Chemicals", "Industrial Machinery"],
            "keyword_passes": [sanitize_query(kw) for kw in keywords[:3]],
            "persona_note": PERSONA_HEADER,
        }

        queries[state] = {
            "significance": cluster.get("srm_significance", "UNKNOWN"),
            "rationale_summary": cluster.get("rationale", "")[:120] + "...",
            "anchor_primes": cluster.get("anchor_primes", []),
            "target_cities": cluster.get("target_cities", []),
            "capability_clusters": cluster.get("known_capability_clusters", []),
            "usaspending": usaspending,
            "sbir": sbir,
            "sam_gov": sam,
            "linkedin": linkedin,
        }

    return queries


# ── Output Matrix ───────────────────────────────────────────────────────────────

def revenue_tier_label(c: dict) -> str:
    rev = c.get("known_revenue", "")
    emp = c.get("employee_count", 0)
    awards = c.get("annual_award_volume_usd", 0)

    if rev:
        return rev
    emp_mid = emp * 200_000
    award_mid = (awards / 0.55) if awards else 0
    est = max(emp_mid, award_mid)

    if est >= 75_000_000:
        return "$75M–$100M (est.)"
    elif est >= 50_000_000:
        return "$50M–$75M (est.)"
    elif est >= 30_000_000:
        return "$30M–$50M (est.)"
    else:
        return "<$30M or unknown"


def generate_matrix(config: dict) -> str:
    companies = load_companies()
    fields    = config["output_schema"]["fields"]
    states    = config["project_metadata"]["hq_regions"]

    filtered = [c for c in companies if c.get("hq_state") in states] or companies

    lines = [
        f"# {config['project_metadata']['codename']} — Target Identification Matrix",
        "**Confidential // Internal Use Only**",
        f"*Generated: {date.today()}  |  "
        f"Scope: {', '.join(states)}  |  "
        f"Revenue band: ${config['project_metadata']['target_revenue_range']['min']/1e6:.0f}M–"
        f"${config['project_metadata']['target_revenue_range']['max']/1e6:.0f}M*",
        "",
    ]

    header = "| " + " | ".join(f.replace("_", " ").title() for f in fields) + " | Score |"
    sep    = "| " + " | ".join(["---"] * (len(fields) + 1)) + " |"
    lines += [header, sep]

    for c in sorted(filtered, key=lambda x: x.get("total_score", 0), reverse=True):
        row_vals = []
        for f in fields:
            if f == "company_name":
                row_vals.append(c.get("company_name", "—"))
            elif f == "estimated_revenue_tier":
                row_vals.append(revenue_tier_label(c))
            elif f == "employee_count":
                row_vals.append(str(c.get("employee_count", "—")))
            elif f == "primary_capability":
                row_vals.append(c.get("srm_role", c.get("notes", "—"))[:60])
            elif f == "prime_customer_history":
                primes = c.get("prime_relationships", [])
                row_vals.append(", ".join(primes) if primes else "—")
            elif f == "geographic_footprint":
                row_vals.append(c.get("hq_state", "—"))
            elif f == "sam_status":
                row_vals.append("Active" if c.get("sam_registered") else "Unverified")
            else:
                row_vals.append(str(c.get(f, "—")))
        score = c.get("total_score", 0)
        row_vals.append(f"{score}/110")
        lines.append("| " + " | ".join(row_vals) + " |")

    if not filtered:
        lines.append("| *No companies profiled yet — run profiler.py to add targets* |" + " — |" * len(fields))

    return "\n".join(lines)


# ── SEC EDGAR Divestiture Signal Query ─────────────────────────────────────────

def sec_edgar_queries(config: dict) -> list[dict]:
    """
    EDGAR full-text search parameters for divestiture and subsidiary sale signals
    from Tier 1 primes — surfaces Tier 2/3 units being spun off or sold.
    """
    primes = config["search_parameters"]["prime_contractors"]
    terms = [
        "divestiture propulsion",
        "sale of subsidiary rocket",
        "spin-off energetic materials",
        "discontinued operations missile",
        "disposal of solid rocket",
    ]
    return [
        {
            "source": "SEC EDGAR Full-Text Search",
            "url": "https://efts.sec.gov/LATEST/search-index?q={query}&dateRange=custom&startdt=2020-01-01",
            "search_terms": terms,
            "prime_context": primes,
            "notes": (
                "Target 10-K and 8-K filings. Divestiture language from a Tier 1 prime "
                "signals a Tier 2/3 subsidiary entering the market. These are the "
                "highest-confidence, time-sensitive acquisition opportunities."
            ),
            "filing_types": ["10-K", "8-K", "SC TO-T", "DEF 14A"],
        }
    ]


# ── Report Generation ───────────────────────────────────────────────────────────

def generate_full_report(config: dict) -> str:
    codename  = config["project_metadata"]["codename"]
    states    = config["project_metadata"]["hq_regions"]
    rev_min   = config["project_metadata"]["target_revenue_range"]["min"] / 1e6
    rev_max   = config["project_metadata"]["target_revenue_range"]["max"] / 1e6
    naics     = config["search_parameters"]["naics_codes"]
    persona   = config["opsec_protocols"]["search_persona"]

    queries = build_state_queries(config)

    lines = [
        f"# {codename} — Full Sourcing Package",
        "**Confidential // Internal Use Only**",
        f"*{date.today()}*",
        "",
        "---",
        "",
        "## Project Parameters",
        "",
        f"| Parameter | Value |",
        f"|---|---|",
        f"| Objective | {config['project_metadata']['objective']} |",
        f"| Target Tiers | {', '.join(str(t) for t in config['project_metadata']['focus_tier'])} |",
        f"| Revenue Band | ${rev_min:.0f}M – ${rev_max:.0f}M |",
        f"| Target States | {', '.join(states)} |",
        f"| NAICS Codes | {', '.join(naics)} |",
        f"| Search Persona | {persona} |",
        f"| OPSEC | Queries anonymized — no deal language embedded |",
        "",
        "---",
        "",
        "## Target Identification Matrix",
        "",
        generate_matrix(config),
        "",
        "---",
        "",
        "## State-by-State Geographic Intelligence",
        "",
    ]

    for state, data in queries.items():
        cluster = STATE_CLUSTERS[state]
        lines += [
            f"### {state}  `{data['significance']}`",
            "",
            f"{cluster['rationale']}",
            "",
            f"**Anchor Primes (Tier 1 reference points):** {', '.join(data['anchor_primes'])}",
            "",
            f"**Target Cities:** {', '.join(data['target_cities'])}",
            "",
            "**Known Capability Clusters:**",
        ]
        for cap in data["capability_clusters"]:
            lines.append(f"- {cap}")
        lines += [""]

    lines += [
        "---",
        "",
        "## USASpending.gov Query Package",
        "",
        "POST the following JSON bodies to `https://api.usaspending.gov/api/v2/search/spending_by_award/`",
        "",
    ]
    for state, data in queries.items():
        lines += [
            f"### {state}",
            "```json",
            json.dumps(data["usaspending"]["body"], indent=2),
            "```",
            "",
        ]

    lines += [
        "---",
        "",
        "## SBIR.gov Search Passes",
        "",
        "| State | Significance | Keyword Pass | SBIR Tip |",
        "|---|---|---|---|",
    ]
    for state, data in queries.items():
        for kw in data["sbir"]["keyword_passes"]:
            lines.append(
                f"| {state} | {data['significance']} | `{kw}` | {data['sbir']['tip'][:80]}... |"
            )

    lines += [
        "",
        "---",
        "",
        "## SAM.gov Entity Registry Searches",
        "",
        "| State | NAICS | Direct URL |",
        "|---|---|---|",
    ]
    for state, data in queries.items():
        for s in data["sam_gov"]:
            lines.append(f"| {state} | {s['naics']} | {s['url']} |")

    lines += [
        "",
        "---",
        "",
        "## LinkedIn Headcount Heuristics",
        "",
        "| State | Headcount Range | Keywords |",
        "|---|---|---|",
    ]
    for state, data in queries.items():
        kws = ", ".join(data["linkedin"]["keyword_passes"])
        lines.append(f"| {state} | {data['linkedin']['headcount_range']} | {kws} |")

    edgar = sec_edgar_queries(config)
    lines += [
        "",
        "---",
        "",
        "## SEC EDGAR Divestiture Signal Monitoring",
        "",
        f"> {edgar[0]['notes']}",
        "",
        "**Search terms:**",
    ]
    for t in edgar[0]["search_terms"]:
        lines.append(f"- `{t}`")
    lines += [
        "",
        f"**Filing types to monitor:** {', '.join(edgar[0]['filing_types'])}",
        "",
        "---",
        "",
        "## Search Coverage Log",
        "",
        "| Database | State | Date Queried | Hits | Analyst | Notes |",
        "|---|---|---|---|---|---|",
    ]
    for state in states:
        for db in ["USASpending", "SBIR.gov", "SAM.gov", "LinkedIn", "SEC EDGAR"]:
            lines.append(f"| {db} | {state} | | | | |")

    lines += [
        "",
        "---",
        "",
        "*All data sourced from public US government databases and open commercial sources.*",
        "*No proprietary, restricted, or export-controlled data is contained herein.*",
        f"*Codename: {codename} // {date.today()}*",
    ]

    return "\n".join(lines)


# ── CLI ─────────────────────────────────────────────────────────────────────────

MENU = """
  ╔══════════════════════════════════════════════╗
  ║  Project Bluestreak — Orchestration Runner   ║
  ║  Confidential // Internal Use Only           ║
  ╚══════════════════════════════════════════════╝

  1.  Generate full sourcing report (bluestreak_report.md)
  2.  Print target matrix only
  3.  Print state intelligence summary
  4.  Print search queries for one state
  0.  Exit
"""


def main() -> None:
    config = load_config()
    print(f"\n  [{config['project_metadata']['codename']}] Config loaded.")
    print(f"  States: {', '.join(config['project_metadata']['hq_regions'])}")
    print(f"  Revenue band: ${config['project_metadata']['target_revenue_range']['min']/1e6:.0f}M–"
          f"${config['project_metadata']['target_revenue_range']['max']/1e6:.0f}M")

    while True:
        print(MENU)
        choice = input("  Select: ").strip()

        if choice == "1":
            report = generate_full_report(config)
            out = os.path.join(OUTPUT_DIR, "bluestreak_report.md")
            with open(out, "w") as f:
                f.write(report)
            print(f"\n  Report written to: {out}")

        elif choice == "2":
            print("\n" + generate_matrix(config))

        elif choice == "3":
            for state, cluster in STATE_CLUSTERS.items():
                if state in config["project_metadata"]["hq_regions"]:
                    print(f"\n{'═'*60}")
                    print(f"  {state.upper()}  [{cluster['srm_significance']}]")
                    print(f"  {cluster['rationale'][:200]}...")
                    print(f"  Capabilities: {', '.join(cluster['known_capability_clusters'][:3])}")

        elif choice == "4":
            state = input("\n  Enter state name: ").strip()
            queries = build_state_queries(config)
            if state in queries:
                print(json.dumps(queries[state], indent=2))
            else:
                print(f"  State '{state}' not in project scope.")

        elif choice == "0":
            break
        else:
            print("\n  Invalid selection.")


if __name__ == "__main__":
    main()
