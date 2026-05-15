"""
SRM Stack Mapper — Bottom-Up Solid Rocket Motor Supply Chain
Confidential // Internal Use Only

Maps Tier 2/3 suppliers to their position in the SRM stack.
Generates leads.md for deal team consumption.
"""

from __future__ import annotations
import json
import os
from datetime import date

COMPANIES_FILE = os.path.join(
    os.path.dirname(__file__), "..", "Target Company Research", "companies.json"
)
LEADS_MD = os.path.join(os.path.dirname(__file__), "..", "Target Company Research", "leads.md")

# ── SRM Stack Definition ────────────────────────────────────────────────────────

SRM_STACK = {
    "PROPELLANT": {
        "label": "Propellant",
        "description": "Binders, oxidizers, energetic additives, mixing & casting",
        "roles": [
            "Propellant — Binders/Pre-polymers (HTPB, MAPO, IPDI)",
            "Propellant — Oxidizers (Ammonium Perchlorate, AP)",
            "Propellant — Energetic Additives (RDX, HMX, Al powder)",
            "Propellant — Mixing & Casting",
        ],
        "strategic_note": (
            "Highest strategic value. Ammonium Perchlorate (AP) is a single-source "
            "domestic supplier risk — any AP-qualified manufacturer is a priority target. "
            "HTPB pre-polymer synthesis is equally constrained."
        ),
        "tier_typical": "Tier 3",
    },
    "CASING": {
        "label": "Casing",
        "description": "Composite filament winding, specialty steel, insulation & liner",
        "roles": [
            "Casing — Carbon Fiber / Filament Winding",
            "Casing — Specialty Steel / Metal",
            "Casing — Insulation & Liner",
        ],
        "strategic_note": (
            "Composite casings are dual-use (commercial COPV, hypersonic). "
            "Metal casings (D6AC, maraging steel) are smaller universe — "
            "fewer than 12 qualified US suppliers. High acquisition value."
        ),
        "tier_typical": "Tier 2",
    },
    "NOZZLE": {
        "label": "Nozzle",
        "description": "Carbon-carbon ablative, throat inserts, TVC components",
        "roles": [
            "Nozzle — Carbon-Carbon / Graphite Ablative",
            "Nozzle — Throat Inserts / TVC Components",
        ],
        "strategic_note": (
            "Carbon-carbon (C/C) nozzle manufacturers overlap with hypersonic TPS "
            "suppliers — significant cross-program leverage. Very few qualified US "
            "shops; acquisition creates immediate defensible moat."
        ),
        "tier_typical": "Tier 2/3",
    },
    "IGNITER": {
        "label": "Igniter / Initiator",
        "description": "Pyrotechnic igniters, EEDs, booster charges",
        "roles": [
            "Igniter / Initiator — Pyrotechnic",
            "Igniter / Initiator — Electrical",
        ],
        "strategic_note": (
            "Highly regulated (ATF, DoT). Very few new entrants — regulatory moat "
            "is significant. Existing qualifications are years-long to replicate. "
            "Ideal Tier 3 acquisition for roll-up."
        ),
        "tier_typical": "Tier 3",
    },
    "TEST": {
        "label": "Test & Measurement",
        "description": "Hot fire test stands, ballistic evaluation, propellant characterization",
        "roles": [
            "Test & Measurement — Hot Fire / Ballistic",
        ],
        "strategic_note": (
            "Test infrastructure is a force-multiplier asset — acquiring a hot fire "
            "capable facility dramatically de-risks propellant development programs."
        ),
        "tier_typical": "Tier 2/3",
    },
    "OTHER": {
        "label": "Other / Multi-role",
        "description": "Multi-role or unclassified stack position",
        "roles": ["Other / Multi-role"],
        "strategic_note": "Requires further classification.",
        "tier_typical": "Unknown",
    },
}


def role_to_category(srm_role: str) -> str:
    for cat, data in SRM_STACK.items():
        if srm_role in data["roles"]:
            return cat
    return "OTHER"


def load_companies() -> list[dict]:
    if not os.path.exists(COMPANIES_FILE):
        return []
    with open(COMPANIES_FILE) as f:
        return json.load(f)


def build_matrix_row(c: dict) -> str:
    primes = ", ".join(c.get("prime_relationships", [])) or "—"
    revenue = c.get("known_revenue") or f"~est. via {c.get('employee_count', '?')} FTEs"
    capabilities = c.get("srm_role", "—")
    sbir = c.get("sbir_signal", "None identified")
    sbir_flag = " ⚑" if "Phase II" in sbir or "Phase III" in sbir else ""
    score = c.get("total_score", 0)
    tier = c.get("tier_fit", "—")
    return (
        f"| {c['company_name']} | {revenue} | {c.get('employee_count', '?')} "
        f"| {capabilities} | {primes} | {c.get('clearance_level', '—')} "
        f"| {sbir}{sbir_flag} | {score}/110 | {tier} |"
    )


def generate_leads_md() -> None:
    companies = load_companies()

    sections: dict[str, list[dict]] = {cat: [] for cat in SRM_STACK}
    for c in companies:
        cat = role_to_category(c.get("srm_role", "Other / Multi-role"))
        sections[cat].append(c)

    priority   = [c for c in companies if "PRIORITY"  in c.get("tier_fit", "")]
    qualified  = [c for c in companies if "QUALIFIED" in c.get("tier_fit", "")]
    watch      = [c for c in companies if "WATCH"     in c.get("tier_fit", "")]

    lines = [
        "# Solid State Propellant — Tier 2/3 Acquisition Leads",
        "**Confidential // Internal Use Only**",
        f"*Generated: {date.today()}*",
        "",
        "---",
        "",
        "## Target Identification Matrix",
        "",
        "| Company Name | Est. Revenue | Employees | Primary Capabilities | Known Prime Partners | Clearance | SBIR Signal | Score | Assessment |",
        "|---|---|---|---|---|---|---|---|---|",
    ]

    for c in sorted(companies, key=lambda x: x.get("total_score", 0), reverse=True):
        lines.append(build_matrix_row(c))

    lines += [
        "",
        "---",
        "",
        "## Ranked Shortlist",
        "",
        "### PRIORITY — Strong Acquisition Candidates",
        "",
    ]
    if priority:
        for c in sorted(priority, key=lambda x: x.get("total_score", 0), reverse=True):
            lines.append(f"- **{c['company_name']}** (Score: {c.get('total_score')}/110) — {c.get('srm_role', '—')} | {c.get('hq_state', '—')}")
    else:
        lines.append("*No companies at this tier yet.*")

    lines += ["", "### QUALIFIED — Warrants Deep Dive", ""]
    if qualified:
        for c in sorted(qualified, key=lambda x: x.get("total_score", 0), reverse=True):
            lines.append(f"- **{c['company_name']}** (Score: {c.get('total_score')}/110) — {c.get('srm_role', '—')} | {c.get('hq_state', '—')}")
    else:
        lines.append("*No companies at this tier yet.*")

    lines += ["", "### WATCH — Monitor & Verify", ""]
    if watch:
        for c in sorted(watch, key=lambda x: x.get("total_score", 0), reverse=True):
            lines.append(f"- **{c['company_name']}** (Score: {c.get('total_score')}/110) — {c.get('srm_role', '—')} | {c.get('hq_state', '—')}")
    else:
        lines.append("*No companies at this tier yet.*")

    lines += ["", "---", "", "## By SRM Stack Position", ""]

    for cat, data in SRM_STACK.items():
        cos = sections.get(cat, [])
        lines += [
            f"### {data['label']}",
            f"*{data['description']}*",
            "",
            f"> **Strategic Note:** {data['strategic_note']}",
            "",
            f"Typical tier: `{data['tier_typical']}`",
            "",
        ]
        if cos:
            for c in sorted(cos, key=lambda x: x.get("total_score", 0), reverse=True):
                sbir = c.get("sbir_signal", "None identified")
                flag = " *(SBIR Phase II/III — high confidence)*" if ("Phase II" in sbir or "Phase III" in sbir) else ""
                lines.append(f"- **{c['company_name']}** — Score {c.get('total_score')}/110{flag}")
                if c.get("notes"):
                    lines.append(f"  - Notes: {c['notes']}")
        else:
            lines.append("*No targets identified in this category yet.*")
        lines.append("")

    lines += [
        "---",
        "",
        "## Search Coverage Log",
        "",
        "Track which databases have been queried to avoid duplication.",
        "",
        "| Database | Date Queried | Query Used | Hits | Analyst |",
        "|---|---|---|---|---|",
        "| USASpending.gov | | | | |",
        "| SAM.gov | | | | |",
        "| SBIR.gov | | | | |",
        "| FPDS Sub-awards | | | | |",
        "| LinkedIn | | | | |",
        "| JANNAF Attendee List | | | | |",
        "| Industry referral | | | | |",
        "",
        "---",
        "*All data is sourced from public government databases and open commercial sources.*",
        "*No proprietary or restricted data is contained herein.*",
    ]

    with open(LEADS_MD, "w") as f:
        f.write("\n".join(lines))

    print(f"\n  leads.md generated: {LEADS_MD}")
    print(f"  Companies included: {len(companies)}")
    print(f"  Priority: {len(priority)}  |  Qualified: {len(qualified)}  |  Watch: {len(watch)}")


def print_stack_summary() -> None:
    companies = load_companies()
    print("\n" + "═" * 60)
    print("  SRM STACK COVERAGE SUMMARY")
    print("═" * 60)
    for cat, data in SRM_STACK.items():
        cos = [c for c in companies if role_to_category(c.get("srm_role", "Other / Multi-role")) == cat]
        bar = "█" * len(cos) if cos else "░"
        print(f"  {data['label']:<25} {len(cos):>2} companies  {bar}")
        print(f"  {'':25} {data['strategic_note'][:60]}...")
    print("═" * 60)


MENU = """
  ╔═══════════════════════════════════════════╗
  ║  SRM Stack Mapper — Supply Chain View     ║
  ║  Confidential // Internal Use Only        ║
  ╚═══════════════════════════════════════════╝

  1.  Generate / refresh leads.md
  2.  Print SRM stack coverage summary
  0.  Exit
"""


def main() -> None:
    while True:
        print(MENU)
        choice = input("  Select: ").strip()
        if choice == "1":
            generate_leads_md()
        elif choice == "2":
            print_stack_summary()
        elif choice == "0":
            break
        else:
            print("\n  Invalid selection.")


if __name__ == "__main__":
    main()
