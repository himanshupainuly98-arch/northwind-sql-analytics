# Northwind Sales & Customer Analytics — SQL Project

**Author:** Himanshu Painuly
**Email:** himanshu.painuly98@gmail.com
**Tool:** MySQL Workbench
**Dataset:** Northwind (retail sales, 2006–2008)

## Overview

Analyzed 3 years of transactional data from the Northwind retail dataset to answer 19 real-world business questions spanning revenue trends, customer behavior, product performance, employee performance, and shipping efficiency. Every query was validated against baseline totals before being trusted — see the [Data Validation](#data-validation--lessons-learned) section for a real bug that was caught and fixed during development.

**Techniques used:** CTEs, window functions (`LAG`, `RANK`, `NTILE`, `SUM() OVER`, `PARTITION BY`), self-joins, multi-level subqueries, and conditional (`CASE WHEN`) aggregation.

## Dataset

This project uses the **Northwind** sample database (retail sales data, re-dated to 2006–2008 in this version). You can load it into MySQL using any standard Northwind MySQL script, for example [pthom/northwind_psql](https://github.com/pthom/northwind_psql). The schema includes `customer`, `salesorder`, `orderdetail`, `product`, `category`, `employee`, and `shipper` tables.

## Key Insights

- **58.41%** of total revenue comes from the top 20% of customers (Pareto analysis)
- **USA** is the top-revenue country ($245,584.61), narrowly ahead of Germany ($230,284.63)
- **Yael Peled** is the top revenue-generating employee ($232,890.85); **Russell King** had the single best month-over-month growth spike (+$22,404.21)
- Product **WHBYK** leads by units sold (1,577), but product **UKXRI** generates more total revenue ($71,155.70) — a clear volume-vs-margin tradeoff
- **Beverages** is the top-revenue product category ($267,868.18)
- Caught and fixed a discount-aggregation bug during development that was mixing row-level and grouped values, silently inflating revenue

---

## Business Questions & Queries

### Revenue & Sales Trends

**1. Total revenue by year and month**
```sql
SELECT YEAR(o.orderDate) AS orderyear, MONTH(o.orderDate) AS ordermonth,
       ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM salesorder AS o
JOIN orderdetail AS od ON o.orderId = od.orderId
GROUP BY orderyear, ordermonth
ORDER BY orderyear, ordermonth;
```
*Revenue ranged from ~$25K to ~$61K per month across 2006–2008, with early 2007 showing the strongest single month ($61,258.07 in Jan 2007).*

**2. Month-over-month revenue growth**
```sql
SELECT orderyear, ordermonth, revenue,
       LAG(revenue) OVER (ORDER BY orderyear, ordermonth) AS previous_month_revenue,
       revenue - LAG(revenue) OVER (ORDER BY orderyear, ordermonth) AS revenue_change
FROM (
    SELECT YEAR(o.orderDate) AS orderyear, MONTH(o.orderDate) AS ordermonth,
           ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
    FROM salesorder AS o
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY orderyear, ordermonth
) AS ot;
```
*Uses `LAG()` to compare each month against the prior month, revealing swings like a -$22,774 drop in Feb 2007 followed by a partial recovery.*

**3. Running total (cumulative revenue)**
```sql
SELECT orderyear, ordermonth, revenue,
       SUM(revenue) OVER (ORDER BY orderyear, ordermonth) AS running_total
FROM (
    SELECT YEAR(o.orderDate) AS orderyear, MONTH(o.orderDate) AS ordermonth,
           ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
    FROM salesorder AS o
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY orderyear, ordermonth
) AS odd;
```
*Cumulative revenue reached $346,372.92 by March 2007.*

**4. Best quarter and its top products**
```sql
-- Part A: find the best quarter
SELECT YEAR(o.orderDate) AS orderyear, QUARTER(o.orderDate) AS order_quarter,
       ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM orderdetail AS od
JOIN salesorder AS o ON od.orderId = o.orderId
GROUP BY orderyear, order_quarter
ORDER BY revenue DESC;

-- Part B: top products within that quarter
SELECT p.productName, SUM(od.quantity * od.unitPrice * (1 - od.discount)) AS revenue,
       YEAR(o.orderDate) AS orderyear, QUARTER(o.orderDate) AS order_quarter
FROM product AS p
JOIN orderdetail AS od ON p.productId = od.productId
JOIN salesorder AS o ON od.orderId = o.orderId
WHERE YEAR(o.orderDate) = 2008 AND QUARTER(o.orderDate) = 1
GROUP BY p.productName, orderyear, order_quarter
ORDER BY revenue DESC;
```
*2008 Q1 was the top-performing quarter. Product QDOMO led with $60,736.75 in revenue, more than double the second-place product.*

### Customer Analysis

**5. Top 10 customers by lifetime revenue**
```sql
SELECT c.custId, c.contactName,
       SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS lifetime_revenue
FROM customer AS c
JOIN salesorder AS o ON c.custId = o.custId
JOIN orderdetail AS od ON o.orderId = od.orderId
GROUP BY c.custId, c.contactName
ORDER BY lifetime_revenue DESC
LIMIT 10;
```

**6. Customer order frequency & average order value**
```sql
SELECT c.custId, c.contactName,
       COUNT(sd.orderId) AS order_count,
       ROUND(AVG(sd.order_total), 2) AS avg_order_value
FROM (
    SELECT o.custId, o.orderId,
           SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS order_total
    FROM salesorder AS o
    JOIN orderdetail AS od ON o.orderId = od.orderId
    GROUP BY o.custId, o.orderId
) AS sd
JOIN customer AS c ON sd.custId = c.custId
GROUP BY c.custId, c.contactName
ORDER BY avg_order_value DESC;
```
*Two-step subquery: order-level totals first, then averaged per customer — avoids the trap of averaging an already-aggregated total. Top customer by average order value: Veronesi, Giorgio ($3,938.48).*

**7. RFM Segmentation — Champions, Loyal, At Risk, Lost**
```sql
SELECT custId, contactName, recency, frequency, monetary, r_score, f_score, m_score,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Other'
    END AS customer_segment
FROM (
    SELECT custId, contactName, recency, frequency, monetary,
           NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
           NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM (
        SELECT c.custId, c.contactName,
               DATEDIFF('2008-05-06', MAX(o.orderDate)) AS recency,
               COUNT(DISTINCT o.orderId) AS frequency,
               ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS monetary
        FROM customer AS c
        JOIN salesorder AS o ON c.custId = o.custId
        JOIN orderdetail AS od ON o.orderId = od.orderId
        GROUP BY c.custId, c.contactName
    ) AS rfm
) AS scored;
```
*Flagship query of the project. Scores every customer 1–5 on Recency, Frequency, and Monetary value (using `NTILE(5)`, with direction flipped for recency since a smaller day-count is "better"), then classifies each into an actionable segment via `CASE WHEN`. `'2008-05-06'` (the dataset's most recent order date) is used as the fixed reference "today" for recency calculations, since the data is historical.*

**8. Customers inactive 6+ months (churn risk)**
```sql
SELECT c.custId, c.contactName, MAX(o.orderDate) AS last_order_date,
       DATEDIFF('2008-05-06', MAX(o.orderDate)) AS days_since_last_order
FROM customer AS c
JOIN salesorder AS o ON c.custId = o.custId
GROUP BY c.custId, c.contactName
HAVING days_since_last_order > 180
ORDER BY days_since_last_order DESC;
```
*Uses `HAVING` instead of `WHERE` since the filter is on an aggregated value (`MAX()`), which can't be evaluated until after grouping. Longest-inactive customer: Benito, Almudena at 658 days.*

**9. Pareto Analysis — revenue share of top 20% of customers**
```sql
SELECT ROUND(SUM(CASE WHEN revenue_quintile = 5 THEN revenue ELSE 0 END) / SUM(revenue) * 100, 2) AS pct_from_top20
FROM (
    SELECT contactName, revenue,
           NTILE(5) OVER (ORDER BY revenue) AS revenue_quintile
    FROM (
        SELECT c.contactName, ROUND(SUM(quantity * unitPrice * (1 - discount)), 2) AS revenue
        FROM customer AS c
        JOIN salesorder AS o ON c.custId = o.custId
        JOIN orderdetail AS od ON o.orderId = od.orderId
        GROUP BY c.contactName
    ) AS rdd
) AS roundd;
```
**Result: 58.41%** — top 20% of customers drive over half of total revenue, suggesting retention efforts should prioritize this segment.

### Product Analysis

**10. Top 10 products by revenue and by quantity sold**
```sql
SELECT p.productName, SUM(od.quantity) AS quantity_sold,
       ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM product AS p
JOIN orderdetail AS od ON p.productId = od.productId
GROUP BY p.productName
ORDER BY quantity_sold DESC  -- swap to revenue DESC for the revenue-ranked version
LIMIT 10;
```
*Product WHBYK leads by units sold (1,577), but product UKXRI generates more total revenue ($71,155.70 vs $46,825.48) despite fewer units — a volume vs. margin tradeoff worth flagging to merchandising.*

**11. Revenue by product category**
```sql
SELECT c.categoryName, ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM category AS c
JOIN product AS p ON c.categoryId = p.categoryId
JOIN orderdetail AS od ON p.productId = od.productId
GROUP BY c.categoryName
ORDER BY revenue DESC;
```
*Beverages leads all categories at $267,868.18, followed by Dairy Products ($234,507.29).*

**12. Market Basket Analysis — products frequently bought together**
```sql
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
```
*Self-join technique: joins `orderdetail` to itself on shared `orderId`, using `od1.productId < od2.productId` to eliminate both self-matches and duplicate reverse-direction pairs. Top pair (Product VJZZH + XYZPE) was purchased together 8 times.*

**13. Product demand & reorder signal** *(reframed — see note below)*
```sql
SELECT p.productName, COUNT(DISTINCT o.orderId) AS times_ordered,
       SUM(o.quantity) AS total_units_ordered,
       ROUND(SUM(o.quantity) / COUNT(DISTINCT o.orderId), 2) AS avg_units_per_order
FROM product AS p
JOIN orderdetail AS o ON p.productId = o.productId
GROUP BY p.productName
ORDER BY total_units_ordered DESC
LIMIT 10;
```
> **Note:** The original question asked for a stock-vs-demand reorder analysis, but the dataset's `unitsInStock` column was empty for all products. This query instead ranks products by total demand volume as a proxy signal for restocking priority. (Question 14, profit margin by product, was excluded for the same reason — no cost/`unitCost` column exists in this dataset.)

### Employee Performance

**15. Employee revenue ranking**
```sql
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
```
**Result:** Yael Peled ranks #1 with $232,890.85 in total revenue.

**16. Employee average order value & order count**
```sql
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
```
*Same two-level subquery pattern as Question 6, applied to employees. Zoya Dolgopyatova has the highest average order value at $1,797.86.*

**17. Best month-over-month employee growth**
```sql
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
```
*Uses `PARTITION BY employeeId` so each employee's month-over-month comparison is calculated independently, without mixing across employees. Russell King had the single largest month-over-month jump: +$22,404.21.*

### Geography & Shipping

**18. Revenue by country**
```sql
SELECT c.country, ROUND(SUM(od.quantity * od.unitPrice * (1 - od.discount)), 2) AS revenue
FROM customer AS c
JOIN salesorder AS o ON c.custId = o.custId
JOIN orderdetail AS od ON o.orderId = od.orderId
GROUP BY c.country
ORDER BY revenue DESC;
```
*USA leads at $245,584.61, narrowly ahead of Germany at $230,284.63. Note: "region" was not modeled as a clean dimension in this dataset, so country was used instead.*

**19. Average shipping delay by carrier**
```sql
SELECT s.companyName AS shipper,
       ROUND(AVG(DATEDIFF(o.shippedDate, o.orderDate)), 2) AS avg_shipping_delay_days
FROM shipper AS s
JOIN salesorder AS o ON s.shipperId = o.shipperId
GROUP BY s.companyName
ORDER BY avg_shipping_delay_days;
```
*Shipper ZHISN is fastest, averaging 7.49 days from order to shipment, vs. 9.26 days for the slowest carrier.*

### Capstone

**20. RFM Segment + Top Purchase Category (combined analysis)**
```sql
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
```
*Combines the RFM segmentation (Question 7) with each customer's top-spend product category — built using `RANK() ... PARTITION BY customer_name` so ranking restarts independently for every customer. E.g., Allen, Michael's top category is Condiments ($1,338.80).*

---

## Data Validation & Lessons Learned

Every query in this project was checked against a baseline total before being trusted, not just written and assumed correct. Two examples from the development process:

1. **Discount-aggregation bug:** An early version of the revenue query applied `(1 - discount)` *outside* the `SUM()`, using a single arbitrary row's discount value against the whole group's total — inflating (or deflating) revenue depending on which row the database happened to pick. Fixed by moving the discount calculation *inside* the aggregate, applied per line item before summing.
2. **NTILE direction bugs (RFM):** `NTILE(5)` bucket 5 means "highest" only when sorted correctly — `ORDER BY frequency ASC` and `ORDER BY monetary ASC` put top spenders in bucket 5, while recency needed the opposite (`DESC`) since a *smaller* day-count is better. Verified by cross-checking a known top customer's `m_score` before trusting the segmentation.

**General validation habits applied throughout:**
- Reconciled aggregated totals against simple baseline `SUM()` queries
- Spot-checked individual customers/orders by hand against query output
- Watched for row-duplication from joins (fan-out) before trusting any `SUM()`

---

## Files

- `queries/` — individual `.sql` files, one per question
- `README.md` — this file

## Tools

MySQL Workbench · Northwind sample database (2006–2008 sales data)
