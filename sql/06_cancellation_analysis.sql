-- ============================================================
-- Day 6 — Cancellation Analysis
-- ============================================================
-- Overall cancellation rate: 1.85% (19,104 of 1,033,031 transactions)
--
-- Monthly rate: stable throughout, roughly 1.3%–2.8% every month
-- with no clear seasonal spike. Notably, November 2011 (the
-- dataset's peak revenue month) had one of the LOWEST cancellation
-- rates (1.29%) — cancellations did not rise during the busiest
-- sales period, a reassuring sign against any capacity-strain or
-- fulfillment-quality issue during the Christmas rush.
--
-- Top cancelled PRODUCTS by value (excluding non-product entries
-- like Manual/Bank Charges/Postage/Discount, which are
-- administrative rows, not real products):
--   1. PAPER CRAFT, LITTLE BIRDIE          £168,469.60 (1 cancellation)
--   2. MEDIUM CERAMIC TOP STORAGE JAR       £77,479.64 (10 cancellations)
--   3. REGENCY CAKESTAND 3 TIER             £16,545.30 (341 cancellations —
--      most FREQUENTLY cancelled real product; worth investigating
--      for a possible quality or listing-accuracy issue)
--   4. WHITE HANGING HEART T-LIGHT HOLDER    £9,387.10 (134 cancellations)
--
-- Note: the original query result also returned non-product stock
-- codes (Manual, AMAZON FEE, Bank Charges, Postage, Discount,
-- Unknown) alongside real products, since it filtered only on
-- is_cancelled without also excluding is_non_product. Re-running
-- with "AND NOT t.is_non_product" added produces the clean
-- product-only list above.
-- ============================================================

-- Overall cancellation rate
SELECT
    COUNT(*) FILTER (WHERE is_cancelled) AS cancelled_rows,
    COUNT(*) AS total_rows,
    ROUND((100.0 * COUNT(*) FILTER (WHERE is_cancelled) / COUNT(*))::numeric, 2) AS cancellation_rate_pct
FROM transactions;


-- Cancellation rate by country (only countries with enough volume to be meaningful)
SELECT
    c.country,
    COUNT(*) FILTER (WHERE t.is_cancelled) AS cancelled_rows,
    COUNT(*) AS total_rows,
    ROUND((100.0 * COUNT(*) FILTER (WHERE t.is_cancelled) / COUNT(*))::numeric, 2) AS cancellation_rate_pct
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.country
HAVING COUNT(*) > 20
ORDER BY cancellation_rate_pct DESC
LIMIT 10;


-- Products most often cancelled, by value
SELECT
    p.description,
    COUNT(*) AS times_cancelled,
    ROUND(SUM(ABS(t.revenue))::numeric, 2) AS cancelled_value
FROM transactions t
JOIN products p ON t.stock_code = p.stock_code
WHERE t.is_cancelled
GROUP BY p.description
ORDER BY cancelled_value DESC
LIMIT 10;


-- Monthly cancellation rate — does it spike anywhere?
SELECT
    DATE_TRUNC('month', invoice_date) AS month,
    COUNT(*) FILTER (WHERE is_cancelled) AS cancelled_rows,
    COUNT(*) AS total_rows,
    ROUND((100.0 * COUNT(*) FILTER (WHERE is_cancelled) / COUNT(*))::numeric, 2) AS cancellation_rate_pct
FROM transactions
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY month;