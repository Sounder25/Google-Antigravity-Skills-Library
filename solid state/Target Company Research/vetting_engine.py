"""
Bluestreak Vetting Engine — Purchasability Scoring & Compliance Screening
Integrates FOCI/NISS (May 2026 rule), CMMC Level 2 deadline, and risk weights.
Confidential // US Industrial Base Resilience Study

Two scoring classes:
  BluestreakVetter  — streamlined assess_target() per latest platform spec
  BluestreakEngine  — full engine with risk weights, briefs, batch ranking
"""

from __future__ import annotations
import datetime
import json
import os
import sys

# ── Canonical Config ────────────────────────────────────────────────────────────

DEFAULT_CONFIG = {
    "platform_vitals": {
        "target_segment":    "SRM Tier 2/3 Supply Chain",
        "revenue_sweet_spot": [30_000_000, 100_000_000],
        "rpe_midpoint":       350_000,
    },
    "regulatory_gates": {
        "foci_threshold":  5_000_000,
        "cmmc_deadline":   "2026-11-01",
        "niss_mandatory":  True,
    },
    "opsec_mask": "US Industrial Base Resilience Study",
    # Extended fields used by BluestreakEngine
    "risk_weights": {
        "foreign_board_member":     0.9,
        "no_cmmc_pathway":          0.7,
        "high_prime_concentration": 0.5,
    },
    "opsec": {
        "mask":      "US Industrial Base Resilience Study",
        "forbidden": ["M&A", "Buyout", "Acquisition", "Valuation"],
    },
}


def _normalise(cfg: dict) -> dict:
    """
    Accept legacy vetting_standards shape or current platform_vitals shape.
    Always returns canonical platform_vitals / regulatory_gates structure.
    """
    if "vetting_standards" in cfg and "platform_vitals" not in cfg:
        vs = cfg["vetting_standards"]
        cfg = dict(cfg)
        cfg["platform_vitals"] = {
            "target_segment":    "SRM Tier 2/3 Supply Chain",
            "revenue_sweet_spot": vs.get("revenue_sweet_spot", [30_000_000, 100_000_000]),
            "rpe_midpoint":       vs.get("rpe_midpoint", 350_000),
        }
        cfg["regulatory_gates"] = {
            "foci_threshold": vs.get("foci_threshold_usd", 5_000_000),
            "cmmc_deadline":  vs.get("cmmc_deadline", "2026-11-01"),
            "niss_mandatory": True,
        }
        cfg.setdefault("opsec_mask", "US Industrial Base Resilience Study")
    return cfg

COMPANIES_FILE = os.path.join(os.path.dirname(__file__), "companies.json")


def _purchasability_label(score: int) -> str:
    if score >= 80:
        return "CLEAN — Low-friction acquisition"
    elif score >= 60:
        return "MANAGEABLE — Known issues, workable"
    elif score >= 40:
        return "COMPLEX — Significant compliance work required"
    elif score > 0:
        return "HIGH-RISK — Structural deal blockers present"
    return "OUT OF SCOPE"


# ══════════════════════════════════════════════════════════════════════════════
# BluestreakVetter — streamlined platform spec (latest)
# ══════════════════════════════════════════════════════════════════════════════

class BluestreakVetter:
    """
    Streamlined target vetter per latest platform spec.
    Three hard gates: revenue band, FOCI/NISS, CMMC Level 2.
    Returns REJECT or MATCH with score 0–100.
    """

    def __init__(self, config: dict = None):
        self.cfg = _normalise(config or DEFAULT_CONFIG)
        self._pv  = self.cfg["platform_vitals"]
        self._rg  = self.cfg["regulatory_gates"]
        self._mask = self.cfg.get("opsec_mask", "US Industrial Base Resilience Study")

    def assess_target(self, company_data: dict) -> dict:
        """
        Score 0–100. Higher = cleaner, lower-friction acquisition.

        Deductions:
          FOCI/NISS (awards > $5M, not NISS eligible) : -40
          CMMC Level 2 not certified                   : -30
        """
        # 1. Revenue filter — sweet spot 85–286 employees ($30M–$100M @ $350k RPE)
        est_rev = company_data["headcount"] * self._pv["rpe_midpoint"]
        lo, hi  = self._pv["revenue_sweet_spot"]
        if not (lo <= est_rev <= hi):
            return {
                "status":  "REJECT",
                "reason":  "Revenue Out of Scope",
                "est_rev": est_rev,
                "score":   0,
            }

        score = 100

        # 2. May 2026 FOCI gate — contracts > $5M trigger mandatory NISS eligibility
        awards = company_data.get("total_federal_awards",
                                  company_data.get("total_awards",
                                  company_data.get("annual_award_volume_usd", 0)))
        if awards > self._rg["foci_threshold"]:
            if not company_data.get("niss_eligible", True):
                score -= 40  # Cannot close until NISS review completes (60–180 days)

        # 3. CMMC Level 2 — Nov 1 2026 cutoff for self-affirmations
        if not company_data.get("cmmc_l2_status",
                                 company_data.get("cmmc_level_2", False)):
            score -= 30  # Acquirer must fund remediation ($150k–$500k)

        return {
            "status":  "MATCH",
            "score":   max(0, score),
            "est_rev": est_rev,
            "rating":  _purchasability_label(max(0, score)),
        }

    def screen_batch(self, companies: list[dict]) -> list[dict]:
        results = []
        for c in companies:
            adapted = {
                "headcount":            c.get("employee_count", 0),
                "total_federal_awards": c.get("annual_award_volume_usd", 0),
                "niss_eligible":        c.get("niss_eligible", True),
                "cmmc_l2_status":       c.get("cmmc_level_2", False),
            }
            result = self.assess_target(adapted)
            results.append({**c, "vetting": result})
        return sorted(
            [r for r in results if r["vetting"]["status"] == "MATCH"],
            key=lambda x: x["vetting"]["score"],
            reverse=True,
        )


# ══════════════════════════════════════════════════════════════════════════════
# BluestreakEngine — full engine with risk weights + acquisition briefs
# ══════════════════════════════════════════════════════════════════════════════

class BluestreakEngine:
    """
    Full purchasability engine with risk weights, acquisition briefs, batch ranking.
    Penalties aligned with BluestreakVetter: FOCI -40, CMMC flat -30.
    Additional risk weights: foreign board -90, no CMMC pathway -70, prime conc -50.
    """

    def __init__(self, config: dict = None):
        self.cfg  = _normalise(config or DEFAULT_CONFIG)
        self._pv  = self.cfg["platform_vitals"]
        self._rg  = self.cfg["regulatory_gates"]
        self._rw  = self.cfg.get("risk_weights", DEFAULT_CONFIG["risk_weights"])
        self._deadline = datetime.datetime.strptime(
            self._rg["cmmc_deadline"], "%Y-%m-%d"
        )
        self._days_to_deadline = (self._deadline - datetime.datetime.now()).days

    # convenience shim so old callers still work
    @property
    def _vs(self) -> dict:
        return {
            "revenue_sweet_spot": self._pv["revenue_sweet_spot"],
            "foci_threshold_usd": self._rg["foci_threshold"],
            "cmmc_deadline":      self._rg["cmmc_deadline"],
            "rpe_midpoint":       self._pv["rpe_midpoint"],
        }

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

        # ── Gate 2: FOCI / NISS (May 2026 Rule) ────────────────────────────────
        total_awards = company.get("total_awards",
                       company.get("total_federal_awards",
                       company.get("annual_award_volume_usd", 0)))
        foci_thresh  = self._rg["foci_threshold"]
        if total_awards > foci_thresh:
            if not company.get("niss_eligible", True):
                score -= 40  # Cannot close until NISS review (60–180 days)
                deductions.append({
                    "item":   "FOCI/NISS — not eligible",
                    "points": -40,
                    "detail": (
                        f"Awards ${total_awards/1e6:.1f}M exceed "
                        f"${foci_thresh/1e6:.1f}M FOCI threshold. "
                        "New SF-328 filing required under May 2026 NISS rule. "
                        "DSS review — adds 60–180 days to close timeline."
                    ),
                })
                flags.append("FOCI_NISS_RISK")

        # ── Gate 3: CMMC Level 2 (Nov 1 2026 cutoff) ───────────────────────────
        cmmc_certified = company.get("cmmc_level_2",
                         company.get("cmmc_l2_status", False))
        if not cmmc_certified:
            score -= 30  # Flat penalty — acquirer funds remediation ($150k–$500k)
            deductions.append({
                "item":   "CMMC Level 2 — not certified",
                "points": -30,
                "detail": (
                    f"{self._days_to_deadline} days to deadline "
                    f"({self._rg['cmmc_deadline']}). "
                    "Uncertified at close = contract eligibility risk. "
                    "Remediation est. $150k–$500k + 12–18 months."
                ),
            })
            flags.append("CMMC_GAP")

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
            "rating":               _purchasability_label(final),
            "risk_multiplier":      round(score / 100, 2),
        }

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

        mask = self.cfg.get("opsec_mask",
               self.cfg.get("opsec", {}).get("mask", "US Industrial Base Resilience Study"))
        lines = [
            f"{'═'*65}",
            f"  ACQUISITION BRIEF — {company.get('company_name', 'UNKNOWN').upper()}",
            f"  {mask} // Confidential",
            f"{'═'*65}",
            "",
            f"  Strategic Score   : {company.get('total_score', '—')} / 110",
            f"  Purchasability    : {v['purchasability_score']} / 100  —  {v['rating']}",
            f"  Est. Revenue      : ${v['est_revenue']/1e6:.1f}M",
            f"  CMMC Days Left    : {v['days_to_cmmc']} days to {self._rg['cmmc_deadline']}",
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

        cmmc_alert = f"  ⚠ CMMC DEADLINE {self._days_to_deadline} DAYS AWAY ({self._rg['cmmc_deadline']}) — uncertified companies: -30 pts"

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
            f"*CMMC Deadline: {self._rg['cmmc_deadline']} — **{self._days_to_deadline} days remaining***",
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
    print(f"  CMMC deadline : {engine._rg['cmmc_deadline']} ({engine._days_to_deadline} days)")
    print(f"  CMMC penalty  : -30 pts (flat) | FOCI penalty: -40 pts")
    print(f"  OPSEC mask    : {engine.cfg.get('opsec_mask', 'US Industrial Base Resilience Study')}")

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
            print(f"\n  CMMC Level 2 Deadline : {engine._rg['cmmc_deadline']}")
            print(f"  Days remaining        : {d}")
            print(f"  Penalty (uncertified) : -30 pts (flat, both engines)")
            print(f"  FOCI penalty          : -40 pts (awards > $5M, NISS ineligible)")

        elif choice == "0":
            break
        else:
            print("\n  Invalid selection.")


if __name__ == "__main__":
    main()
