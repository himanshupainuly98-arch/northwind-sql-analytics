-- Q12: Which products are frequently ordered together? (Market Basket Analysis)

SELECT p1.productName AS product_A, p2.productName AS product_B,
       COUNT(*) AS times_bought_together
FROM orderdetail AS od1
JOIN orderdetail AS od2
    ON od1.orderId = od2.orderId
    AND od1.productId < od2.productId
JOIN product AS p1 ON od1.productId = p1.productId
JOIN product AS p2 ON od2.productId = p2.productId
GROUP BY p1.productName, p2.productName
ORDER BY times_bought_together DESC
LIMIT 10;

-- Result: Top pair (Product VJZZH + XYZPE) was purchased together 8 times.
-- Note: self-join on shared orderId; od1.productId < od2.productId removes
-- both self-matches and duplicate reverse-direction pairs.
