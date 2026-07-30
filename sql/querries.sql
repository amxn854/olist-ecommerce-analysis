-- ============================================================
-- QUERY 4: Customer Segmentation (RFM)
-- 3 segments: Champions, At Risk, Lost
-- Mirrors: rfm segmentation in Python
-- ============================================================

WITH customer_stats AS (
    -- Step 1: Calculate recency and monetary per customer
    SELECT
        c.customer_unique_id,
        DATEDIFF('2018-08-30', MAX(o.order_purchase_timestamp)) AS recency_days,
        ROUND(SUM(i.price + i.freight_value), 2)                AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN items  i ON o.order_id    = i.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
customer_scored AS (
    -- Step 2: Score recency (lower days = higher score) and monetary
    SELECT
        customer_unique_id,
        recency_days,
        total_spent,
        NTILE(4) OVER (ORDER BY recency_days DESC)  AS r_score,
        NTILE(4) OVER (ORDER BY total_spent ASC)    AS m_score
    FROM customer_stats
)
-- Step 3: Assign segments and summarise
SELECT
    CASE
        WHEN r_score >= 3 AND m_score >= 3 THEN 'Champions'
        WHEN r_score >= 2 AND m_score >= 2 THEN 'At Risk'
        ELSE                                    'Lost'
    END                          AS segment,
    COUNT(*)                     AS customers,
    ROUND(AVG(recency_days), 1)  AS avg_recency_days,
    ROUND(AVG(total_spent), 2)   AS avg_monetary,
    ROUND(SUM(total_spent), 2)   AS total_revenue
FROM customer_scored
GROUP BY segment
ORDER BY total_revenue DESC;