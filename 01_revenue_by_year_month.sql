-- Q1: What is the total revenue by year and by month?

SELECT YEAR(o.orderDate) AS orderyear,
       MONTH(o.orderDate) AS ordermonth,
       ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM salesorder AS o
JOIN orderdetail AS od ON o.orderId = od.orderId
GROUP BY orderyear, ordermonth
ORDER BY orderyear, ordermonth;

-- Result: Revenue ranged ~$25K-$61K per month across 2006-2008.
