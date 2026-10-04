-- Q16: What is each employee's average order value and number of orders handled?

SELECT employeeId, fullName, COUNT(NO_OF_ORDER) AS order_count,
       ROUND(AVG(order_total), 2) AS avg_order_value
FROM (
    SELECT e.employeeId, CONCAT(e.firstname, ' ', e.lastname) AS fullName,
           o.orderId AS NO_OF_ORDER,
           ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS order_total
    FROM employee AS e
    JOIN salesorder AS o ON e.employeeId = o.employeeId
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY e.employeeId, fullName, NO_OF_ORDER
) AS po
GROUP BY employeeId, fullName;

-- Result: Zoya Dolgopyatova has the highest average order value at $1,797.86.
-- Note: same two-level subquery pattern as Q6, applied to employees.
