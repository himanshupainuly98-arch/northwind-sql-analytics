-- Q15: Rank employees by total sales revenue generated.

SELECT employeeId, fullName, revenue,
       RANK() OVER (ORDER BY revenue DESC) AS rnk
FROM (
    SELECT e.employeeId, CONCAT(e.firstname, " ", e.lastname) AS fullName,
           ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS revenue
    FROM employee AS e
    JOIN salesorder AS o ON e.employeeId = o.employeeId
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY e.employeeId, fullName
) AS rrr;

-- Result: Yael Peled ranks #1 with $232,890.85 in total revenue.
