													# 1st SQL PROJECT
												# Digital music store Analysis 

# 1. who is the senior most employee based on job titles?
select * from employee
	order by levels DESC 
		limit 1;

# 2. which countries have the most invoices?
select billing_country, COUNT(*) as total_invoices 
	from invoice
group by billing_country
order by total_invoices  DESC;

# 3. What are top 3 values of total invoice?
select *
	from invoice
	order by total DESC
limit 3;

# 4. Which city has the best customers? We would like to throw a promotional music festival in the city we made the most money. Write a query that 
# returns one city has the highest sum of invoice totals. return both city name and sum of all invoice totals?
select billing_city, sum(total) as invoice_total
	from invoice
		group by billing_city
	order by invoice_total DESC 
limit 1 ;

# 5. Who is the best customer? The customer who has spent the most money will be declared the best customer. Write a query that returns the person 
# who has spent the most money?
select c.customer_id, concat(first_name, " ", last_name) 
	as full_name, round(sum(i.total),2) as total_amount
	from customer c
		join invoice i
			on c.customer_id=i.customer_id 
		group by c.customer_id 
	order by total_amount DESC
limit 1;

# 6. write a query to return the email, first_name, last_name & genre of all rock music listeners. 
# Return your list ordered alphabetically by emailing starting with A?
select distinct email, first_name, last_name 
	from customer c
		Join invoice i 
			on c.customer_id = i.customer_id
		join invoice_line il
	on i.invoice_id = il.invoice_id
where track_id in 
		(select track_id from track t
			join genre g on t. genre_id = g.genre_id
				where g.name like "rock")
order by email ASC ;

## 7. Lets invite the artists who have written the most rock music in our dataset. Write a query that returns the
#            artist name and total track count of the top 10 rock bands.
 select art.artist_id, art.name, count(art.artist_id) as number_of_songs
	from track t
		join album a
			on a.album_id=t.album_id
				join artist art
					on art.artist_id= a.artist_id
						join genre g
				on g.genre_id=t.genre_id
			where g.name like "rock"
		group by art.artist_id
	order by number_of_songs DESC 
limit 10;

# To disbale the strict mode in MYSQL:
SHOW VARIABLES LIKE 'sql_mode';
set global sql_mode='';

## 8. Rerurn all the track names that have a song length longer than the average song length. Return the name and milliseconds for 
	# each track. Order by the song length with the longest songs listed first.
select name, milliseconds 
	from track 
		where milliseconds > (
				SELECT AVG(milliseconds) AS avg_track_length
				FROM track)
order by milliseconds DESC 
;

## 9. Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent.
WITH best_selling_artists AS (
    SELECT a.artist_id AS artist_id, a.name AS artist_name, 
    ROUND(SUM(il.unit_price * il.quantity),2) AS total_sales
    FROM invoice_line il
    JOIN track t ON t.track_id = il.track_id
    JOIN album al ON al.album_id = t.album_id
    JOIN artist a ON a.artist_id = al.artist_id
    GROUP BY a.artist_id, a.name
    ORDER BY total_sales DESC
    LIMIT 1
)
SELECT c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
round(SUM(il.unit_price * il.quantity),2) AS amount_spent
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_selling_artists bsa ON bsa.artist_id = alb.artist_id
GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
ORDER BY amount_spent DESC;

## 10. WE WANT TO FIND OUT THE MMOST POPULAR MUSIC GENRE FOR EACH COUNTRY. WE DETERMINE THE MOST POPULAR GENRE AS THE GENRE WITH THE HIGGHEST AMOUNT 
# OF PURCHASES. WRITE A QUERY THAT RETURNS EACH COUNTRY ALONG WOTH THE TOP GENRE. FOR COUNTRIES WHERE THE MAXIMUM NO. OF PRURCHASESSHARED RETURN ALL 
# GENRES.
WITH popular_genre AS (
    SELECT 
        COUNT(il.quantity) AS purchases, 
        c.country, 
        g.name AS genre_name, 
        g.genre_id, 
        ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS RowNo
    FROM invoice_line il
    JOIN invoice i ON i.invoice_id = il.invoice_id
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY c.country, g.name, g.genre_id
    ORDER BY c.country ASC, purchases DESC
)
SELECT * 
FROM popular_genre 
WHERE RowNo <= 1;

/* Method 2: : Using Recursive */
WITH RECURSIVE
	sales_per_country AS(
		SELECT COUNT(*) AS purchases_per_genre, customer.country, genre.name, genre.genre_id
		FROM invoice_line
		JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
		JOIN customer ON customer.customer_id = invoice.customer_id
		JOIN track ON track.track_id = invoice_line.track_id
		JOIN genre ON genre.genre_id = track.genre_id
		GROUP BY 2,3,4
		ORDER BY 2
	),
	max_genre_per_country AS (SELECT MAX(purchases_per_genre) AS max_genre_number, country
		FROM sales_per_country
		GROUP BY 2
		ORDER BY 2)

SELECT sales_per_country.* 
FROM sales_per_country
JOIN max_genre_per_country ON sales_per_country.country = max_genre_per_country.country
WHERE sales_per_country.purchases_per_genre = max_genre_per_country.max_genre_number;

# 11. write a query that determines the customer that has spent the most on music for each country. ewrite a query that returns the country along 
# with the top customer an how much they spent. for countries where the top amount spent is shared , provide all customers who spent this amount..
with recursive 
	customer_with_country as (
		select c.customer_id, first_name, last_name, billing_country, sum(total) as total_spent
        from invoice i
        join customer c
			on c.customer_id=i.customer_id
		group by 1,2,3,4
        order by 1,5 DESC), 
        
	country_max_spending as (
    select billing_country, max(total_spent) as max_spending
    from customer_with_country
    group by billing_country)

select cc.billing_country, cc.total_spent, cc.first_name, cc.last_name
from customer_with_country cc
join country_max_spending cms
	on cc.billing_country=cms.billing_country
where cc.total_spent=cms.max_spending
order by 1;

/* Method 2: using CTE */

WITH Customter_with_country AS (
		SELECT customer.customer_id,first_name,last_name,billing_country,
        round(SUM(total),2) AS total_spending,
	    ROW_NUMBER() OVER(PARTITION BY billing_country ORDER BY SUM(total) DESC) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC,5 DESC)
SELECT * FROM Customter_with_country WHERE RowNo <= 1
