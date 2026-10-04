-- Q2: What is the month-over-month revenue growth rate?

SELECT orderyear, ordermonth, revenue,
       LAG(revenue) OVER (ORDER BY orderyear, ordermonth) AS previous_month_revenue,
       revenue - LAG(revenue) OVER (ORDER BY orderyear, ordermonth) AS revenue_change
FROM (
    SELECT YEAR(o.orderDate) AS orderyear, MONTH(o.orderDate) AS ordermonth,
           ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
    FROM salesorder AS o
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY orderyear, ordermonth
) AS ot;

-- Result: Feb 2007 saw a -$22,774 drop, followed by partial recovery in March.
