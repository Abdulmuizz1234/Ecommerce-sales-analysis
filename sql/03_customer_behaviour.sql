-- ============================================================
-- Day 5 — Customer Behaviour
-- ============================================================
-- Average Order Value: £466.18
--
-- Repeat vs. one-time customers: 72.23% of customers are repeat
-- buyers, generating 96.74% of total revenue vs 3.26% from one-time
-- customers.
--
-- Revenue concentration: the top 20% of customers (quintile 1)
-- generate 77.20% of total revenue — a strongly concentrated,
-- near-Pareto pattern. The business's revenue is heavily
-- dependent on a small group of high-value customers rather
-- than spread evenly across its customer base.
-- ============================================================


-- Query 1: Average Order Value
SELECT ROUND(AVG(invoice_total)::numeric, 2) AS average_order_value
FROM (
    SELECT invoice, SUM(revenue) AS invoice_total
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND NOT is_cancelled
      AND NOT is_non_product
      AND NOT is_stock_adjustment
    GROUP BY invoice
) AS invoice_totals;


-- Query 2: Repeat vs. one-time customers
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT invoice) AS num_orders, SUM(revenue) AS customer_revenue
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND NOT is_cancelled
      AND NOT is_non_product
      AND NOT is_stock_adjustment
    GROUP BY customer_id
)
SELECT
    CASE WHEN num_orders > 1 THEN 'Repeat' ELSE 'One-time' END AS customer_type,
    COUNT(*) AS num_customers,
    ROUND(SUM(customer_revenue)::numeric, 2) AS total_revenue,
    ROUND((100.0 * SUM(customer_revenue) / SUM(SUM(customer_revenue)) OVER ())::numeric, 2) AS pct_of_revenue
FROM customer_orders
GROUP BY customer_type;


-- Query 3: Revenue concentration (top 20% of customers)
WITH customer_revenue AS (
    SELECT customer_id, SUM(revenue) AS total_revenue
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND NOT is_cancelled
      AND NOT is_non_product
      AND NOT is_stock_adjustment
    GROUP BY customer_id
),
ranked AS (
    SELECT
        customer_id,
        total_revenue,
        NTILE(5) OVER (ORDER BY total_revenue DESC) AS revenue_quintile
    FROM customer_revenue
)
SELECT
    revenue_quintile,
    COUNT(*) AS num_customers,
    ROUND(SUM(total_revenue)::numeric, 2) AS quintile_revenue,
    ROUND((100.0 * SUM(total_revenue) / SUM(SUM(total_revenue)) OVER ())::numeric, 2) AS pct_of_total_revenue
FROM ranked
GROUP BY revenue_quintile
ORDER BY revenue_quintile;