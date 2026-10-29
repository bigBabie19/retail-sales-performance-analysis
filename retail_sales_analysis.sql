/*
Retail Sales Performance Analysis
PostgreSQL query collection

Tables:
- online_retail_staging: imported raw data, values stored as TEXT
- online_retail_clean: converted types; retains unusual transactions
- retail_sales_analysis_v2: filtered sales analysis subset

Important:
- Revenue = quantity * unit_price, not profit.
- The 80,995-unit PAPER CRAFT transaction (invoice 581483, stock_code 23843)
  is excluded from retail_sales_analysis_v2 after investigation, but remains
  in online_retail_clean.
- The 74,215-unit invoice for stock_code 23166 is retained. An unusual value
  is not automatically an error.
*/


/* =========================================================
   01. DATA QUALITY CHECKS
   ========================================================= */

-- 1.1 Basic quality overview
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS missing_customer_id,
    COUNT(*) FILTER (
        WHERE description IS NULL OR BTRIM(description) = ''
    ) AS missing_description,
    COUNT(*) FILTER (WHERE quantity <= 0) AS non_positive_quantity,
    COUNT(*) FILTER (WHERE unit_price <= 0) AS non_positive_unit_price,
    COUNT(*) FILTER (WHERE invoice_no LIKE 'C%') AS cancellation_invoice_rows
FROM public.online_retail_clean;

-- 1.2 Dataset date range
SELECT
    MIN(invoice_date) AS first_invoice_date,
    MAX(invoice_date) AS last_invoice_date
FROM public.online_retail_clean;

-- 1.3 Inspect non-positive quantity or price rows
-- These remain in the cleaned table for possible returns/cancellation analysis.
SELECT
    invoice_no, stock_code, description, quantity, invoice_date,
    unit_price, customer_id, country
FROM public.online_retail_clean
WHERE quantity <= 0 OR unit_price <= 0
ORDER BY invoice_date;

-- 1.4 Inspect rows with missing descriptions
SELECT
    invoice_no, stock_code, quantity, invoice_date,
    unit_price, customer_id, country
FROM public.online_retail_clean
WHERE description IS NULL OR BTRIM(description) = ''
ORDER BY invoice_date;


/* =========================================================
   02. MONTHLY SALES ANALYSIS
   ========================================================= */

-- 2.1 Monthly sales revenue, invoice count, and units sold
SELECT
    DATE_TRUNC('month', invoice_date)::DATE AS sales_month,
    COUNT(DISTINCT invoice_no) AS invoice_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(line_revenue), 2) AS sales_revenue
FROM public.retail_sales_analysis_v2
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY sales_month;

-- 2.2 Month-over-month revenue change
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', invoice_date)::DATE AS sales_month,
        SUM(line_revenue) AS sales_revenue
    FROM public.retail_sales_analysis_v2
    GROUP BY DATE_TRUNC('month', invoice_date)
),
monthly_comparison AS (
    SELECT
        sales_month,
        sales_revenue,
        LAG(sales_revenue) OVER (ORDER BY sales_month) AS previous_month_revenue
    FROM monthly_sales
)
SELECT
    sales_month,
    ROUND(sales_revenue, 2) AS sales_revenue,
    ROUND(previous_month_revenue, 2) AS previous_month_revenue,
    ROUND(
        100.0 * (sales_revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS month_over_month_change_pct
FROM monthly_comparison
ORDER BY sales_month;


/* =========================================================
   03. PRODUCT ANALYSIS
   ========================================================= */

-- 3.1 Top 10 products by sales revenue
-- Excludes known shipping/manual codes. This may not exclude every service item.
WITH product_sales AS (
    SELECT
        stock_code,
        description,
        SUM(quantity) AS total_units_sold,
        COUNT(DISTINCT invoice_no) AS invoice_count,
        SUM(line_revenue) AS sales_revenue
    FROM public.retail_sales_analysis_v2
    WHERE stock_code NOT IN ('DOT', 'POST', 'M')
    GROUP BY stock_code, description
)
SELECT
    stock_code,
    description,
    total_units_sold,
    invoice_count,
    ROUND(sales_revenue, 2) AS sales_revenue,
    ROUND(
        total_units_sold::NUMERIC / NULLIF(invoice_count, 0), 2
    ) AS average_units_per_invoice,
    ROUND(
        sales_revenue / NULLIF(total_units_sold, 0), 2
    ) AS average_revenue_per_unit
FROM product_sales
ORDER BY sales_revenue DESC
LIMIT 10;

-- 3.2 Inspect the highest-quantity transactions for stock_code 23166
SELECT
    invoice_no, invoice_date, quantity, unit_price, line_revenue, country
FROM public.retail_sales_analysis_v2
WHERE stock_code = '23166'
ORDER BY quantity DESC
LIMIT 10;

-- 3.3 Sensitivity check for invoice 541431 and stock_code 23166
-- This compares results with and without the invoice; it does not delete data.
SELECT
    'All transactions' AS scenario,
    SUM(quantity) AS total_units,
    ROUND(SUM(line_revenue), 2) AS sales_revenue
FROM public.retail_sales_analysis_v2
WHERE stock_code = '23166'

UNION ALL

SELECT
    'Excluding invoice 541431' AS scenario,
    SUM(quantity) AS total_units,
    ROUND(SUM(line_revenue), 2) AS sales_revenue
FROM public.retail_sales_analysis_v2
WHERE stock_code = '23166'
  AND invoice_no <> '541431';

-- 3.4 Review the investigated PAPER CRAFT transaction in the cleaned table
SELECT
    invoice_no, stock_code, description, quantity, invoice_date,
    unit_price, customer_id, country
FROM public.online_retail_clean
WHERE invoice_no = '581483'
  AND stock_code = '23843';


/* =========================================================
   04. COUNTRY ANALYSIS
   ========================================================= */

-- 4.1 Sales revenue, invoice count, and units by country
SELECT
    country,
    COUNT(DISTINCT invoice_no) AS invoice_count,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(line_revenue), 2) AS sales_revenue
FROM public.retail_sales_analysis_v2
GROUP BY country
ORDER BY sales_revenue DESC;

-- 4.2 Revenue contribution and average revenue per invoice
SELECT
    country,
    COUNT(DISTINCT invoice_no) AS invoice_count,
    ROUND(SUM(line_revenue), 2) AS sales_revenue,
    ROUND(
        100.0 * SUM(line_revenue)
        / NULLIF(SUM(SUM(line_revenue)) OVER (), 0),
        2
    ) AS revenue_contribution_pct,
    ROUND(
        SUM(line_revenue)
        / NULLIF(COUNT(DISTINCT invoice_no), 0),
        2
    ) AS average_revenue_per_invoice
FROM public.retail_sales_analysis_v2
GROUP BY country
ORDER BY sales_revenue DESC;


/* =========================================================
   05. ANALYSIS TABLE VALIDATION
   ========================================================= */

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE quantity <= 0) AS non_positive_quantity_rows,
    COUNT(*) FILTER (WHERE unit_price <= 0) AS non_positive_price_rows,
    COUNT(*) FILTER (
        WHERE description IS NULL OR BTRIM(description) = ''
    ) AS missing_description_rows,
    ROUND(SUM(line_revenue), 2) AS total_sales_revenue,
    MIN(invoice_date) AS first_invoice_date,
    MAX(invoice_date) AS last_invoice_date
FROM public.retail_sales_analysis_v2;


/* =========================================================
   NOTES FOR REPORTING
   =========================================================
   - December 2011 is partial: the dataset ends on 2011-12-09.
   - UK has the largest revenue contribution in this dataset.
   - Average revenue per invoice is not profitability; costs are unavailable.
   - Invoice 541431 contributes most of the sales for stock_code 23166.
     Retain it unless independent evidence proves it invalid.
   - Do not assume invoice_no + stock_code + invoice_date is a unique key.
*/
