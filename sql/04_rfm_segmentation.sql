-- ============================================================
-- Day 6 — RFM Segmentation
-- ============================================================
-- Customers were split into 5 segments based on Recency, Frequency,
-- and Monetary quartile scores:
--
--   Champions        1,831 customers   £13,024,092.78   76.23% of revenue
--   Loyal Customers    695 customers   £2,177,910.35    12.75% of revenue
--   Needs Attention  1,101 customers   £822,448.80        4.81% of revenue
--   Lost             1,799 customers   £573,206.96        3.35% of revenue
--   At Risk            439 customers   £487,965.41        2.86% of revenue
--
-- "Champions" (recent, frequent, high-spending) drive 76.23% of total
-- revenue from just 1,831 customers — reinforcing the Day 5 finding
-- that repeat customers generate 96.74% of revenue, now with much
-- finer precision: it's specifically this top RFM segment doing
-- almost all of the work.
--
-- "Lost" is notably the second-largest segment by customer count
-- (1,799) but contributes almost nothing (3.35%) — a large pool of
-- previously active customers who have gone quiet, representing a
-- potential re-engagement opportunity for the business.
-- ============================================================



-- Step 1: calculate raw R, F, M per customer, then score each on a 1–4 scale
WITH customer_rfm AS (
    SELECT
        customer_id,
        (SELECT MAX(invoice_date) FROM transactions) - MAX(invoice_date) AS recency,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(revenue) AS monetary
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND NOT is_cancelled AND NOT is_non_product AND NOT is_stock_adjustment
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id, recency, frequency, monetary,
        NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_rfm
)
SELECT
    customer_id, recency, frequency, ROUND(monetary::numeric, 2) AS monetary,
    r_score, f_score, m_score,
    CASE
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
        WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
        ELSE 'Needs Attention'
    END AS segment
FROM rfm_scored
ORDER BY monetary DESC;


-- Segment summary: how many customers and how much revenue per segment
WITH customer_rfm AS (
    SELECT
        customer_id,
        (SELECT MAX(invoice_date) FROM transactions) - MAX(invoice_date) AS recency,
        COUNT(DISTINCT invoice) AS frequency,
        SUM(revenue) AS monetary
    FROM transactions
    WHERE customer_id IS NOT NULL
      AND NOT is_cancelled AND NOT is_non_product AND NOT is_stock_adjustment
    GROUP BY customer_id
),
rfm_scored AS (
    SELECT
        customer_id, monetary,
        NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM customer_rfm
),
segmented AS (
    SELECT
        customer_id, monetary,
        CASE
            WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Champions'
            WHEN f_score >= 3 AND m_score >= 3 THEN 'Loyal Customers'
            WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*) AS num_customers,
    ROUND(SUM(monetary)::numeric, 2) AS total_revenue,
    ROUND((100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER ())::numeric, 2) AS pct_of_revenue
FROM segmented
GROUP BY segment
ORDER BY total_revenue DESC;