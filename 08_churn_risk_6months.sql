-- Q8: Which customers haven't ordered in the last 6 months? (churn risk)

SELECT c.custId, c.contactName, MAX(o.orderDate) AS last_order_date,
       DATEDIFF('2008-05-06', MAX(o.orderDate)) AS days_since_last_order
FROM customer AS c
JOIN salesorder AS o ON c.custId = o.custId
GROUP BY c.custId, c.contactName
HAVING days_since_last_order > 180
ORDER BY days_since_last_order DESC;

-- Result: Longest-inactive customer: Benito, Almudena at 658 days.
-- Note: uses HAVING (not WHERE) since the filter is on an aggregated value.
