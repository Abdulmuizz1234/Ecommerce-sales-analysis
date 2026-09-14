WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', invoice_date) AS month,
        SUM(revenue) AS total_revenue
    FROM transactions
    GROUP BY DATE_TRUNC('month', invoice_date)
)
SELECT
    month,
    ROUND(total_revenue::numeric, 2) AS total_revenue,
    ROUND((total_revenue - LAG(total_revenue) OVER (ORDER BY month))::numeric, 2) AS change_from_prior_month
FROM monthly_revenue
ORDER BY month;