-- Q4: Which quarter had the highest revenue, and what products drove it?

-- Part A: find the best quarter
SELECT YEAR(o.orderDate) AS orderyear, QUARTER(o.orderDate) AS order_quarter,
       ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM orderdetail AS od
JOIN salesorder AS o ON od.orderId = o.orderId
GROUP BY orderyear, order_quarter
ORDER BY revenue DESC;

-- Part B: top products within that quarter
SELECT p.productName, SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS revenue,
       YEAR(o.orderDate) AS orderyear, QUARTER(o.orderDate) AS order_quarter
FROM product AS p
JOIN orderdetail AS od ON p.productId = od.productId
JOIN salesorder AS o ON od.orderId = o.orderId
WHERE YEAR(o.orderDate) = 2008 AND QUARTER(o.orderDate) = 1
GROUP BY p.productName, orderyear, order_quarter
ORDER BY revenue DESC;

-- Result: 2008 Q1 was the top quarter. Product QDOMO led with $60,736.75 revenue.
