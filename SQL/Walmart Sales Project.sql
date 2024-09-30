CREATE DATABASE IF NOT EXISTS salesDataWalmart;

CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
	product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12, 4),
    rating FLOAT(2, 1)
);

SELECT * FROM sales;

-------------------------------- Feature Engineering -------------------------------------------------
-- time_of_date
SELECT time,
	(CASE 
		WHEN time BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN time BETWEEN "12:00:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END
    ) AS time_of_date
FROM sales;

ALTER TABLE sales ADD COLUMN time_of_date VARCHAR(20);

UPDATE sales 
SET time_of_date = (
	CASE 
		WHEN time BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN time BETWEEN "12:00:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END
);

-- day_name
ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales 
SET day_name = DAYNAME(date);

-- month_name
ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales 
SET month_name = MONTHNAME(date);

------------------- Explonatory Data Analysis (EDA) ---------------------

SELECT DISTINCT city
FROM sales;

SELECT DISTINCT branch
FROM sales;

-- In which city is each branch?
SELECT 
	DISTINCT city,
	branch
FROM sales; 

----------------- Product ----------------
-- How many unique product lines does the data have?
SELECT COUNT(DISTINCT(product_line))
FROM sales;

-- What is the most common payment method?
SELECT 
	payment,
	COUNT(payment) AS count
FROM sales
GROUP BY payment
ORDER BY count DESC;

-- What is the most selling product line?
SELECT 
	product_line,
	COUNT(product_line) AS count
FROM sales
GROUP BY product_line
ORDER BY 2 DESC;

-- What is the total revenue by month?
SELECT 
	month_name month,
	SUM(total) AS total_revenue
FROM sales
GROUP BY month_name
ORDER BY 2 DESC;

-- What month had the largest COGS?
SELECT 
	month_name month,
	SUM(cogs) AS cogs
FROM sales
GROUP BY month_name
ORDER BY 2 DESC;

-- What product line had the largest revenue?
SELECT 
	product_line,
	SUM(total) AS total_revenue
FROM sales
GROUP BY product_line
ORDER BY 2 DESC;

-- What is the city with the largest revenue?
SELECT 
	city,
	SUM(total) AS total_revenue
FROM sales
GROUP BY city
ORDER BY 2 DESC;

-- What product line had the largest VAT(Value Addead Tax)?
SELECT 
	product_line,
	AVG(tax_pct) AS avg_tax
FROM sales
GROUP BY product_line
ORDER BY 2 DESC;

-- Which branch sold more products than average product sold?
SELECT 
	branch,
	SUM(quantity) AS total_quantity
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

-- What is the most common product line by gender?
SELECT 
	gender,
    product_line,
    COUNT(product_line) AS total_count
FROM sales
GROUP BY gender, product_line
ORDER BY total_count DESC;

-- What is the average rating of each product line?
SELECT 
    product_line,
    ROUND(AVG(rating),2) AS avg_rating
FROM sales
GROUP BY product_line
ORDER BY 2 DESC;

-- Fetch each month and product line and add a column to those showing "Good", "Bad". Good if its greater than average sales
WITH cte_subquery AS (
    SELECT
        month_name,
        product_line,
        SUM(total) AS total_sales 
    FROM sales
    GROUP BY month_name, product_line
)
SELECT 
    month_name,
    product_line,
    total_sales,
    CASE
        WHEN total_sales > (SELECT AVG(total_sales) FROM cte_subquery) THEN 'Good'
        ELSE 'Bad'
    END AS performance
FROM cte_subquery
ORDER BY 
	FIELD(month_name, 'January', 'February', 'March'), performance DESC;

----------------- Sales ----------------
-- Number of sales made in each time of the day per weekday
SELECT
	day_name,
	time_of_date,
    COUNT(*) AS total_sales
FROM sales
GROUP BY day_name, time_of_date
ORDER BY
    FIELD(day_name, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'),
    CASE 
        WHEN time_of_date = 'Morning' THEN 1
        WHEN time_of_date = 'Afternoon' THEN 2
        WHEN time_of_date = 'Evening' THEN 3
    END;

-- Which of the customer types brings the most revenue?
SELECT
	customer_type,
    SUM(total) AS total_revenue
FROM sales
GROUP BY customer_type
ORDER BY 2 DESC;

-- Which city has the largest tax percent/ VAT (Value Added Tax)?
SELECT
	city,
    AVG(tax_pct) AS avg_tax_pct
FROM sales
GROUP BY city
ORDER BY 2 DESC;

-- Which customer type pays the most in VAT?
SELECT
	customer_type,
    AVG(tax_pct) AS avg_tax_pct
FROM sales
GROUP BY customer_type
ORDER BY 2 DESC;

----------------- Customer ----------------
-- Which customer type buys the most?
SELECT
	customer_type,
    COUNT(*)
FROM sales
GROUP BY customer_type
ORDER BY 2 DESC;

-- What is the gender of most of the customers?
SELECT
	gender,
    COUNT(*)
FROM sales
GROUP BY gender
ORDER BY 2 DESC;

-- What is the gender distribution per branch?
SELECT
	branch,
    gender,
    COUNT(*)
FROM sales
GROUP BY branch, gender
ORDER BY branch;

-- Which time of the day do customers give most ratings?
SELECT
	time_of_date,
    AVG(rating) as avg_rating
FROM sales
GROUP BY time_of_date
ORDER BY 2 DESC;

-- Which time of the day do customers give most ratings per branch?
SELECT
	branch,
    time_of_date,
    AVG(rating) as avg_rating
FROM sales
GROUP BY branch, time_of_date
ORDER BY 1 ASC, 3 DESC;

-- Which day fo the week has the best avg ratings?
SELECT
	day_name,
    AVG(rating) as avg_rating
FROM sales
GROUP BY day_name
ORDER BY 2 DESC;

-- Which day of the week has the best average ratings per branch?
SELECT
	branch,
    day_name,
    AVG(rating) as avg_rating
FROM sales
GROUP BY branch, day_name
ORDER BY 1 ASC, 3 DESC;

SELECT * FROM sales;

