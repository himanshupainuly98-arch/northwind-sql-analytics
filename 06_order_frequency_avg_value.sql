-- Q6: What is each customer's order frequency (number of orders) and average order value?

SELECT c.custId, c.contactName,
       COUNT(sd.orderId) AS order_count,
       ROUND(AVG(sd.order_total), 2) AS avg_order_value
FROM (
    SELECT o.custId, o.orderId,
           SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS order_total
    FROM salesorder AS o
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY o.custId, o.orderId
) AS sd
JOIN customer AS c ON sd.custId = c.custId
GROUP BY c.custId, c.contactName
ORDER BY avg_order_value DESC;

-- Result: Top avg order value: Veronesi, Giorgio at $3,938.48.
-- Note: two-level subquery -- order totals computed first, then averaged per
-- customer -- avoids incorrectly averaging an already-collapsed total.
