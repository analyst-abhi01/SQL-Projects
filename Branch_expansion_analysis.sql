													# MONDAY COFFEE EXPANSION ANALYSIS

select * from products;
select * from city;
select * from customers;
select * from sales;

-- Business Requirement: Suggest 3 major cities in India to setup coffee shops --

# Coffee consumer counts: How many people in each city are estimated to consume coffee, give that 25% of population does?
SELECT 
city_id,
city_name,
population,
	ROUND((population * 0.25)/1000000,2) AS estimated_coffee_consumers_in_millions
FROM city
order by estimated_coffee_consumers_in_millions DESC;

# 2. Total revenue from coffee sales: What is the total revenue generated from coffee sales across all cities in last qtr of 2023?
SELECT 
	ct.city_name,
	SUM(s.total) as total_revenue
FROM sales s
	JOIN customers c
		ON c.customer_id= s.customer_id
	JOIN city ct
		ON ct.city_id=c.city_id
WHERE 
	EXTRACT(QUARTER from s.sale_date)=4
		AND 
	EXTRACT(YEAR from s.sale_date)=2023
GROUP BY 1
ORDER BY total_revenue DESC;

# 3. Sales count for each product: How many units of each coffee product have been sold?
select 
	p.product_name, 
	count(s.sale_id) as total_orders
from sales s
right join products p
	on s.product_id=p.product_id
group by p.product_name
order by total_orders DESC;

# 4.Avg. sales amount per city: what is the avg sales amount per customer in each city?
select 
	ct.city_name,
    sum(s.total) as total_revenue,
    count(DISTINCT s.customer_id) as unqiue_cx,
    round(
		(sum(s.total)/count(DISTINCT s.customer_id)),2) as avg_sales_per_cx
from sales s
	join customers c
		on c.customer_id= s.customer_id
	left join city ct
		on c.city_id=ct.city_id
group by ct.city_name
order by avg_sales_per_cx DESC;

# 5. City population and coffee consumer: Provide a list of cities along with their population and estimated coffee consumer?
-- return city_name, total_current_customers
with cte_1 as(
	select 
		city_name, 
		round(((population* 0.25)/1000000),2) as estimated_coffee_consumer_in_millions
	from city
),
cte_2 as(
    select
		ct.city_name,
		count(DISTINCT s.customer_id) as unqiue_cx
	from sales s
	join customers cs
		on cs.customer_id=s.customer_id
	join city ct
		on cs.city_id=ct.city_id
	group by 1
)
select 
	cte_2.city_name, 
	cte_1.estimated_coffee_consumer_in_millions,
    cte_2.unqiue_cx
from cte_1
join cte_2
	on cte_2.city_name= cte_1.city_name
order by cte_1.estimated_coffee_consumer_in_millions DESC;

-- Top Selling Products by City: What are the top 3 selling products in each city based on sales volume?
with cte_1 as(
	select 
		ct.city_name, 
		p.product_name, 
        count(s.sale_id) as total_orders,
        sum(s.total) as total_sales,
		dense_rank() over(partition by ct.city_name order by count(s.sale_id) DESC) as sales_rank
	from sales s
	join products p
		on p.product_id=s.product_id
	join customers cs 
		on cs.customer_id=s.customer_id
	join city ct
		on cs.city_id=ct.city_id
	group by ct.city_name, p.product_name
)
select * from cte_1
where sales_rank <=3

-- Customer Segmentation by City: How many unique customers are there in each city who have purchased coffee products?
select 
	ct.city_name,
	count(DISTINCT s.customer_id) as unique_customers
from sales s
join customers c
	on c.customer_id = s.customer_id
join city ct
	on ct.city_id=c.city_id
where s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by ct.city_name
    
-- Average Sale vs Rent: Find each city and their average sale per customer and avg rent per customer.
WITH cte_1 AS (
    SELECT 
        ct.city_id,
        ct.city_name,
        COUNT(DISTINCT c.customer_id) AS customers_count,
        ROUND(SUM(s.total) / COUNT(DISTINCT c.customer_id), 2) AS avg_sale_per_customer
    FROM sales s
    JOIN customers c 
        ON c.customer_id = s.customer_id
    JOIN city ct 
        ON ct.city_id = c.city_id
    GROUP BY ct.city_id, ct.city_name
)
SELECT 
    cte_1.city_name,
    ct.estimated_rent,
    cte_1.customers_count,
    cte_1.avg_sale_per_customer,
    ROUND(ct.estimated_rent / cte_1.customers_count, 2) AS avg_rent_per_customer
FROM cte_1
JOIN city ct 
    ON ct.city_id = cte_1.city_id;
    
-- Monthly Sales Growth Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
with cte_monthly_sales as(
	select 
		ct.city_name, 
		MONTH(s.sale_date) as months,
		YEAR(s.sale_date) as years,
		sum(s.total) as total_sale
	from sales s
	join customers c
		on c.customer_id=s.customer_id
	join city ct
		on ct.city_id=c.city_id
	group by 1,2,3
	order by 1,3,2
),
cte_growth_ratio as (
select 
	city_name,
    months,
    years,
    total_sale as curr_month_sale,
   lag(total_sale,1) over(partition by city_name order by years, months) as prev_month_sale
from cte_monthly_sales
)
select 
	city_name,
    months,
    years,
    curr_month_sale,
    prev_month_sale,
    round(
		(curr_month_sale-prev_month_sale)/prev_month_sale*100,2) as growth_rate
from cte_growth_ratio
where prev_month_sale IS NOT NULL;

-- Market Potential Analysis: Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table AS
(SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customers,
		ROUND(
			SUM(s.total)/ COUNT(DISTINCT s.customer_id),2) as avg_sale_pr_customer
	FROM sales as s
	JOIN customers as c
		ON s.customer_id = c.customer_id
	JOIN city as ci
		ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent AS
(SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customers,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_customer,
	ROUND(cr.estimated_rent/ct.total_customers, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
	ON cr.city_name = ct.city_name
ORDER BY 2 DESC

# ☕ Monday Coffee – Expansion Recommendation Analysis
#🎯 Objective
-- 1.Identify the Top 3 cities where Monday Coffee should open its next branches based on:
-- 2.Revenue potential
-- 3. Market size
-- 4.Rental cost efficiency
-- 5.Customer spending behavior

# RECOMMENDATION 1: Pune should be the first priority for expansion due to strong profitability and cost efficiency.
-- 1st Pune – Strongest Overall Opportunity:
/* 
1. Highest Revenue: ₹1.26M (highest among all cities)
2. Highest Avg Sale per Customer: ₹24.1K
3. Lowest Rent: ₹15.3K
4. Lowest Avg Rent per Customer: ₹294
5. 1.87M Estimated Coffee Consumers
*/
-- Pune gives:
/* 
1. High spending customers
2. Lower operating cost
3. Strong revenue base
*/

# RECOMMENDATION 2: Chennai should be the second expansion target due to its strong market size and balanced cost structure.
-- 2nd Chennai – Large Consumer Base + Balanced Economics
/*
1. Revenue: ₹944K
2. Estimated Consumers: 2.77M (Large market size)
3. Moderate Rent: ₹17.1K
4. Avg Sale per Customer: ₹22.4K
5. Avg Rent per Customer: ₹407
*/
-- Chennai offers:
/*
1. Bigger untapped market
2. Healthy customer spending
3. Reasonable rent
*/

# RECOMMENDATION 3: Bangalore should be the third priority, suitable for premium positioning or high-footfall areas.
-- 3rd Bangalore – Large Market but Higher Cost
/*
1. Revenue: ₹860K
2. Largest Consumer Base: 3.07M
3. Highest Rent: ₹29.7K
4. Highest Avg Rent per Customer: ₹761
*/
-- Bangalore offers:
/*
1. Huge market potential
2. But significantly higher operational cost
3. Margins may be tighter initially.
*/