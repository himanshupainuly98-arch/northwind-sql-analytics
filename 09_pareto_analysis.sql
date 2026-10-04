-- Q9: What % of total revenue comes from the top 20% of customers? (Pareto / 80-20)

SELECT ROUND(SUM(CASE WHEN revenue_quintile = 5 THEN revenue ELSE 0 END) / SUM(revenue) * 100, 2) AS pct_from_top20
FROM (
    SELECT contactName, revenue,
           NTILE(5) OVER (ORDER BY revenue) AS revenue_quintile
    FROM (
        SELECT c.contactName, ROUND(SUM(quantity * unitPrice * (1 - discount)), 2) AS revenue
        FROM customer AS c
        JOIN salesorder AS o ON c.custId = o.custId
        JOIN orderdetail AS od ON o.orderId = od.orderId
        GROUP BY c.contactName
    ) AS rdd
) AS roundd;

-- Result: 58.41% of total revenue comes from the top 20% of customers.
