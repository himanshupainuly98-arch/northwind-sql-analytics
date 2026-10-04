-- Q20 (Capstone): RFM segment + each customer's top purchase category
-- Combines the RFM segmentation (Q7) with each customer's top-spend product
-- category, using RANK() ... PARTITION BY so ranking restarts independently
-- for every customer.

-- Step 1: each customer's spend per category
SELECT c.contactName AS customer_name, ca.categoryName,
       ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS category_spend
FROM customer AS c
JOIN salesorder AS o ON c.custId = o.custId
JOIN orderdetail AS od ON o.orderId = od.orderId
JOIN product AS p ON od.productId = p.productId
JOIN category AS ca ON p.categoryId = ca.categoryId
GROUP BY c.contactName, ca.categoryName;

-- Step 2: rank each customer's categories, restarting per customer
SELECT customer_name, categoryName, category_spend,
       RANK() OVER (PARTITION BY customer_name ORDER BY category_spend DESC) AS category_rnk
FROM ( /* Step 1 query */ ) rfm;

-- Step 3: keep only each customer's #1 category
SELECT customer_name, categoryName, category_spend
FROM ( /* Step 2 query */ ) ranked
WHERE category_rnk = 1;

-- Result: e.g., Allen, Michael's top category is Condiments ($1,338.80).
