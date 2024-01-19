/*----------------------------
The provided code was developed during the course as part 
of the learning process and is maintained on GitHub solely 
for the purpose of practice.
-----------------------------*/

/*----------------------------
The 'wisdom.pets' dataset, utilized consistently throughout
the course, has been included in this repository as well.
-----------------------------*/

--Selecting all columns from dataset
--In general, it is advisable to avoid this practice on BigQuery 
--to minimize additional costs.
SELECT * FROM `wisdom_pets.products`;
--The preview option is available to display all columns and sample data.


-- SELECT specific column 
SELECT
  product_id,
  product_name
FROM `wisdom_pets.products`;


--ORDER BY clause 
--Ques: Which products from each category have the highest discount?
SELECT
  product_id,
  product_name,
  category_name,
  retail_price,
  wholesale_discount_percentage
FROM `wisdom_pets.products`
ORDER BY 
  category_name,
  wholesale_discount_percentage DESC;


--WHERE clause
--Ques: What is the most expensive product in the Care category?
SELECT
  product_id,
  product_name,
  retail_price,
  category_name
FROM `wisdom_pets.products`
WHERE category_name = 'Care'
ORDER BY retail_price DESC;


--WHERE clause (BETWEEN operator)
--Ques: Which Care products have wholesale discount between 20 and 30%?
SELECT
  product_id,
  product_name,
  retail_price,
  category_name,
  wholesale_discount_percentage
FROM `wisdom_pets.products`
WHERE
  category_name = 'Care'
  AND wholesale_discount_percentage BETWEEN 20 AND 30;


--LIKE ANY operator
--Ques: Find all the products which have 'Teeth' or 'Tooth' and any 'Coat' related products
SELECT
  product_id,
  product_name,
  retail_price
FROM `wisdom_pets.products`
WHERE 
    product_name LIKE ANY ('%Teeth%', '%Tooth%', '%Coat%');


--Ques: How many products are in the Care category with a price less than $9?
SELECT
  COUNT(*) AS product_counts
FROM `wisdom_pets.products`
WHERE 
    category_name = 'Care'
    AND retail_price < 9;


--Ques: What are the average and standard deviation of the retail price for all wisdom pets products? 
SELECT
  ROUND(
    AVG(retail_price),
    2
   ) as avg_retail_price,
  ROUND(
    STDDEV(retail_price),
    2
   ) as std_retail_price
FROM `wisdom_pets.products`;


--Challenge Questions (to test the knowledge)

--Question 1: Show top products with ID, name, retail price and category,
--sort output from lowest to highest price.
SELECT
  product_id, 
  product_name,
  retail_price,
  category_name
FROM `wisdom_pets.products`
ORDER BY retail_price ASC;

--Question 2: How many dog supplement products are available? 
--Show avergae retail price and rating rounded to nearest 2 decimal places
SELECT
  COUNT(*) AS product_count,
  ROUND(
    AVG(retail_price),
    2
   ) as avg_retail_price,
  ROUND(
    AVG(rating),
    2
   ) as avg_rating_price
FROM `wisdom_pets.products`
WHERE 
  category_name = 'Supplement'
  AND product_name LIKE '%Dog%';

--Question 3: Calculate the wholesale price using the discount percentage
-- sort output from highest discount amount to lowest. 
SELECT
  product_id,
  product_name,
  retail_price,
  wholesale_discount_percentage,
  retail_price * (
    1 - wholesale_discount_percentage/100) 
    as wholesale_price,
  retail_price * (wholesale_discount_percentage / 100) as discount_amount
FROM `wisdom_pets.products`
ORDER BY discount_amount DESC;


--GROUP BY 
--Ques: How many products in each category have a rating greater than or equal to 4.5?
SELECT
  category_name,
  COUNT(*) as product_count
FROM `wisdom_pets.products`
WHERE rating >= 4.5
GROUP BY category_name;


/*----------------------------------------------
CASE WHEN statements
Ques: How many products are between the price bands of:
  $1 to $5
  $5 to $10
  $10 to $25
  $25 + 
----------------------------------------------*/
SELECT
  CASE
    WHEN retail_price BETWEEN 1 AND 5
      THEN  '$1 to $5'
    WHEN retail_price BETWEEN 5 AND 10
      THEN  '$5 to $10'
    WHEN retail_price BETWEEN 10 AND 25
      THEN  '$10 to $25'
    WHEN retail_price > 25
      THEN '$25 +'
    ELSE NULL
    END as price_band,
  COUNT(*) AS product_count
FROM `wisdom_pets.products`
GROUP BY price_band;


/*---------------------------------------------
COUNTIF operator
How many Five star dog products are there?
How many Four star cat products are there?
-----------------------------------------------*/
SELECT
  category_name,
  COUNTIF(rating = 5 AND product_name LIKE '%Dog%') as dog_product_5_star,
  COUNTIF(rating = 4 AND product_name LIKE '%Cat%') as cat_product_5_star
FROM `wisdom_pets.products`
GROUP BY category_name;


--PIVOT Operator
--Ques: Find the Maximum average rating and Maximum product count for Dog, Cat and other 

WITH cte_pivot_table AS (
  SELECT 
  category_name,
  CASE 
    WHEN product_name LIKE '%Dog%' THEN 'Dog'
    WHEN product_name LIKE '%Cat%' THEN 'Cat'
    ELSE 'Other'
  END as segment_name,
  AVG(rating) AS avg_rating,
  COUNT(*) AS product_count
  FROM `wisdom_pets.products`
  GROUP BY category_name,segment_name
  ORDER BY category_name,segment_name
  )
SELECT * FROM cte_pivot_table
PIVOT(
      MAX(avg_rating) AS avg_rating,
      MAX(product_count) AS product_count
      FOR LOWER(segment_name) IN
      ('dog','cat','other')
);


--Challenge Questions: Financial Analysis 

--Question 1: Which top three product IDs are the best selling
--based on the total_amount field
SELECT
  product_id,
  SUM(total_amount) AS total_sales
FROM `wisdom_pets.sales`
GROUP BY product_id
ORDER BY total_sales DESC
LIMIT 3;


--Question 2: What are the total sales and percentage
--breakdown by transaction_type?

WITH perc_table AS (
  SELECT 
  transaction_type,
  ROUND(SUM(total_amount),2) AS total_sales,
  SUM(SUM(total_amount)) OVER () AS overall_sales
  FROM `wisdom_pets.sales`
  GROUP BY transaction_type
)
SELECT 
  transaction_type,
  total_sales,
  ROUND(
    total_sales/overall_sales,
    2
   ) AS percentage_breakdown
FROM perc_table;


--INNER JOIN 
--Ques: Which products have the most total sales?
--Return the product name, category, sales and quantity
SELECT
  product_name,
  category_name,
  SUM(total_amount) AS total_sales,
  SUM (quantity) AS total_quantity
FROM `wisdom_pets.sales` AS sales
INNER JOIN `wisdom_pets.products` AS products 
  ON sales.product_id = products.product_id
GROUP BY 
  products.product_name,
  products.category_name
ORDER BY total_sales DESC;      


--LEFT JOIN 
--Ques:What are the total sales for retail vs wholesale customers?
-- Are there any transactions from unregistered customers?
SELECT
  CASE
    WHEN customers.business_name IS NULL THEN 'retail'
    WHEN customers.business_name IS NOT NULL THEN 'Wholesale'
    ELSE NULL
  END customer_type,
  CASE 
    WHEN customers.customer_id IS NULL THEN 'Unregistered'
    WHEN customers.customer_id IS NOT NULL THEN 'Registered'
    ELSE NULL
    END as registration_status,
  SUM(sales.total_amount) AS total_amount
FROM `wisdom_pets.sales` AS sales
LEFT JOIN `wisdom_pets.customers`AS customers
  ON sales.customer_id = customers.customer_id
GROUP BY customer_type, registration_status;


--Challenge Questions
--What are the average transaction sizes for wholesale and retail 
--transaction types, split by customer VIP status

WITH cte_transaction_size AS (
SELECT 
  sales.transaction_type,
  sales.transaction_id,
  customers.vip_customer_flag,
  SUM(total_amount) AS total_sales,
FROM  `wisdom_pets.sales` sales
INNER JOIN `wisdom_pets.customers` customers
  ON sales.customer_id = customers.customer_id 
GROUP BY 
  sales.transaction_type,
  sales.transaction_id,
  customers.vip_customer_flag
)
SELECT
  transaction_type,
  vip_customer_flag,
  AVG(total_sales)
FROM cte_transaction_size
GROUP BY 
  transaction_type,
  vip_customer_flag;

--Ques: What is the total discount amount for all wholesale transactions? 
WITH cte_product_discount AS (
SELECT 
  sales.product_id,
  sales.quantity,
  products.retail_price * (products.wholesale_discount_percentage / 100 ) AS discount_amount_per_unit
FROM `wisdom_pets.sales` AS sales
INNER JOIN `wisdom_pets.products` AS products
  ON sales.product_id = products.product_id
  WHERE transaction_type = 'Wholesale'
)
SELECT
  SUM(quantity * discount_amount_per_unit) AS total_discount_amount
FROM cte_product_discount;


--WINDOW FUNCTIONS
--RANK FUNCTION 
--Ques: Identify the top 5 customer IDs by sales performance and show their total sales amount
SELECT
  customer_id,
  SUM(total_amount) AS total_sales,
  RANK() OVER(
    ORDER BY SUM(total_amount) DESC
  ) AS sales_rank
FROM `wisdom_pets.sales`
GROUP BY customer_id
QUALIFY sales_rank <=5 --Qualify operator is similar like the LIMIT operator, it just comes before ORDER BY
ORDER BY sales_rank ASC;


--Cumulative Metrics
--Ques: What are the monthly cumulative retail sales in 2022?
WITH cte_monthly_sales AS (
SELECT
  DATE_TRUNC(transaction_date, MONTH) AS month_start,
  SUM(total_amount) AS monthly_sales
FROM `wisdom_pets.sales`
WHERE transaction_date BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY month_start
)
SELECT
  month_start,
  monthly_sales,
  SUM(monthly_sales) OVER(
    ORDER BY month_start
  ) AS monthly_cumulative_sales
FROM cte_monthly_sales
ORDER BY month_start;


--Moving Averages - To find the average of previous 7 days or 1/2 month. 
--Ques: What are the latest 7 and 28 day moving average of daily sales for wholesale and retail transactions? 
WITH cte_daily_sales AS (
SELECT
  transaction_type, 
  transaction_date,
  SUM(total_amount) AS daily_sales
FROM `wisdom_pets.sales`
GROUP BY
  transaction_type, 
  transaction_date
ORDER BY 
  transaction_date
  )
SELECT
  transaction_type,
  AVG(daily_sales) OVER(
    PARTITION BY transaction_type
    ORDER BY UNIX_DATE(transaction_date)
    RANGE BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS sales_7_day_moving_average,
  AVG(daily_sales) OVER(
    PARTITION BY transaction_type
    ORDER BY UNIX_DATE(transaction_date)
    RANGE BETWEEN 27 PRECEDING AND CURRENT ROW
  ) AS sales_28_day_moving_average,
FROM cte_daily_sales
QUALIFY RANK() OVER(ORDER BY transaction_date DESC) = 1;


--CHALLENGE QUESTIONS 
--Question 1: What is the most purchased item for each customer?
-- How many units, what was the total amount of their historic top item purchase? 
WITH cte_customer_product_sales AS (
  SELECT
  customer_id,
  product_id,
  SUM(quantity) AS total_units,
  SUM(total_amount) AS total_sales
FROM `wisdom_pets.sales` 
GROUP BY 
  customer_id,
  product_id
)
SELECT 
  customer_id,
  product_id,
  total_units,
  total_sales
FROM cte_customer_product_sales
QUALIFY RANK() OVER(
  PARTITION BY customer_id
  ORDER BY total_units DESC
) = 1
ORDER BY customer_id;


--Question 2: When was the last purchase made by each customer? 
--What was their 30-day moving total spend on this date? 
WITH cte_customer_daily_sales AS (
  SELECT 
  customer_id,
  transaction_date,
  SUM(total_amount) AS daily_sales
FROM `wisdom_pets.sales`
GROUP BY customer_id, transaction_date
)
SELECT
  customer_id,
  transaction_date,
  SUM(daily_sales) OVER(
    PARTITION BY customer_id
    ORDER BY UNIX_DATE(transaction_date)
    RANGE BETWEEN 39 PRECEDING AND CURRENT ROW
  ) AS total_sales_moving_avg_30_days
FROM cte_customer_daily_sales
QUALIFY RANK() OVER(
  PARTITION BY customer_id
  ORDER BY transaction_date DESC
) = 1;

--THANK YOU 








