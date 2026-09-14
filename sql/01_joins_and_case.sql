SELECT
    t.invoice,
    t.invoice_date,
    p.description,
    c.country,
    t.quantity,
    t.revenue,
    CASE
        WHEN t.revenue >= 100 THEN 'High value'
        WHEN t.revenue >= 30  THEN 'Medium value'
        ELSE 'Low value'
    END AS order_value_tier
FROM transactions t
JOIN products p ON t.stock_code = p.stock_code
JOIN customers c ON t.customer_id = c.customer_id
ORDER BY t.revenue DESC
LIMIT 20;