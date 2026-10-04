-- Q5: Who are the top 10 customers by total lifetime revenue?

SELECT c.custId, c.contactName,
       SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS lifetime_revenue
FROM customer AS c
JOIN salesorder AS o ON c.custId = o.custId
JOIN orderdetail AS od ON o.orderId = od.orderId
GROUP BY c.custId, c.contactName
ORDER BY lifetime_revenue DESC
LIMIT 10;
