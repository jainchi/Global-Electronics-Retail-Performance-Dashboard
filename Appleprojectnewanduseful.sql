CREATE TABLE category (
    category_id VARCHAR(50) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE storedetails (
    store_id VARCHAR(50) PRIMARY KEY,
    store_name VARCHAR(150) NOT NULL,
    city VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category_id VARCHAR(50),
    launch_date DATE,
    price INT,
    FOREIGN KEY (category_id) REFERENCES category(category_id)
);

CREATE TABLE sales_data (
    sale_id VARCHAR(50) PRIMARY KEY,
    sale_date DATE NOT NULL,
    store_id VARCHAR(50),
    product_id VARCHAR(50),
    quantity INT NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (store_id) REFERENCES storedetails(store_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


CREATE TABLE warrantystatus (
    claim_id VARCHAR(50) PRIMARY KEY,
    claim_date DATE NOT NULL,
    sale_id VARCHAR(50),
    repair_status VARCHAR(100),
    FOREIGN KEY (sale_id) REFERENCES sales_data(sale_id)
);


SELECT * FROM category
SELECT * FROM storedetails
SELECT * FROM products
SELECT * FROM sales_data
SELECT * FROM warranty_status



/*

## Objectives

The project is split into three tiers of questions to test SQL skills of increasing complexity:

### Easy to Medium (9 Questions)

1. Find the number of stores in each country.
2. Calculate the total number of units sold by each store.
3. Identify how many sales occurred in December 2023.
4. Determine how many stores have never had a warranty claim filed.
5. Identify which store had the highest total units sold in the last year.
6. Count the number of unique products sold in the last year.
7. Find the average price of products in each category.
8. How many warranty claims were filed in 2024?
9. For each store, identify the best-selling day based on highest quantity sold.
*/


-- Q.1
SELECT country,count(*)as totalstores
FROM  storedetails
GROUP BY 1 

-- Q.2
SELECT sr.store_id, store_name,SUM(quantity)as totalsale
FROM  storedetails sr
JOIN sales_data sd
ON sr.store_id=sd.store_id
GROUP BY 1,2

-- Q.3
SELECT COUNT(*)AS totaltransactions,SUM(quantity) AS totalquantitysold,sum(price*quantity) AS totalrevenue
FROM sales_data sd
JOIN products p
ON sd.product_id=p.product_id
WHERE EXTRACT (YEAR FROM sale_date)=2023
AND EXTRACT (MONTH FROM sale_date)=12
-- Q.4

SELECT count(*) as neverfilled
FROM storedetails 
WHERE store_id NOT IN(
SELECT DISTINCT sd.store_id from storedetails sd
LEFT JOIN sales_data sl
ON sd.store_id=sl.store_id
JOIN warrantystatus w
ON sl.sale_id=w.sale_id
)


-- Q.5
SELECT ss.store_id,SUM(quantity) as totalsales FROM storedetails ss
JOIN sales_data sd
ON ss.store_id=sd.store_id
WHERE CURRENT_DATE-sale_date< 365
GROUP BY 1

-- Q.6
SELECT COUNT(DISTINCT pp.product_id) FROM products pp
JOIN sales_data sd
ON pp.product_id=sd.product_id
WHERE CURRENT_DATE-sale_date< 365

-- Q.7
SELECT c.category_id,category_name, ROUND(avg(price),2) as avgpriceincategory FROM products p
JOIN category c
ON p.category_id=c.category_id
GROUP BY 1,2

-- Q.8
SELECT count(*) as totalclaimfiledin2024
FROM warrantystatus
WHERE EXTRACT(YEAR FROM claim_date)=2024

-- Q.9
SELECT * FROM(
SELECT sa.store_id,sale_date,count(*)as totaltransaction, SUM(quantity) as quantitysold,SUM(quantity*price) as totalsales,
ROW_NUMBER() OVER(PARTITION BY sa.store_id ORDER BY SUM(quantity) DESC) as rnk
FROM storedetails sr
JOIN sales_data sa
ON sr.store_id=sa.store_id
JOIN products p
ON sa.product_id=p.product_id
GROUP BY 1,2
ORDER BY sa.store_id,quantitysold DESC
)
WHERE rnk=1


/*
### Medium to Hard (5 Questions)
10. Identify the least selling product in each country for each year based on total units sold, 'CREATE CTAS'
11. Calculate how many warranty claims were filed within 180 days of a product sale.
12. Determine how many warranty claims were filed for products launched in the last two years 'PER PRODUCT'
13. List the best selling months from each year of country 'US'
14. List the months in the last three years where sales exceeded 25 units in the USA.
15. Identify the product category with the most warranty claims filed in the last two years.
*/

-- Q.10
CREATE TABLE bestprodbystoreyear AS
SELECT * FROM(
WITH cte1 AS(
SELECT country,EXTRACT(YEAR FROM sale_date) as years,product_id,SUM(quantity)as totalsold from storedetails ss
JOIN sales_data st
ON ss.store_id=st.store_id
GROUP BY 1,2,3
ORDER BY 1,years,totalsold DESC
)
SELECT *,DENSE_RANK() OVER (PARTITION BY country,years ORDER BY totalsold) as rank
FROM cte1)
WHERE rank=1
SELECT * FROM bestprodbystoreyear

-- Q.11 Calculate how many warranty claims were filed within 180 days of a product sale.

WITH warrantyperiod AS
(
SELECT claim_date- sale_date AS product_usedwithoutissue
FROM sales_data sa
JOIN warrantystatus ws
ON sa.sale_id=ws.sale_id
)
SELECT * FROM warrantyperiod
where product_usedwithoutissue BETWEEN 0 AND 180

-- Q.12
SELECT pc.product_name,count(claim_id) AS totalclaimed 
FROM sales_data sa
JOIN warrantystatus ws
ON sa.sale_id=ws.sale_id
JOIN products pc
ON sa.product_id=pc.product_id
WHERE CURRENT_DATE-launch_date<365*2
GROUP BY 1


-- Q.13 List the best selling months from each year of country 'US'
SELECT * FROM(

SELECT 
	country,
	EXTRACT(YEAR FROM sale_date) as years,
	EXTRACT(months from sale_date)as months,
	SUM(quantity) AS totalquasold,
	RANK() OVER(PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY SUM(quantity) DESC) AS ranking
FROM sales_data sa
JOIN storedetails se
ON sa.store_id=se.store_id
WHERE country='United States'
GROUP BY 1,2,3
)
WHERE ranking=1


-- Q.14List the months in the last three years where sales exceeded 25 units in the USA.
SELECT * FROM(
SELECT 
	EXTRACT(YEAR FROM sale_date) as years,
	EXTRACT(months from sale_date)as months,
	SUM(quantity) AS totalquasold
FROM sales_data sa
JOIN storedetails se
ON sa.store_id=se.store_id
WHERE country='United States' 
GROUP BY 1,2)
WHERE totalquasold>25

-- Q.15. Identify the product category with the most warranty claims filed in the last two years.
SELECT category_name,COUNT(claim_id) AS totalclaimfiled
FROM products p
JOIN sales_data sa
ON p.product_id=sa.product_id
JOIN warrantystatus ws
ON sa.sale_id=ws.sale_id
JOIN category c
ON c.category_id=p.category_id
WHERE CURRENT_DATE-claim_date <365*2
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1

/*
Complex (5 Questions)

Q.16--Determine the percentage chance of receiving warranty claims after each purchase for each country.
Q.17--Analyze the year-by-year growth ratio for each store.
Q.18--Calculate the correlation between product price and warranty claims for products sold in the last five years, segmented by price range.
Q.19--Identify the TOP 3 store with the highest percentage of "Cantberepaied" claims relative to total claims filed.
Q.20-Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.
Q.21--
Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6–12 months, 12–18 months, and beyond 18 months.
*/

-- Q.16--Determine the percentage chance of receiving warranty claims after each purchase for each country.

WITH cte1 AS(
SELECT 	
	store_name,
	SUM(CASE WHEN repair_status='Cantberepaied' THEN 0 ELSE 1 END) as totalapproved,
	COUNT(repair_status) as totalfiled
FROM warrantystatus ws
LEFT JOIN sales_data ss
ON ws.sale_id=ss.sale_id
JOIN storedetails sr
ON ss.store_id=sr.store_id
GROUP BY 1)
SELECT *,100.0* totalapproved/totalfiled AS chances
FROM cte1

-- Q.17--Analyze the year-by-year growth ratio for each store.

WITH cte1 AS(
SELECT store_name,EXTRACT(YEAR FROM sale_date) as yearrss ,SUM(quantity) as quasold,
LAG(SUM(quantity)) OVER(PARTITION BY store_name ORDER BY EXTRACT(YEAR FROM sale_date)) AS lastyear_sold
FROM sales_data sa
JOIN storedetails sse
ON sa.store_id=sse.store_id
GROUP BY 1,2
ORDER BY 1,2)
SELECT *,ROUND(100.0*(quasold-lastyear_sold)/ lastyear_sold ,2) as growthpercentage
FROM cte1


-- Q.18--Calculate the correlation between product price and warranty claims for products sold in the last four years, segmented by price range.
SELECT 
CASE 
	WHEN  price<3000 THEN 'Under 3k'
	WHEN  price<6000 THEN 'Under 6k'
	WHEN  price<9000 THEN 'Under 9k'
	WHEN  price<12000 THEN 'Under 12k'
	ELSE '12k or above 12k'
END AS pricecategorisation,
SUM(CASE WHEN repair_status='Cantberepaied' THEN 1 ELSE 0 END) AS totalpaidrepairing,
SUM(CASE WHEN repair_status='Cantberepaied' THEN 0 ELSE 1 END) AS totalclaimrepairing,
COUNT(*) as totalrepairorderreceived
FROM products pr
JOIN sales_data sa
ON pr.product_id=sa.product_id
LEFT JOIN warrantystatus ws
ON ws.sale_id=sa.sale_id
WHERE sale_date>CURRENT_DATE-365*4
GROUP BY 1



----- OR ------

WITH product_claims_summary AS (
    SELECT 
        p.product_id,
        p.price,
        COUNT(ws.claim_id) AS total_claims
    FROM products p
    JOIN sales_data sa ON p.product_id = sa.product_id
    LEFT JOIN warrantystatus ws ON sa.sale_id = ws.sale_id
    WHERE sa.sale_date >= CURRENT_DATE - INTERVAL '5 years' -- 5-year constraint
    GROUP BY p.product_id, p.price
)
SELECT 
    CASE 
        WHEN price < 3000 THEN 'Under 3k'
        WHEN price < 6000 THEN 'Under 6k'
        WHEN price < 9000 THEN 'Under 9k'
        WHEN price < 12000 THEN 'Under 12k'
        ELSE '12k or above'
    END AS price_segment,
    COUNT(*) AS total_products_in_segment,
    -- PostgreSQL built-in correlation function between price and claim counts
    ROUND(CORR(price, total_claims)::NUMERIC, 4) AS price_to_claims_correlation
FROM product_claims_summary
GROUP BY 1
ORDER BY MIN(price);


-- Q.19--Identify the TOP 3 store with the highest percentage of "Cantberepaied" claims relative to total claims filed.
WITH cte1 AS(
SELECT 	
	store_name,
	SUM(CASE WHEN repair_status='Cantberepaied' THEN 1 ELSE 0 END) as totalpaidrepaired,
	COUNT(repair_status) as totalfiled
FROM warrantystatus ws
LEFT JOIN sales_data ss
ON ws.sale_id=ss.sale_id
JOIN storedetails sr
ON ss.store_id=sr.store_id
GROUP BY 1
)
SELECT *,ROUND(100.0*(totalpaidrepaired::numeric/ totalfiled::numeric),2) as paidpercentage
FROM cte1
ORDER BY paidpercentage DESC
LIMIT 3



--Q.20-Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.
WITH cte1 AS
(
SELECT 	
	sr.store_id,
	EXTRACT(YEAR from sale_date) as yearr,
	EXTRACT(MONTH from sale_date) as monthh,
	price*quantity as totalmonthlysale,
	price, quantity
FROM sales_data ss
JOIN storedetails sr
ON ss.store_id=sr.store_id
JOIN products p
ON ss.product_id=p.product_id
WHERE CURRENT_DATE-sale_date<365*4
ORDER BY 1,2,3
),
cte2 AS
(
SELECT store_id,yearr, monthh,SUM(price* quantity) AS totalrevenue
from cte1
GROUP BY 1,2,3
ORDER BY 1,2,3
)
SELECT cte2.store_id,cte2.yearr, cte2.monthh,SUM(totalrevenue) OVER(PARTITION BY store_id ORDER BY yearr, monthh) as cumulative
FROM cte2

----- OR-----

-- Q.20 Calculate the monthly running total of sales for each store over the past four years.
WITH monthly_store_sales AS (
    SELECT 	
        sr.store_id,
        sr.store_name,
        EXTRACT(YEAR FROM ss.sale_date) AS sale_year,
        EXTRACT(MONTH FROM ss.sale_date) AS sale_month,
        SUM(p.price * ss.quantity) AS total_monthly_sales
    FROM sales_data ss
    JOIN storedetails sr ON ss.store_id = sr.store_id
    JOIN products p ON ss.product_id = p.product_id
    WHERE ss.sale_date >= CURRENT_DATE - INTERVAL '4 years' -- Filters past 4 years dynamically
    GROUP BY sr.store_id, sr.store_name, EXTRACT(YEAR FROM ss.sale_date), EXTRACT(MONTH FROM ss.sale_date)
)
SELECT 
    store_id,
    store_name,
    sale_year,
    sale_month,
    total_monthly_sales,
    -- The Magic Vector: Accumulates month-by-month, restarting for each individual store
    SUM(total_monthly_sales) OVER (
        PARTITION BY store_id 
        ORDER BY sale_year, sale_month
    ) AS running_total_sales
FROM monthly_store_sales
ORDER BY store_id, sale_year, sale_month;





-- Bonus Question
-- Analyze product sales trends over time, segmented into key periods: from launch to 6 months, 6–12 months, 12–18 months, and beyond 18 months
WITH cte1 AS(
SELECT product_name,quantity,sale_id,
case
	WHEN s.sale_id IS NULL THEN 'No Sales Recorded'
	WHEN sale_date<=launch_date+INTERVAL '6 months' THEN 'first 6 months'
	WHEN sale_date<=launch_date+INTERVAL '12 months' THEN 'month 7th to 12th'
	WHEN sale_date<=launch_date+INTERVAL '18 months' THEN 'month 13th to 18th'
	ELSE 'beyond 18 months'
END AS monthcategorisation
from products p
LEFT JOIN sales_data s
ON p.product_id=s.product_id
)SELECT product_name,monthcategorisation,
COUNT(sale_id) as totaltransactions,SUM(quantity) AS totalsold
FROM cte1
GROUP BY 1,2
ORDER BY 1,4 DESC