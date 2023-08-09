use [Bike Store Sales];

select 
     ord.Order_id,
	 CONCAT(cus.first_name,' ',cus.last_name) as 'Customers',
	 cus.City,
	 cus.State,
	 ord.Order_date,
	 SUM(ite.quantity) as 'Total_units',
	 SUM(ite.quantity * ite.list_price) as 'Revenue',
	 pro.Product_name,
	 cat.Category_name,
	 br.Brand_name,
	 sto.Store_name,
	 CONCAT(sta.first_name,' ',sta.last_name) as 'Sales_Rep'
INTO #BikeSalesStore
from sales.orders ord
join sales.customers cus
on ord.customer_id = cus.customer_id
join sales.order_items ite
on ord.order_id = ite.order_id
join production.products pro
on ite.product_id = pro.product_id
join production.categories cat
on pro.category_id = cat.category_id
join sales.stores sto
on ord.store_id = sto.store_id
join sales.staffs sta
on ord.staff_id = sta.staff_id
join production.brands br
on br.brand_id = pro.brand_id
group by 
       ord.order_id,
	   CONCAT(cus.first_name,' ',cus.last_name),
	   cus.City,
	   cus.State,
	   ord.Order_date,
	   pro.Product_name,
	   cat.Category_name,
	   br.Brand_name,
	   sto.store_name,
	   CONCAT(sta.first_name,' ',sta.last_name) 

select * from #BikeSalesStore

-- 1. STATISTICS REGARDING DATASET --
-- Total Number of orders and Products
SELECT 
     COUNT(DISTINCT Order_id) AS 'Number_of_Orders',
	 COUNT(DISTINCT Product_name) AS 'Number_of_Distinct_Products'
FROM #BikeSalesStore

-- Total Units of products sold
SELECT SUM(Total_units) AS 'TotalUnits'
FROM #BikeSalesStore
  
 -- Total Units of products sold in Year 2016, 2017 and 2018 
SELECT SUM(Total_units) AS 'Total Units'
FROM #BikeSalesStore
where Year(Order_date) = 2016 ;

SELECT SUM(Total_units) AS 'Total Units'
FROM #BikeSalesStore
where Year(Order_date) = 2017 ;

SELECT SUM(Total_units) AS 'Total Units'
FROM #BikeSalesStore
where Year(Order_date) = 2018 ;


-- Total Revenue made by the store 
SELECT Product_name,SUM(Revenue) AS Total_Revenue 
FROM #BikeSalesStore
group by Product_name ;

-- Total Revenue made by the store in Year 2016, 2017 and 2018
SELECT SUM(Revenue) AS Total_Revenue 
FROM #BikeSalesStore
where Year(Order_date) = 2016;

SELECT SUM(Revenue) AS Total_Revenue 
FROM #BikeSalesStore
where Year(Order_date) = 2017;

SELECT SUM(Revenue) AS Total_Revenue 
FROM #BikeSalesStore
where Year(Order_date) = 2018;

-- No of customers 
SELECT COUNT(DISTINCT Customers) AS Customers 
FROM #BikeSalesStore ;

-- Average price of products in the store 
select AVG(Revenue_Per_Unit) as AveragePrice
from (
     SELECT distinct Product_name,
     (Revenue / Total_units) AS Revenue_Per_Unit
     FROM #BikeSalesStore
	 ) q


-- Least and the most expensive products in the store 
SELECT 'Least expensive product', MIN(Revenue_Per_Unit) AS price 
FROM (
     SELECT distinct Product_name,
     (Revenue / Total_units) AS Revenue_Per_Unit
     FROM #BikeSalesStore
	 ) q
UNION ALL 
SELECT 'most expensive product', MAX(Revenue_Per_Unit) AS Price 
FROM (
     SELECT distinct Product_name,
     (Revenue / Total_units) AS Revenue_Per_Unit
     FROM #BikeSalesStore
	 ) q ;

-- 2. ANALYTICAL QUESTIONS ---
 
-- Find out total Cost for each order ID 
select order_id,product_name, SUM(Revenue) as 'Total Cost'
from #BikeSalesStore
group by order_id,product_name
order by [Total Cost] ;

 
-- Total orders by different categories 
Select Category_name, COUNT(Total_units) As 'Total Orders'
from #BikeSalesStore
group by Category_name

-- Total orders categorized by different subcategories under specific brands
SELECT Brand_name,Category_name, COUNT(Total_units) As 'Total Orders'
FROM #BikeSalesStore
GROUP BY Brand_name,Category_name 
ORDER BY Brand_name ,Category_name ; 

-- Revenue for each category 
SELECT Category_name, SUM(Revenue) AS Sales 
FROM #BikeSalesStore
GROUP BY Category_name 
ORDER BY Sales desc; 
 
-- TOP 5 Revenue category
SELECT TOP 5 Category_name, SUM(Revenue) AS Total_Revenue
FROM #BikeSalesStore
GROUP BY Category_name
ORDER BY Total_Revenue DESC;



-- Retrieve the top 3 revenue-generating sub-categories for each category, grouped under specific brands.
WITH RankedCategories AS (
    SELECT 
        Brand_name,
        Category_name,
        SUM(Revenue) AS Total_Revenue,
        ROW_NUMBER() OVER(PARTITION BY Brand_name ORDER BY SUM(Revenue) DESC) AS Rank
    FROM #BikeSalesStore
    GROUP BY Brand_name, Category_name
)
SELECT 
    Brand_name,
    Category_name,
    Total_Revenue
FROM RankedCategories
WHERE Rank <= 3
ORDER BY Brand_name, Total_Revenue DESC;

 
-- Top 1 revenue-generating states: 
SELECT TOP 1
    State,
    SUM(Revenue) AS Total_Revenue
FROM #BikeSalesStore
GROUP BY State
ORDER BY Total_Revenue DESC;

 
-- Total Units per state 
SELECT
    State,
    SUM(Total_units) AS Total_Units_Sold
FROM #BikeSalesStore
GROUP BY State
ORDER BY Total_Units_Sold DESC;

-- No of customers state-wise 
SELECT
    State,
    COUNT(DISTINCT Customers) AS Number_of_Customers
FROM #BikeSalesStore
GROUP BY State
ORDER BY Number_of_Customers DESC;


-- Total Revenue Generated by the store 
SELECT
    Store_name,
    SUM(Revenue) AS Total_Revenue
FROM #BikeSalesStore
GROUP BY Store_name
ORDER BY Total_Revenue DESC;

-- Total Revenue per category 
SELECT
    Category_name,
    SUM(Revenue) AS Total_Revenue
FROM #BikeSalesStore
GROUP BY Category_name
ORDER BY Total_Revenue DESC;


-- Customer segmentation by count orders 
SELECT
    Customers,
    COUNT( Order_id) AS Order_Count,
    CASE
        WHEN COUNT( Order_id) >= 10 THEN 'Frequent Buyer'
        WHEN COUNT( Order_id) <= 2 THEN 'Occasional Buyer'
        ELSE 'Regular Buyer'
    END AS Customer_Segment
FROM #BikeSalesStore
GROUP BY Customers
ORDER BY Order_Count DESC;

-- Count of orders for each month 
SELECT
    YEAR(Order_date) AS Order_Year,
    MONTH(Order_date) AS Order_Month,
    COUNT(Order_id) AS Order_Count
FROM #BikeSalesStore
GROUP BY YEAR(Order_date), MONTH(Order_date)
ORDER BY Order_Year, Order_Month;


-- 3. RFM ANALYSIS --- 
-- Calculating R Score for each customer 
WITH rfm AS (
    SELECT 
        Customers AS CUSTOMERNAME, 
        MAX(Order_date) AS last_order_date,
        (SELECT MAX(Order_date) FROM #BikeSalesStore) AS max_order_date,
        DATEDIFF(DAY, MAX(Order_date), (SELECT MAX(Order_date) FROM #BikeSalesStore)) AS Recency
    FROM #BikeSalesStore
    GROUP BY Customers
)
SELECT 
    r.CUSTOMERNAME,
    r.Recency,
    NTILE(4) OVER (ORDER BY r.Recency DESC) AS R_Score
FROM rfm r;


-- Calculating F score for each customer 
WITH rfm AS (
    SELECT 
        Customers AS CUSTOMERNAME, 
        COUNT(DISTINCT Order_id) AS Frequency
    FROM #BikeSalesStore
    GROUP BY Customers
)
SELECT 
    r.CUSTOMERNAME,
    r.Frequency,
    NTILE(4) OVER (ORDER BY r.Frequency DESC) AS F_Score
FROM rfm r;

-- Calculating M score for each customer 
WITH rfm AS (
    SELECT 
        Customers AS CUSTOMERNAME, 
        SUM(Revenue) AS MonetaryValue
    FROM #BikeSalesStore
    GROUP BY Customers
)
SELECT 
    r.CUSTOMERNAME,
    r.MonetaryValue,
    NTILE(4) OVER (ORDER BY r.MonetaryValue DESC) AS M_Score
FROM rfm r;

-- Calculating RFM Score 
DROP TABLE IF EXISTS #rfm;

WITH rfm AS (
    SELECT 
        Customers AS CUSTOMERNAME, 
        SUM(Revenue) AS MonetaryValue,
        AVG(Revenue) AS AvgMonetaryValue,
        COUNT(DISTINCT Order_id) AS Frequency,
        MAX(Order_date) AS last_order_date,
        (SELECT MAX(Order_date) FROM #BikeSalesStore) AS max_order_date,
        DATEDIFF(DAY, MAX(Order_date), (SELECT MAX(Order_date) FROM #BikeSalesStore)) AS Recency
    FROM #BikeSalesStore
    GROUP BY Customers
),
rfm_calc AS (
    SELECT r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY MonetaryValue) AS rfm_monetary
    FROM rfm r 
)
SELECT 
    c.*, 
    rfm_recency + rfm_frequency + rfm_monetary AS rfm_cell,
    CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR) AS rfm_cell_string
INTO #rfm
FROM rfm_calc c;

SELECT 
    CUSTOMERNAME, 
    rfm_recency, 
    rfm_frequency, 
    rfm_monetary,
    CASE 
        WHEN rfm_recency = 1 AND rfm_frequency = 1 AND rfm_monetary = 1 THEN 'Best Customer'
        WHEN rfm_recency BETWEEN 2 AND 4 AND rfm_frequency BETWEEN 2 AND 4 AND rfm_monetary = 1 THEN 'Big Spenders'
        WHEN rfm_recency BETWEEN 2 AND 4 AND rfm_frequency = 1 AND rfm_monetary BETWEEN 1 AND 4 THEN 'Loyal Customers'
        WHEN rfm_recency = 1 AND rfm_frequency BETWEEN 1 AND 4 AND rfm_monetary BETWEEN 1 AND 4 THEN 'Recent Customers'
        WHEN rfm_recency = 3 AND rfm_frequency = 1 AND rfm_monetary = 1 THEN 'Almost lost'
        WHEN rfm_recency = 4 AND rfm_frequency = 1 AND rfm_monetary = 1 THEN 'Lost Customers'
        WHEN rfm_recency = 4 AND rfm_frequency BETWEEN 3 AND 4 AND rfm_monetary BETWEEN 3 AND 4 THEN 'Lost Cheap Customers'
        WHEN rfm_recency BETWEEN 2 AND 4 AND rfm_frequency BETWEEN 2 AND 4 AND rfm_monetary BETWEEN 2 AND 4 THEN 'Unspecified'
    END AS rfm_segment
FROM #rfm;


-- Customer Segemenatation on the basis of priority 
WITH rfm AS (
    SELECT 
        Customers AS CUSTOMERNAME, 
        MAX(Order_date) AS last_order_date,
        DATEDIFF(DAY, MAX(Order_date), (SELECT MAX(Order_date) FROM #BikeSalesStore)) AS Recency,
        COUNT(DISTINCT Order_id) AS Frequency,
        SUM(Revenue) AS MonetaryValue
    FROM #BikeSalesStore
    GROUP BY Customers
)
SELECT 
    r.CUSTOMERNAME,
    r.Recency,
    r.Frequency,
    r.MonetaryValue,
    (r.Recency * 0.4 + r.Frequency * 0.3 + r.MonetaryValue * 0.3) AS PriorityScore,
    CASE 
        WHEN (r.Recency * 0.4 + r.Frequency * 0.3 + r.MonetaryValue * 0.3) >= 2.5 THEN 'High Priority'
        WHEN (r.Recency * 0.4 + r.Frequency * 0.3 + r.MonetaryValue * 0.3) >= 1.5 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END AS CustomerSegment
FROM rfm r;


-- Recency Score distribution i.e.Customer with most recent order are given R_SCORE AS 4 
WITH rfm AS (
    SELECT 
        Customers AS CUSTOMERNAME, 
        MAX(Order_date) AS last_order_date,
        DATEDIFF(DAY, MAX(Order_date), (SELECT MAX(Order_date) FROM #BikeSalesStore)) AS Recency
    FROM #BikeSalesStore
    GROUP BY Customers
),
normalized_rfm AS (
    SELECT 
        r.*,
        1 + ((4 - 1) * (1.0 - (Recency - 1) / (SELECT MAX(Recency) FROM rfm))) AS normalized_recency
    FROM rfm r
)
SELECT 
    n.CUSTOMERNAME,
    n.Recency,
    CAST(ROUND(n.normalized_recency, 0) AS INT) AS R_Score
FROM normalized_rfm n;



-- Frequency Score distribution i.e.Customer with most frequent orders are given F_SCORE AS 4
SELECT F_Score, COUNT(1) AS Customers 
FROM rfm
GROUP BY F_Score
ORDER BY F_Score DESC;

WITH rfm AS (
    SELECT 
        Customers AS CUSTOMERNAME, 
        COUNT(DISTINCT Order_id) AS Frequency
    FROM #BikeSalesStore
    GROUP BY Customers
),
rfm_with_f_score AS (
    SELECT
        r.CUSTOMERNAME,
        r.Frequency,
        NTILE(4) OVER (ORDER BY r.Frequency DESC) AS f_score
    FROM rfm r
)
SELECT 
    f.CUSTOMERNAME,
    f.Frequency,
    f.f_score AS F_Score
FROM rfm_with_f_score f;


-- Monitary Score distribution i.e.Customer with Max Revenue are given M_SCORE AS 4
WITH rfm AS (
    SELECT 
        Customers AS CUSTOMERNAME, 
        SUM(Revenue) AS MonetaryValue
    FROM #BikeSalesStore
    GROUP BY Customers
),
rfm_with_m_score AS (
    SELECT
        r.CUSTOMERNAME,
        r.MonetaryValue,
        NTILE(4) OVER (ORDER BY r.MonetaryValue DESC) AS m_score
    FROM rfm r
)
SELECT 
    m.CUSTOMERNAME,
    m.MonetaryValue,
    m.m_score AS M_Score
FROM rfm_with_m_score m;
