-- Q3: What is the running total (cumulative revenue) over time?

SELECT orderyear, ordermonth, revenue,
       SUM(revenue) OVER (ORDER BY orderyear, ordermonth) AS running_total
FROM (
    SELECT YEAR(o.orderDate) AS orderyear, MONTH(o.orderDate) AS ordermonth,
           ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
    FROM salesorder AS o
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY orderyear, ordermonth
) AS odd;

-- Result: Cumulative revenue reached $346,372.92 by March 2007.
