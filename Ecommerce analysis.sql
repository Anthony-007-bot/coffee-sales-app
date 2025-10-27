USE ecommerce;
SELECT * FROM ecommerce.categories;
SELECT * FROM ecommerce.employees;
SELECT * FROM ecommerce.orderdetails;
SELECT * FROM ecommerce.orders;
SELECT * FROM ecommerce.customers;
SELECT * FROM ecommerce.products;
SELECT * FROM ecommerce.shippers;
SELECT * FROM ecommerce.suppliers;

-- Q1
-- Total Sales by Employee: 
-- Write a query to calculate the total sales (in dollars) made by each employee, considering the quantity and unit price of products sold
SELECT e.LastName,
       CONCAT('$', FORMAT(SUM(od.Quantity * od.UnitPrice), 2)) AS TotalSales_USD,
       RANK() OVER(ORDER BY SUM(od.Quantity * od.UnitPrice) DESC) AS Salesrank
FROM employees e
JOIN orders o 
ON e.employeeID = o.employeeID
JOIN orderdetails od 
ON o.orderID = od.orderID
GROUP BY e.lastname;

-- Q2
-- Top 5 Customers by Sales:
-- Identify the top 5 customers who have generated the most revenue. Show the customer’s name and the total amount they’ve spent.
SELECT c.CustomerName,
		CONCAT('$', FORMAT(SUM(od.Quantity * od.UnitPrice), 2)) AS Totalspent_USD
FROM customers c
JOIN orders o
ON c.customerID = o.customerID
JOIN orderdetails od 
ON o.orderID = od.orderID
GROUP BY CustomerName
ORDER BY SUM(od.Quantity * od.UnitPrice) DESC
LIMIT 5;

-- Q3
-- Monthly Sales Trend:
-- Write a query to display the total sales amount for each month in the year 1997.
SELECT MONTH(o.OrderDate) AS Month,
       CONCAT('$', FORMAT(SUM(od.Quantity * od.UnitPrice), 2)) AS TotalSales_USD
FROM Orders o
JOIN OrderDetails od
ON o.OrderID = od.OrderID
WHERE YEAR(o.OrderDate) = 1997
GROUP BY MONTH(o.OrderDate)
ORDER BY Month;

-- Q4
-- Order Fulfilment Time:
-- Calculate the average time (in days) taken to fulfil an order for each employee. Assuming shipping takes 3 or 5 days respectively depending on if the item was ordered in 1996 or 1997.

SELECT CONCAT_WS(' ', e.FirstName, e.LastName) AS EmployeeName,
       ROUND(AVG(CASE 
                   WHEN YEAR(o.OrderDate) = 1996 THEN 3
                   WHEN YEAR(o.OrderDate) = 1997 THEN 5
                   ELSE 0
                 END), 2) AS AvgFulfilmentDays
FROM Employees e
JOIN Orders o ON e.EmployeeID = o.EmployeeID
GROUP BY EmployeeName;

-- Q5
-- Products by Category with No Sales:
-- List the customers operating in London and total sales for each. 
SELECT c.CustomerName,
       CONCAT('$', FORMAT(SUM(od.Quantity * od.UnitPrice * (1 - COALESCE(od.Discount,0))), 2)) AS TotalSales_USD
FROM Customers c
JOIN Orders o        ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID    = od.OrderID
WHERE c.City = 'London'
GROUP BY c.CustomerName
ORDER BY SUM(od.Quantity * od.UnitPrice * (1 - COALESCE(od.Discount,0))) DESC;

-- Q6
-- Customers with Multiple Orders on the Same Date:
-- Write a query to find customers who have placed more than one order on the same date.
SELECT c.CustomerName,
		o.OrderDate,
		COUNT(o.OrderID) AS OrdersOnDate
FROM Customers c
JOIN Orders o 
ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerName, o.OrderDate
HAVING COUNT(o.OrderID) > 1
ORDER BY OrdersOnDate DESC;

-- Q7
-- Average Discount per Product:
-- Calculate the average discount given per product across all orders. Round to 2 decimal places.
SELECT p.ProductName,
		ROUND(AVG(od.Discount), 2) AS AvgDiscount
FROM Products p
JOIN OrderDetails od
ON p.ProductID = od.ProductID
GROUP BY p.ProductName
ORDER BY AvgDiscount DESC;

-- Q8
-- Products Ordered by Each Customer:
-- For each customer, list the products they have ordered along with the total quantity of each product ordered.
SELECT c.CustomerName,
       p.ProductName,
       SUM(od.Quantity) AS TotalProductOrdered
FROM Customers c
JOIN orders o
ON c.CustomerID = o.CustomerID
JOIN orderdetails od
ON o.OrderID = od.OrderID
INNER JOIN Products p
ON od.ProductID = p.ProductID
GROUP BY c.CustomerName, p.ProductName
ORDER BY CustomerName, TotalProductOrdered DESC;

-- Q9
-- Employee Sales Ranking:
-- Rank employees based on their total sales. Show the employeename, total sales, and their rank.
SELECT e.LastName,
       CONCAT('$', FORMAT(SUM(od.Quantity * od.UnitPrice), 2)) AS TotalSales_USD,
       RANK() OVER(ORDER BY SUM(od.Quantity * od.UnitPrice) DESC) AS Salesrank
FROM employees e
JOIN orders o 
ON e.employeeID = o.employeeID
JOIN orderdetails od 
ON o.orderID = od.orderID
GROUP BY e.lastname;

-- Q10
-- Sales by Country and Category:
-- Write a query to display the total sales amount for each product category, grouped by country.
SELECT c.Country, cat.CategoryName,
		CONCAT('$', FORMAT(SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)), 2)) AS TotalSales_USD
FROM Customers c
JOIN Orders o
ON c.CustomerID = o.CustomerID
JOIN OrderDetails od
ON o.OrderID = od.OrderID
JOIN Products p
ON od.ProductID = p.ProductID
JOIN Categories cat
ON p.CategoryID = cat.CategoryID
GROUP BY c.Country, cat.CategoryName
ORDER BY c.Country, TotalSales_USD DESC;

-- Q11
-- Year-over-Year Sales Growth:
-- Calculate the percentage growth in sales from one year to the next for each product.
WITH yearly_sales AS (
    SELECT 
        p.ProductName,
        YEAR(o.OrderDate) AS SalesYear,
        SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS TotalSales
    FROM Products p
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o        ON od.OrderID  = o.OrderID
    GROUP BY p.ProductName, YEAR(o.OrderDate)
)
SELECT 
    y1.ProductName,
    y1.SalesYear,
    CONCAT('$', FORMAT(y1.TotalSales, 2)) AS TotalSales_USD,
    CONCAT(ROUND(((y1.TotalSales - y0.TotalSales) / y0.TotalSales) * 100, 2), '%') AS YoYGrowth
FROM yearly_sales y1
LEFT JOIN yearly_sales y0 
    ON y1.ProductName = y0.ProductName AND y1.SalesYear = y0.SalesYear + 1
ORDER BY y1.ProductName, y1.SalesYear;

-- Q12
-- Order Quantity Percentile:
-- Calculate the percentile rank of each order based on the total quantity of products in the order.
WITH order_totals AS (
    SELECT 
        o.OrderID,
        SUM(od.Quantity) AS TotalQuantity
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY o.OrderID
)
SELECT 
    OrderID,
    TotalQuantity,
    ROUND(PERCENT_RANK() OVER (ORDER BY TotalQuantity), 2) AS QuantityPercentile
FROM order_totals
ORDER BY TotalQuantity DESC;

-- Q13
-- Products Never Reordered:
-- Identify products that have been sold but have never been reordered (ordered only once). 
SELECT c.CustomerName,
		o.OrderDate,
		COUNT(DISTINCT(o.OrderID)) AS OrdersOnDate
FROM Customers c
JOIN Orders o 
ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerName, o.OrderDate
HAVING COUNT(DISTINCT(o.OrderID)) = 1
ORDER BY OrdersOnDate DESC;

-- Q14
-- Most Valuable Product by Revenue:
-- Write a query to find the product that has generated the most revenue in each category.
WITH product_revenue AS (
    SELECT 
        cat.CategoryName,
        p.ProductName,
        SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS Revenue
    FROM Products p
    JOIN Categories cat ON p.CategoryID = cat.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    GROUP BY cat.CategoryName, p.ProductName
)
SELECT 
    pr.CategoryName,
    pr.ProductName,
    CONCAT('$', FORMAT(pr.Revenue, 2)) AS TotalRevenue_USD
FROM product_revenue pr
WHERE pr.Revenue = (
    SELECT MAX(r.Revenue)
    FROM product_revenue r
    WHERE r.CategoryName = pr.CategoryName
)
ORDER BY pr.CategoryName;

-- Q15
-- Complex Order Details:
-- Identify orders where the total price of all items exceeds $100 and contains at least one product with a discount of 5% or more.
WITH order_check AS (
    SELECT 
        o.OrderID,
        SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)) AS OrderTotal,
        MAX(od.Discount) AS MaxDiscount
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    GROUP BY o.OrderID
)
SELECT 
    OrderID,
    CONCAT('$', FORMAT(OrderTotal, 2)) AS OrderTotal_USD,
    CONCAT(ROUND(MaxDiscount*100,2), '%') AS MaxDiscountApplied
FROM order_check
WHERE OrderTotal > 100
  AND MaxDiscount >= 0.05
ORDER BY OrderTotal DESC;



