-- ------------------------------------
--  RETAIL OUTLOOK — Australian Retail Trade Analysis
--  Data Source : Australian Bureau of Statistics (ABS), Retail Trade.
--  Author      : Ayman Zahid
--  Description : End-to-end SQL pipeline covering data ingestion,
--                cleaning, and analytical queries to support an
--                interactive Power BI dashboard on Australian
--                retail market performance (2010–2025).
-- ------------------------------------

-- Create staging table
CREATE TABLE retail_raw (
    reporting_date    TEXT,
    state             TEXT,
    industry          TEXT,
    turnover_millions NUMERIC
);

-- Verify imported data
SELECT COUNT(*) FROM retail_raw;
SELECT * FROM retail_raw LIMIT 10;

-- ------------------------------------

-- << Data Cleaning >>
CREATE TABLE retail_clean AS
SELECT
    TO_DATE(reporting_date, 'DD/MM/YYYY') AS reporting_date,
    EXTRACT(YEAR FROM TO_DATE(reporting_date, 'DD/MM/YYYY'))::INTEGER AS year,
    EXTRACT(MONTH FROM TO_DATE(reporting_date, 'DD/MM/YYYY'))::INTEGER AS month_no,
    TO_CHAR(TO_DATE(reporting_date, 'DD/MM/YYYY'), 'Month') AS month,
    TRIM(state) AS state,
    TRIM(industry) AS industry,
    turnover_millions
FROM retail_raw
WHERE turnover_millions IS NOT NULL
  AND reporting_date IS NOT NULL
  AND state IS NOT NULL
  AND industry IS NOT NULL;

ALTER TABLE retail_clean ADD COLUMN id SERIAL PRIMARY KEY;

SELECT * FROM retail_clean;
SELECT MIN(reporting_date), MAX(reporting_date) FROM retail_clean;

CREATE INDEX idx_date ON retail_clean (reporting_date);
CREATE INDEX idx_state ON retail_clean (state);
CREATE INDEX idx_industry ON retail_clean (industry);
CREATE INDEX idx_year ON retail_clean (year);

-- ------------------------------------

-- << Data Profiling >>
-- High-level dataset summary: date range, coverage, and volume.
SELECT
    MIN(reporting_date) AS earliest_period,
    MAX(reporting_date) AS latest_period,
    COUNT(DISTINCT state) AS num_states,
    COUNT(DISTINCT industry) AS num_industries,
    COUNT(*) AS total_rows
FROM retail_clean;
-- Distinct states present in the dataset.
SELECT DISTINCT state
FROM retail_clean
ORDER BY state;
-- Distinct retail industry categories present in the dataset.
SELECT DISTINCT industry
FROM retail_clean
ORDER BY industry;
-- Row count per state [confirms even coverage across geographies].
SELECT
    state,
    COUNT(*) AS row_count
FROM retail_clean
GROUP BY state
ORDER BY row_count DESC;

-- ------------------------------------

/* ABS data includes both granular industry rows and
   their parent aggregate categories simultaneously. Excluding 
   the five parent categories below prevents hierarchical 
   double-counting in all SUM aggregations */

-- State-level summary [last 5 years]
SELECT
	state,
	ROUND(SUM(turnover_millions)::NUMERIC, 1) AS total_turnover_m,
	ROUND(AVG(turnover_millions)::NUMERIC, 1) AS avg_monthly_turnover_m
FROM retail_clean
WHERE reporting_date >= DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '5 years'
      AND industry NOT IN (
          'Food retailing',
          'Household goods retailing',
          'Clothing, footwear and personal accessory retailing',
          'Other retailing',
          'Cafes, restaurants and takeaway food services'
      )
GROUP BY state
ORDER BY total_turnover_m DESC;

-- ------------------------------------

-- Industrial Ranking [retail industry categories ranked by total turnover]
SELECT
	industry,
	ROUND(SUM(turnover_millions)::NUMERIC, 1) AS total_turnover_m,
	RANK() OVER (ORDER BY SUM(turnover_millions) DESC) AS industry_rank
FROM retail_clean
WHERE industry NOT IN (
          'Food retailing',
          'Household goods retailing',
          'Clothing, footwear and personal accessory retailing',
          'Other retailing',
          'Cafes, restaurants and takeaway food services'
      )
GROUP BY industry
ORDER BY industry_rank;

-- ------------------------------------

/* Covers 2019–2025 to capture pre-COVID baseline, 
   COVID-impact, post-COVID recovery, and the most 
   recent period up to June 2025 */
   
-- Year-on-year growth [Calculates monthly YoY growth (%) per state and industry offset by 12 months]
SELECT
	state, industry, reporting_date, year, month, month_no,
	turnover_millions,
	-- Growth % = [(This Year - Last Year) / Last Year] * 100
	ROUND(
            (
                (turnover_millions - LAG(turnover_millions, 12) OVER (
                    PARTITION BY state, industry ORDER BY reporting_date
                ))
                / NULLIF(LAG(turnover_millions, 12) OVER (
                    PARTITION BY state, industry ORDER BY reporting_date
                ), 0)
            ) * 100
        , 2) AS yoy_growth_pct
FROM retail_clean
WHERE reporting_date BETWEEN '2019-01-01' AND '2025-06-01'
      AND industry NOT IN (
          'Food retailing',
          'Household goods retailing',
          'Clothing, footwear and personal accessory retailing',
          'Other retailing',
          'Cafes, restaurants and takeaway food services'
      )
ORDER BY state, industry, reporting_date;

-- ------------------------------------

-- National Monthly Trend [Aggregates total national retail turnover month by month from 2019-25]
SELECT
	reporting_date, year, month, month_no,
    ROUND(SUM(turnover_millions)::NUMERIC, 1) AS national_turnover_m
FROM retail_clean
WHERE reporting_date BETWEEN '2019-01-01' AND '2025-06-01'
      AND industry NOT IN (
          'Food retailing',
          'Household goods retailing',
          'Clothing, footwear and personal accessory retailing',
          'Other retailing',
          'Cafes, restaurants and takeaway food services'
      )
GROUP BY reporting_date, year, month, month_no
ORDER BY reporting_date;

-- ------------------------------------