-- Q10: What are the top 10 best-selling products by revenue and by quantity sold?

SELECT p.productName, SUM(od.quantity) AS quantity_sold,
       ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM product AS p
JOIN orderdetail AS od ON p.productId = od.productId
GROUP BY p.productName
ORDER BY quantity_sold DESC  -- swap to revenue DESC for the revenue-ranked version
LIMIT 10;

-- Result: Product WHBYK leads by units sold (1,577), but product UKXRI
-- generates more total revenue ($71,155.70) despite fewer units -- a
-- volume vs. margin tradeoff.
