-- Q11: Which product categories generate the most revenue?

SELECT c.categoryName, ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM category AS c
JOIN product AS p ON c.categoryId = p.categoryId
JOIN orderdetail AS od ON p.productId = od.productId
GROUP BY c.categoryName
ORDER BY revenue DESC;

-- Result: Beverages leads at $267,868.18, followed by Dairy Products ($234,507.29).
