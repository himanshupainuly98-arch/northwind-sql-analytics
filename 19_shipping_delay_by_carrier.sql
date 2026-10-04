-- Q19: What is the average shipping delay by carrier, and which is fastest?

SELECT s.companyName AS shipper,
       ROUND(AVG(DATEDIFF(o.shippedDate, o.orderDate)), 2) AS avg_shipping_delay_days
FROM shipper AS s
JOIN salesorder AS o ON s.shipperId = o.shipperId
GROUP BY s.companyName
ORDER BY avg_shipping_delay_days;

-- Result: Shipper ZHISN is fastest, averaging 7.49 days from order to shipment.
