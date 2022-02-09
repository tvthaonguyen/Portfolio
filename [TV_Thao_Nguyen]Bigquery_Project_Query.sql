-- Big project for SQL
-- Link instruction: https://docs.google.com/spreadsheets/d/1WnBJsZXj_4FDi2DyfLH1jkWtfTridO2icWbWCh7PLs8/edit#gid=0


-- Query 01: calculate total visit, pageview, transaction and revenue for Jan, Feb and March 2017 order by month
#standardSQL
select
    FORMAT_DATE('%Y%m',parse_date('%Y%m%d',date)) as month,
    count(distinct fullVisitorId) as total_visit,
    sum(totals.pageviews), 
    sum(totals.transactions) as transactions, 
    (sum(totals.totalTransactionRevenue)/1000000) as revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
Where _table_suffix between '20170101' and '20170331'
group by  month
order by month



-- Query 02: Bounce rate per traffic source in July 2017
#standardSQL
with a as (SELECT trafficSource.source as Sources,
                    sum(case when totals.bounces is null then 1 else 0 end) as total_no_of_bounces
            FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` 
            where (_table_suffix between '20170701' and '20170731')
                and totals.bounces is null
            group by trafficSource.source),
b as (select 
        trafficSource.source as Sources,
        count(distinct fullVisitorId) as total_visits,
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
Where _table_suffix between '20170701' and '20170731'
group by trafficSource.source
order by total_visits desc)

select 
        b.Sources,
        b.total_visits,
        a.total_no_of_bounces,
        a.total_no_of_bounces/b.total_visits*100 as bounce_rate
from a join b
on a.Sources=b.Sources
order by total_visits desc


-- Query 3: Revenue by traffic source by week, by month in June 2017
select 'month' as timetype,
        format_date('%Y%m',parse_date('%Y%m%d',date)) as time,
        trafficSource.source as source,
        sum(totals.totalTransactionRevenue) as revenue
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
where _table_suffix between '20170601' and '20170630'
group by timetype,time,source

union all 

select 'week' as timetype,
        format_date('%Y%V',parse_date('%Y%m%d',date)) as time,
        trafficSource.source as source,
        sum(totals.totalTransactionRevenue) as revenue
from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
where _table_suffix between '20170601' and '20170630'
group by timetype,time,source




--Query 04: Average number of product pageviews by purchaser type (purchasers vs non-purchasers) in June, July 2017. Note: totals.transactions >=1 for purchaser and totals.transactions is null for non-purchaser
#standardSQL
with a as (select format_date('%Y%m',parse_date('%Y%m%d',date)) as month,
				avg(totals.pageviews) as avg_pageviews_non_purchase, 
			from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
			where (_table_suffix between '20170601' and '20170731')
				 and totals.transactions is null
			group by month),

	b as (select format_date('%Y%m',parse_date('%Y%m%d',date)) as month,
				avg(totals.pageviews) as avg_pageviews_purchase, 
			from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
			where (_table_suffix between '20170601' and '20170731')
				and totals.transactions is not null
			group by month)

select a.month,
		b.avg_pageviews_purchase, 
		a.avg_pageviews_non_purchase
from a join b
on a.month=b.month
order by a.month


-- Query 05: Average number of transactions per user that made a purchase in July 2017
#standardSQL
with trans_per_user as (select format_date('%Y%m',parse_date('%Y%m%d',date)) as month,
            avg(totals.transactions) over(partition by fullVisitorId) as Avg_total_transactions_per_user
        from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
        where (_table_suffix between '20170701' and '20170731')
        and totals.transactions is not null)

select month, avg(Avg_total_transactions_per_user) as Avg_total_transactions_per_user
from trans_per_user
group by month


-- Query 06: Average amount of money spent per session
#standardSQL
with trans_per_session as (select format_date('%Y%m',parse_date('%Y%m%d',date)) as month,
            avg(totals.totalTransactionRevenue) over(partition by totals.transactions) as avg_revenue_by_user_per_visit
        from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
        where (_table_suffix between '20170701' and '20170731')
        and totals.transactions is not null)

select month, avg(avg_revenue_by_user_per_visit) as avg_revenue_by_user_per_visit
from trans_per_session
group by month


-- Query 07: Products purchased by customers who purchased product A (Classic Ecommerce)
#standardSQL
--Tìm những khách có mua món "YouTube Men's Vintage Henley"
with a as (Select fullVisitorId
			FROM
				 `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
				UNNEST (hits) hits,
				 UNNEST (hits.product) product
			where product.v2ProductName="YouTube Men's Vintage Henley"),
--Tìm ID khách, tên món hàng, số lượng mua của tất cả khách
	b as (SElect fullVisitorId, 
				product.v2ProductName as other_purchased_products ,
				sum(product.productQuantity) as quantity
			FROM
				`bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
				 UNNEST (hits) hits,
				UNNEST (hits.product) product
			group by fullVisitorId,product.v2ProductName)
-- Inner join 2 bảng để tìm ID khách, tên món hàng và số lượng của những khách có mua "YouTube Men's Vintage Henley"
 select b.other_purchased_pro as quantity
from a
join b
on b.fullVisitorId=a.fullVisitorId
group by b.other_purchased_products

--Query 08: Calculate cohort map from pageview to addtocart to purchase in last 3 month. For example, 100% pageview then 40% add_to_cart and 10% purchase.
#standardSQL
with product_view as(
select format_date('%Y%m',parse_date('%Y%m%d',date)) as month,
        COUNT(product.v2ProductName) as num_product_view
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
Where (_table_suffix between '20170101' and '20170331')
and hits.ecommerceaction.action_type = '2'
group by  month),
 
addtocart as (
select format_date('%Y%m',parse_date('%Y%m%d',date)) as month,
        COUNT(product.v2ProductName) as num_addtocart
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
Where (_table_suffix between '20170101' and '20170331')
and hits.ecommerceaction.action_type = '3'
group by  month),
 
purchase as (
select format_date('%Y%m',parse_date('%Y%m%d',date)) as month,
        COUNT(product.v2ProductName) as num_purchase
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
UNNEST (hits) hits,
UNNEST (hits.product) product
Where (_table_suffix between '20170101' and '20170331')
and hits.ecommerceaction.action_type = '4'
group by  month)
 
Select product_view.month, 
        product_view.num_product_view, 
        addtocart.num_addtocart, 
        purchase.num_purchase,
        round(addtocart.num_addtocart/product_view.num_product_view*100,2) as add_to_cart_rate,
        round(purchase.num_purchase/num_addtocart*100,2) as purchase_rate
From product_view join addtocart on product_view.month = addtocart.month
Join purchase on purchase.month=addtocart.month
order by product_view.month


