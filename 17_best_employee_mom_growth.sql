-- Q17: Which employee has the best month-over-month sales growth?

SELECT employeeId, FullName, revenue,
       LAG(revenue) OVER (PARTITION BY employeeId ORDER BY orderyear, ordermonth) AS previous_month_sale,
       revenue - LAG(revenue) OVER (PARTITION BY employeeId ORDER BY orderyear, ordermonth) AS change_in_sale
FROM (
    SELECT e.employeeId, CONCAT(e.firstname, ' ', e.lastname) AS FullName,
           YEAR(o.orderDate) AS orderyear, MONTH(o.orderDate) AS ordermonth,
           ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
    FROM employee AS e
    JOIN salesorder AS o ON e.employeeId = o.employeeId
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY e.employeeId, FullName, orderyear, ordermonth
) AS rd
ORDER BY change_in_sale DESC
LIMIT 1;

-- Result: Russell King had the single largest month-over-month jump: +$22,404.21.
-- Note: PARTITION BY employeeId keeps each employee's trend independent.
