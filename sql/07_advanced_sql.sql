-- ============================================================
-- Day 7 — Advanced SQL: Subqueries & Window Functions
-- ============================================================
-- FINDINGS:
-- 1. Top product per country (PARTITION BY + RANK()):
--    UK's top product is "WHITE HANGING HEART T-LIGHT HOLDER" (£227,965.51),
--    by far the largest single top-product figure of any country, consistent
--    with the UK dominating total transaction volume. Other countries' top
--    products range from ~£2,700 (Sweden) to ~£14,600 (Eire).
--    Data quality note: before filtering, "Unknown" (missing product
--    descriptions) appeared as the UK's top "product," covering 486 distinct
--    stock codes, 17,828 transactions and £362,819.20 (1.84%) of total
--    revenue. Excluded via `p.description <> 'Unknown'` so results reflect
--    real, nameable products. Documented as a limitation in the README.
--
-- 2. Unusually large orders (correlated subquery, rewritten as a window
--    function for performance): flags invoices where a customer spent more
--    than 3x their own average order value. Top case: customer 12346,
--    invoice 541431, £77,183.60 — a clear outlier vs. their typical spend,
--    likely a bulk/wholesale order worth a closer look rather than a
--    representative "normal" purchase.
--
-- 3. Running total revenue (SUM() OVER (ORDER BY month)): revenue climbs
--    steadily from £798,732 (Dec 2009) to over £15.4M (by Aug 2011) with no
--    unexplained jumps or drops, confirming the monthly revenue figures used
--    elsewhere in the analysis are internally consistent.
-- ============================================================

-- Query 1: Top-selling product per country (window function, PARTITION BY)
WITH country_product_revenue AS (
    SELECT
        c.country,
        p.description,
        SUM(t.revenue) AS product_revenue,
        RANK() OVER (PARTITION BY c.country ORDER BY SUM(t.revenue) DESC) AS revenue_rank
    FROM transactions t
    JOIN products p ON t.stock_code = p.stock_code
    JOIN customers c ON t.customer_id = c.customer_id
    WHERE NOT t.is_cancelled AND NOT t.is_non_product AND NOT t.is_stock_adjustment
      AND p.description <> 'Unknown'
    GROUP BY c.country, p.description
)
SELECT country, description, ROUND(product_revenue::numeric, 2) AS product_revenue
FROM country_product_revenue
WHERE revenue_rank = 1
ORDER BY product_revenue DESC
LIMIT 10;

-- Query 2 (optimized): Orders that are unusually large relative to the customer's own average (correlated subquery)
WITH invoice_totals AS (
    SELECT
        t.customer_id,
        t.invoice,
        SUM(t.revenue) AS invoice_total
    FROM transactions t
    WHERE t.customer_id IS NOT NULL
      AND NOT t.is_cancelled AND NOT t.is_non_product AND NOT t.is_stock_adjustment
    GROUP BY t.customer_id, t.invoice
),
with_avg AS (
    SELECT
        *,
        AVG(invoice_total) OVER (PARTITION BY customer_id) AS customer_avg_invoice
    FROM invoice_totals
)
SELECT customer_id, invoice, ROUND(invoice_total::numeric, 2) AS invoice_total
FROM with_avg
WHERE invoice_total > customer_avg_invoice * 3
ORDER BY invoice_total DESC
LIMIT 10;

-- Query 3: Running total (cumulative) revenue by month
WITH monthly AS (
    SELECT DATE_TRUNC('month', invoice_date) AS month, SUM(revenue) AS monthly_revenue
    FROM transactions
    WHERE NOT is_cancelled AND NOT is_non_product AND NOT is_stock_adjustment
    GROUP BY DATE_TRUNC('month', invoice_date)
)
SELECT
    month,
    ROUND(monthly_revenue::numeric, 2) AS monthly_revenue,
    ROUND(SUM(monthly_revenue) OVER (ORDER BY month)::numeric, 2) AS running_total_revenue
FROM monthly
ORDER BY month;