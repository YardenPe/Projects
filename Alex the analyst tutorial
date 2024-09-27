-- SELECT * 
-- FROM parks_and_recreation.employee_salary
-- WHERE first_name = 'Leslie'
-- ;

-- SELECT * 
-- FROM parks_and_recreation.employee_demographics
-- WHERE birth_date > '1985-01-01'
-- ;

-- SELECT * 
-- FROM parks_and_recreation.employee_demographics
-- WHERE birth_date LIKE '1989%'
-- ;

-- SELECT gender, AVG(age), MAX(age), MIN(age), COUNT(age)
-- FROM parks_and_recreation.employee_demographics
-- GROUP BY gender
-- ;

-- SELECT occupation, AVG(salary)
-- FROM parks_and_recreation.employee_salary
-- WHERE occupation LIKE '%manager%'
-- GROUP BY occupation
-- HAVING AVG(salary) > 75000
-- ;

-- SELECT *
-- FROM parks_and_recreation.employee_demographics
-- ORDER BY age DESC
-- LIMIT 2, 1
-- ;

-- SELECT employee_id, age, occupation
-- FROM employee_demographics AS dem
-- INNER JOIN employee_salary AS sal
-- USING (employee_id)
-- ;

-- SELECT *
-- FROM employee_demographics AS dem
-- RIGHT JOIN employee_salary AS sal
-- 	ON dem.employee_id = sal.employee_id
-- ;

-- SELECT *
-- FROM employee_salary AS emp1
-- JOIN employee_salary AS emp2
-- 	ON emp1.employee_id + 1 = emp2.employee_id
-- ;

-- SELECT *
-- FROM employee_demographics AS dem
-- INNER JOIN employee_salary AS sal
-- 	ON dem.employee_id = sal.employee_id
-- INNER JOIN parks_departments AS pd
-- 	ON sal.dept_id = pd.department_id
-- ;

-- SELECT first_name, last_name, 'old Man' AS label
-- FROM employee_demographics
-- WHERE age > 40 AND gender = 'Male'
-- UNION
-- SELECT first_name, last_name, 'old Lady' AS label
-- FROM employee_demographics
-- WHERE age > 40 AND gender = 'Female'
-- UNION
-- SELECT first_name, last_name, 'Highly Paid Employee' AS label
-- FROM employee_salary
-- WHERE salary > 70000
-- ORDER BY first_name, last_name
-- ;

-- SELECT first_name, LENGTH(first_name)
-- FROM employee_demographics
-- ORDER BY 2;
-- UPPER, LOWER, TRIM, LTRIM, RTRIM

-- SELECT first_name, LEFT(first_name, 4), RIGHT(first_name, 4),
-- SUBSTRING(first_name, 3, 2),
-- birth_date,
-- SUBSTRING(birth_date, 6, 2) AS birth_month
-- FROM employee_demographics;

-- replaces only lower case a
-- SELECT first_name, REPLACE(first_name, 'a', 'z')
-- FROM employee_demographics;

-- SELECT first_name, LOCATE('An', first_name) AS locate
-- FROM employee_demographics
-- ORDER BY locate DESC;

-- SELECT first_name, last_name,
-- CONCAT (first_name, ' ' ,last_name)
-- FROM employee_demographics;

USE parks_and_recreation;
-- Case statementss
SELECT first_name, last_name, age,
CASE 
	WHEN age <= 30 THEN 'Young'
    WHEN age BETWEEN 31 AND 50 THEN 'Old'
    WHEN age >= 50 THEN "On Death's Door"
END AS age_bracket
FROM employee_demographics;

SELECT first_name, last_name, salary,
CASE
	WHEN salary < 50000 THEN salary * 1.05
    WHEN salary > 50000 THEN salary * 1.07
END AS new_salary,
CASE
	WHEN dept_id = 6 THEN salary * .10
END AS Bonus
FROM employee_salary;

-- Subqueries
SELECT *
FROM employee_demographics
WHERE employee_id IN 
	(SELECT employee_id
    FROM employee_salary 
	WHERE dept_id = 1)
;

SELECT first_name, salary, (SELECT AVG(salary) FROM employee_salary)
FROM employee_salary;

SELECT AVG(max_age)
FROM 
(SELECT gender, AVG(age), MAX(age) AS max_age, MIN(age), COUNT(age)
FROM employee_demographics
GROUP BY gender) AS agg_talbe
;

USE parks_and_recreation;
-- Window Functions
SELECT gender, AVG(salary) AS avg_salary
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
GROUP BY gender;

-- avg salary over everything
SELECT gender, AVG(salary) OVER()
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

SELECT dem.first_name, gender, AVG(salary) OVER(PARTITION BY gender)
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

-- rolling total
SELECT dem.first_name, gender, salary,
SUM(salary) OVER(PARTITION BY gender ORDER BY dem.employee_id) AS rolling_total
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

SELECT dem.employee_id, dem.first_name, gender, salary,
ROW_NUMBER() OVER()
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

SELECT dem.employee_id, dem.first_name, gender, salary,
ROW_NUMBER() OVER(PARTITION BY gender)
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

SELECT dem.employee_id, dem.first_name, gender, salary,
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY salary DESC)
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

-- rank same number in position 5 and skips 6 right to 7.
SELECT dem.employee_id, dem.first_name, gender, salary,
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY salary DESC) AS row_num,
RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS rank_num
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

-- doesn't skip 6
SELECT dem.employee_id, dem.first_name, gender, salary,
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY salary DESC) AS row_num,
DENSE_RANK() OVER(PARTITION BY gender ORDER BY salary DESC) AS rank_num
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
;

-- CTE - common table expressions - can only use it immediately after you create it
WITH CTE_Example AS 
(
SELECT gender, AVG(salary) AS avg_sal, MIN(salary) AS min_sal, MAX(salary) AS max_sal
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
GROUP BY gender 
)
SELECT AVG(avg_sal)
FROM CTE_Example;

-- same in subquery
SELECT AVG(avg_sal)
FROM (
SELECT gender, AVG(salary) AS avg_sal, MIN(salary) AS min_sal, MAX(salary) AS max_sal
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
GROUP BY gender 
) AS example_subquery
;


-- Multiple CTEs
WITH CTE_Example AS 
(
SELECT employee_id, birth_date
FROM employee_demographics
WHERE birth_date > '1985-01-01'
),
CTE_Example2 AS
(
SELECT employee_id, salary
FROM employee_salary
WHERE salary > 50000
)
SELECT *
FROM CTE_Example
JOIN CTE_Example2
	ON CTE_Example.employee_id = CTE_Example2.employee_id
;

-- Aliasing in CTE - name new columns on the top instead
WITH CTE_Example (Gender, avg_sal, min_sal, max_sal) AS
(
SELECT gender, AVG(salary), MIN(salary), MAX(salary)
FROM employee_demographics AS dem
JOIN employee_salary AS sal
	ON dem.employee_id = sal.employee_id
GROUP BY gender 
)
SELECT *
FROM CTE_Example;

-- to create a noraml talbe : CREATE TABLE __

-- Temporary Tables - only available for temporary session so if I get out of sql and return its not going to be there

-- One way to do it (less followed): 
DROP TEMPORARY TABLE IF EXISTS temp_table;

CREATE TEMPORARY TABLE temp_table
(first_name varchar(50),
last__name varchar(50),
favorite_movie varchar(100)
);

INSERT INTO temp_table
VALUES('Alex', 'Freeberg', 'Lord of the rings');

-- delete specific row
DELETE FROM temp_table
WHERE first_name = 'Alex' LIMIT 4;

SELECT *
FROM temp_table;

-- Second way:
CREATE TEMPORARY TABLE salary_over_50k
SELECT *
FROM employee_salary
WHERE salary >= 50000
;

SELECT * 
FROM salary_over_50k;

-- Stored Procedures
USE parks_and_recreation
CREATE PROCEDURE large_salaries()
SELECT *
FROM employee_salary
WHERE salary >= 50000;

-- ran this code and get the result:
CALL large_salaries;
-- or this way
CALL parks_and_recreation.large_salaries;

-- to get all the code into one store procedure
DELIMITER $$
CREATE PROCEDURE large_salaries3()
BEGIN
    -- First query for salaries >= 50,000
    SELECT * 
    FROM employee_salary
    WHERE salary >= 50000;
    -- Second query for salaries >= 10,000
    SELECT * 
    FROM employee_salary
    WHERE salary >= 10000;
END $$
DELIMITER ;

CALL large_salaries3();

DROP PROCEDURE IF EXISTS large_salaries3;

-- parameter - return salary where employee_id is 1
DELIMITER $$
CREATE PROCEDURE large_salaries4(id INT)
BEGIN
    SELECT salary
    FROM employee_salary
    WHERE employee_id = id
    ;
END $$
DELIMITER ;

CALL large_salaries4(1);

-- Triggers and Events
-- when someone is updated to salary table, will be updated in demographics
SELECT *
FROM employee_demographics;
SELECT *
FROM employee_salary;

DELIMITER $$
CREATE TRIGGER employee_insert
AFTER INSERT ON employee_salary
FOR EACH ROW
BEGIN
    INSERT INTO employee_demographics (employee_id, first_name, last_name)
    VALUES (NEW.employee_id, NEW.first_name, NEW.last_name);
END $$
DELIMITER ;

-- if we want to drop
DROP TRIGGER IF EXISTS employee_insert;

INSERT INTO employee_salary (employee_id, first_name, last_name, occupation, salary, dept_id)
VALUES(13, 'Jean-Ralphio', 'Saperstein', 'Entertainment', 1000000, NULL);

-- was added automatically to both
SELECT * FROM employee_salary;
SELECT * FROM employee_demographics;

-- EVENTS

-- over 60 they retire, 
DELIMITER $$
CREATE EVENT delete_retirees
 ON SCHEDULE EVERY 30 SECOND
 DO
 BEGIN
	DELETE 
    FROM employee_dempgraphics
    WHERE age >= 60;
 END $$
 DELIMITER ;

-- if event doesn't work, need to update value to ON
SHOW VARIABLES LIKE 'event%';
-- if still doesn't work then its in the video: Triggers and Events in MySQL | Advanced MySQL Series



