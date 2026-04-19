\# Retail Trade Outlook — Australian Retail Market Analysis

&#x20; 

> \*\*An end-to-end data analytics project\*\* analysing Australian retail trade turnover

> across 8 states, 15 industry categories, and 15+ years of ABS data — delivering

> actionable market intelligence through PostgreSQL, Microsoft Excel, and Power BI.

&#x20;

\---

&#x20;

\## Table of Contents

&#x20;

\- \[Project Overview](#project-overview)

\- \[Tools and Technologies](#tools-and-technologies)

\- \[Project Structure](#project-structure)

\- \[Data Source](#data-source)

\- \[Methodology](#methodology)

\- \[SQL Pipeline](#sql-pipeline)

\- \[Excel Analysis](#excel-analysis)

\- \[Power BI Dashboard](#power-bi-dashboard)

\- \[Key Findings](#key-findings)

\- \[Methodological Notes](#methodological-notes)

\- \[Author](#author)

\---

&#x20;

\## Project Overview

&#x20;

This project delivers a comprehensive analysis of Australian retail trade turnover

using publicly available data from the \*\*Australian Bureau of Statistics (ABS)\*\*,

covering the period \*\*January 2010 to June 2025\*\*. The analysis spans the full

analytics pipeline — from raw data ingestion and relational database construction

through exploratory Excel analysis to an interactive two-page Power BI dashboard.

&#x20;

The project was designed to demonstrate practical, employer-ready data analytics

competency relevant to the Australian market, with deliberate emphasis on data

quality, methodological rigour, and business-level insight communication.

&#x20;

\*\*Business questions answered:\*\*

\- How has Australian national retail turnover trended over 6 years (2019–2025)?

\- Which states and industries are the dominant contributors to national turnover?

\- What was the measurable impact of COVID-19 on Australian retail, and how quickly

&#x20; did the market recover?

\- Which industries drive the majority of retail economic activity (Pareto analysis)?

\- What is the current growth trajectory heading into 2025?

\---

&#x20;

\## Tools and Technologies

&#x20;

| Tool | Version | Purpose |

|------|---------|---------|

| PostgreSQL | 18 | Data ingestion, staging, cleaning, transformation, and analytical queries |

| Microsoft Excel | 365 | Exploratory analysis, pivot tables, KPI dashboard, dynamic formulas, sparklines |

| Power BI Desktop | 2025 | Two-page interactive dashboard with DAX measures, map visual, Pareto analysis |

| GitHub | — | Version control and portfolio documentation |

&#x20;

\---

&#x20;

\## Project Structure

&#x20;

```

retail-trade-outlook/

│

├── data/

│   ├── abs\_retail\_trade.csv       # Cleaned source data (Excel Power Query output)

│   ├── state\_summary.csv          # State-level turnover aggregates (SQL export)

│   ├── industry\_rank.csv          # Industry ranking by total turnover (SQL export)

│   ├── yoy\_growth.csv             # Monthly YoY growth per state \& industry (SQL export)

│   └── monthly\_trend.csv          # National monthly trend aggregates (SQL export)

│

├── sql/

│   └── retail\_outlook\_analysis.sql    # Fully annotated end-to-end SQL pipeline

│

├── excel/

│   └── retail\_outlook\_analysis.xlsx   # Excel workbook with pivot tables and KPI dashboard

│

├── powerbi/

│   ├── retail\_outlook\_dashboard.pbix  # Power BI Desktop source file

│   └── retail\_outlook\_dashboard.pdf   # Exported two-page dashboard (PDF)

│

├── images/

│   ├── excel\_dashboard\_preview.png    # Excel KPI dashboard screenshot

│   ├── powerbi\_dashboard\_pg1.png      # National Retail Trade Outlook page

│   └── powerbi\_dashboard\_pg2.png      # Industry-level Insights page

│

└── README.md

```

&#x20;

\---

&#x20;

\## Data Source

&#x20;

\*\*Australian Bureau of Statistics (ABS)\*\*

Retail Trade, Catalogue 8501.0

Table 11

Monthly retail turnover by state and industry (seasonally adjusted)

Period: January 2010 – June 2025

&#x20;

> Source data is freely available at:

> https://www.abs.gov.au/statistics/industry/retail-and-wholesale-trade/retail-trade-australia/jun-2025

&#x20;

The ABS Retail Trade dataset is the primary reference for Australian retail

economic performance, used by the Reserve Bank of Australia, Treasury, and

major financial institutions as a leading indicator of consumer spending conditions.

&#x20;

\---

&#x20;

\## Methodology

&#x20;

\### ETL Pipeline

&#x20;

Raw ABS data was downloaded as a wide-format CSV with metadata header rows

and industry categories as columns. The following ETL steps were performed

before SQL ingestion:

&#x20;

1\. \*\*Metadata removal\*\* — Rows 1–11 (Unit, Series Type, Data Type, Frequency,

&#x20;  Collection Month fields) were deleted, retaining only the data header row.

2\. \*\*Unpivoting\*\* — Microsoft Excel Power Query was used to unpivot all industry

&#x20;  columns into a long-format structure with four fields:

&#x20;  `reporting\_date`, `state`, `industry`, `turnover\_millions`.

3\. \*\*Null exclusion\*\* — Empty cells arising from ABS confidentiality suppression

&#x20;  of low-volume markets were automatically dropped during unpivoting, preventing

&#x20;  zero-inflation of downstream aggregations.

4\. \*\*Date formatting\*\* — The `reporting\_date` column was confirmed in `DD/MM/YYYY`

&#x20;  format consistent with Australian locale settings, handled explicitly in the

&#x20;  PostgreSQL `TO\_DATE()` function.

5\. \*\*CSV export\*\* — The cleaned dataset was exported as UTF-8 CSV for PostgreSQL

&#x20;  ingestion.



\### Hierarchical Double-Counting Correction

&#x20;

The ABS classification structure includes both granular leaf-level industry rows

\*\*and\*\* their parent aggregate category rows within the same dataset. Including

both in SUM aggregations produces inflated totals — a non-obvious data quality

issue requiring domain knowledge of the ABS taxonomy to identify and correct.

&#x20;

The following five parent categories were identified and excluded from all

aggregation queries using a `NOT IN` filter:

&#x20;

| Excluded Parent Category | Sub-categories it contains |

|--------------------------|---------------------------|

| Food retailing | Supermarket and grocery stores, Liquor retailing, Other specialised food retailing |

| Household goods retailing | Furniture/floor coverings, Electrical and electronic goods, Hardware and garden supplies |

| Clothing, footwear and personal accessory retailing | Clothing retailing, Footwear and other personal accessory retailing |

| Other retailing | Newspaper and book, Recreational goods, Pharmaceutical and cosmetic, Other retailing n.e.c., Department stores |

| Cafes, restaurants and takeaway food services | Cafes, restaurants and catering services, Takeaway food services |

&#x20;

This correction reduced the reported 2024 national turnover figure from an

inflated \~$841B to an accurate $428.5B, consistent with independently

published ABS annual totals.

&#x20;

\---

&#x20;

\## SQL Pipeline



\*\*File:\*\* `sql/retail\_outlook\_analysis.sql`



The SQL script executes a six-stage analytical pipeline in PostgreSQL 18,

progressing from raw data ingestion through to four analysis-ready result sets

used by both the Excel workbook and Power BI dashboard.



\### Stage 1 — Staging table

Raw CSV imported into `retail\_raw` with all columns typed as `TEXT` to

prevent type-mismatch errors at import. Numeric casting is deliberately

carried out on Stage 2 to ensure clean, controlled transformation.



```sql

CREATE TABLE retail\_raw (

&#x20;   reporting\_date    TEXT,

&#x20;   state             TEXT,

&#x20;   industry          TEXT,

&#x20;   turnover\_millions NUMERIC

);

```



\### Stage 2 — Data cleaning and production table

`retail\_clean` created with full type casting, date decomposition, and

whitespace normalisation applied in a single `CREATE TABLE AS SELECT` statement:



\- `TO\_DATE()` casting of the reporting date with explicit `DD/MM/YYYY` format

&#x20; consistent with Australian locale

\- `EXTRACT()` for separate integer `year` and `month\_no` columns — enabling

&#x20; direct use as slicer fields in Power BI without additional DAX transformation

\- `TO\_CHAR()` for a text `month` column (January, February...) for readable

&#x20; axis labelling in charts

\- `TRIM()` applied to `state` and `industry` to remove leading/trailing

&#x20; whitespace that would cause silent GROUP BY mismatches

\- NULL exclusion enforced across all four columns



\### Stage 3 — Performance indexing

Four indexes created on `reporting\_date`, `state`, `industry`, and `year`

to accelerate operations like `GROUP BY`, `WHERE`, and `PARTITION BY`

across the analytical queries.



\### Stage 4 — Data profiling

Row counts, distinct value counts per state and industry, and date range

validation are run to confirm complete and correct ingestion before any

analysis is performed. Uneven row counts by state are expected and documented;

they reflect ABS confidentiality suppression of low-volume markets rather than

a pipeline error.



\### Stage 5 — Analytical queries



Four queries produce the result sets, laying the foundation for all analysis.



\*\*State-level summary — 5-year rolling window:\*\*

```sql

SELECT state,

&#x20;      ROUND(SUM(turnover\_millions)::NUMERIC, 1) AS total\_turnover\_m,

&#x20;      ROUND(AVG(turnover\_millions)::NUMERIC, 1) AS avg\_monthly\_turnover\_m

FROM retail\_clean

WHERE reporting\_date >= DATE\_TRUNC('year', CURRENT\_DATE) - INTERVAL '5 years'

&#x20; AND industry NOT IN (/\* five parent aggregate exclusions \*/)

GROUP BY state

ORDER BY total\_turnover\_m DESC;

```



\*\*Industry ranking — full dataset, window function:\*\*

```sql

SELECT industry,

&#x20;      ROUND(SUM(turnover\_millions)::NUMERIC, 1) AS total\_turnover\_m,

&#x20;      RANK() OVER (ORDER BY SUM(turnover\_millions) DESC) AS industry\_rank

FROM retail\_clean

WHERE industry NOT IN (/\* five parent aggregate exclusions \*/)

GROUP BY industry

ORDER BY industry\_rank;

```



\*\*Year-on-year growth — LAG window function, 2019–2025:\*\*

```sql

\-- Growth % = \[(This Year - Last Year) / Last Year] \* 100

\-- LAG offset of 12 months partitioned by state and industry

\-- captures true same-period comparison across every category

LAG(turnover\_millions, 12) OVER (

&#x20;   PARTITION BY state, industry

&#x20;   ORDER BY reporting\_date

)

```



\*\*National monthly trend — aggregated turnover, 2019–2025:\*\*

```sql

SELECT reporting\_date, year, month, month\_no,

&#x20;      ROUND(SUM(turnover\_millions)::NUMERIC, 1) AS national\_turnover\_m

FROM retail\_clean

WHERE reporting\_date BETWEEN '2019-01-01' AND '2025-06-01'

&#x20; AND industry NOT IN (/\* five parent aggregate exclusions \*/)

GROUP BY reporting\_date, year, month, month\_no

ORDER BY reporting\_date;

```



The hero line chart on Power BI dashboard and the

national turnover KPI card are based on this query, providing the month-by-month aggregate used to

calculate both total annual turnover and year-on-year growth via DAX measures.



\*\*Key SQL techniques demonstrated:\*\*

`RANK() OVER`, `LAG() OVER`, `PARTITION BY`, `TO\_DATE()`, `EXTRACT()`,

`TO\_CHAR()`, `DATE\_TRUNC()`, `NULLIF()`, `ROUND()`, `TRIM()`,

multi-column indexing, staging table intake pattern.



\### Stage 6 — Result export

All four query result sets were exported to CSV using pgAdmin's built-in

table data export function and saved to `data (clean)/` for use in

Excel (via Power Query) and Power BI (via Get Data → Text/CSV). 



\---

&#x20;

\## Excel Analysis



\*\*File:\*\* `excel/retail\_outlook\_analysis.xlsx`



!\[Excel Dashboard](images/excel\_dashboard\_preview.png)

&#x20;

| Sheet | Contents |

|-------|---------|

| Dashboard | Executive KPI summary — 4 headline metrics, national trend chart, state contribution chart, source citation |

| state\_summary | Imported state-level aggregates from PostgreSQL |

| industry\_rank | Imported industry ranking from PostgreSQL |

| yoy\_growth | Imported year-on-year growth data from PostgreSQL |

| monthly\_trend | Imported national monthly trend from PostgreSQL |

| Pivot State | State × Year turnover matrix with green-red conditional formatting colour scale |

| Pivot Industry | Industry share breakdown with donut chart |

| SparklineData | Helper table powering per-state 5-year sparklines |

&#x20;

\*\*Key Excel techniques demonstrated:\*\*

\- Power Query data import and schema transformation

\- Dynamic formulas: `SUMIF`, `AVERAGEIFS`, `INDEX/MATCH`, `MAXIFS`

\- PivotTables with conditional formatting colour scales

\- Sparklines with high/low point markers

\- KPI dashboard design with gridlines removed and formula-driven values

\*\*Dashboard KPI formulas:\*\*

```excel

\-- National Turnover 2024 ($B)

=ROUND(SUMIF(monthly\_trend\[year],2024,monthly\_trend\[national\_turnover\_m])/1000,1)\&" B"

&#x20;

\-- Average YoY Growth 2024

=IFERROR(ROUND(AVERAGEIFS(yoy\_growth\[yoy\_growth\_pct],yoy\_growth\[year],2024,

&#x20;        yoy\_growth\[yoy\_growth\_pct],"<>"\&""),1)\&"%","N/A")

&#x20;

\-- Top State

=INDEX(state\_summary\[State],MATCH(MAX(state\_summary\[total\_turnover\_m]),

&#x20;      state\_summary\[total\_turnover\_m],0))

&#x20;

\-- Top Industry

=INDEX(IndustryData\[industry],MATCH(1,IndustryData\[industry\_rank],0))

```

&#x20;

\---

&#x20;

\## Power BI Dashboard

&#x20;

\*\*File:\*\* `powerbi/retail\_outlook\_dashboard.pdf`

&#x20;

The dashboard comprises two pages with a consistent dark-header KPI strip

design and white-card visual layout on a warm grey canvas.

&#x20;

\### Page 1 — National Retail Trade Outlook

&#x20;

!\[Page 1](images/powerbi\_dashboard\_pg1.png)

&#x20;

\*\*KPI strip (5 cards):\*\*

\- Total Retail Turnover 2024: \*\*$428.5B\*\* (interactive with year slicer)

\- YoY Growth %: \*\*3.0%\*\* (defaults to 2024, updates with year filter)

\- Growth 2019–2024: \*\*33.1%\*\* (fixed 5-year benchmark)

\- Most Contributing State: \*\*New South Wales\*\*

\- Most Contributing Industry: \*\*Supermarket and grocery stores\*\*

\*\*Visuals:\*\*

\- Filled map of Australia — state turnover shown via colour intensity

&#x20; (light to dark teal scale), 5-year total

\- National monthly trend line chart 2019–2025 with COVID-19 impact annotation

\- Year-on-year growth column chart 2020–2024 with explanatory footnote

\*\*DAX measures:\*\*

```dax

\-- Dynamic turnover with year slicer support

National Turnover =

VAR SelectedYear = IF(ISFILTERED(monthly\_trend\[year]),

&#x20;                     SELECTEDVALUE(monthly\_trend\[year]), BLANK())

VAR DefaultValue = CALCULATE(SUM(monthly\_trend\[national\_turnover\_m]),

&#x20;                            monthly\_trend\[year] = 2024)

VAR SelectedValue = CALCULATE(SUM(monthly\_trend\[national\_turnover\_m]),

&#x20;                            monthly\_trend\[year] = SelectedYear)

VAR RawResult = IF(ISBLANK(SelectedYear), DefaultValue, SelectedValue)

RETURN DIVIDE(RawResult, 1000)



\-- YoY Growth with prior year comparison

YoY Growth (%) =

VAR SelectedYear = IF(ISFILTERED(monthly\_trend\[year]),

&#x20;                    SELECTEDVALUE(monthly\_trend\[year]), 2024)

VAR CurrentTurnover = CALCULATE(SUM(monthly\_trend\[national\_turnover\_m]),

&#x20;                              monthly\_trend\[year] = SelectedYear)

VAR PriorTurnover = CALCULATE(SUM(monthly\_trend\[national\_turnover\_m]),

&#x20;                            monthly\_trend\[year] = SelectedYear - 1)

RETURN DIVIDE(CurrentTurnover - PriorTurnover, PriorTurnover) \* 100

```

&#x20;

\### Page 2 — Industry-level Insights

&#x20;

!\[Page 2](images/powerbi\_dashboard\_pg2.png)

&#x20;

\*\*KPI strip (2 cards):\*\*

\- Industries Analysed: \*\*15\*\* (with double-counting exclusion note)

\- Total Industry Turnover: \*\*$4.96T\*\* (cumulative 2010–mid 2025)

\*\*Visuals:\*\*

\- Treemap — market composition by cumulative turnover, purple gradient scale

\- Industry share horizontal bar chart — colour saturation gradient

&#x20; communicating the dominance gap between rank 1 and the rest

\- Pareto analysis combo chart — column turnover values with cumulative

&#x20; percentage line showing the 80/20 concentration pattern

\---

&#x20;

\## Key Findings

&#x20;

\### National Market Performance

&#x20;

\*\*1. Australian retail turnover reached $428.5B in 2024 — up 33.1% from 2019.\*\*

National retail turnover grew from approximately $322B in 2019 to $428.5B in

2024, representing a compound annual growth rate of approximately 5.9%. This

sustained nominal expansion reflects post-pandemic demand recovery.

&#x20;

\*\*2. COVID-19 produced a sharp but brief disruption — full-year 2020 growth

remained positive at 6.4%.\*\*

Despite the severity of pandemic-era restrictions, Australia's full-year 2020

retail turnover recorded net positive year-on-year growth. This counterintuitive

outcome reflects a structural demand shift. The collapse in hospitality and

discretionary spending was offset by a significant surge in supermarket, hardware,

and home goods purchasing as consumers redirected spending during lockdown periods.

The monthly trend chart shows a sharp dip in April 2020, followed by a full recovery

in July 2020, a V-shaped pattern unique to the Australian retail context given

relatively compressed lockdown durations versus peer economies.

&#x20;

\*\*3. 2022 recorded peak post-COVID growth at 11.6% — the strongest annual

expansion in the dataset.\*\*

YoY growth peaked at 11.6% in 2022, driven by the full reopening of the Australian

economy, release of pandemic-era household savings, and elevated consumer price

levels contributing to nominal turnover inflation. This figure represents the

high-water mark of Australia's retail recovery and has since moderated significantly.

&#x20;

\*\*4. Growth is decelerating toward structural baseline — 2023 (3.2%) and 2024

(3.0%) signal normalisation.\*\*

The stepdown from 11.6% in 2022 to 3.2% and 3.0% in subsequent years indicates

the post-pandemic demand surge has fully unwound. Current growth rates are

consistent with pre-COVID structural trends driven by population growth and modest

price inflation rather than cyclical demand uplift. This moderation has implications

for retail sector capital allocation and workforce planning heading into 2025–2026.

&#x20;

\*\*5. New South Wales dominates national retail — eastern seaboard concentration

is structurally stable.\*\*

NSW consistently records the highest state-level retail turnover across the full

analytical window. Victoria ranks second, with Queensland third. The three eastern

seaboard states collectively account for the large majority of national turnover,

a pattern that has remained structurally stable across the full 2010–2025 period.

&#x20;

\### Industry-level Analysis

&#x20;

\*\*6. Australian non-aggregate retail generated $4.96 trillion in cumulative

turnover from 2010 to mid-2025.\*\*

Calculated using 15 leaf-level industry categories only, with five ABS parent

aggregate categories excluded to prevent hierarchical double-counting, this

figure represents the true economic footprint of Australia's retail sector across

a 15-year period.

&#x20;

\*\*7. Supermarket and grocery stores account for 34% of all Australian retail

turnover — a structural dominance no other category approaches.\*\*

With approximately $1.70 trillion in cumulative turnover, supermarket and grocery

stores represent more than one-third of total retail activity. The next largest

category, Cafes, restaurants and catering services at $0.41T, represents less

than a quarter of that figure. This concentration reflects both the non-discretionary

nature of food spending and the structural characteristics of the Australian

grocery market.

&#x20;

\*\*8. Pareto analysis confirms approximately 4 industries generate the dominant

share of Australian retail turnover.\*\*

A Pareto decomposition reveals that Supermarket and grocery stores (34.3%),

Cafes, restaurants and catering services (42.6%), Electrical and electronic goods

retailing (49.4%), and Other retailing n.e.c. (55.7%), just four of fifteen

analysed categories, collectively account for more than half of all retail

market activity. This concentration has direct implications for retail property

investment, supply chain prioritisation, and workforce allocation decisions.

&#x20;

\*\*9. The long tail — 11 categories share the remaining \~45% of turnover.\*\*

Outside the top four categories, the remaining eleven industries each individually

represent between 2% and 8% of total turnover. This long-tail structure indicates

meaningful economic activity distributed across hardware, pharmaceutical, clothing,

and specialised food categories, sectors where growth trajectories diverge from

the national aggregate and merit independent monitoring.

&#x20;

\---

&#x20;

\## Methodological Notes

&#x20;

\*\*ABS confidentiality suppression:\*\*

Row counts vary by state due to ABS suppression of turnover data for low-volume

markets, most notably affecting South Australia, Queensland, Tasmania, and the Northern Territory. 

Suppressed values were excluded during ETL rather than imputed with zero, preventing 

zero-inflation of state-level averages in SQL aggregations.

&#x20;

\*\*2025 partial year:\*\*

All 2025 figures represent January to June only and are not directly comparable

to full calendar-year figures for prior periods. The 2025 period is included in

trend visualisations for directional context only. The Power BI KPI card defaults

to full-year 2024 to ensure the headline figure is always a complete annual total.

&#x20;

\*\*Units:\*\*

All source values are in Australian dollars, millions ($M). Conversions to

billions ($B) and trillions ($T) are performed in DAX and Excel formulas at the

presentation layer; the underlying data remains unchanged in millions throughout

the SQL and CSV pipeline.

&#x20;

\---

&#x20;

\## Author

&#x20;

\*\*Ayman Zahid\*\*

Data Analyst | Townsville, Queensland, Australia

&#x20;

\[!\[LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue)](https://www.linkedin.com/in/ayman-zahid)

\[!\[GitHub](https://img.shields.io/badge/GitHub-Portfolio-black)](https://github.com/ayman-zahid)

&#x20;

\---

&#x20;

\*Data sourced from the Australian Bureau of Statistics under Creative Commons

Attribution 4.0 International licence (CC BY 4.0).\*

&#x20;

\*This project was completed independently as a portfolio demonstration.

All analytical conclusions are the author's own interpretation of publicly

available data.\*

