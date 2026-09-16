-- ============================================================
-- Day 6 — Geographic Performance
-- ============================================================
-- UK vs. International:
--
--   UK             33,389 orders   £14,294,286.13 total   £428.11 AOV
--   International    3,261 orders   £2,791,338.18 total   £855.98 AOV
--
-- The UK dominates in raw order volume and total revenue, as
-- expected given the dataset's origin. However, international
-- customers spend roughly DOUBLE per order (£855.98 vs £428.11)
-- despite placing far fewer orders overall — suggesting
-- international markets are comparatively underexploited relative
-- to their per-order value, and could be a worthwhile focus for
-- expanded marketing reach.
-- ============================================================


-- Revenue, orders, and AOV by country
SELECT
    c.country,
    COUNT(DISTINCT t.invoice) AS num_orders,
    ROUND(SUM(t.revenue)::numeric, 2) AS total_revenue,
    ROUND((SUM(t.revenue) / COUNT(DISTINCT t.invoice))::numeric, 2) AS avg_order_value,
    ROUND((100.0 * SUM(t.revenue) / SUM(SUM(t.revenue)) OVER ())::numeric, 2) AS pct_of_total_revenue
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
WHERE NOT t.is_cancelled AND NOT t.is_non_product AND NOT t.is_stock_adjustment
GROUP BY c.country
ORDER BY total_revenue DESC;


-- UK vs. everywhere else, side by side
SELECT
    CASE WHEN c.country = 'United Kingdom' THEN 'UK' ELSE 'International' END AS market,
    COUNT(DISTINCT t.invoice) AS num_orders,
    ROUND(SUM(t.revenue)::numeric, 2) AS total_revenue,
    ROUND((SUM(t.revenue) / COUNT(DISTINCT t.invoice))::numeric, 2) AS avg_order_value
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
WHERE NOT t.is_cancelled AND NOT t.is_non_product AND NOT t.is_stock_adjustment
GROUP BY market;