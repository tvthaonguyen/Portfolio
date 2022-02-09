--Tháng đầu khách hàng mua hàng
WITH user_first_month as (
SELECT user_id,
	   FORMAT(MIN(ACTIVITY_DATE),'yyyyMM') as first_month
FROM [SSSMarket].[dbo].[user_data]
GROUP BY user_id),

--Đếm số lượng khách mới theo tháng đầu mua hàng
count_new_users as (
SELECT first_month,
		COUNT(distinct user_id) as new_users_by_month
FROM user_first_month
GROUP BY first_month
),

--Tất cả các ngày mua theo khách hàng
users_retention as (
select user_id,
	   format(activity_date,'yyyyMM') as retention_month
FROM [SSSMarket].[dbo].[user_data]
),

--tháng đầu mua, các lần mua sau, số lượng khách còn lại
retained_users as (
SELECT b.first_month,
	   a.retention_month,
	   COUNT(distinct a.user_id) as retained_users
FROM users_retention AS a
LEFT JOIN user_first_month b
ON a.user_id=b.user_id
GROUP BY b.first_month,
		a.retention_month
)
--Left join để thêm cột số khách hàng mới mỗi tháng
SElECT r.*, 
	   c.new_users_by_month
FROM retained_users r
LEFT JOIN count_new_users c
ON c.first_month=r.first_month
ORDER BY r.first_month,
		r.retention_month
		


