# Retail Sales Performance Analysis

An exploratory retail sales analysis project using PostgreSQL and Power BI to examine sales performance, monthly trends, top-selling products, and country-level sales distribution.

## Project Overview

This project analyzes historical online retail transaction data to understand sales patterns across time, products, and countries.
The analysis uses PostgreSQL for data quality checks, transaction filtering, and SQL-based analysis. Power BI is used to present key metrics and findings through an interactive dashboard.

## Business Questions

This project aims to answer the following questions:
- How does sales revenue change over time?
- Which products generate the highest sales revenue?
- Which countries contribute the most to total sales?
- How concentrated are sales across countries?
- Which unusual transactions may materially influence product-level results?

## Dataset

- **Source:** UCI Machine Learning Repository: Online Retail
- **Period:** December 1, 2010 to December 9, 2011
- **Raw dataset:** 541,909 transaction rows
- **Analysis table:** 530,099 rows
- **Geographic coverage:** 38 countries

The analysis table excludes non-positive quantities, non-positive unit prices, missing or blank product descriptions, cancellation invoices, and one investigated high-quantity transaction.

## Tools Used

- PostgresSQL: Data quality checks, transaction filtering, aggregation, and analysis.
- pgAdmin: SQL query execution and database inspection.
- Power BI Desktop: KPI cards, monthly sales trend, product ranking, and country-level visualizations.

## Analysis Process
1. Reviewed data quality, including missing descriptions, non-positive quantities, non-positive prices, and cancellation invoices.
2. Prepared a filtered analysis table for sales analysis.
3. Calculated sales revenue as quantity multiplied by unit price.
4. Analyzed monthly sales, product performance, and country-level sales.
5. Validated key dashboard metrics against PostgreSQL query results.
6. Investigated an unusually large product transaction and assessed its influence on product-level results.

## Key Findings
- Total sales revenue: £10,498,214.94.
- Total invoices: 19,959 distinct invoices.
- Total units sold: 5,507,377.
- Countries represented: 38.
- Largest country by sales: United Kingdom, with approximately £8.86 million in sales, representing 84.36% of total sales.
- Top product by sales revenue: REGENCY CAKESTAND 3 TIER, generating £174,484.74.
- Monthly trend: November 2011 recorded the highest monthly sales in the analysis period.

These findings describe the analyzed dataset and should not be interpreted as evidence of profitability or causal business effects.

## Dashboard Preview

![Retail Sales Performance Dashboard](retail%20sales%20performance.png)

The dashboard includes:

- Total Sales
- Total Units Sold
- Total Invoices
- Total Countries
- Monthly Sales Trend
- Top 10 Products by Sales
- Sales by Country
- Sales Contribution by Country

## Data Considerations and Limitations
- Sales revenue is calculated as quantity multiplied by unit price. It is not profit because cost data is unavailable.
- December 2011 contains transactions only through December 9, so it represents a partial month.
- One transaction involving 80,995 units of stock code 23843 was excluded from the analysis table after investigation. It remains in the cleaned table.
- Another unusually large transaction involving stock code 23166 was retained. Unusual values are not automatically errors and can materially affect product-level results.
- The analysis is descriptive and does not establish the causes of sales changes.

## Project Files
- retail_sales_analysis.sql: SQL queries for data quality checks, monthly sales analysis, product analysis, country analysis, and validation.
- retail_sales_performance1.pdf: PDF export of the Power BI dashboard.
- retail sales performance.png: Dashboard preview image.

## Author
Created as a data analytics portfolio project using PostgreSQL and Power BI.
