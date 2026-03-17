create database Ecommerce
use Ecommerce

Create Table Customers(
customer_id	varchar(50) primary key,
customer_unique_id	varchar(50),
customer_zip_code_prefix	int,
customer_city	varchar(100),
customer_state varchar(10)
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Customers.csv'
INTO TABLE Customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from Customers

Create table Sellers(
seller_id varchar(50) primary key,
seller_zip_code_prefix	int,
seller_city	varchar(100),
seller_state varchar(10)
);

LOAD DATA INFILE "D:/Clean_data new_project/Sellers.csv"
INTO TABLE Sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

UPDATE sellers
SET seller_city = NULL
WHERE seller_city REGEXP '^[0-9]+$';

SET SQL_SAFE_UPDATES = 0

Create table Products(
product_id	varchar(50) primary key,
product_category_name	varchar(100),
product_name_lenght	int,
product_description_lenght	int,
product_photos_qty	int,
product_weight_g	float,
product_length_cm	float,
product_height_cm	float,
product_width_cm	float,
product_volume_cm3 float
);

LOAD DATA INFILE "D:/Clean_data new_project/Product.csv"
INTO TABLE Product
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


Create table Orders(
order_id varchar(50) primary key,
customer_id	varchar(50),
order_status	varchar(20),
order_purchase_timestamp datetime,
order_approved_at	datetime,
order_delivered_carrier_date	datetime,
order_delivered_customer_date	datetime,
order_estimated_delivery_date	datetime,
delivery_delay_days	float,
delivery_days float,

foreign key(customer_id) references Customers(customer_id)
);

LOAD DATA INFILE "D:/Clean_data new_project/Order_clean.csv"
INTO TABLE Orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from Orders

Create table Order_Items(
order_id varchar(50),
order_item_id	int,
product_id	varchar(50),
seller_id	varchar(50),
shipping_limit_date	datetime,
price	float,
freight_value	float,
total_item_value float,

primary key(order_id,order_item_id),

foreign key(order_id) references Orders(order_id),
foreign key(product_id) references Products(product_id),
foreign key(seller_id) references Sellers(seller_id)
);

LOAD DATA INFILE "D:/Clean_data new_project/order_item (1).csv"
INTO TABLE Orders_Item
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from Order_Items

Create table Order_Payments (
order_id	varchar(50),
payment_sequential	int,
payment_type	varchar(20),
payment_installments	int,
payment_value float,

primary key(order_id,payment_sequential),

foreign key(order_id) references Orders(order_id)
);

LOAD DATA INFILE "D:/Clean_data new_project/Orders_Payments.csv"
INTO TABLE Order_Payments
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

Create table Order_Reviews(
review_id	varchar(50) primary key,
order_id	varchar(50),
review_score	int,
review_creation_date	datetime,
review_answer_timestamp	 datetime,
response_time_hours float,

foreign key(order_id) references Orders(order_id)
);

LOAD DATA INFILE "D:/Clean_data new_project/order_review.csv"
INTO TABLE Order_Reviews
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from Order_Reviews

select * from customers;
select * from order_payments;
select * from orders;
select * from order_items;
select * from order_reviews;
select * from products;
select * from sellers;

/* Basic Business Metrics */

/* total_revenue  16008872.12 */
select round(sum(payment_value),2) as total_revenue
from order_payments;

/* total_customers 96096 */
select count(distinct customer_unique_id) as total_customers 
from customers;

/* total_orders 99441 */
select count(*) as total_orders
from Orders;

/* monthly revenur trend */
select 
year(o.order_purchase_timestamp)as year,
month(o.order_purchase_timestamp) as month,
round(sum(p.payment_value),2) as revenue
from orders o left join order_payments p
on o.order_id=p.order_id
group by year,month;

/* Insight: Shows business growth over time */

/* Top 10 Selling Products */
select product_id,
count(*) as total_sales
from order_items
group by product_id
order by total_sales desc
limit 10;

/* Top 10 Product Categories by product_Revenue */
select p.product_category_name,
round(sum(oi.price),2) as product_revenue
from order_items oi left join products p
on oi.product_id=p.product_id
group by  p.product_category_name
order by product_revenue desc
limit 10

/* Insight: Identifies most profitable product categories */

/* Top 10 Sellers by Revenue */
select s.seller_id,
round(sum(oi.price),2) as total_seller_revenue
from order_items oi left join sellers s
on oi.seller_id=s.seller_id
group by s.seller_id
order by total_seller_revenue desc
limit 10;

/* Insight: Shows which sellers generate the most sales */

/* Average Order Value 154.1 */
select round(avg(payment_value),2) as avg_order_value
from order_payments;

/* Insight: Shows how much customers spend per order */

/* Top States by Number of Customers */
select customer_state,
count(*) as total_customers
from customers
group by customer_state
order by total_customers desc;

/* Repeat Customers */
select c.customer_unique_id,
count(o.order_id) as total_orders
from customers c  left join orders o 
on o.customer_id=c.customer_id
group by c.customer_unique_id 
having count(o.order_id) > 1
order by total_orders desc;

/* Insight: Shows customer retention */

/* Delivery Performance Analysis */
select round(avg(delivery_days),2) as avg_delivery_days
from orders;

/* Insight: Measures delivery efficiency: avg_delivery_days = 12.09 */

/* Late Deliveries */
select count(*)as late_deliveries 
from orders
where delivery_delay_days > 0;

/* Insight: Shows logistics problems */

/* rating Distribution */
select review_score,
count(*) as total_reviews
from order_reviews
group by review_score 
order by total_reviews desc;

/* Insight: Measures customer satisfaction */

/* Delivery Delay vs Review Score */

select 
case
when o.delivery_delay_days > 0 then 'late'
else 'on time'
end as delivery_status,
round(avg(r.review_score),2) as avg_review_score
from orders o left join order_reviews r
on o.order_id=r.order_id
group by delivery_status;

/* Insight: Late deliveries reduce review scores by 1.9 points on average.
/* Insight: Shows impact of delivery delays on ratings */

/* Average Review Score */
select round(avg(review_score),2) as avg_review_score
from order_reviews;

/* Top 5 Products per Category */
select * from(
select p.product_category_name,
oi.product_id,
count(*) as total_sales,
dense_rank() over(partition by p.product_category_name order by count(*) desc) as rank_num
from products p left join order_items oi
on p.product_id=oi.product_id
group by p.product_category_name,oi.product_id
)ranked_products
where rank_num <= 5

/* Insight: Shows top products in each category */

/* Revenue by State */
select c.customer_state,
round(sum(p.payment_value),2) as total_revenue
from customers c left join orders o
on c.customer_id=o.customer_id
join order_payments p
on o.order_id=p.order_id
group by c.customer_state
order by total_revenue desc;

/* Insight: Shows which regions generate the most revenue */

select customer_city,
count(distinct customer_unique_id) as total_customers
from customers 
group by customer_city
order by total_customers desc;

/*Insight: Most customers come from São Paulo city */

select customer_state,
count(distinct customer_unique_id) as total_customers
from customers 
group by customer_state
order by total_customers desc;

/* Insight: /* Most customers come from SP state */

select p.product_category_name,
round(sum(oi.price),2) as revenue
from products p left join order_items oi
on p.product_id=oi.product_id
group by p.product_category_name
order by revenue desc;

/* Insight: Beauty and Health (beleza_saude) is the highest revenue generating category with 275,366.76 in sales.*/

select round(sum(price)* 100 /
(select sum(price) from order_items),2) as top50_revenue_percenatge
from (
select seller_id,sum(price) as price
from order_items
group by seller_id
order by price desc 
limit 50
)t;


/* top 50 sellers generate 33.66% seller_revenue

/* Customer Lifetime Value (CLV) */
/* q.1] Find how much revenue each customer generates over time. */

select o.customer_id,
count(o.order_id) as total_orders,
round(sum(p.payment_value),2) as total_revenue
from orders o left join order_payments p
on o.order_id=p.order_id
group by o.customer_id
order by total_revenue desc;

/* insight: Helps identify high-value customers who contribute the most revenue.*/

/* RFM Customer Segmentation */
select o.customer_id,
datediff(max(o.order_purchase_timestamp),min(o.order_purchase_timestamp)) as recency,
count(o.order_id) as frequency,
round(sum(p.payment_value),2) as monetary
from orders o left join order_payments p
on o.order_id=p.order_id
group by o.customer_id;

select a.product_id as product1,
b.product_id as product2,
count(*) as times_bought_together
from order_items a join order_items b
on a.order_id=b.order_id
and a.product_id < b.product_id
group by a.product_id,b.product_id
order by times_bought_together desc;

select delivery_days,
count(*) as total_orders
from orders
group by delivery_days
order by delivery_days;

/* Seller Performance vs Reviews */
select oi.seller_id,
round(avg(r.review_score),2) as avg_rating,
count(*) as total_orders
from order_items oi left join order_reviews r
on oi.order_id=r.order_id
group by oi.seller_id
order by avg_rating desc;

/* Insight: Best performing sellers
Sellers affecting customer satisfaction */

/* monthly order volume */
select year(order_purchase_timestamp) as year,
month(order_purchase_timestamp) as month,
count(order_id) as total_orders
from orders
group by year,month
order by year,month;

/* Revenue Contribution by Customer Segments */

select 
case
when total_spent >= 500 then 'high value'
when total_spent >= 200 then 'medium value'
else 'low value'
end as customer_segment,
count(*) as customers 
from(
select o.customer_id,
round(sum(p.payment_value),2)as total_spent
from orders o left join order_payments p
on o.order_id=p.order_id
group by o.customer_id
)t
group by customer_segment;

/* Most customers fall into the low-value segment.
Low-value customers: 79,161 (~80% of total customers)
Medium-value customers: 15,984 (~16%)
High-value customers: 4,296 (~4%)*/

