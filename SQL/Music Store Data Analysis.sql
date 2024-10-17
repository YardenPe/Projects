-------- SQL Project - Music Store Data Analysis --------

-- Question Set 1 – Easy --

-- Who is the most senior employee based on their job title?
SELECT first_name, last_name, title, levels
FROM employee
ORDER BY levels DESC
LIMIT 1;

-- Which countries have the most invoices?
SELECT billing_country, COUNT(*) AS total_invoices
FROM invoice
GROUP BY billing_country
ORDER BY total_invoices DESC
LIMIT 5;

-- What are the top 3 values of total invoice amounts?
SELECT total
FROM Invoice
ORDER BY total DESC
LIMIT 3;

-- Which city has the best customers? We want to host a promotional Music Festival in the city where we earned the most money. Write a query to find the city that has the highest sum of invoice totals. Return both the city name and the total sum of all invoices.
SELECT billing_city, SUM(total) AS invoice_totals
FROM invoice
GROUP BY billing_city
ORDER BY invoice_totals DESC
LIMIT 1;

-- Who is the best customer? The customer who has spent the most money will be considered the best customer. Write a query that returns the name of the customer who has spent the most money.
SELECT customer_id, first_name, last_name, SUM(total) AS total_amount
FROM invoice AS i
JOIN customer AS c
	USING (customer_id)
GROUP BY customer_id, first_name, last_name
ORDER BY total_amount DESC
LIMIT 1;

-- Question Set 2 – Moderate --

-- Write a query to return the email, first name, last name, and genre of all Rock Music listeners. Return the list ordered alphabetically by email, starting with "A."
WITH CTE1 AS(
	SELECT track_id
	FROM track
	JOIN genre
	USING (genre_id)
	WHERE genre.name LIKE 'Rock'
)
SELECT DISTINCT email, first_name, last_name
FROM customer
JOIN invoice
	USING (customer_id)
JOIN invoice_line
	USING (invoice_id)
WHERE track_id IN (SELECT track_id FROM CTE1)
ORDER BY email;


-- Let’s invite the artists who have written the most rock music in the dataset. Write a query that returns the artist name and the total track count for the top 10 rock bands.
SELECT artist.name, COUNT(track_id) AS total_rock_tracks
FROM track
JOIN album
	USING (album_id)
JOIN artist
	USING (artist_id)
JOIN genre
	USING (genre_id)
WHERE genre.name LIKE 'Rock'
GROUP BY artist_id, artist.name
ORDER BY total_rock_tracks DESC
LIMIT 10;

-- Return all track names that have a song length longer than the average song length. Return the track name and milliseconds for each track. Order the results by song length, with the longest songs listed first.
SELECT name, milliseconds
FROM track
WHERE milliseconds > (SELECT AVG(milliseconds) FROM track)
ORDER BY milliseconds DESC;

-- Question Set 3 – Advanced --

-- How much has each customer spent on artists? Write a query to return the customer name, artist name, and total amount spent.
SELECT customer.first_name, customer.last_name, artist.name AS artist_name, SUM(invoice_line.unit_price * invoice_line.quantity) AS total_spent
FROM customer
JOIN invoice 
	USING (customer_id)
JOIN invoice_line 
	USING (invoice_id)
JOIN track 
	USING(track_id)
JOIN album
	USING(album_id)
JOIN artist 
	USING(artist_id)
GROUP BY customer.customer_id, artist.artist_id
ORDER BY total_spent DESC;

-- Find the most popular music genre for each country (by number of purchases).
WITH CTE2 AS
(
	SELECT country, genre.name AS genre, COUNT(quantity) AS purchases,
	-- rank or row_number is good
	RANK() OVER(PARTITION BY country ORDER BY COUNT(quantity) DESC) AS row_num
	FROM invoice_line 
	JOIN invoice
		USING (invoice_id)
	JOIN customer
		USING (customer_id)
	JOIN track
		USING (track_id)
	JOIN genre
		USING(genre_id)
	GROUP BY 1, 2
	ORDER BY 1 ASC, 3 DESC
)
SELECT * 
FROM CTE2
WHERE row_num = 1;

-- Find the customer who spent the most on music in each country.
-- One Way:
WITH SpendingPerCustomer AS (
    SELECT country, first_name, last_name, SUM(total) AS spending
    FROM customer AS c
    JOIN invoice AS i
		USING (customer_id)
    GROUP BY country, c.customer_id
)
SELECT country, first_name, last_name, spending
FROM SpendingPerCustomer
WHERE (country, spending) IN (
    SELECT country, MAX(spending)
    FROM SpendingPerCustomer
    GROUP BY country
)
ORDER BY country;

-- Second way:
WITH SpendingPerCustomer AS (
    SELECT country, first_name, last_name, SUM(total) AS spending,
    ROW_NUMBER() OVER (PARTITION BY country ORDER BY SUM(total) DESC) AS row_num
    FROM customer AS c
    JOIN invoice AS i 
		USING(customer_id)
    GROUP BY country, c.customer_id
)
SELECT country, first_name, last_name, spending
FROM SpendingPerCustomer
WHERE row_num = 1
ORDER BY 1;

-- Chatgpt Questions --

-- Find out how many tracks belong to each genre. Display the genre name and the count of tracks.
SELECT g.name, COUNT(track_id) AS tracks_amount
FROM track
JOIN genre g
	USING(genre_id)
GROUP BY g.name
ORDER BY tracks_amount DESC;

-- Find all customers whose email contains the word "gmail".
SELECT first_name, last_name, email
FROM Customer 
WHERE email LIKE '%gmail%';

-- For each customer, calculate their rank based on the total amount spent (use the total from the Invoice table).
SELECT first_name, last_name, SUM(total) AS total_spent,
       RANK() OVER (ORDER BY SUM(total) DESC) AS rank
FROM customer c
JOIN invoice
	USING(customer_id)
GROUP BY c.customer_id
ORDER BY rank ASC;

-- Write a query to find all employees along with their manager's first name. If they don’t have a manager, show "No Manager."
SELECT e.first_name AS employee_name, 
	COALESCE(m.first_name, 'No Manager') AS manager_name
FROM Employee e
LEFT JOIN Employee m ON e.reports_to = m.employee_id;

-- Find all employees who share the same manager.
SELECT e1.first_name AS employee1_first_name, e2.first_name AS employee2_first_name, e1.reports_to AS manager_id
FROM employee e1
JOIN employee e2 
	ON e1.reports_to = e2.reports_to
WHERE e1.employee_id < e2.employee_id;