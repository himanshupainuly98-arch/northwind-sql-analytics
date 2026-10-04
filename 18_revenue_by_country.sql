-- Q18: What is total revenue by country?
-- Note: "region" was not modeled as a clean dimension in this dataset, so
-- country was used instead.

SELECT c.country, ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM customer AS c
JOIN salesorder AS o ON c.custId = o.custId
JOIN orderdetail AS od ON o.orderId = od.orderId
GROUP BY c.country
ORDER BY revenue DESC;

-- Result: USA leads at $245,584.61, narrowly ahead of Germany ($230,284.63).
