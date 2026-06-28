select * from customers;
select * from geolocation;
select * from leads_closed;
select * from leads_qualified;
select * from order_items;
select * from order_payments;
select * from order_reviews;
select * from orders;
select * from product_category_name_translation;
select * from products;
select * from sellers;


-- Question 1: Find the total number of orders fulfilled by each seller state. 
SELECT 
    s.seller_state, COUNT(DISTINCT oi.order_id) AS Total_orders
FROM
    sellers s
        JOIN
    order_items oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_state
ORDER BY Total_orders DESC;

 
-- Q 2  For each product category, calculate the cumulative revenue generated as orders come in over time.
 
      with category_revenue as (
    select 
pct.product_category_name_english,
     date(o.order_purchase_timestamp) as order_date,
	 sum(oi.price) as revenue
 from orders o 
 join order_items oi 
     on o.order_id = oi.order_id
 join products p 
     on p.product_id = oi.product_id
 join product_category_name_translation  pct
     on p.product_category_name = pct.product_category_name
     group by pct.product_category_name_english , 
     date(o.order_purchase_timestamp))
select 
product_category_name_english ,
order_date,
revenue ,
sum(revenue) over
(
partition by product_category_name_english 
order by order_date
      rows between unbounded 
preceding and current row
      )as cumulative_revenue
from category_revenue
order by 
      product_category_name_english , 
      order_date;



-- Q 3 Which payment method do customers use the most, and what is the average order value for each payment type? 
SELECT 
    payment_type,
    COUNT(DISTINCT order_id) AS Total_orders,
    AVG(Order_total) AS average_order_value
FROM
    (SELECT 
        order_id, payment_type, SUM(payment_value) AS Order_total
    FROM
        order_payments
    GROUP BY order_id , payment_type) AS Payment_summary
GROUP BY payment_type
ORDER BY Total_orders DESC;

 
-- 4 Find the customer who has spent the most money across all their orders. 
SELECT 
    customer_unique_id, SUM(op.payment_value) AS Total_spent
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_payments op ON o.order_id = op.order_id
GROUP BY c.customer_unique_id
ORDER BY Total_spent DESC
LIMIT 1;


-- Q 5 Find the average review score for each product category. 
SELECT 
    pct.product_category_name_english,
    AVG(ore.review_score) AS Average_review_score
FROM
    order_reviews ore
        JOIN
    order_items oi ON ore.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY Average_review_score DESC;


-- Q 6 : Find the total number of orders placed by each customer, broken down by the state they live in.
SELECT 
    c.customer_unique_id,
    c.customer_state,
    COUNT(DISTINCT order_id) AS Total_orders
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_state , c.customer_unique_id
ORDER BY Total_orders DESC;

-- Q 7  Identify sellers who registered on the platform but have never fulfilled a single order.
SELECT 
    s.seller_id, s.seller_city, s.seller_state
FROM
    sellers s
        LEFT JOIN
    order_items oi ON s.seller_id = oi.seller_id
WHERE
    oi.seller_id IS NULL;


-- Q 8 Find the top 5 product categories by total revenue.
SELECT 
    pct.product_category_name_english AS product_category,
    SUM(oi.price) AS Total_revenue
FROM
    products p
        JOIN
    order_items oi ON p.product_id = oi.product_id
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY Total_revenue DESC
LIMIT 5;
 

-- Q 9 Find the median delivery time (in days) between order placement and actual delivery.

with delivery_time as (
SELECT 
    order_id,
    DATEDIFF(order_delivered_customer_date,
            order_purchase_timestamp) AS delivery_days
FROM
    orders
WHERE
    order_delivered_customer_date IS NOT NULL)
  select 
      round(avg(delivery_days),0) as median_delivery_time
  from 
  (
  select 
    delivery_days , 
    row_number() over(
    order by delivery_days ) 
    as row_num,
   count(*) over () as total_rows 
   from delivery_time ) as rankeddata 
   where 
      row_num in (
   floor ((total_rows + 1)/2),
   ceil ((total_rows + 1)/2)
   );


-- Q 10 Find all products that have never been ordered. 
SELECT 
    p.product_id, p.product_category_name
FROM
    products p
        LEFT JOIN
    order_items oi ON p.product_id = oi.product_id
WHERE
    oi.product_id IS NULL;


-- Q 11 Find sellers who have fulfilled more orders than the average seller on the platform.

SELECT 
    oi.seller_id, COUNT(DISTINCT oi.order_id) AS total_orders
FROM
    order_items oi
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT oi.order_id) > (SELECT 
        AVG(seller_order_count)
    FROM
        (SELECT 
            seller_id, COUNT(DISTINCT order_id) AS seller_order_count
        FROM
            order_items
        GROUP BY seller_id) AS Seller_orders);
 
-- Q 12 Find which Brazilian states have the highest average customer review score for orders delivered there. 
SELECT 
    c.customer_state,
    AVG(ore.review_score) AS average_review_score
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        JOIN
    order_reviews ore ON o.order_id = ore.order_id
GROUP BY c.customer_state
ORDER BY average_review_score DESC;


-- Q 13  Identify customers who have placed orders but never left a review. 
SELECT 
    c.customer_unique_id
FROM
    customers c
        JOIN
    orders o ON c.customer_id = o.customer_id
        LEFT JOIN
    order_reviews ore ON o.order_id = ore.order_id
WHERE
    ore.order_id IS NULL
GROUP BY c.customer_unique_id;

-- Q 14 Find the month with the highest number of orders placed across the entire platform. 

SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(order_id) AS total_orders
FROM
    orders
GROUP BY YEAR(order_purchase_timestamp) , MONTH(order_purchase_timestamp)
ORDER BY total_orders DESC
LIMIT 1;





