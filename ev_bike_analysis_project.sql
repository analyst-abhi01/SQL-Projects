create schema evbike_db

select * from rides;
select * from users;
select * from stations;

-- KPI's
select
	(select count(*) from rides) as total_rides,
	(select count(*) from stations) as total_stations,
	(select count(*) from users) as total_users

-- checking for missing values:
SELECT
    SUM(CASE WHEN ride_id IS NULL THEN 1 ELSE 0 END) AS missing_ride,
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS missing_user,
    SUM(CASE WHEN start_time IS NULL THEN 1 ELSE 0 END) AS missing_start,
    SUM(CASE WHEN end_time IS NULL THEN 1 ELSE 0 END) AS missing_end
FROM rides;

-- Statistics summary of the rides table:
select 
	min(distance_km) as min_distance,
    max(distance_km) as max_distance,
    round(avg(distance_km),2) as avg_distance,
    MIN(TIMESTAMPDIFF(MINUTE, start_time, end_time)) AS min_duration_mins,
    MAX(TIMESTAMPDIFF(MINUTE, start_time, end_time)) AS max_duration_mins,
    round(AVG(TIMESTAMPDIFF(MINUTE, start_time, end_time)),2) AS avg_duration_mins
from rides;

-- checking for false starts for the rides:
SELECT 
    COUNT(IF(distance_km = 0, 1, NULL)) AS zero_distance_count,
    COUNT(IF(TIMESTAMPDIFF(MINUTE, start_time, end_time) < 2, 1, NULL)) AS short_rides_count
FROM rides;

-- different membership:
SELECT 
	u.membership_level,
    count(r.ride_id) as rides_count,
    round(avg(distance_km),2) as avg_distance,
    round(avg(TIMESTAMPDIFF(MINUTE, r.start_time, r.end_time)),2) as avg_duration
from rides r
left join users u
	on u.user_id=r.user_id
group by u.membership_level
order by 2 DESC;

-- peek hours:
select
	EXTRACT(HOUR FROM start_time) as hour_of_day,
    count(*) as rides_cnt
from rides
group by 1
order by 2 DESC

-- TOP 10 popular stations:
select 
	s.station_name,
    count(r.ride_id) AS rides_cnt
from stations s
left join rides r
	on r.start_station_id=s.station_id
group by s.station_name
order by 2 DESC
LIMIT 10;

-- categorizing rides into short, medium and long rides;
select
CASE
	WHEN timestampdiff(MINUTE, start_time, end_time)<=10 THEN 'Short (<10min)'
    WHEN timestampdiff(MINUTE, start_time, end_time) BETWEEN 11 and 30 THEN 'Medium (11-30min)'
ELSE 'Long (>30min)'
END AS ride_category, 
count(*) as rides_cnt
from rides
GROUP BY ride_category
order by rides_cnt DESC

-- net flow for each station:
with departures_cte as (
	select start_station_id, count(*) as total_departures
	from rides
	group by 1
), 
arrivals_cte as (
	select end_station_id, count(*) as total_arrivals
    from rides
    group by 1 
)
select 
	s.station_name,
    d.total_departures,
    a.total_arrivals,
   (a.total_arrivals-d.total_departures) as net_flow
from stations s
join departures_cte d
	on s.station_id= d.start_station_id
join arrivals_cte a
	on s.station_id=a.end_station_id
order by net_flow ASC

-- user retention:
with monthly_signup_CTE as (
	SELECT 
		DATE_FORMAT(created_at, '%Y-%m') AS signup_month,
		COUNT(*) AS new_user_cnt
	FROM users
	GROUP BY signup_month
)
select 
	signup_month,
	new_user_cnt,
    LAG(new_user_cnt) over(order by signup_month) as prev_month_cnt,
    round(
		((new_user_cnt - LAG(new_user_cnt) over (order by signup_month)) / 
		NULLIF(LAG(new_user_cnt) over(order by signup_month),0) * 100)
		,2) as MoM_growth
from monthly_signup_CTE
order by signup_month;