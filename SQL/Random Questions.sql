CREATE TABLE Employee (
	EmpID int NOT NULL,
	EmpName Varchar,
	Gender Char,
	Salary int,
	City Char(20)
	)

INSERT INTO Employee
VALUES (1, 'Arjun', 'M', 75000, 'Pune'),
(2, 'Ekadanta', 'M', 125000, 'Bangalore'),
(3, 'Lalita', 'F', 150000 , 'Mathura'),
(4, 'Madhav', 'M', 250000 , 'Delhi'),
(5, 'Visakha', 'F', 120000 , 'Mathura')

CREATE TABLE EmployeeDetail (
	EmpID int NOT NULL,
	Project Varchar,
	EmpPosition Char(20),
	DOJ date
	)

INSERT INTO EmployeeDetail
VALUES (1, 'P1', 'Executive', '26-01-2019'),
(2, 'P2', 'Executive', '04-05-2020'),
(3, 'P1', 'Lead', '21-10-2021'),
(4, 'P3', 'Manager', '29-11-2019'),
(5, 'P2', 'Manager', '01-08-2020')

-- Q1(a): Find the list of employees whose salary ranges between 2L to 3L.
SELECT EmpName, Salary 
FROM Employee
WHERE Salary BETWEEN 200000 AND 300000;

-- Q1(b): Write a query to retrieve the list of employees from the same city.
-- One way:
SELECT DISTINCT e1.empid, e1.empname, city
FROM Employee AS e1
LEFT JOIN Employee e2
	USING (city)
WHERE e1.empname <> e2.empname;

-- Second way:
SELECT E1.EmpID, E1.EmpName, E1.City
FROM Employee E1, Employee E2
WHERE E1.City = E2.City AND E1.EmpID != E2.EmpID

-- Q1(c): Query to find the null values in the Employee table.
SELECT * FROM Employee
WHERE EmpID IS NULL;

-- Q2(a): Query to find the cumulative sum of employee’s salary.
SELECT EmpID, Salary, SUM(Salary) OVER (ORDER BY EmpID) AS CumulativeSum
FROM Employee;

-- Q2(b): What’s the male and female employees ratio.
SELECT
	ROUND(COUNT(*) FILTER (WHERE Gender = 'M') * 100.0 / COUNT(*),1) AS MalePct,
	ROUND(COUNT(*) FILTER (WHERE Gender = 'F') * 100.0 / COUNT(*),1) AS FemalePct
FROM Employee;

-- Q2(c): Write a query to fetch 50% records from the Employee table.
SELECT * 
FROM Employee
ORDER BY RANDOM()
LIMIT (SELECT COUNT(*) / 2 FROM Employee);

-- Q3: Query to fetch the employee’s salary but replace the LAST 2 digits with ‘XX’ i.e 12345 will be 123XX
-- One way:
SELECT Salary,
	CONCAT(SUBSTRING(Salary::text, 1, LENGTH(Salary::text)-2), 'XX') as masked_number
FROM Employee;

-- Second way:
SELECT Salary, 
	CONCAT(LEFT(CAST(Salary AS text), LENGTH(CAST(Salary AS text))-2), 'XX')
AS masked_number
FROM Employee;

-- Q4: Write a query to fetch even and odd rows from Employee table.
SELECT * FROM Employee
WHERE MOD(EmpID,2)=0;
SELECT * FROM Employee
WHERE MOD(EmpID,2)=1;

-- Q5(a): Write a query to find all the Employee names whose name:
-- • Begin with ‘A’
-- • Contains ‘A’ alphabet at second place
-- • Contains ‘Y’ alphabet at second last place
-- • Ends with ‘L’ and contains 4 alphabets
-- • Begins with ‘V’ and ends with ‘A’
SELECT * 
FROM Employee
WHERE empname SIMILAR TO 'A%|_a%|%y_|___l|V%a';

-- Q5(b): Write a query to find the list of Employee names which is:
-- • starting with vowels (a, e, i, o, or u), without duplicates
-- • ending with vowels (a, e, i, o, or u), without duplicates
-- • starting & ending with vowels (a, e, i, o, or u), without duplicates
SELECT DISTINCT EmpName
FROM Employee
WHERE LOWER(EmpName) SIMILAR TO '[aeiou]%'  -- Starts with a vowel
   OR LOWER(EmpName) SIMILAR TO '%[aeiou]'  -- Ends with a vowel
   OR LOWER(EmpName) SIMILAR TO '[aeiou]%[aeiou]';  -- Starts and ends with a vowel

-- Q6: Write a query to find and remove duplicate records from a table.
--One way:
WITH CTE AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY empid, empname, gender, salary, city ORDER BY empid) AS RowNum
    FROM Employee
)
DELETE FROM Employee
WHERE EmpID IN (
    SELECT EmpID
    FROM CTE
    WHERE RowNum > 1
);

-- Q6(b): Query to retrieve the list of employees working in same project.
WITH CTE AS (
SELECT e.EmpID, e.EmpName, ed.Project
FROM Employee AS e
JOIN EmployeeDetail AS ed
	USING (EmpID)
)
SELECT c1.EmpName, c2.EmpName, c1.project
FROM CTE c1, CTE c2
WHERE c1.Project = c2.Project AND c1.EmpID != c2.EmpID AND c1.EmpID < c2.EmpID

-- Q7: Show the employee with the highest salary for each project
-- One way:
SELECT ed.Project, MAX(e.Salary) AS ProjectSal
FROM Employee AS e
JOIN EmployeeDetail AS ed
	USING (EmpID)
GROUP BY Project
ORDER BY ProjectSal DESC;

-- Second way:
WITH CTE AS (
SELECT EmpName, project, salary,
	ROW_NUMBER() OVER(PARTITION BY project ORDER BY salary DESC) AS row_rank
FROM Employee AS e
JOIN EmployeeDetail AS ed
	USING (EmpID)
)
SELECT EmpName, project, salary
FROM CTE
WHERE row_rank = 1;

-- Q8: Query to find the total count of employees joined each year
SELECT EXTRACT('year' FROM doj) AS years, COUNT(*) AS empcount
FROM Employee
JOIN EmployeeDetail
	USING (EmpID)
GROUP BY years
ORDER BY years;

-- Q9: Create 3 groups based on salary col, salary less than 1L is low, between 1-2L is medium and above 2L is High
SELECT empname, salary,
	CASE
		WHEN salary < 10000 THEN 'Low'
		WHEN salary BETWEEN 10000 AND 20000 THEN 'Medium'
		ELSE 'High'
		END AS salarygroup
FROM employee;

-- Q10: Query to pivot the data in the Employee table and retrieve the total salary for each city.
-- The result should display the EmpID, EmpName, and separate columns for each city (Mathura, Pune, Delhi), containing the corresponding total salary.
SELECT EmpID, EmpName,
	SUM(CASE WHEN City = 'Pune' THEN salary END) AS "Pune",
	SUM(CASE WHEN city = 'Bangalore' THEN salary END) AS "Bangalore",
	SUM(CASE WHEN city = 'Mathura' THEN salary END) AS "Mathura",
	SUM(CASE WHEN city = 'Delhi' THEN salary END) AS "Delhi"
FROM Employee
GROUP BY EmpID, EmpName;