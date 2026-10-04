-- Q13: Which products are understocked relative to demand? (reorder point analysis)
-- NOTE: the dataset's unitsInStock column was empty for all products, so this
-- query uses total demand volume as a proxy signal for restocking priority instead.
-- (Q14, profit margin by product, was excluded entirely -- no cost/unitCost
-- column exists in this dataset.)

SELECT p.productName, COUNT(DISTINCT o.orderId) AS times_ordered,
       SUM(o.quantity) AS total_units_ordered,
       ROUND(SUM(o.quantity) / COUNT(DISTINCT o.orderId), 2) AS avg_units_per_order
FROM product AS p
JOIN orderdetail AS o ON p.productId = o.productId
GROUP BY p.productName
ORDER BY total_units_ordered DESC
LIMIT 10;

-- Result: Product WHBYK: 1,577 units across 51 orders -- highest total demand.
