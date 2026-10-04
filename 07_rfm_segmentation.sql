-- Q7: Segment customers using RFM (Recency, Frequency, Monetary) analysis
-- Flagship query of the project.

SELECT custId, contactName, recency, frequency, monetary, r_score, f_score, m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Other'
    END AS customer_segment
FROM (
    SELECT custId, contactName, recency, frequency, monetary,
           NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
           NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM (
        SELECT c.custId, c.contactName,
               DATEDIFF('2008-05-06', MAX(o.orderDate)) AS recency,
               COUNT(DISTINCT o.orderId) AS frequency,
               ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS monetary
        FROM customer AS c
        JOIN salesorder AS o ON c.custId = o.custId
        JOIN orderdetail AS od ON o.orderId = od.orderId
        GROUP BY c.custId, c.contactName
    ) AS rfm
) AS scored;

-- Note: '2008-05-06' (the dataset's most recent order date) is used as the
-- fixed reference "today" for recency, since the data is historical.
-- NTILE(5) bucket 5 = "best": frequency/monetary sorted ASC, recency sorted
-- DESC (a smaller day-count is better for recency).
