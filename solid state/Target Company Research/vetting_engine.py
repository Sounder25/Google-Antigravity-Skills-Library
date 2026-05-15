"""
Bluestreak Vetting Engine — Purchasability Scoring & Compliance Screening
Integrates FOCI/NISS (May 2026 rule), CMMC Level 2 deadline, and risk weights.
Confidential // Industrial Base Resilience Mapping
"""

from __future__ import annotations
import datetime
import json
import os
import sys

# ── Default Config (overridden by bluestreak_config.json vetting_standards) ────

DEFAULT_CONFIG = {
    "vetting_standards": {
        "revenue_sweet_spot":  [30_000_000, 100_000_000],
        "foci_threshold_usd":  5_000_000,
        "cmmc_deadline":       "2026-11-10",
        "rpe_midpoint":        350_000,
    },
    "risk_weights": {
        "foreign_board_member":    0.9,
        "no_cmmc_pathway":         0.7,
        "high_prime_concentration": 0.5,
    },
    "opsec": {
        "mask":      "Industrial Base Resilience Mapping",
        "forbidden": ["M&A", "Buyout", "Acquisition", "Valuation"],
    },
}

COMPANIES_FILE = os.path.join(os.path.dirname(__file__), "companies.json")


class BluestreakEngine:
    """
    Purchasability scoring engine for Project Bluestreak.
    Evaluates acquisition cleanliness across three compliance dimensions:
      1. Revenue band (RPE gate)
      2. FOCI / NISS exposure (May 2026 rule)
      3. CMMC Level 2 posture (Nov 10 2026 deadline)
    Risk weights penalize foreign influence, CMMC gaps, and prime concentration.
    """

    def __init__(self, config: dict = None):
        self.cfg = config or DEFAULT_CONFIG
        self._vs  = self.cfg["vetting_standards"]
        self._rw  = self.cfg["risk_weights"]
        self._deadline = datetime.datetime.strptime(
            self._vs["cmmc_deadline"], "%Y-%m-%d"
        )
        self._days_to_deadline = (self._deadline - datetime.datetime.now()).days

    # ── Core Scoring ────────────────────────────────────────────────────────────

    def calculate_purchasability(self, company: dict) -> dict:
        """
        Returns purchasability score 0–100.
        Higher = cleaner, lower-friction acquisition.
        Returns 0 with explanation if out-of-scope (revenue band fail).
        """
        score      = 100
        deductions = []
        flags      = []

        # ── Gate 1: Revenue Band ────────────────────────────────────────────────
        est_rev = company["headcount"] * self._vs["rpe_midpoint"]
        lo, hi  = self._vs["revenue_sweet_spot"]
        if not (lo <= est_rev <= hi):
            return {
                "purchasability_score": 0,
                "gate_fail":   "REVENUE_BAND",
                "est_revenue": est_rev,
                "rating":      "OUT OF SCOPE",
                "days_to_cmmc": self._days_to_deadline,
                "note": (f"Est. revenue ${est_rev/1e6:.1f}M outside "
                         f"${lo/1e6:.0f}M–${hi/1e6:.0f}M band — out of scope"),
                "deductions": [],
                "flags": [],
                "risk_multiplier": 1.0,
            }

        # ── Gate 2: FOCI / NISS (New May 2026 Rule) ────────────────────────────
        total_awards = company.get("total_awards", company.get("annual_award_volume_usd", 0))
        if total_awards > self._vs["foci_threshold_usd"]:
            if not company.get("niss_eligible", True):
                score -= 30
                deductions.append({
                    "item":   "FOCI/NISS — not eligible",
                    "points": -30,
                    "detail": (
                        f"Awards ${total_awards/1e6:.1f}M exceed "
                        f"${self._vs['foci_threshold_usd']/1e6:.1f}M FOCI threshold. "
                        "New SF-328 filing required under May 2026 NISS rule. "
                        "DSS review likely — adds 60–180 days to close timeline."
                    ),
                })
                flags.append("FOCI_NISS_RISK")

        # ── Gate 3: CMMC Level 2 Deadline ──────────────────────────────────────
        if not company.get("cmmc_level_2", False):
            if self._days_to_deadline > 180:
                penalty = 20
                urgency = "MODERATE"
            else:
                penalty = 50
                urgency = "CRITICAL"
            score -= penalty
            deductions.append({
                "item":   f"CMMC Level 2 — not certified [{urgency}]",
                "points": -penalty,
                "detail": (
                    f"{self._days_to_deadline} days to deadline "
                    f"({self._vs['cmmc_deadline']}). "
                    f"Uncertified at close = contract eligibility risk. "
                    f"Remediation cost est. $150k–$500k + 12–18 months."
                ),
            })
            flags.append(f"CMMC_GAP_{urgency}")

        # ── Risk Weight Penalties ───────────────────────────────────────────────
        if company.get("foreign_board_member", False):
            penalty = round(self._rw["foreign_board_member"] * 100)
            score  -= penalty
            deductions.append({
                "item":   "Foreign board member",
                "points": -penalty,
                "detail": (
                    "Foreign national on board or advisory committee. "
                    "DCSA FOCI review mandatory before cleared facility transfer. "
                    "Structural mitigation (SSA, SCA, or board resolution) required."
                ),
            })
            flags.append("FOREIGN_INFLUENCE")

        if not company.get("cmmc_pathway_exists", True):
            penalty = round(self._rw["no_cmmc_pathway"] * 100)
            score  -= penalty
            deductions.append({
                "item":   "No CMMC pathway defined",
                "points": -penalty,
                "detail": (
                    "Company has no documented System Security Plan (SSP) or "
                    "CMMC remediation roadmap. Post-close compliance burden falls "
                    "entirely on acquirer — factor into purchase price adjustment."
                ),
            })
            flags.append("NO_CMMC_PATHWAY")

        prime_conc = company.get("prime_concentration_pct", 0)
        if prime_conc > 70:
            penalty = round(self._rw["high_prime_concentration"] * 100)
            score  -= penalty
            deductions.append({
                "item":   f"High prime concentration ({prime_conc}%)",
                "points": -penalty,
                "detail": (
                    f"{prime_conc}% of revenue from single prime. "
                    "Change-of-control notification required; prime may exercise "
                    "consent rights under sub-contract terms. Revenue cliff risk "
                    "if prime relationship does not transfer."
                ),
            })
            flags.append("PRIME_CONCENTRATION")

        final = max(0, score)

        return {
            "purchasability_score": final,
            "gate_fail":            None,
            "est_revenue":          est_rev,
            "days_to_cmmc":         self._days_to_deadline,
            "deductions":           deductions,
            "flags":                flags,
            "rating":               self._purchasability_label(final),
            "risk_multiplier":      round(score / 100, 2),
        }

    @staticmethod
    def _purchasability_label(score: int) -> str:
        if score >= 80:
            return "CLEAN — Low-friction acquisition"
        elif score >= 60:
            return "MANAGEABLE — Known issues, workable"
        elif score >= 40:
            return "COMPLEX — Significant compliance work required"
        elif score > 0:
            return "HIGH-RISK — Structural deal blockers present"
        else:
            return "OUT OF SCOPE"

    # ── Batch Processing ────────────────────────────────────────────────────────

    def screen_batch(self, companies: list[dict]) -> list[dict]:
        """Score all companies and attach purchasability results."""
        results = []
        for c in companies:
            adapted = {
                "headcount":              c.get("employee_count", 0),
                "total_awards":           c.get("annual_award_volume_usd", 0),
                "niss_eligible":          c.get("niss_eligible", True),
                "cmmc_level_2":           c.get("cmmc_level_2", False),
                "cmmc_pathway_exists":    c.get("cmmc_pathway_exists", True),
                "foreign_board_member":   c.get("foreign_board_member", False),
                "prime_concentration_pct": c.get("prime_concentration_pct", 0),
            }
            result = self.calculate_purchasability(adapted)
            results.append({**c, "vetting": result})
        return sorted(results, key=lambda x: x["vetting"]["purchasability_score"], reverse=True)

    def rank_targets(self) -> list[dict]:
        """Load companies.json and return ranked by purchasability."""
        if not os.path.exists(COMPANIES_FILE):
            return []
        with open(COMPANIES_FILE) as f:
            companies = json.load(f)
        return self.screen_batch(companies)

    # ── Report Generation ───────────────────────────────────────────────────────

    def generate_acquisition_brief(self, company: dict) -> str:
        """One-page acquisition brief for a single company."""
        adapted = {
            "headcount":              company.get("employee_count", 0),
            "total_awards":           company.get("annual_award_volume_usd", 0),
            "niss_eligible":          company.get("niss_eligible", True),
            "cmmc_level_2":           company.get("cmmc_level_2", False),
            "cmmc_pathway_exists":    company.get("cmmc_pathway_exists", True),
            "foreign_board_member":   company.get("foreign_board_member", False),
            "prime_concentration_pct": company.get("prime_concentration_pct", 0),
        }
        v = self.calculate_purchasability(adapted)

        lines = [
            f"{'═'*65}",
            f"  ACQUISITION BRIEF — {company.get('company_name', 'UNKNOWN').upper()}",
            f"  {self.cfg['opsec']['mask']} // Confidential",
            f"{'═'*65}",
            "",
            f"  Strategic Score   : {company.get('total_score', '—')} / 110",
            f"  Purchasability    : {v['purchasability_score']} / 100  —  {v['rating']}",
            f"  Est. Revenue      : ${v['est_revenue']/1e6:.1f}M",
            f"  CMMC Days Left    : {v['days_to_cmmc']} days to {self._vs['cmmc_deadline']}",
            "",
        ]

        if v.get("gate_fail"):
            lines += [f"  ⛔ GATED OUT: {v['note']}", ""]
        elif v["flags"]:
            lines += ["  Active Risk Flags:"]
            for flag in v["flags"]:
                lines.append(f"    ⚑ {flag}")
            lines.append("")

        if v["deductions"]:
            lines += ["  Compliance Deductions:", ""]
            for d in v["deductions"]:
                lines.append(f"  [{d['points']:>4}]  {d['item']}")
                lines.append(f"         {d['detail']}")
                lines.append("")

        lines += [
            "  SRM Stack Role    : " + company.get("srm_role", "—"),
            "  HQ State          : " + company.get("hq_state", "—"),
            "  Clearance         : " + company.get("clearance_level", "—"),
            "  M&A Signal        : " + company.get("ma_signal", "—"),
            "  Prime Partners    : " + ", ".join(company.get("prime_relationships", ["—"])),
            "",
        ]

        if company.get("notes"):
            lines += [f"  Notes: {company['notes']}", ""]

        lines.append(f"{'═'*65}")
        return "\n".join(lines)

    def print_ranked_table(self) -> None:
        ranked = self.rank_targets()
        if not ranked:
            print("\n  No companies profiled. Run profiler.py first.")
            return

        cmmc_alert = ""
        if self._days_to_deadline <= 180:
            cmmc_alert = f"  ⚠ CMMC DEADLINE {self._days_to_deadline} DAYS AWAY — uncertified companies take -50 penalty"

        print(f"\n{'═'*75}")
        print(f"  BLUESTREAK — RANKED ACQUISITION TARGETS")
        print(f"  {self.cfg['opsec']['mask']} // Confidential")
        if cmmc_alert:
            print(cmmc_alert)
        print(f"{'═'*75}")
        print(f"  {'Company':<28} {'Rev Est':>8}  {'Strat':>5}  {'P-Score':>7}  Rating")
        print(f"  {'─'*28}  {'─'*8}  {'─'*5}  {'─'*7}  {'─'*30}")

        for c in ranked:
            v = c["vetting"]
            if v.get("gate_fail"):
                continue
            name    = c.get("company_name", "—")[:27]
            rev     = f"${v['est_revenue']/1e6:.0f}M"
            strat   = c.get("total_score", "—")
            pscore  = v["purchasability_score"]
            rating  = v["rating"].split("—")[0].strip()
            flags   = " ".join(f"[{f[:4]}]" for f in v["flags"][:2])
            print(f"  {name:<28} {rev:>8}  {str(strat):>5}  {pscore:>7}  {rating}  {flags}")

        print(f"{'═'*75}")

    def generate_compliance_report(self) -> str:
        """Full compliance status markdown report."""
        ranked = self.rank_targets()
        lines  = [
            "# Project Bluestreak — Compliance & Purchasability Report",
            f"**{self.cfg['opsec']['mask']} // Confidential**",
            f"*Generated: {datetime.date.today()}*",
            f"*CMMC Deadline: {self._vs['cmmc_deadline']} — **{self._days_to_deadline} days remaining***",
            "",
            "---",
            "",
            "## Purchasability Rankings",
            "",
            f"| Company | Est. Revenue | Strat Score | P-Score | Rating | Flags |",
            f"|---|---|---|---|---|---|",
        ]

        for c in ranked:
            v = c["vetting"]
            if v.get("gate_fail"):
                continue
            flags = ", ".join(v["flags"]) or "—"
            lines.append(
                f"| {c.get('company_name','—')} "
                f"| ${v['est_revenue']/1e6:.1f}M "
                f"| {c.get('total_score','—')}/110 "
                f"| **{v['purchasability_score']}/100** "
                f"| {v['rating']} "
                f"| {flags} |"
            )

        lines += ["", "---", "", "## Compliance Status by Company", ""]
        for c in ranked:
            v = c["vetting"]
            if v.get("gate_fail"):
                continue
            lines.append(self.generate_acquisition_brief(c))
            lines.append("")

        return "\n".join(lines)


# ── CLI ─────────────────────────────────────────────────────────────────────────

MENU = """
  ╔═══════════════════════════════════════════════╗
  ║  Bluestreak Vetting Engine                    ║
  ║  Purchasability & Compliance Scoring          ║
  ║  Industrial Base Resilience Mapping           ║
  ╚═══════════════════════════════════════════════╝

  1.  Print ranked acquisition targets
  2.  Generate compliance report (bluestreak_compliance.md)
  3.  Score a single test company (interactive)
  4.  Show CMMC deadline status
  0.  Exit
"""


def _load_project_config() -> dict:
    cfg_path = os.path.join(os.path.dirname(__file__), "..", "bluestreak_config.json")
    if not os.path.exists(cfg_path):
        return DEFAULT_CONFIG
    with open(cfg_path) as f:
        raw = json.load(f)
    combined = dict(DEFAULT_CONFIG)
    if "vetting_standards" in raw:
        combined["vetting_standards"] = raw["vetting_standards"]
    if "risk_weights" in raw:
        combined["risk_weights"] = raw["risk_weights"]
    if "opsec" in raw.get("opsec_constraints", {}):
        combined["opsec"]["mask"] = raw["opsec_constraints"].get("query_masking", combined["opsec"]["mask"])
    return combined


def main() -> None:
    config = _load_project_config()
    engine = BluestreakEngine(config)

    print(f"\n  Bluestreak Vetting Engine initialized.")
    print(f"  CMMC deadline: {config['vetting_standards']['cmmc_deadline']} "
          f"({engine._days_to_deadline} days)")
    if engine._days_to_deadline <= 180:
        print(f"  ⚠ CRITICAL: Uncertified companies now take -50 CMMC penalty")

    while True:
        print(MENU)
        choice = input("  Select: ").strip()

        if choice == "1":
            engine.print_ranked_table()

        elif choice == "2":
            report = engine.generate_compliance_report()
            out    = os.path.join(os.path.dirname(__file__), "bluestreak_compliance.md")
            with open(out, "w") as f:
                f.write(report)
            print(f"\n  Report written to: {out}")

        elif choice == "3":
            print("\n  Test company intake:")
            from profiler import prompt, prompt_int, prompt_float, prompt_bool
            name   = prompt("Company name")
            hc     = prompt_int("Employee count", 150)
            awards = prompt_float("Annual award volume ($)", 0)
            niss   = prompt_bool("NISS eligible?")
            cmmc   = prompt_bool("CMMC Level 2 certified?")
            path   = prompt_bool("CMMC pathway documented?")
            fgn    = prompt_bool("Foreign board member?")
            conc   = prompt_int("Prime concentration % (0-100)", 0)
            test   = {
                "company_name":           name,
                "headcount":              hc,
                "total_awards":           awards,
                "niss_eligible":          niss,
                "cmmc_level_2":           cmmc,
                "cmmc_pathway_exists":    path,
                "foreign_board_member":   fgn,
                "prime_concentration_pct": conc,
            }
            print("\n" + engine.generate_acquisition_brief(test))

        elif choice == "4":
            d = engine._days_to_deadline
            status = "CRITICAL — -50 penalty active" if d <= 180 else f"WATCH — {d} days, -20 penalty"
            print(f"\n  CMMC Level 2 Deadline: {config['vetting_standards']['cmmc_deadline']}")
            print(f"  Days remaining       : {d}")
            print(f"  Status               : {status}")
            print(f"  Penalty (uncertified): {'-50' if d <= 180 else '-20'} points on purchasability score")

        elif choice == "0":
            break
        else:
            print("\n  Invalid selection.")


if __name__ == "__main__":
    main()
