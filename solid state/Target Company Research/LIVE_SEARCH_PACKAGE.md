# Project Bluestreak — Live Search Package
**US Industrial Base Resilience Study // Confidential**
*Execute these queries to replace seed profiles with verified live data.*
*All queries anonymized — no deal language embedded.*

---

## HOW TO USE THIS PACKAGE

1. Run each query below in your browser or paste the API body into Postman/curl
2. For each company surfaced, run `python3 profiler.py` → Option 1 to create a verified profile
3. Run `python3 vetting_engine.py` → Option 1 to rescore the ranked table
4. Run `python3 "Market & Supply Chain Mapping/srm_stack_mapper.py"` → Option 1 to refresh leads.md

---

## PRIORITY 1 — Arkansas (CRITICAL)
*Camden corridor: propellant mix/cast, nozzle throat, energetic material processors*

### USASpending.gov — Direct Awards (POST request)
**URL:** `https://api.usaspending.gov/api/v2/search/spending_by_award/`
**Method:** POST / Content-Type: application/json

```json
{
  "filters": {
    "naics_codes": ["336415","325920","332710","325211","332993","325180"],
    "award_type_codes": ["A","B","C","D"],
    "award_amounts": [{"lower_bound": 300000, "upper_bound": 50000000}],
    "place_of_performance_locations": [{"country": "USA", "state": "AR"}],
    "time_period": [{"start_date": "2020-01-01", "end_date": "2026-12-31"}]
  },
  "fields": ["Award ID","Recipient Name","Recipient DUNS","Award Amount",
             "NAICS Code","NAICS Description","Place of Performance City Name",
             "Period of Performance Current End Date","Awarding Agency Name"],
  "sort": "Award Amount",
  "order": "desc",
  "limit": 100
}
```

### USASpending.gov — Sub-Awards under Northrop Grumman (AR)
```json
{
  "filters": {
    "award_type_codes": ["A","B","C","D"],
    "naics_codes": ["336415","325920","332710","325211","332993","325180"],
    "recipient_search_text": ["Northrop Grumman"],
    "place_of_performance_locations": [{"country": "USA", "state": "AR"}],
    "time_period": [{"start_date": "2020-01-01", "end_date": "2026-12-31"}]
  },
  "fields": ["Award ID","Recipient Name","Award Amount","NAICS Code"],
  "sort": "Award Amount", "order": "desc", "limit": 20
}
```
*Then for each Award ID: GET `https://api.usaspending.gov/api/v2/subawards/?award_id=<ID>&limit=50`*

### USASpending.gov — Sub-Awards under L3Harris/Aerojet (AR)
*Same as above, replace `"Northrop Grumman"` with `"L3Harris"` and `"Aerojet"`*

### SAM.gov — Entity Registry (open in browser)
- NAICS 325920 + AR: `https://sam.gov/search?index=ei&naicsCode=325920&q=&stateOfIncorporation=AR`
- NAICS 332710 + AR: `https://sam.gov/search?index=ei&naicsCode=332710&q=&stateOfIncorporation=AR`
- NAICS 332993 + AR: `https://sam.gov/search?index=ei&naicsCode=332993&q=&stateOfIncorporation=AR`

### SBIR.gov — Phase II Passes (open in browser)
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:AR&f[3]=agency:DOD&keyword=solid+propellant+rocket+motor`
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:AR&f[3]=agency:DOD&keyword=energetic+material+synthesis`
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:AR&f[3]=agency:DOD&keyword=ammonium+perchlorate`

### LinkedIn Headcount Filter
- **Search term:** `"energetic materials" OR "propellant" OR "solid rocket"` + Defense & Space
- **Location:** Arkansas, United States
- **Headcount:** 85–285 employees
- **Cross-reference:** every hit → verify CAGE code on SAM.gov

---

## PRIORITY 2 — Utah (HIGH)
*Brigham City / Promontory: composite motor cases, HTPB binders, ballistic test*

### USASpending.gov — Direct Awards (POST)
```json
{
  "filters": {
    "naics_codes": ["336415","325920","332710","325211","332993","325180"],
    "award_type_codes": ["A","B","C","D"],
    "award_amounts": [{"lower_bound": 300000, "upper_bound": 50000000}],
    "place_of_performance_locations": [{"country": "USA", "state": "UT"}],
    "time_period": [{"start_date": "2020-01-01", "end_date": "2026-12-31"}]
  },
  "fields": ["Award ID","Recipient Name","Recipient DUNS","Award Amount",
             "NAICS Code","NAICS Description","Place of Performance City Name",
             "Awarding Agency Name"],
  "sort": "Award Amount", "order": "desc", "limit": 100
}
```

### SAM.gov — Entity Registry (UT)
- NAICS 336415 + UT: `https://sam.gov/search?index=ei&naicsCode=336415&q=&stateOfIncorporation=UT`
- NAICS 325211 + UT: `https://sam.gov/search?index=ei&naicsCode=325211&q=&stateOfIncorporation=UT`
- NAICS 332999 + UT: `https://sam.gov/search?index=ei&naicsCode=332999&q=&stateOfIncorporation=UT`

### SBIR.gov — Phase II Passes (UT)
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:UT&f[3]=agency:DOD&keyword=solid+propellant`
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:UT&f[3]=agency:DOD&keyword=filament+winding+composite+motor`
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:UT&f[3]=agency:DOD&keyword=HTPB+binder`

---

## PRIORITY 3 — Alabama (HIGH)
*Huntsville / Redstone: igniters, nozzle components, propulsion engineering*

### USASpending.gov — Direct Awards (POST)
```json
{
  "filters": {
    "naics_codes": ["336415","332710","332993","541330","336419"],
    "award_type_codes": ["A","B","C","D"],
    "award_amounts": [{"lower_bound": 300000, "upper_bound": 50000000}],
    "place_of_performance_locations": [{"country": "USA", "state": "AL"}],
    "time_period": [{"start_date": "2020-01-01", "end_date": "2026-12-31"}]
  },
  "fields": ["Award ID","Recipient Name","Recipient DUNS","Award Amount",
             "NAICS Code","NAICS Description","Place of Performance City Name",
             "Awarding Agency Name"],
  "sort": "Award Amount", "order": "desc", "limit": 100
}
```

### SAM.gov — Entity Registry (AL)
- NAICS 332993 + AL: `https://sam.gov/search?index=ei&naicsCode=332993&q=&stateOfIncorporation=AL`
- NAICS 332710 + AL: `https://sam.gov/search?index=ei&naicsCode=332710&q=&stateOfIncorporation=AL`
- NAICS 336415 + AL: `https://sam.gov/search?index=ei&naicsCode=336415&q=&stateOfIncorporation=AL`

### SBIR.gov — Phase II Passes (AL)
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:AL&f[3]=agency:DOD&keyword=tactical+missile+propulsion`
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:AL&f[3]=agency:DOD&keyword=pyrotechnic+igniter+initiator`
- `https://www.sbir.gov/sbirsearch/award/all?f[0]=program:SBIR&f[1]=phase:Phase+II&f[2]=state:AL&f[3]=agency:DOD&keyword=solid+rocket+motor+nozzle`

---

## SEC EDGAR — Divestiture Watch (open in browser)
*Flag Tier 1 primes divesting propulsion/energetics units — highest-confidence signal*

| Priority | Query | URL |
|---|---|---|
| CRITICAL | NG 8-K "divestiture"+"propulsion" | `https://efts.sec.gov/LATEST/search-index?q=%22divestiture%22+%22propulsion%22&forms=8-K&dateRange=custom&startdt=2024-01-01` |
| CRITICAL | NG 8-K "discontinued operations"+"rocket motor" | `https://efts.sec.gov/LATEST/search-index?q=%22discontinued+operations%22+%22rocket+motor%22&forms=8-K&dateRange=custom&startdt=2024-01-01` |
| CRITICAL | LM 8-K "strategic sale"+"propellant" | `https://efts.sec.gov/LATEST/search-index?q=%22strategic+sale%22+%22propellant%22&forms=8-K&dateRange=custom&startdt=2024-01-01` |
| HIGH | All primes 10-K "divestiture"+"energetics" | `https://efts.sec.gov/LATEST/search-index?q=%22divestiture%22+%22energetics%22&forms=10-K&dateRange=custom&startdt=2024-01-01` |
| HIGH | All primes 10-K "divest"+"solid rocket" | `https://efts.sec.gov/LATEST/search-index?q=%22divest%22+%22solid+rocket%22&forms=10-K&dateRange=custom&startdt=2024-01-01` |

---

## WORKFLOW AFTER RUNNING QUERIES

```
For each company surfaced from the above:

1. Verify CAGE code on SAM.gov
2. Check headcount via LinkedIn (confirm 85–285 FTE band)
3. Run: python3 profiler.py  → Add new company profile
4. After all entries added:
   python3 vetting_engine.py  → Option 2 (compliance report)
   python3 "../Market & Supply Chain Mapping/srm_stack_mapper.py"  → refresh leads.md
```

---
*US Industrial Base Resilience Study // Project Bluestreak // Confidential*
