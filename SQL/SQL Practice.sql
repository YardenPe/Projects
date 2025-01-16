--Basic Questions--
--1 Retrieve all customers who made a purchase in 2017, including their name, order number, and order date.
SELECT CONCAT(FirstName,' ',LastName) AS FUll_Name,
	ordernumber,
	orderdate
FROM Sales s
JOIN Customers c
ON s.CustomerKey=c.ID
WHERE YEAR(OrderDate) = 2017
ORDER BY orderdate, FUll_Name;

--2 Find the total revenue (price * quantity) for each product sold in January 2016.
SELECT p.Name,
	SUM(Price*OrderQuantity) AS Total_Revenue
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
WHERE OrderDate BETWEEN '2016-01-01' AND '2016-01-31'
GROUP BY p.Name;

--3 List all products that have never been sold (i.e., do not appear in the Sales table).
SELECT p.ID, p.Name
FROM Products p
LEFT JOIN Sales s
ON p.ID=s.ProductKey
WHERE OrderNumber IS NULL;

--4 Find the total number of orders placed for each region (Region) in 2016
SELECT Region,
	COUNT(DISTINCT OrderNumber) AS orders_num
FROM Territories t
LEFT JOIN Sales s
ON t.ID=s.TerritoryKey
WHERE YEAR(OrderDate) = 2016
GROUP BY Region;

--Intermediate Questions--
--5 Calculate the total sales (OrderQuantity * Price) for each category (CategoryName) in 2017.
SELECT CategoryName,
	SUM(Price*OrderQuantity) AS Total_Sales
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
LEFT JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
LEFT JOIN Categories c
ON c.ID = sb.CategoryKey
WHERE YEAR(OrderDate)=2017
GROUP BY CategoryName;

--6 Find the most popular product in terms of quantity sold in each region.
WITH quantity_per_region AS(
SELECT Region,
	ProductKey,
	SUM(OrderQuantity) AS TotalQuantity,
	ROW_NUMBER() OVER(PARTITION BY Region ORDER BY SUM(OrderQuantity) DESC) AS ranking
FROM Territories t
LEFT JOIN Sales s
ON t.ID=s.TerritoryKey
GROUP BY Region, ProductKey
)
SELECT region,
	ProductKey,
	TotalQuantity
FROM quantity_per_region
WHERE ranking =1;

--7 Retrieve the average price of products sold within each subcategory.
SELECT sb.Name,
	FORMAT(AVG(Price),'C') AS avg_Price
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
JOIN Subcategories sb
ON sb.ID =p.SubcategoryKey 
GROUP BY sb.Name;

--Advanced Questions--
--8 For each month in 2016, calculate the total revenue generated and compare it to the previous month's revenue. 
-- Show the month, total revenue, and difference.
SELECT MONTH(OrderDate) AS 'Month',
	FORMAT(SUM(OrderQuantity*Price),'C') AS Total_Revenue,
	FORMAT(SUM(OrderQuantity*Price) - LAG(SUM(OrderQuantity*Price)) OVER(ORDER BY MONTH(OrderDate)),'C') AS Monthly_Revenue_Diff
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
WHERE YEAR(OrderDate)=2016
GROUP BY MONTH(OrderDate);

--9 Find the top 3 customers in terms of total revenue generated in 2015, including their names and the total amount spent.
SELECT TOP 3 FirstName+' '+LastName AS Full_Name,
	SUM(OrderQuantity*Price) AS Total_Revenue
FROM Sales s
JOIN Customers c
ON s.CustomerKey=c.ID
JOIN Products p
ON s.ProductKey=p.ID
WHERE YEAR(OrderDate)=2015
GROUP BY CustomerKey, FirstName,LastName
ORDER BY Total_Revenue DESC;

--10 Determine the percentage of products returned for each subcategory compared to the total quantity sold in that subcategory.
SELECT sb.Name AS Subcategory, 
	FORMAT(SUM(COALESCE(ReturnQuantity,0))*1.0 / SUM(OrderQuantity),'P') AS Returns_Percentage
FROM Sales s
LEFT JOIN Returns r
ON s.ProductKey=r.ProductKey
JOIN Products p
ON p.ID=s.ProductKey
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
GROUP BY sb.Name

--Practical Business-Oriented Questions--
--11 Calculate the profit (price - cost) for each product and find which product generated the most profit.
SELECT p.Name,
	FORMAT(SUM(OrderQuantity * (Price-Cost)),'C') AS Profit
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
GROUP BY p.ID, p.Name
ORDER BY Profit DESC;

--12 Determine the return rate (quantity returned / quantity sold) for each product.
SELECT p.Name AS Product_Name, 
	FORMAT(SUM(COALESCE(ReturnQuantity,0))*1.0 / SUM(OrderQuantity),'P') AS Returns_Percentage
FROM Sales s
LEFT JOIN Returns r
ON s.ProductKey=r.ProductKey
JOIN Products p
ON p.ID=s.ProductKey
GROUP BY p.ID, p.Name

--13 Find which region generated the highest revenue for each year.
WITH Total_Revenue_cte AS(
SELECT YEAR(OrderDate) AS 'Year',
	Region,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Total_Revenue,
	ROW_NUMBER() OVER(PARTITION BY YEAR(OrderDate) ORDER BY SUM(Price*OrderQuantity) DESC) AS Ranking
FROM Territories t
JOIN Sales s
ON t.ID=s.TerritoryKey
JOIN Products p
ON p.ID=s.ProductKey
GROUP BY YEAR(OrderDate), Region
)
SELECT Year, Region, Total_Revenue
FROM Total_Revenue_cte
WHERE Ranking = 1;

--Window Function Questions--
--14 For each customer, calculate their cumulative spending over time.
SELECT CustomerKey,
	OrderDate,
	FORMAT(SUM(Price*OrderQuantity),'C') AS spending,
	FORMAT(SUM(SUM(Price*OrderQuantity)) OVER(PARTITION BY CustomerKey ORDER BY OrderDate),'C') AS Spending_Over_Time
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
GROUP BY CustomerKey, OrderDate
ORDER BY CustomerKey, OrderDate

--15 Find the product that had the highest weekly sales growth in 2015.
WITH Weekly_Sales AS(
SELECT p.Name AS Product_Name,
	DATEPART(Week, OrderDate) AS Week_Num,
	SUM(OrderQuantity) AS Total_Sales,
	LAG(SUM(OrderQuantity)) OVER(PARTITION BY p.Name ORDER BY DATEPART(Week, OrderDate)) AS Last_Week_Sales
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
GROUP BY p.ID, p.Name, DATEPART(Week, OrderDate)
)
SELECT TOP 1 Product_Name,
	Week_Num,
	Total_Sales - Last_Week_Sales AS Weekly_Sales_Growth
FROM Weekly_Sales
ORDER BY Weekly_Sales_Growth DESC;

--16 Rank all products within each category by their total sales (quantity sold) in descending order.
SELECT CategoryName,
	p.Name AS ProductName,
	SUM(OrderQuantity) AS Total_Sales,
	ROW_NUMBER() OVER(PARTITION BY CategoryName ORDER BY SUM(OrderQuantity) DESC) AS Ranking
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories ca
ON ca.ID=sb.CategoryKEy
GROUP BY CategoryName, p.Name
ORDER BY CategoryName, Ranking

--17 Calculate the rolling 3-month average revenue for each category.
WITH Monthly_Revnue_cte AS(
SELECT CategoryName,
	YEAR(OrderDate) AS 'Year',
	MONTH(OrderDate) AS 'Month',
	SUM(OrderQuantity*Price) AS Monthly_Revnue
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories ca
ON ca.ID=sb.CategoryKEy
GROUP BY CategoryName, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT CategoryName,
	Year,
	Month,
	FORMAT(AVG(Monthly_Revnue) OVER(
		PARTITION BY CategoryName ORDER BY Year, Month
			ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING),'C') AS Rolling_3_Months_Avg
FROM Monthly_Revnue_cte
ORDER BY CategoryName, Year, Month;

--18 Find the top 3 most expensive products in each category based on their price.
WITH cte AS (
SELECT CategoryName,
	p.Name AS Product_Name,
	Price,
	ROW_NUMBER() OVER(PARTITION BY CategoryName ORDER BY Price DESC) AS Ranking
FROM Products p
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID=sb.CategoryKey
)
SELECT CategoryName,
	Product_Name,
	FORMAT(Price,'C') AS Price
FROM cte
WHERE Ranking < 4;

--19 Rank customers based on their total spending in 2015, resetting the rank for each region.
WITH cte AS(
SELECT Region,
	CustomerKey,
	SUM(Price*OrderQuantity) AS Total_Spending
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Territories t
ON t.ID= s.TerritoryKey
WHERE YEAR(OrderDate)=2015
GROUP BY Region, CustomerKey
)
SELECT *,
		ROW_NUMBER() OVER(PARTITION BY region ORDER BY Total_Spending DESC) AS Rank
FROM cte;

--20 For each product, assign a rank based on the total quantity sold, with ties being assigned the same rank.
SELECT ProductKey,
	SUM(OrderQuantity) AS Total_Quantity,
	DENSE_RANK() OVER(ORDER BY SUM(OrderQuantity) DESC) AS Ranking
FROM Sales s
GROUP BY ProductKey

--21 Identify the nth (e.g., 5th) highest-selling product in terms of revenue for each year.
WITH cte AS(
SELECT ProductKey,
	YEAR(OrderDate) AS Year,
	SUM(Price*OrderQuantity) AS Revenue,
	ROW_NUMBER() OVER(PARTITION BY YEAR(OrderDate) ORDER BY SUM(Price*OrderQuantity) DESC) AS Ranking
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
GROUP BY ProductKey, YEAR(OrderDate)
)
SELECT ProductKey, Year, Revenue
FROM cte
WHERE Ranking =5 ;

--22 For each product, calculate the month-over-month change in total sales (quantity sold).
WITH cte AS(
SELECT ProductKey,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SUM(OrderQuantity) AS Quantity_Sold,
	LAG(SUM(OrderQuantity)) OVER(PARTITION BY ProductKey ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS Last_Month
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
GROUP BY ProductKey, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT ProductKey, Year, Month, 
	(Quantity_Sold-Last_Month) AS 'month-over-month change'
FROM cte
ORDER BY ProductKey, Year, Month;

--23 For each customer, find the difference in their spending between their most recent purchase and the previous one.
WITH cte AS(
SELECT CustomerKey,
	OrderDate,
	SUM(OrderQuantity*Price) AS Spending,
	LAG(SUM(OrderQuantity*Price)) OVER(PARTITION BY CustomerKey ORDER BY OrderDate) AS Last_Purchase
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
GROUP BY CustomerKey, OrderDate
)
SELECT CustomerKey, OrderDate, Spending-Last_Purchase AS Diff
FROM cte

--24 Determine the previous and next order date for each customer.
SELECT CustomerKey,
	OrderNumber,
	OrderDate,
	LAG(OrderDate) OVER(PARTITION BY CustomerKey ORDER BY OrderDate) AS Last_Order,
	LEAD(OrderDate) OVER(PARTITION BY CustomerKey ORDER BY OrderDate) AS Next_Order
FROM Sales
GROUP BY CustomerKey, OrderNumber, OrderDate

--25 For each category, identify the product with the largest positive or negative week-over-week revenue change.
WITH cte AS (
SELECT CategoryKey,
	P.Name AS Product_Name,
	DATEPART(Week, OrderDate) AS Week,
	SUM(Price*OrderQuantity) AS Revenue,
	LAG(SUM(Price*OrderQuantity)) OVER(PARTITION BY CategoryKey, P.Name ORDER BY DATEPART(Week, OrderDate)) AS Last_Week
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
GROUP BY CategoryKey, P.Name, DATEPART(Week, OrderDate)
), cte2 AS(
SELECT CategoryKey,
	Product_Name,
	Week,
	LAG(Week) OVER(PARTITION BY CategoryKey, Product_Name ORDER BY Week) AS Last_Week_Date,
	Revenue,
	Revenue - Last_Week AS Revenue_Change,
	ROW_NUMBER() OVER(PARTITION BY CategoryKey ORDER BY ABS(Revenue - Last_Week) DESC) AS Ranking
FROM cte
)
SELECT CategoryKey,
	Product_Name,
	Week,
	FORMAT(Revenue_Change,'C') AS Revenue_Change
FROM cte2
WHERE (Week - Last_Week_Date) = 1
	AND Ranking = 1
ORDER BY CategoryKey, Product_Name, Week

--26 Find customers who purchased a product and then returned it within the following week.
SELECT 
    s.CustomerKey,
    s.ProductKey,
    s.OrderDate AS PurchaseDate,
    r.ReturnDate
FROM Sales s
JOIN Returns r
    ON s.ProductKey = r.ProductKey
    AND r.ReturnDate >= s.OrderDate
    AND DATEDIFF(DAY, s.OrderDate, r.ReturnDate) <= 7;

--27 Divide products into 4 quartiles based on their total revenue across all years.
SELECT p.ID AS Product,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Revenue,
	NTILE(4) OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Revenue_Quarters
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
GROUP BY p.ID
ORDER BY Revenue_Quarters;

--28 Split customers into 5 equal-sized groups based on their total spending and identify which quartile each customer belongs to.
SELECT s.CustomerKey AS Customer,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Spending,
	NTILE(5) OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Spending_Quarters
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
GROUP BY s.CustomerKey
ORDER BY Spending_Quarters;

--29 Divide months of the year into 3 equal groups based on total sales revenue and identify the range of revenue for each group.
WITH Revenue_Per_Month AS(
SELECT YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Revenue
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
), Revenue_Group AS(
SELECT *,
	NTILE(3) OVER(PARTITION BY Year ORDER BY Revenue DESC) AS Revenue_Group
FROM Revenue_Per_Month
), RevenueRange AS (
SELECT 
	Year,
	Revenue_Group,
    MIN(Revenue) AS Min_Revenue,
    MAX(Revenue) AS Max_Revenue
FROM Revenue_Group
GROUP BY Year, Revenue_Group
)
SELECT Revenue_Group.Year, 
	Revenue_Group.Month,
	Revenue_Group.Revenue,
	Revenue_Group.Revenue_Group,
	CONCAT(RevenueRange.Min_Revenue,'-',RevenueRange.Max_Revenue) AS Revenue_Range
FROM Revenue_Group
JOIN RevenueRange
ON Revenue_Group.Year = RevenueRange.Year
	AND Revenue_Group.Revenue_Group = RevenueRange.Revenue_Group
ORDER BY Year, Month;

--30 Calculate the cumulative total revenue for each category across months in 2015.
SELECT CategoryKey,
	MONTH(OrderDate) AS Month,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Revenue,
	FORMAT(SUM(SUM(Price*OrderQuantity)) OVER(ORDER BY MONTH(OrderDate)),'C') AS Commulative_Revenue
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
JOIN Subcategories sb
ON sb.ID =p.SubcategoryKey 
WHERE YEAR(OrderDate) = 2015
GROUP BY CategoryKey, MONTH(OrderDate)

--31 Find the rolling 6-month average revenue for each region.
WITH cte AS(
	SELECT 
	Region,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Revenue
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
JOIN Territories t
ON t.ID =s.TerritoryKey 
GROUP BY Region, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT 
	Region,
	Year,
	Month,
	FORMAT(Revenue,'C') AS Revenue,
	FORMAT(AVG(Revenue) OVER(
			PARTITION BY Region 
			ORDER BY Year, Month
			ROWS BETWEEN 5 PRECEDING AND CURRENT ROW),'C') AS Rolling_6_Months_Avg
FROM cte
ORDER BY Region, Year, Month;

--32 For each product, calculate the percentage of total revenue it contributed to its category.
WITH cte AS(
SELECT sb.CategoryKey AS Category,
	p.ID AS Product,
	SUM(Price*OrderQuantity) AS Product_Revenue,
	SUM(SUM(Price*OrderQuantity)) OVER(PARTITION BY CategoryKey) AS Category_Revenue
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
JOIN Subcategories sb
ON sb.ID =p.SubcategoryKey 
GROUP BY sb.CategoryKey, p.ID
)
SELECT Category,
	Product,
	FORMAT(Product_Revenue, 'C') AS Product_Revenue, 
	FORMAT(Product_Revenue/Category_Revenue,'P') AS 'percentage of total revenue'
FROM cte
ORDER BY Category, 'percentage of total revenue' DESC

--33 Identify the year-month with the highest revenue for each category and calculate its percentage contribution to the yearly revenue.
WITH cte AS(
SELECT sb.CategoryKey AS Category,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Monthly_Revenue,
	SUM(SUM(Price*OrderQuantity)) OVER(PARTITION BY YEAR(OrderDate)) AS Yearly_Revenue
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
JOIN Subcategories sb
ON sb.ID =p.SubcategoryKey 
GROUP BY sb.CategoryKey, YEAR(OrderDate), MONTH(OrderDate)
), Highest_Revenue AS(
SELECT Category,
	MAX(Monthly_Revenue) AS Highest_Month_Revenue
FROM cte
GROUP BY Category
)
SELECT hr.Category,
	Year,
	Month,
	Monthly_Revenue,
	FORMAT(Monthly_Revenue/Yearly_Revenue,'P') AS 'percentage of Yearly revenue'
FROM cte
JOIN Highest_Revenue AS hr
ON cte.Category = hr.Category
	AND cte.Monthly_Revenue=hr.Highest_Month_Revenue
ORDER BY Category;

--34 Identify the month with the highest revenue for each category and calculate its percentage contribution to the the overall revenue.
WITH cte AS(
SELECT sb.CategoryKey AS Category,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Monthly_Revenue,
	SUM(SUM(Price*OrderQuantity)) OVER(PARTITION BY CategoryKey) AS Category_Revenue
FROM Sales s
JOIN Products p
ON p.ID=s.ProductKey
JOIN Subcategories sb
ON sb.ID =p.SubcategoryKey 
GROUP BY sb.CategoryKey, MONTH(OrderDate)
), Highest_Revenue AS(
SELECT Category,
	MAX(Monthly_Revenue) AS Highest_Month_Revenue
FROM cte
GROUP BY Category
)
SELECT hr.Category,
	Month,
	Monthly_Revenue,
	FORMAT(Monthly_Revenue/Category_Revenue,'P') AS 'percentage of Yearly revenue'
FROM cte
JOIN Highest_Revenue AS hr
ON cte.Category = hr.Category
	AND cte.Monthly_Revenue=hr.Highest_Month_Revenue
ORDER BY Category;

--35 For each customer, calculate their cumulative total orders and compare it to their overall total orders.
SELECT CustomerKey,
	OrderDate,
	SUM(COUNT(OrderNumber)) OVER(PARTITION BY CustomerKey ORDER BY OrderDate) AS 'cumulative total orders',
	SUM(COUNT(OrderNumber)) OVER(PARTITION BY CustomerKey) AS 'overall total orders'
FROM Sales
GROUP BY CustomerKey, OrderDate;

--36 Write a query to calculate total revenue for each category, subcategory, and a grand total.
SELECT ISNULL(CategoryName,'--GRAND TOTAL--') AS Category,
	ISNULL(sb.Name,'--TOTAL--') AS Subcategory,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Revenue
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories ca
ON ca.ID=sb.CategoryKey
GROUP BY CategoryName, sb.Name
WITH ROLLUP;

--37 Write a query to calculate total revenue for each category and region combination, including subtotals for each category, each region, and a grand total.
SELECT ISNULL(CategoryName,'--TOTAL--') AS Category,
	ISNULL(Region,'--TOTAL--') AS Region,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Revenue
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories ca
ON ca.ID=sb.CategoryKey
JOIN Territories t
ON t.ID=s.TerritoryKey
GROUP BY CategoryName, Region
WITH CUBE;

--38 Retrieve the top 10% of customers based on their total spending in 2016.
SELECT TOP 10 PERCENT c.ID,
	CONCAT(c.FirstName +' ',c.LastName) AS Full_Name,
	SUM(Price*OrderQuantity) AS Spending
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Customers c
ON s.CustomerKey=c.ID
WHERE YEAR(OrderDate) =2016
GROUP BY c.ID, c.FirstName,c.LastName
ORDER BY Spending DESC;

--39 Retrieve the top 5 customers based on their total revenue, but include ties for the 5th place.
SELECT TOP 5 WITH TIES
	c.ID,
	CONCAT(c.FirstName +' ',c.LastName) AS Full_Name,
	SUM(Price*OrderQuantity) AS Spending
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Customers c
ON s.CustomerKey=c.ID
GROUP BY c.ID, c.FirstName,c.LastName
ORDER BY Spending DESC;

--40 Write a query to retrieve the 6th to 10th highest-spending customers in 2015.
SELECT c.ID,
	CONCAT(c.FirstName +' ',c.LastName) AS Full_Name,
	SUM(Price*OrderQuantity) AS Spending
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Customers c
ON s.CustomerKey=c.ID
GROUP BY c.ID, c.FirstName,c.LastName
ORDER BY Spending DESC
	OFFSET 5 ROWS
	FETCH NEXT 5 ROWS ONLY; 

--41 Find all products whose names start with a letter in the range A-C.
SELECT c.ID,
	CONCAT(c.FirstName +' ',c.LastName) AS Full_Name
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Customers c
ON s.CustomerKey=c.ID
WHERE FirstName LIKE '[A-C]%'

--42 Retrieve all subcategories whose names do not start with A or B. (^)
SELECT c.ID,
	CONCAT(c.FirstName +' ',c.LastName) AS Full_Name
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Customers c
ON s.CustomerKey=c.ID
WHERE FirstName NOT LIKE '[A-B]%'

--43 Rank customers based on their total revenue, with ties receiving the same rank (RANK)
SELECT c.ID,
	SUM(Price*OrderQuantity) AS Revenue,
	RANK() OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Ranking
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Customers c
ON s.CustomerKey=c.ID
GROUP BY c.ID;

--44 Rank customers based on their total revenue, ensuring no gaps in ranking for ties (DENSE_RANK)
SELECT c.ID,
	SUM(Price*OrderQuantity) AS Revenue,
	DENSE_RANK() OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Ranking
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
JOIN Customers c
ON s.CustomerKey=c.ID
GROUP BY c.ID;

--45 Divide all products into 4 equal groups (quartiles) based on their total revenue.
SELECT p.ID,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Revenue,
	NTILE(4) OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Revenue_Group
FROM Sales s
JOIN Products p
ON p.ID = s.ProductKey
GROUP BY p.ID;

--46 Calculate the rolling 3-month average revenue for each category.
WITH cte AS(
SELECT CategoryName,
	YEAR(OrderDate) AS year,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Revenue
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
LEFT JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
LEFT JOIN Categories c
ON c.ID = sb.CategoryKey
GROUP BY CategoryName, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT *,
	AVG(Revenue) OVER(
		PARTITION BY CategoryName ORDER BY Year, Month
		ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) AS Rolling_3_Months_Avg
FROM cte;

--47 Create a pivot table to display total revenue for each category across each year.
SELECT CategoryName,
	SUM(CASE WHEN YEAR(OrderDate) = 2015 THEN Price*OrderQuantity ELSE 0 END) AS '2015',
	SUM(CASE WHEN YEAR(OrderDate) = 2016 THEN Price*OrderQuantity ELSE 0 END) AS '2016',
	SUM(CASE WHEN YEAR(OrderDate) = 2017 THEN Price*OrderQuantity ELSE 0 END) AS '2017'
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID = sb.CategoryKey
GROUP BY CategoryName
ORDER BY CategoryName;

--48 Create a pivot table to display the total quantity of products sold for each subcategory across each quarter of 2016.
SELECT Sb.Name,
	SUM(CASE WHEN DATEPART(Q, OrderDate)=1 THEN OrderQuantity ELSE 0 END) AS 'Q1-2016',
	SUM(CASE WHEN DATEPART(Q, OrderDate)=2 THEN OrderQuantity ELSE 0 END) AS 'Q2-2016',
	SUM(CASE WHEN DATEPART(Q, OrderDate)=3 THEN OrderQuantity ELSE 0 END) AS 'Q3-2016',
	SUM(CASE WHEN DATEPART(Q, OrderDate)=4 THEN OrderQuantity ELSE 0 END) AS 'Q4-2016'
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
GROUP BY sb.Name
ORDER BY sb.Name;

--49 Create a pivot table to display the total revenue generated by each region for each product category across all years.
SELECT Region,
	SUM(CASE WHEN c.CategoryName = 'Bikes' THEN Price*OrderQuantity ELSE 0 END) AS 'Bikes',
	SUM(CASE WHEN c.CategoryName = 'Accessories' THEN Price*OrderQuantity ELSE 0 END) AS 'Accessories',
	SUM(CASE WHEN c.CategoryName = 'Clothing' THEN Price*OrderQuantity ELSE 0 END) AS 'Clothing'
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID = sb.CategoryKey
JOIN Territories t
ON t.ID=s.TerritoryKey
GROUP BY Region
ORDER BY Region;

--50 Find the average time between orders for each customer.
WITH cte AS(
SELECT CustomerKey,
	OrderDate,
	LAG(OrderDate) OVER(PARTITION BY CustomerKey ORDER BY OrderDate) AS Last_Order_Date,
	DATEDIFF(DAY, LAG(OrderDate) OVER(PARTITION BY CustomerKey ORDER BY OrderDate), OrderDate) AS Diff
FROM Sales s
)
SELECT CustomerKey,
	AVG(Diff) AS DayDiff
FROM cte
WHERE Diff IS NOT NULL
GROUP BY CustomerKey
ORDER BY DayDiff DESC;
	
--51 Calculate the year-over-year growth in total revenue for each category.
WITH cte AS(
SELECT CategoryName,
	YEAR(OrderDate) AS Year,
	SUM(Price*OrderQuantity) AS Revenue,
	LAG(SUM(Price*OrderQuantity)) OVER(PARTITION BY CategoryName ORDER BY YEAR(OrderDate)) AS Last_Year
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID = sb.CategoryKey
GROUP BY CategoryName, YEAR(OrderDate)
)
SELECT CategoryName,
	Year,
	FORMAT(Revenue,'C') AS Revenue,
	FORMAT(Revenue/Last_Year -1,'P') AS Growth_In_Revenue
FROM cte;

--52 Determine the cumulative number of orders placed by each customer, partitioned by year.
SELECT CustomerKey,
	YEAR(OrderDate) AS Year,
	SUM(OrderQuantity) AS Yearly_Quantity,
	SUM(SUM(OrderQuantity)) OVER(PARTITION BY CustomerKey ORDER BY YEAR(OrderDate)) AS 'cumulative number of orders'
FROM Sales
GROUP BY CustomerKey, YEAR(OrderDate)
ORDER BY CustomerKey, YEAR(OrderDate)

--53  Identify products that consistently rank in the top 3 for total revenue across all months in 2015.
WITH cte AS(
SELECT ProductKey,
	MONTH(OrderDate) AS Month,
	SUM(p.Price*OrderQuantity) AS Revenue,
	DENSE_RANK() OVER(PARTITION BY MONTH(OrderDate) ORDER BY SUM(Price*OrderQuantity) DESC) AS Ranking
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
WHERE YEAR(OrderDate) = 2015
GROUP BY ProductKey, MONTH(OrderDate)
)
SELECT ProductKey,
	COUNT(Month) AS Num_Months_Rank_Top_3
FROM cte
WHERE Ranking < 4
GROUP BY ProductKey
ORDER BY Num_Months_Rank_Top_3 DESC;

--54 For each region, calculate the running total and the percentage of cumulative revenue compared to the region's total revenue.
WITH cte AS(
SELECT Region,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Revenue
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID = sb.CategoryKey
JOIN Territories t
ON t.ID=s.TerritoryKey
GROUP BY Region, MONTH(OrderDate)
), Total_Revenue_By_Region AS(
SELECT Region,
	SUM(Price*OrderQuantity) AS Region_Revenue
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID = sb.CategoryKey
JOIN Territories t
ON t.ID=s.TerritoryKey
GROUP BY Region
)
SELECT cte.Region,
	cte.Month,
	FORMAT(cte.Revenue,'C') AS Revenue,
	FORMAT(SUM(Revenue) OVER(PARTITION BY cte.Region ORDER BY Month),'C') AS 'Cumulative Revenue',
	FORMAT(SUM(Revenue) OVER(PARTITION BY cte.Region ORDER BY Month) / Region_Revenue,'P') AS 'Percentage Compared To Region'
FROM cte
JOIN Total_Revenue_By_Region
ON cte.Region=Total_Revenue_By_Region.Region
ORDER BY cte.Region, cte.Month;

--55 For each product, calculate the rolling 12-week total sales and highlight products that show a growth trend for three consecutive weeks.
WITH Product_Sales AS(
SELECT ProductKey,
	DATEPART(Week, OrderDate) AS Week,
	SUM(OrderQuantity) AS Total_Sales
FROM Sales
GROUP BY ProductKey, YEAR(OrderDate), DATEPART(Week, OrderDate)
), week_12_sales AS(
SELECT *,
	SUM(Total_Sales) OVER(
		PARTITION BY ProductKey ORDER BY Week
		ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS '12-week total sales',
	(CASE WHEN Total_Sales - LAG(Total_Sales) OVER(PARTITION BY ProductKEy ORDER BY Week)>0 THEN 1 ELSE 0 END) AS Abs_Diff
FROM Product_Sales
), Growth_Trend_cte AS(
SELECT *,
	SUM(Abs_Diff) OVER(
		PARTITION BY ProductKey ORDER BY Week
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Growth_Trend
FROM week_12_sales
)
SELECT *,
	(CASE WHEN Growth_Trend = 3 THEN 'STRIKE' ELSE NULL END) AS 'Selling Product'
FROM Growth_Trend_cte
ORDER BY ProductKey, Week

-- Another Way --
WITH WeeklySales AS (
    SELECT 
        p.ID AS ProductID,
        DATEPART(YEAR, s.OrderDate) AS Year,
        DATEPART(WEEK, s.OrderDate) AS Week,
        SUM(s.OrderQuantity) AS TotalSales
    FROM Sales s
    JOIN Products p
        ON s.ProductKey = p.ID
    GROUP BY p.ID, DATEPART(YEAR, s.OrderDate), DATEPART(WEEK, s.OrderDate)
),
RollingSales AS (
    SELECT 
        ProductID,
        Year,
        Week,
        SUM(TotalSales) OVER (
            PARTITION BY ProductID 
            ORDER BY Year, Week 
            ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ) AS Rolling12WeekSales
    FROM WeeklySales
),
GrowthTrend AS (
    SELECT 
        ProductID,
        Year,
        Week,
        Rolling12WeekSales,
        CASE 
            WHEN Rolling12WeekSales > LAG(Rolling12WeekSales) OVER (
                PARTITION BY ProductID 
                ORDER BY Year, Week
            ) 
            AND LAG(Rolling12WeekSales) OVER (
                PARTITION BY ProductID 
                ORDER BY Year, Week
            ) > LAG(Rolling12WeekSales, 2) OVER (
                PARTITION BY ProductID 
                ORDER BY Year, Week
            ) 
            AND LAG(Rolling12WeekSales, 2) OVER (
                PARTITION BY ProductID 
                ORDER BY Year, Week
            ) > LAG(Rolling12WeekSales, 3) OVER (
                PARTITION BY ProductID 
                ORDER BY Year, Week
            )
            THEN 1 ELSE 0 
        END AS GrowthTrendFlag
    FROM RollingSales
)
SELECT DISTINCT 
    ProductID
FROM GrowthTrend
WHERE GrowthTrendFlag = 1
ORDER BY ProductID;

--56 For each subcategory, calculate the minimum and maximum revenue in a year and identify the months in which these occurred.
WITH cte AS(
SELECT sb.Name AS Subcategory,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Revenue
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID = sb.CategoryKey
GROUP BY sb.Name, YEAR(OrderDate), MONTH(OrderDate)
), Min_Max_Revenue AS(
SELECT Subcategory,
	Year,
	MIN(Revenue) OVER(PARTITION BY Subcategory, Year) AS Min_Revenue,
	MAX(Revenue) OVER(PARTITION BY Subcategory, Year) AS Max_Revenue
FROM cte	
)
SELECT DISTINCT
	cte.Subcategory,
	cte.Year,
	cte.Month,
	cte.Revenue,
	CONCAT(mm.Min_Revenue,'-',mm.Max_Revenue) AS Range
FROM cte
JOIN Min_Max_Revenue mm
ON cte.Subcategory = mm.Subcategory
AND cte.Year = mm.Year
WHERE cte.Revenue = mm.Min_Revenue OR cte.Revenue = mm.Max_Revenue

--57 For each product, determine how often it was the best-selling product in its category over all weeks in 2015.
WITH Weeks_cte AS(
SELECT CategoryKey,
	ProductKey,
	DATEPART(Week, OrderDate) AS Week,
	SUM(OrderQuantity) AS Total_Quantity
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
WHERE YEAR(OrderDate) = 2016
GROUP BY CategoryKey, ProductKey, DATEPART(Week, OrderDate)
), Ranked_cte AS(
SELECT *,
	RANK() OVER(PARTITION BY CategoryKey, Week ORDER BY Total_Quantity DESC) AS Ranking
FROM Weeks_cte
)
SELECT CategoryKey,
	ProductKey,
	COUNT(Week) AS 'best-selling product in its category'
FROM Ranked_cte
WHERE Ranking=1
GROUP BY CategoryKey, ProductKey
ORDER BY CategoryKey;

--58 Compare the growth rates of two regions by calculating their cumulative monthly revenues using SUM() with OVER().
WITH cte AS(
SELECT Region,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Revenue,
	SUM(SUM(Price*OrderQuantity)) OVER(PARTITION BY Region ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS 'Cumulative_Monthly_Revenue'
FROM Territories t
LEFT JOIN Sales s
ON t.ID=s.TerritoryKey
JOIN Products p
ON s.ProductKey = p.ID
WHERE Region IN ('Australia','Southwest')
GROUP BY Region, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT Year, Month,
	MAX(CASE WHEN Region = 'Australia' THEN (Revenue/Cumulative_Monthly_Revenue-1) END) AS AU_Growth_Rate,
	MAX(CASE WHEN Region = 'Southwest' THEN (Revenue/Cumulative_Monthly_Revenue-1) END) AS SW_Growth_Rate
FROM cte
GROUP BY Year, Month
ORDER BY Year, Month;

--59 For each product, find the first and last month it was sold in 2015.
WITH cte AS(
SELECT ProductKey,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month
FROM Sales 
WHERE YEAR(OrderDate)=2015
GROUP BY ProductKey, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT ProductKey,
	MIN(Month) AS First_Month,
	MAX(Month) AS Last_Month
FROM cte
GROUP BY ProductKey

--60 Calculate the total revenue for each region and product category, including subtotals for each region and a grand total.
SELECT ISNULL(Region,'Total') AS Region,
	ISNULL(CAST(CategoryKey AS VARCHAR),'Total') AS CategoryKey,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Revenue
FROM Territories t
LEFT JOIN Sales s
ON t.ID=s.TerritoryKey
JOIN Products p
ON s.ProductKey = p.ID
JOIN Subcategories sb
ON sb.ID = p.SubcategoryKey
GROUP BY Region, CategoryKey
WITH ROLLUP;

--61 For each customer, compute the total quantity of products they purchased, and include subtotals for each region.
SELECT Region,
	CustomerKey,
	SUM(OrderQuantity) AS Total_Quantity
FROM Territories t
LEFT JOIN Sales s
ON t.ID=s.TerritoryKey
GROUP BY Region, CustomerKey
WITH ROLLUP;

--61 Calculate the total sales for each combination of region, category, and product, including all possible subtotal combinations (e.g., region+category, category+product).
SELECT Region,
	CategoryKey,
	ProductKey,
	SUM(Price*OrderQuantity) AS Revenue
FROM Territories t
LEFT JOIN Sales s
ON t.ID=s.TerritoryKey
JOIN Products p
ON s.ProductKey = p.ID
JOIN Subcategories sb
ON sb.ID = p.SubcategoryKey
GROUP BY Region, CategoryKey, ProductKey
WITH CUBE;

--62 Generate a report that shows total revenue for combinations of year, month, and product category, including subtotals at each level.
SELECT YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	CategoryKey,
	SUM(Price*OrderQuantity) AS Revenue
FROM Sales s
JOIN Products p
ON s.ProductKey = p.ID
JOIN Subcategories sb
ON sb.ID = p.SubcategoryKey
GROUP BY YEAR(OrderDate), MONTH(OrderDate), CategoryKey
WITH CUBE;

--63 Retrieve the top 10% of products based on total sales in 2016.
SELECT TOP 10 PERCENT 
	ProductKey,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Total_Sales
FROM Sales s
JOIN Products p
ON s.ProductKey = p.ID
WHERE YEAR(OrderDate) = 2016
GROUP BY ProductKey
ORDER BY Total_Sales DESC

--PERCENT_RANK-- WHY NOT TOP 20 PERCENT?
--64 Find the top 20% of customers by total spending, but include ties where spending is the same.
WITH CustomerSpending AS (
    SELECT 
        CustomerKey,
        SUM(Price * OrderQuantity) AS Total_Spending
    FROM Sales s
    JOIN Products p
        ON s.ProductKey = p.ID
    GROUP BY CustomerKey
),
SpendingWithRank AS (
    SELECT 
        CustomerKey,
        Total_Spending,
        PERCENT_RANK() OVER (ORDER BY Total_Spending DESC) AS SpendingRank
    FROM CustomerSpending
	ORDER BY SpendingRank
)
SELECT 
    CustomerKey,
    FORMAT(Total_Spending, 'C') AS Total_Spending
FROM SpendingWithRank
WHERE SpendingRank <= 0.2 -- Top 20%
ORDER BY Total_Spending DESC;

--65 Identify the top 5 customers with the highest revenue, ensuring all ties are included if multiple customers have the same revenue as the 5th-ranked customer.
SELECT TOP 5 WITH TIES
	CustomerKey,
	SUM(Price * OrderQuantity) AS Total_Spending
FROM Sales s
JOIN Products p
ON s.ProductKey = p.ID
GROUP BY CustomerKey
ORDER BY Total_Spending DESC;

--66 Retrieve the 11th to 20th most popular products (based on sales) in 2016.
SELECT ProductKey,
	SUM(Price*OrderQuantity) AS Total_Sales
FROM Sales s
JOIN Products p
ON s.ProductKey = p.ID
WHERE YEAR(OrderDate) = 2016
GROUP BY ProductKey
ORDER BY Total_Sales DESC
	OFFSET 10 ROWS
	FETCH NEXT 10 ROWS ONLY;

--67 Get the 2nd and 3rd highest revenue-generating months for a specific region.
SELECT MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Total_Sales
FROM Territories t
JOIN Sales s
ON t.ID=s.TerritoryKey
JOIN Products p
ON s.ProductKey = p.ID
WHERE Region='Australia'
GROUP BY MONTH(OrderDate)
ORDER BY Total_Sales DESC
	OFFSET 1 ROWS
	FETCH NEXT 2 ROWS ONLY;

--68 Create a pivot table to display total sales revenue for each category across each quarter of 2016.
SELECT CategoryKey,
	SUM(CASE WHEN DATEPART(QQ, OrderDate) = 01 THEN Price*OrderQuantity ELSE 0 END) AS 'Q1',
	SUM(CASE WHEN DATEPART(QQ, OrderDate) = 02 THEN Price*OrderQuantity ELSE 0 END) AS 'Q2',
	SUM(CASE WHEN DATEPART(QQ, OrderDate) = 03 THEN Price*OrderQuantity ELSE 0 END) AS 'Q3',
	SUM(CASE WHEN DATEPART(QQ, OrderDate) = 04 THEN Price*OrderQuantity ELSE 0 END) AS 'Q4'
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
WHERE YEAR(OrderDate) = 2016
GROUP BY CategoryKey;

--69 Create a pivot table showing the total quantity sold for each product in each month of 2015.
SELECT p.Name,
    SUM(CASE WHEN MONTH(s.OrderDate) = 1 THEN s.OrderQuantity ELSE 0 END) AS Jan,
    SUM(CASE WHEN MONTH(s.OrderDate) = 2 THEN s.OrderQuantity ELSE 0 END) AS Feb,
    SUM(CASE WHEN MONTH(s.OrderDate) = 3 THEN s.OrderQuantity ELSE 0 END) AS Mar,
    SUM(CASE WHEN MONTH(s.OrderDate) = 4 THEN s.OrderQuantity ELSE 0 END) AS Apr,
    SUM(CASE WHEN MONTH(s.OrderDate) = 5 THEN s.OrderQuantity ELSE 0 END) AS May,
    SUM(CASE WHEN MONTH(s.OrderDate) = 6 THEN s.OrderQuantity ELSE 0 END) AS Jun,
    SUM(CASE WHEN MONTH(s.OrderDate) = 7 THEN s.OrderQuantity ELSE 0 END) AS Jul,
    SUM(CASE WHEN MONTH(s.OrderDate) = 8 THEN s.OrderQuantity ELSE 0 END) AS Aug,
    SUM(CASE WHEN MONTH(s.OrderDate) = 9 THEN s.OrderQuantity ELSE 0 END) AS Sep,
    SUM(CASE WHEN MONTH(s.OrderDate) = 10 THEN s.OrderQuantity ELSE 0 END) AS Oct,
    SUM(CASE WHEN MONTH(s.OrderDate) = 11 THEN s.OrderQuantity ELSE 0 END) AS Nov,
    SUM(CASE WHEN MONTH(s.OrderDate) = 12 THEN s.OrderQuantity ELSE 0 END) AS Dec
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
WHERE YEAR(OrderDate) = 2015
GROUP BY p.Name;

--70 Divide customers into 4 quartiles based on their total spending in 2015 and identify the range of spending for each quartile.
WITH cte AS(
SELECT CustomerKey,
	SUM(Price*OrderQuantity) AS Total_Spending,
	NTILE(4) OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Quartiles
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
WHERE YEAR(OrderDate) = 2015
GROUP BY CustomerKey
)
SELECT *,
CONCAT(MIN(Total_Spending) OVER(PARTITION BY Quartiles),'-',MAX(Total_Spending) OVER(PARTITION BY Quartiles)) AS Range
FROM cte;

--71 Rank products into 5 groups based on their revenue and calculate the total revenue for each group.
WITH cte AS(
SELECT ProductKey,
	SUM(Price*OrderQuantity) AS Revenue,
	NTILE(5) OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Revenue_Groups
FROM Sales s
JOIN Products p
ON s.ProductKey=p.ID
GROUP BY ProductKey
)
SELECT *,
CONCAT(MIN(Revenue) OVER(PARTITION BY Revenue_Groups),'-',MAX(Revenue) OVER(PARTITION BY Revenue_Groups)) AS Range
FROM cte;

--72 Calculate the rolling 3-month average revenue for each region.
WITH cte AS(
SELECT Region,
	YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Revenue
FROM Territories t
JOIN Sales s
ON t.ID=s.TerritoryKey
JOIN Products p
ON p.ID = s.ProductKey
GROUP BY Region, YEAR(OrderDate), MONTH(OrderDate)
)
SELECT *,
	AVG(Revenue) OVER(
	PARTITION BY Region ORDER BY Year, Month
	ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS 'Rolling 3-Month Average Revenue'
FROM cte;

--73 For each product, calculate the total sales in the current and the next two weeks.
WITH cte AS(
SELECT p.Name,
	YEAR(OrderDate) AS Year,
	DATEPART(Week, OrderDate) AS Week,
	SUM(Price*OrderQuantity) AS Revenue
FROM Territories t
JOIN Sales s
ON t.ID=s.TerritoryKey
JOIN Products p
ON p.ID = s.ProductKey
GROUP BY p.Name, YEAR(OrderDate), DATEPART(Week, OrderDate)
)
SELECT *,
	SUM(Revenue) OVER(
	PARTITION BY Name ORDER BY Year, Week
	ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING) AS 'Rolling 3-Month Total Revenue'
FROM cte;

--74 Use `OFFSET` and `FETCH` to paginate through a list of customers, sorted by their total spending.
WITH CustomerSpending AS (
    SELECT 
        CustomerKey,
        CONCAT(FirstName, ' ', LastName) AS FullName,
        SUM(Price * OrderQuantity) AS TotalSpending
    FROM Sales s
    JOIN Customers c
        ON s.CustomerKey = c.ID
    JOIN Products p
        ON s.ProductKey = p.ID
    GROUP BY CustomerKey, FirstName, LastName
)
SELECT 
    CustomerKey,
    FullName,
    TotalSpending
FROM CustomerSpending
ORDER BY TotalSpending DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

--75 Create a pivot table to compare the total revenue for each product category across years, including a column for year-over-year growth.
WITH cte AS(
SELECT YEAR(OrderDate) AS Year,
	SUM(CASE WHEN CategoryName='Bikes' THEN Price*OrderQuantity ELSE 0 END) AS 'Bikes_Revenue',
	SUM(CASE WHEN CategoryName='Accessories' THEN Price*OrderQuantity ELSE 0 END) AS 'Accessories_Revenue',
	SUM(CASE WHEN CategoryName='Clothing' THEN Price*OrderQuantity ELSE 0 END) AS 'Clothing_Revenue'
FROM Sales s
JOIN Products p
ON s.ProductKey = p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID=sb.CategoryKey
GROUP BY YEAR(OrderDate)
)
SELECT *,
	FORMAT(Bikes_Revenue*1.0/LAG(Bikes_Revenue) OVER(ORDER BY Year)-1,'P') AS 'Bikes_YoY_Growth',
    FORMAT(Accessories_Revenue*1.0  / NULLIF(LAG(Accessories_Revenue) OVER (ORDER BY Year), 0), 'P') AS Accessories_YoY_Growth,
    FORMAT(Clothing_Revenue*1.0  / NULLIF(LAG(Clothing_Revenue) OVER (ORDER BY Year), 0), 'P') AS Clothing_YoY_Growth
FROM cte
ORDER BY Year;

--76 Divide months into 3 equal groups based on revenue (NTILE) and use aggregate window functions to calculate the rolling 6-rows average revenue for each group.
WITH cte AS(
SELECT YEAR(OrderDate) AS Year,
	MONTH(OrderDate) AS Month,
	SUM(Price*OrderQuantity) AS Revenue,
	NTILE(3) OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Groups
FROM Sales s
JOIN Products p
ON s.ProductKey = p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID=sb.CategoryKey
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT *,
	AVG(Revenue) OVER(
	PARTITION BY Groups
	ORDER BY Year, Month
	ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
	) AS Rolling_Rows_Group_Avg
FROM cte;

--77 Find the percentile rank of products based on their total revenue in 2021. Then, categorize products into three groups:
-- Top 20% (High Revenue).
-- Middle 60% (Medium Revenue).
-- Bottom 20% (Low Revenue).
WITH cte AS(
SELECT p.ID,
	p.Name,
	FORMAT(SUM(Price*OrderQuantity),'C') AS Total_Revenue,
	PERCENT_RANK() OVER(ORDER BY SUM(Price*OrderQuantity) DESC) AS Percentile_Rank
FROM Sales s
JOIN Products p
ON s.ProductKey = p.ID
JOIN Subcategories sb
ON sb.ID=p.SubcategoryKey
JOIN Categories c
ON c.ID=sb.CategoryKey 
WHERE YEAR(OrderDate) = 2016
GROUP BY p.ID, p.Name
)
SELECT *,
	CASE 
		WHEN Percentile_Rank < 0.2 THEN 'High'
		WHEN Percentile_Rank > 0.8 THEN 'LOW'
		ELSE 'Medium' 
		END AS 'RevenueCategory'
FROM cte
ORDER BY Percentile_Rank;


