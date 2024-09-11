create database Amazon;

use amazon;

create table amazon_data(
invoice_id varchar(30) NOT NULL,
branch varchar(5) NOT NULL,
city varchar(30) NOT NULL,
customer_type varchar(30) NOT NULL,
gender varchar(10) NOT NULL,
product_line varchar(100) NOT NULL,
unit_price decimal(10,2) NOT NULL,
quantity int NOT NULL,
VAT float(6,4) NOT NULL,
total decimal(10,2) NOT NULL,
date date NOT NULL,
time time NOT NULL,
payment_method varchar(30) NOT NULL,
cogs decimal(10,2) NOT NULL,
gross_margin_percentage float(11,9) NOT NULL,
gross_income DECIMAL(10, 2) NOT NULL,
rating float(2,1) NOT NULL
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/amazon_data.csv'
INTO TABLE amazon_data
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from amazon_data;

show variables like "local_infile";

set global local_infile = 1;

SET GLOBAL sql_mode = '';

SHOW VARIABLES LIKE 'secure_file_priv';

-- FEATURE ENGINEERING

-- Adding first additional column for time of the day
ALTER TABLE amazon_data
ADD COLUMN time_of_day VARCHAR(10);

-- setting safe update to zero so that i can update the table value
SET SQL_SAFE_UPDATES = 0;

UPDATE amazon_data
SET time_of_day = "morning"
WHERE time < "12:00:00";

UPDATE amazon_data
SET time_of_day = "afternoon"
WHERE time between "12:00:00" and "17:00:00"; 

UPDATE amazon_data
SET time_of_day = "evening"
WHERE time > "17:00:00";

-- Adding second column for day name

ALTER TABLE amazon_data
ADD COLUMN day_name VARCHAR(10);

UPDATE amazon_data
SET day_name = dayname(Date);

-- Adding third column for the month name

ALTER TABLE amazon_data
ADD COLUMN month_name VARCHAR(10);

UPDATE amazon_data
SET month_name = monthname(Date);

-- Exploratory Data Analysis

SHOW tables;

SHOW COLUMNS FROM amazon_data;

SELECT COUNT(*) FROM amazon_data;

-- Product analysis
select product_line, sum(total) as revenue from amazon_data
group by product_line
order by revenue desc;

select product_line, sum(quantity) as Total_quantity from amazon_data
group by product_line
order by Total_quantity;

-- sales analysis
select product_line, city, sum(total) as revenue from amazon_data
group by product_line
order by revenue desc;


-- Customer analysis
select product_line, gender, sum(total) as revenue from amazon_data
group by product_line, gender
order by revenue desc;

select product_line, gender, avg(rating) as average_rating from amazon_data
group by product_line, gender
order by average_rating desc;


select city, sum(total) as revenue from amazon_data
group by city;

-- Question 1. What is the count of distinct cities in the dataset?
SELECT COUNT(DISTINCT city) as Distinct_city_count from amazon_data;


-- Question 2. For each branch, what is the corresponding city?
SELECT DISTINCT branch, city from amazon_data
order by branch;


-- Question 3. What is the count of distinct product lines in the dataset?
SELECT COUNT(DISTINCT Product_line) as Product_line_count FROM amazon_data;


-- Question 4. Which payment method occurs most frequently?
SELECT COUNT(payment_method) as count, payment_method FROM amazon_data
group by payment_method
order by count desc
limit 1;


-- Question 5. Which product line has the highest sales?
SELECT product_line, sum(quantity) as sales FROM amazon_data
group by product_line
order by sales desc
limit 1;


-- Question 6. How much revenue is generated each month?
SELECT month_name, sum(total) as t FROM amazon_data
group by month_name
order by t desc;


-- Question 7. In which month did the cost of goods sold reach its peak?
SELECT month_name, sum(cogs) as cogs FROM amazon_data
group by month_name
order by cogs desc
limit 1;


-- Question 8. Which product line generated the highest revenue?
SELECT product_line, sum(total) as t FROM amazon_data
group by product_line
order by t desc
limit 1;

-- Question 9. In which city was the highest revenue recorded?
SELECT city, sum(total) as t FROM amazon_data
group by city
order by t desc
limit 1;


-- Question 10. Which product line incurred the highest Value Added Tax?
SELECT product_line, sum(VAT) as t FROM amazon_data
group by product_line
order by t desc
limit 1;


-- Question 11.For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."
select product_line, quantity,
        CASE
			when quantity>(select avg(quantity) from amazon_data) then 'good'
            else 'bad'
		END AS 'sales_status'
from amazon_data;

-- Question 12. Identify the branch that exceeded the average number of products sold.
select branch, avg(quantity) as average_quantity from amazon_data
group by branch
having average_quantity>(select avg(quantity) from amazon_data);


-- Question 13. Which product line is most frequently associated with each gender?
WITH RankedSales AS (
    SELECT
        product_line,
        gender,
		SUM(quantity) as Total_quantity,
        ROW_NUMBER() OVER(PARTITION BY gender ORDER BY SUM(quantity) DESC ) as pos
    FROM amazon_data
    group by gender,product_line
)
SELECT product_line, gender, Total_quantity
FROM RankedSales
WHERE pos = 1;

 
-- Question 14. Calculate the average rating for each product line.
select product_line, avg(rating) average_rating from amazon_data
group by product_line;


-- Question 15. Count the sales occurrences for each time of day on every weekday.
select  day_name, time_of_day, count(quantity) as sales from amazon_data
group by day_name, time_of_day
having day_name != "saturday" and day_name != "sunday";

-- Question 16. Identify the customer type contributing the highest revenue.
select customer_type, sum(total) as revenue from amazon_data
group by customer_type
order by revenue desc
limit 1;

-- Question 17.Determine the city with the highest VAT percentage.
select city, sum(VAT)/(select sum(vat) from amazon_data)*100 as vat_percentage from amazon_data
group by city
order by vat_percentage desc
limit 1;

-- Question 18. Identify the customer type with the highest VAT payments.
select customer_type, sum(VAT) as VAT_payment from amazon_data
group by customer_type
order by VAT_payment desc
limit 1;

-- Question 19. What is the count of distinct customer types in the dataset?
select count(DISTINCT customer_type) as customer_type_count from amazon_data;

-- Question 20. What is the count of distinct payment methods in the dataset?
select count(DISTINCT payment_method) as payment_method_count from amazon_data;

-- Question 21. Which customer type occurs most frequently?
select customer_type, count(customer_type) as total_count from amazon_data
group by customer_type
order by total_count desc
limit 1;


-- Question 22. Identify the customer type with the highest purchase frequency.
select customer_type, sum(quantity) as total_quantity from amazon_data
group by customer_type
order by total_quantity desc
limit 1;

-- Question 23. Determine the predominant gender among customers.
select gender, count(gender) as total_count from amazon_data
group by gender
order by total_count desc
limit 1;

-- Question 24. Examine the distribution of genders within each branch.
select branch, gender, count(gender) as Total_count from amazon_data
group by branch, gender
order by branch;

-- Question 25. Identify the time of day when customers provide the most ratings. 
select time_of_day, count(rating) as Total_count from amazon_data
group by time_of_day;

-- Question 26. Determine the time of day with the highest customer ratings for each branch.
WITH RankedSales AS (
    SELECT
        time_of_day,
        branch,
		sum(rating) as Total_rating,
        ROW_NUMBER() OVER(PARTITION BY branch ORDER BY sum(rating) DESC) as pos
    FROM amazon_data
    group by branch, time_of_day
)
SELECT time_of_day, branch, Total_rating
FROM RankedSales
WHERE pos = 1;

-- Question 27. Identify the day of the week with the highest average ratings.
select day_name, avg(rating) as Average_rating from amazon_data
group by day_name
order by Average_rating desc
limit 1;


-- Question 28. Determine the day of the week with the highest average ratings for each branch.
WITH RankedSales AS (
    SELECT
        day_name,
        branch,
		avg(rating) as average_rating,
        ROW_NUMBER() OVER(PARTITION BY branch ORDER BY avg(rating) DESC) as pos
    FROM amazon_data
    group by branch, day_name
)
SELECT day_name, branch, average_rating
FROM RankedSales
WHERE pos = 1;


