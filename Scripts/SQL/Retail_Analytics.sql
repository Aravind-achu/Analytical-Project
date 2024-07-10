use aravind

drop table transformed_file;

create table transformed_file(order_id int primary key,
order_date date,
ship_mode varchar(20),
segment varchar(20),
country varchar(20),
city varchar(20),
state varchar(20),
postal_code varchar(20),
region varchar(20),
category varchar(20),
sub_category varchar(20),
product_id varchar(20),
cost_price int,
list_price int,
quantity int,
discount_percent int);

select * from transformed_file;

#Then try some queries
#find top 5 highest reveue generating products
#
SELECT product_id, SUM(sale_price) AS sale
FROM transformed_file
GROUP BY product_id
ORDER BY sale DESC
LIMIT 5;


#find top 5 highest selling product in each region
##
WITH cte AS (
    SELECT region, product_id, SUM(sale_price) AS sale
    FROM transformed_file
    GROUP BY region, product_id
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY region ORDER BY sale DESC) AS rn
    FROM cte
) subquery
WHERE rn <= 5;

#find month over month growth comparison
###
WITH cte AS (
    SELECT 
        YEAR(order_date) AS order_year,
        MONTH(order_date) AS order_month,
        SUM(sale_price) AS sales
    FROM transformed_file
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT 
    order_month,
    SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sales_2022,
    SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sales_2023
FROM cte 
GROUP BY order_month
ORDER BY order_month;

#for each category which month had highest sales
####
WITH cte AS (
    SELECT 
        category, 
        DATE_FORMAT(order_date, '%Y%m') AS order_year_month,  -- Use DATE_FORMAT for MySQL
        SUM(sale_price) AS sales
    FROM transformed_file
    GROUP BY category, DATE_FORMAT(order_date, '%Y%m')  -- Ensure the date format is correct
)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rn
    FROM cte
) a
WHERE rn = 1;

#which sub category had highest growth by profit in 2023 compare to 2022
#####
WITH cte AS (
    SELECT 
        sub_category, 
        YEAR(order_date) AS order_year,
        SUM(sale_price) AS sales
    FROM transformed_file
    GROUP BY sub_category, YEAR(order_date)
),
cte2 AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN order_year = 2022 THEN sales ELSE 0 END) AS sale_2022,
        SUM(CASE WHEN order_year = 2023 THEN sales ELSE 0 END) AS sale_2023
    FROM cte
    GROUP BY sub_category
)
SELECT *,
       (sale_2023 - sale_2022) AS sales_growth
FROM cte2
ORDER BY sales_growth DESC
LIMIT 1;
