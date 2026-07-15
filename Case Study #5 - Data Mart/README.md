# 🧺 Case Study #5 - Data Mart
URL https://8weeksqlchallenge.com/case-study-5/

URL https://www.db-fiddle.com/f/jmnwogTsUE8hGqkZv9H7E8/8

## 📌 Business Overview
In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.

The key business question he wants you to help him answer are the following:

- What was the quantifiable impact of the changes introduced in June 2020?
	Using the metrics of 4 weeks before and after, there is an increase of 0.17% in the sales, but using the 12 weeks there is a decrease of 9.27% of sales.
- Which platform, region, segment and customer types were the most impacted by this change?
  	South America, shopify and retail - the reduction of sales in all age band and demographics.
- What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?
	First make the change in one location to see the impact and then move to another location, like in Canada make the change see the impact in 12 weeks in both platforms.
---

## A.Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

- Convert the week_date to a DATE format
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
- Add a month_number with the calendar month for each week_date value as the 3rd column
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
(1=Young Adults,2=Middle Aged,3 or 4	=Retirees)
- Add a new demographic column using the following mapping for the first letter in the segment values:
(C=Couples,F=Families)
- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

```sql
SELECT 
CREATE TABLE data_mart.clean_weekly_sales AS (
	SELECT
		week_date::DATE,
		CEIL(EXTRACT(DOY FROM week_date::DATE)/7.0) AS week_number,
		EXTRACT(MONTH FROM week_date::DATE)AS month_number,
		EXTRACT(YEAR FROM week_date::DATE) AS calendar_year,
		region,
		platform,
		CASE 
			WHEN LOWER(segment) LIKE 'null' OR segment IS NULL THEN 'unknown'
			ELSE segment
		END AS segment,
		CASE 
			WHEN RIGHT(segment,1) = '1' THEN 'Young Adults'
			WHEN RIGHT(segment,1) = '2' THEN 'Middle Aged'
			WHEN RIGHT(segment,1) = '3' OR RIGHT(segment,1) = '4' THEN 'Retirees'
			ELSE 'unknown'
		END AS age_band,
		CASE 
			WHEN LEFT(segment,1) = 'C' THEN 'Couples'
			WHEN LEFT(segment,1) = 'F' THEN 'Families'
			ELSE 'unknown'
		END AS demographic,
		customer_type,
		transactions,
		sales,
		ROUND(sales  / (transactions * 1.0),2) AS avg_transaction
	FROM data_mart.weekly_sales
	ORDER BY week_date 
)
```

---
## B.Data Exploration
### 1. What day of the week is used for each week_date value?
Monday
```sql
SELECT
	DISTINCT EXTRACT(DOW FROM week_date) AS day_of_the_week
FROM data_mart.clean_weekly_sales;
```
**Results:**
| day_of_the_week |
|--------------|
| 1            |

### 2. What range of week numbers are missing from the dataset?
The range of week numbers in this data is from 12 to 36, hence 1 to 11 and 37 to 52
```sql
WITH total_weeks AS (
	SELECT GENERATE_SERIES(1,52) as week_number
)
SELECT 
	t.week_number AS week_numbers_missing
FROM total_weeks AS t 
LEFT JOIN data_mart.clean_weekly_sales AS c
	ON t.week_number = c.week_number
WHERE c.week_date IS NULL
ORDER BY t.week_number;
```
**Results:**
| week_numbers_missing |
|----------------------|
| 1                    |
| 2                    |
| 3                    |
| 4                    |
| 5                    |
| 6                    |
| 7                    |
| 8                    |
| 9                    |
| 10                   |
| 11                   |
| 37                   |
| 38                   |
| 39                   |
| 40                   |
| 41                   |
| 42                   |
| 43                   |
| 44                   |
| 45                   |
| 46                   |
| 47                   |
| 48                   |
| 49                   |
| 50                   |
| 51                   |
| 52                   |



### 3. How many total transactions were there for each year in the dataset?
More than 300M transactions each year
```sql
SELECT
	calendar_year,
	TO_CHAR(SUM(transactions),'FM999,999,999') AS total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;
```
**Results:**
| calendar_year | total_transactions |
|---------------|--------------------|
| 2018          | 346,406,460        |
| 2019          | 365,639,285        |
| 2020          | 375,813,651        |

### 4. What is the total sales for each region for each month?
```sql
SELECT
	region,
	calendar_year,
	TO_CHAR(TO_DATE(month_number::TEXT,'MM'),'FMMonth') AS month_name,
	SUM(sales)::MONEY AS total_sales
FROM data_mart.clean_weekly_sales
GROUP BY region, calendar_year, month_number
ORDER BY region, calendar_year, month_number
```
**Results:**
| region        | calendar_year | month_name | total_sales     |
|---------------|---------------|------------|-----------------|
| AFRICA        | 2018          | March      | $130,542,213.00 |
| AFRICA        | 2018          | April      | $650,194,751.00 |
| AFRICA        | 2018          | May        | $522,814,997.00 |
| AFRICA        | 2018          | June       | $519,127,094.00 |
| AFRICA        | 2018          | July       | $674,135,866.00 |
| AFRICA        | 2018          | August     | $539,077,371.00 |
| AFRICA        | 2018          | September  | $135,084,533.00 |
| AFRICA        | 2019          | March      | $141,619,349.00 |
| AFRICA        | 2019          | April      | $700,447,301.00 |
| AFRICA        | 2019          | May        | $553,828,220.00 |
| AFRICA        | 2019          | June       | $546,092,640.00 |
| AFRICA        | 2019          | July       | $711,867,600.00 |
| AFRICA        | 2019          | August     | $564,497,281.00 |
| AFRICA        | 2019          | September  | $141,236,454.00 |
| AFRICA        | 2020          | March      | $295,605,918.00 |
| AFRICA        | 2020          | April      | $561,141,452.00 |
| AFRICA        | 2020          | May        | $570,601,521.00 |
| AFRICA        | 2020          | June       | $702,340,026.00 |
| AFRICA        | 2020          | July       | $574,216,244.00 |
| AFRICA        | 2020          | August     | $706,022,238.00 |
| ASIA          | 2018          | March      | $119,180,883.00 |
| ASIA          | 2018          | April      | $603,716,301.00 |
| ASIA          | 2018          | May        | $472,634,283.00 |
| ASIA          | 2018          | June       | $462,233,474.00 |
| ASIA          | 2018          | July       | $602,910,228.00 |
| ASIA          | 2018          | August     | $486,137,188.00 |
| ASIA          | 2018          | September  | $122,529,255.00 |
| ASIA          | 2019          | March      | $129,174,041.00 |
| ASIA          | 2019          | April      | $654,973,051.00 |
| ASIA          | 2019          | May        | $511,773,780.00 |
| ASIA          | 2019          | June       | $498,386,324.00 |
| ASIA          | 2019          | July       | $635,366,443.00 |
| ASIA          | 2019          | August     | $514,795,070.00 |
| ASIA          | 2019          | September  | $130,307,552.00 |
| ASIA          | 2020          | March      | $281,415,869.00 |
| ASIA          | 2020          | April      | $545,939,355.00 |
| ASIA          | 2020          | May        | $541,877,336.00 |
| ASIA          | 2020          | June       | $658,863,091.00 |
| ASIA          | 2020          | July       | $530,568,085.00 |
| ASIA          | 2020          | August     | $662,388,351.00 |
| CANADA        | 2018          | March      | $33,815,571.00  |
| CANADA        | 2018          | April      | $163,479,820.00 |
| CANADA        | 2018          | May        | $130,367,940.00 |
| CANADA        | 2018          | June       | $130,410,790.00 |
| CANADA        | 2018          | July       | $164,198,426.00 |
| CANADA        | 2018          | August     | $133,635,800.00 |
| CANADA        | 2018          | September  | $34,042,238.00  |
| CANADA        | 2019          | March      | $36,087,248.00  |
| CANADA        | 2019          | April      | $179,830,236.00 |
| CANADA        | 2019          | May        | $140,979,946.00 |
| CANADA        | 2019          | June       | $138,690,815.00 |
| CANADA        | 2019          | July       | $173,991,586.00 |
| CANADA        | 2019          | August     | $139,428,879.00 |
| CANADA        | 2019          | September  | $35,025,721.00  |
| CANADA        | 2020          | March      | $74,731,510.00  |
| CANADA        | 2020          | April      | $141,242,538.00 |
| CANADA        | 2020          | May        | $141,030,479.00 |
| CANADA        | 2020          | June       | $174,745,093.00 |
| CANADA        | 2020          | July       | $138,944,935.00 |
| CANADA        | 2020          | August     | $174,008,340.00 |
| EUROPE        | 2018          | March      | $8,402,183.00   |
| EUROPE        | 2018          | April      | $44,549,418.00  |
| EUROPE        | 2018          | May        | $36,492,553.00  |
| EUROPE        | 2018          | June       | $38,998,277.00  |
| EUROPE        | 2018          | July       | $50,535,910.00  |
| EUROPE        | 2018          | August     | $39,104,650.00  |
| EUROPE        | 2018          | September  | $9,777,575.00   |
| EUROPE        | 2019          | March      | $8,989,328.00   |
| EUROPE        | 2019          | April      | $46,983,044.00  |
| EUROPE        | 2019          | May        | $36,446,510.00  |
| EUROPE        | 2019          | June       | $36,464,369.00  |
| EUROPE        | 2019          | July       | $47,154,102.00  |
| EUROPE        | 2019          | August     | $36,638,154.00  |
| EUROPE        | 2019          | September  | $9,099,858.00   |
| EUROPE        | 2020          | March      | $17,945,582.00  |
| EUROPE        | 2020          | April      | $35,801,793.00  |
| EUROPE        | 2020          | May        | $36,399,326.00  |
| EUROPE        | 2020          | June       | $47,351,180.00  |
| EUROPE        | 2020          | July       | $39,067,454.00  |
| EUROPE        | 2020          | August     | $46,360,191.00  |
| OCEANIA       | 2018          | March      | $175,777,460.00 |
| OCEANIA       | 2018          | April      | $869,324,594.00 |
| OCEANIA       | 2018          | May        | $692,610,094.00 |
| OCEANIA       | 2018          | June       | $687,546,255.00 |
| OCEANIA       | 2018          | July       | $871,333,919.00 |
| OCEANIA       | 2018          | August     | $714,036,679.00 |
| OCEANIA       | 2018          | September  | $180,310,608.00 |
| OCEANIA       | 2019          | March      | $192,331,207.00 |
| OCEANIA       | 2019          | April      | $953,735,279.00 |
| OCEANIA       | 2019          | May        | $746,580,473.00 |
| OCEANIA       | 2019          | June       | $732,354,251.00 |
| OCEANIA       | 2019          | July       | $934,476,631.00 |
| OCEANIA       | 2019          | August     | $759,346,286.00 |
| OCEANIA       | 2019          | September  | $192,154,910.00 |
| OCEANIA       | 2020          | March      | $415,174,221.00 |
| OCEANIA       | 2020          | April      | $776,707,747.00 |
| OCEANIA       | 2020          | May        | $776,466,737.00 |
| OCEANIA       | 2020          | June       | $951,984,238.00 |
| OCEANIA       | 2020          | July       | $757,648,850.00 |
| OCEANIA       | 2020          | August     | $958,930,687.00 |
| SOUTH AMERICA | 2018          | March      | $16,302,144.00  |
| SOUTH AMERICA | 2018          | April      | $80,814,046.00  |
| SOUTH AMERICA | 2018          | May        | $63,685,837.00  |
| SOUTH AMERICA | 2018          | June       | $63,764,243.00  |
| SOUTH AMERICA | 2018          | July       | $81,690,746.00  |
| SOUTH AMERICA | 2018          | August     | $66,079,697.00  |
| SOUTH AMERICA | 2018          | September  | $16,932,862.00  |
| SOUTH AMERICA | 2019          | March      | $17,351,683.00  |
| SOUTH AMERICA | 2019          | April      | $87,069,807.00  |
| SOUTH AMERICA | 2019          | May        | $67,552,363.00  |
| SOUTH AMERICA | 2019          | June       | $67,122,227.00  |
| SOUTH AMERICA | 2019          | July       | $84,577,363.00  |
| SOUTH AMERICA | 2019          | August     | $68,364,336.00  |
| SOUTH AMERICA | 2019          | September  | $17,242,721.00  |
| SOUTH AMERICA | 2020          | March      | $37,369,282.00  |
| SOUTH AMERICA | 2020          | April      | $70,567,678.00  |
| SOUTH AMERICA | 2020          | May        | $70,153,609.00  |
| SOUTH AMERICA | 2020          | June       | $87,360,985.00  |
| SOUTH AMERICA | 2020          | July       | $69,314,667.00  |
| SOUTH AMERICA | 2020          | August     | $86,722,019.00  |
| USA           | 2018          | March      | $52,734,998.00  |
| USA           | 2018          | April      | $260,725,717.00 |
| USA           | 2018          | May        | $210,050,720.00 |
| USA           | 2018          | June       | $206,372,070.00 |
| USA           | 2018          | July       | $262,393,377.00 |
| USA           | 2018          | August     | $212,470,882.00 |
| USA           | 2018          | September  | $54,294,291.00  |
| USA           | 2019          | March      | $55,764,198.00  |
| USA           | 2019          | April      | $277,108,603.00 |
| USA           | 2019          | May        | $220,370,520.00 |
| USA           | 2019          | June       | $219,743,295.00 |
| USA           | 2019          | July       | $274,203,066.00 |
| USA           | 2019          | August     | $222,170,302.00 |
| USA           | 2019          | September  | $56,238,077.00  |
| USA           | 2020          | March      | $116,853,847.00 |
| USA           | 2020          | April      | $221,952,003.00 |
| USA           | 2020          | May        | $225,545,881.00 |
| USA           | 2020          | June       | $277,763,625.00 |
| USA           | 2020          | July       | $223,735,311.00 |
| USA           | 2020          | August     | $277,361,606.00 |

### 5. What is the total count of transactions for each platform
```sql
SELECT
	platform,
	COUNT(transactions) total_transactions
FROM data_mart.clean_weekly_sales
GROUP BY platform
```
**Results:**
| platform | total_transactions |
|----------|--------------------|
| Shopify  | 8549               |
| Retail   | 8568               |

### 6. What is the percentage of sales for Retail vs Shopify for each month?
```sql
SELECT
	calendar_year,
	TO_CHAR(TO_DATE(month_number::TEXT,'MM'),'FMMonth') AS months,
	ROUND((SUM(sales)FILTER(WHERE platform = 'Shopify')) * 100.0 /SUM(sales),2) AS shopify_sales_perc,
	ROUND((SUM(sales)FILTER(WHERE platform = 'Retail')) * 100.0 /SUM(sales),2) AS retail_sales_perc
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, month_number
ORDER BY calendar_year, month_number
```
**Results:**
| calendar_year | months    | shopify_sales_perc | retail_sales_perc |
|---------------|-----------|--------------------|-------------------|
| 2018          | March     | 2.08               | 97.92             |
| 2018          | April     | 2.07               | 97.93             |
| 2018          | May       | 2.27               | 97.73             |
| 2018          | June      | 2.24               | 97.76             |
| 2018          | July      | 2.25               | 97.75             |
| 2018          | August    | 2.29               | 97.71             |
| 2018          | September | 2.32               | 97.68             |
| 2019          | March     | 2.29               | 97.71             |
| 2019          | April     | 2.20               | 97.80             |
| 2019          | May       | 2.48               | 97.52             |
| 2019          | June      | 2.58               | 97.42             |
| 2019          | July      | 2.65               | 97.35             |
| 2019          | August    | 2.79               | 97.21             |
| 2019          | September | 2.91               | 97.09             |
| 2020          | March     | 2.70               | 97.30             |
| 2020          | April     | 3.04               | 96.96             |
| 2020          | May       | 3.29               | 96.71             |
| 2020          | June      | 3.20               | 96.80             |
| 2020          | July      | 3.33               | 96.67             |
| 2020          | August    | 3.49               | 96.51             |

### 7. What is the percentage of sales by demographic for each year in the dataset?
```sql
SELECT
	calendar_year,
	ROUND((SUM(sales)FILTER(WHERE demographic = 'Families')) * 100.0 /SUM(sales),2) AS families_sales_perc,
	ROUND((SUM(sales)FILTER(WHERE demographic = 'Couples')) * 100.0 /SUM(sales),2) AS couples_sales_perc,
	ROUND((SUM(sales)FILTER(WHERE demographic = 'unknown')) * 100.0 /SUM(sales),2) AS unknown_sales_perc
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year
```
**Results:**
| calendar_year | families_sales_perc | couples_sales_perc | unknown_sales_perc |
|---------------|---------------------|--------------------|--------------------|
| 2018          | 31.99               | 26.38              | 41.63              |
| 2019          | 32.47               | 27.28              | 40.25              |
| 2020          | 32.73               | 28.72              | 38.55              |


### 8. Which age_band and demographic values contribute the most to Retail sales?
```sql
SELECT
	age_band,
	demographic,
	SUM(sales)::MONEY AS sales,
	ROUND(SUM(sales) *100 / SUM(SUM(sales)) OVER(),2) AS percentage
FROM data_mart.clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY SUM(sales) DESC
```
**Results:**
| age_band     | demographic | sales              | percentage |
|--------------|-------------|--------------------|------------|
| unknown      | unknown     | $16,067,285,533.00 | 40.52      |
| Retirees     | Families    | $6,634,686,916.00  | 16.73      |
| Retirees     | Couples     | $6,370,580,014.00  | 16.07      |
| Middle Aged  | Families    | $4,354,091,554.00  | 10.98      |
| Young Adults | Couples     | $2,602,922,797.00  | 6.56       |
| Middle Aged  | Couples     | $1,854,160,330.00  | 4.68       |
| Young Adults | Families    | $1,770,889,293.00  | 4.47       |


### 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
No, we can´t use the avg_transaction because it´s the avg of each week, first we need to get the  total of sales and transaction for each year and platform and then get the avg.
```sql
SELECT
	calendar_year,
	platform,
	ROUND(SUM(sales)/(SUM(transactions)*1.0),2) AS avg_transaction
FROM data_mart.clean_weekly_sales
GROUP BY calendar_year, platform
ORDER BY calendar_year, platform;
```
**Results:**
| calendar_year | platform | avg_transaction |
|---------------|----------|-----------------|
| 2018          | Retail   | 36.56           |
| 2018          | Shopify  | 192.48          |
| 2019          | Retail   | 36.83           |
| 2019          | Shopify  | 183.36          |
| 2020          | Retail   | 36.56           |
| 2020          | Shopify  | 179.03          |

---
## C. Before & After Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before
Using this analysis approach - answer the following questions:

### 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
```sql
WITH resume AS (
	SELECT
		SUM(sales) FILTER (WHERE week_number BETWEEN 21 AND 24 AND calendar_year = 2020) AS sales_before,
		SUM(sales) FILTER (WHERE week_number BETWEEN 25 AND 28 AND calendar_year = 2020) AS sales_after
	FROM data_mart.clean_weekly_sales
)
SELECT
	sales_before::MONEY,
	sales_after::MONEY,
	(sales_after - sales_before)::MONEY AS difference,
	ROUND((sales_after - sales_before)*100.0/ sales_before,2) AS percentage
FROM resume
```
**Results:**
| sales_before      | sales_after       | difference    | percentage |
|-------------------|-------------------|---------------|------------|
| $2,330,895,615.00 | $2,334,905,223.00 | $4,009,608.00 | 0.17       |

### 2. What about the entire 12 weeks before and after?
```sql
WITH resume AS (
	SELECT
		SUM(sales) FILTER (WHERE week_number BETWEEN 13 AND 24 AND calendar_year = 2020) AS sales_before,
		SUM(sales) FILTER (WHERE week_number BETWEEN 25 AND 36 AND calendar_year = 2020) AS sales_after
	FROM data_mart.clean_weekly_sales
)
SELECT
	sales_before::MONEY,
	sales_after::MONEY,
	(sales_after - sales_before)::MONEY AS difference,
	ROUND((sales_after - sales_before)*100.0/ sales_before,2) AS percentage
FROM resume
```
**Results:**
| sales_before      | sales_after       | difference       | percentage |
|-------------------|-------------------|------------------|------------|
| $7,058,100,989.00 | $6,403,922,405.00 | -$654,178,584.00 | -9.27      |

### 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
The change impact in the wrong way.
```sql
WITH resume AS (
	SELECT
		calendar_year,
		SUM(sales) FILTER (WHERE week_number BETWEEN 13 AND 24 ) AS sales_before,
		SUM(sales) FILTER (WHERE week_number BETWEEN 25 AND 36 ) AS sales_after
	FROM data_mart.clean_weekly_sales
	GROUP BY calendar_year
)
SELECT
	calendar_year,
	sales_before::MONEY,
	sales_after::MONEY,
	(sales_after - sales_before)::MONEY AS difference,
	ROUND((sales_after - sales_before)*100.0/ sales_before,2) AS percentage
FROM resume
ORDER BY calendar_year

```
**Results:**
| calendar_year | sales_before      | sales_after       | difference       | percentage |
|---------------|-------------------|-------------------|------------------|------------|
| 2018          | $6,396,562,317.00 | $6,500,818,510.00 | $104,256,193.00  | 1.63       |
| 2019          | $6,861,158,161.00 | $6,303,557,285.00 | -$557,600,876.00 | -8.13      |
| 2020          | $7,058,100,989.00 | $6,403,922,405.00 | -$654,178,584.00 | -9.27      |

---
## D. Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
- region
- platform
- age_band
- demographic
- customer_type
- 
Do you have any further recommendations for Danny’s team at Data Mart or any interesting insights based off this analysis?

Investigate south america-shopify- the reduction of sales in all age band and demographics. 
```sql
WITH resume AS (
	SELECT
		region,
		platform,
		age_band,
		demographic,
		customer_type,
		SUM(sales) FILTER (WHERE week_number BETWEEN 13 AND 24 ) AS sales_before,
		SUM(sales) FILTER (WHERE week_number BETWEEN 25 AND 36 ) AS sales_after
	FROM data_mart.clean_weekly_sales
	WHERE calendar_year = 2020
	GROUP BY 1,2,3,4,5
)
SELECT
	region,
	platform,
	age_band,
	demographic,
	customer_type,
	sales_before::MONEY,
	sales_after::MONEY,
	(sales_after - sales_before)::MONEY AS difference,
	ROUND((sales_after - sales_before)*100.0/ sales_before,2) AS percentage
FROM resume
ORDER BY percentage
```
**Results:**
| region        | platform | age_band     | demographic | customer_type | sales_before    | sales_after     | difference      | percentage |
|---------------|----------|--------------|-------------|---------------|-----------------|-----------------|-----------------|------------|
| SOUTH AMERICA | Shopify  | unknown      | unknown     | Existing      | $11,433.00      | $6,436.00       | -$4,997.00      | -43.71     |
| EUROPE        | Shopify  | Retirees     | Families    | New           | $7,224.00       | $4,358.00       | -$2,866.00      | -39.67     |
| SOUTH AMERICA | Shopify  | Retirees     | Families    | New           | $8,038.00       | $5,421.00       | -$2,617.00      | -32.56     |
| EUROPE        | Shopify  | Young Adults | Families    | New           | $15,530.00      | $11,034.00      | -$4,496.00      | -28.95     |
| SOUTH AMERICA | Shopify  | Middle Aged  | Families    | New           | $13,350.00      | $9,679.00       | -$3,671.00      | -27.50     |
| SOUTH AMERICA | Shopify  | Retirees     | Couples     | New           | $62,070.00      | $45,719.00      | -$16,351.00     | -26.34     |
| SOUTH AMERICA | Retail   | unknown      | unknown     | Existing      | $121,332.00     | $91,260.00      | -$30,072.00     | -24.78     |
| SOUTH AMERICA | Retail   | Retirees     | Families    | New           | $158,369.00     | $123,229.00     | -$35,140.00     | -22.19     |
| SOUTH AMERICA | Retail   | Retirees     | Couples     | Existing      | $1,131,727.00   | $910,890.00     | -$220,837.00    | -19.51     |
| SOUTH AMERICA | Retail   | Retirees     | Couples     | New           | $597,390.00     | $485,212.00     | -$112,178.00    | -18.78     |
| SOUTH AMERICA | Retail   | Young Adults | Families    | Existing      | $415,075.00     | $344,377.00     | -$70,698.00     | -17.03     |
| OCEANIA       | Retail   | unknown      | unknown     | Existing      | $23,614,631.00  | $19,667,885.00  | -$3,946,746.00  | -16.71     |
| SOUTH AMERICA | Retail   | unknown      | unknown     | New           | $568,789.00     | $476,798.00     | -$91,991.00     | -16.17     |
| AFRICA        | Retail   | unknown      | unknown     | Existing      | $19,077,582.00  | $16,130,721.00  | -$2,946,861.00  | -15.45     |
| ASIA          | Retail   | unknown      | unknown     | Existing      | $17,215,566.00  | $14,559,221.00  | -$2,656,345.00  | -15.43     |
| CANADA        | Shopify  | unknown      | unknown     | Existing      | $192,186.00     | $162,968.00     | -$29,218.00     | -15.20     |
| EUROPE        | Shopify  | Retirees     | Families    | Existing      | $355,912.00     | $305,384.00     | -$50,528.00     | -14.20     |
| SOUTH AMERICA | Retail   | Middle Aged  | Couples     | Existing      | $496,586.00     | $426,791.00     | -$69,795.00     | -14.05     |
| CANADA        | Shopify  | Middle Aged  | Couples     | New           | $172,184.00     | $148,301.00     | -$23,883.00     | -13.87     |
| SOUTH AMERICA | Retail   | Young Adults | Couples     | Existing      | $1,094,780.00   | $944,787.00     | -$149,993.00    | -13.70     |
| CANADA        | Shopify  | Young Adults | Families    | New           | $102,129.00     | $88,676.00      | -$13,453.00     | -13.17     |
| USA           | Shopify  | unknown      | unknown     | New           | $309,356.00     | $269,057.00     | -$40,299.00     | -13.03     |
| OCEANIA       | Retail   | unknown      | unknown     | New           | $34,294,963.00  | $29,838,836.00  | -$4,456,127.00  | -12.99     |
| CANADA        | Retail   | unknown      | unknown     | New           | $6,858,908.00   | $5,978,667.00   | -$880,241.00    | -12.83     |
| ASIA          | Retail   | Middle Aged  | Families    | Existing      | $131,060,690.00 | $115,096,796.00 | -$15,963,894.00 | -12.18     |
| ASIA          | Retail   | unknown      | unknown     | New           | $26,081,038.00  | $23,003,822.00  | -$3,077,216.00  | -11.80     |
| SOUTH AMERICA | Retail   | Young Adults | Families    | New           | $121,900.00     | $107,568.00     | -$14,332.00     | -11.76     |
| OCEANIA       | Retail   | Young Adults | Families    | Existing      | $89,876,131.00  | $79,334,299.00  | -$10,541,832.00 | -11.73     |
| CANADA        | Shopify  | unknown      | unknown     | New           | $162,125.00     | $143,152.00     | -$18,973.00     | -11.70     |
| USA           | Retail   | Young Adults | Families    | Existing      | $28,504,176.00  | $25,177,976.00  | -$3,326,200.00  | -11.67     |
| ASIA          | Retail   | unknown      | unknown     | Guest         | $598,318,725.00 | $529,404,942.00 | -$68,913,783.00 | -11.52     |
| OCEANIA       | Retail   | Middle Aged  | Families    | Existing      | $219,327,614.00 | $194,275,863.00 | -$25,051,751.00 | -11.42     |
| ASIA          | Retail   | Retirees     | Couples     | Existing      | $197,070,957.00 | $174,734,582.00 | -$22,336,375.00 | -11.33     |
| CANADA        | Retail   | Young Adults | Families    | Existing      | $15,884,841.00  | $14,115,412.00  | -$1,769,429.00  | -11.14     |
| OCEANIA       | Retail   | unknown      | unknown     | Guest         | $785,487,392.00 | $698,304,085.00 | -$87,183,307.00 | -11.10     |
| ASIA          | Retail   | Young Adults | Families    | Existing      | $55,306,213.00  | $49,233,490.00  | -$6,072,723.00  | -10.98     |
| USA           | Retail   | unknown      | unknown     | Existing      | $7,862,566.00   | $6,999,000.00   | -$863,566.00    | -10.98     |
| AFRICA        | Retail   | Young Adults | Families    | Existing      | $63,819,355.00  | $56,874,911.00  | -$6,944,444.00  | -10.88     |
| USA           | Retail   | unknown      | unknown     | Guest         | $202,709,419.00 | $181,047,378.00 | -$21,662,041.00 | -10.69     |
| SOUTH AMERICA | Shopify  | Young Adults | Couples     | New           | $28,657.00      | $25,602.00      | -$3,055.00      | -10.66     |
| SOUTH AMERICA | Shopify  | Retirees     | Couples     | Existing      | $263,912.00     | $235,799.00     | -$28,113.00     | -10.65     |
| USA           | Retail   | Middle Aged  | Families    | Existing      | $66,401,956.00  | $59,378,935.00  | -$7,023,021.00  | -10.58     |
| OCEANIA       | Retail   | Middle Aged  | Couples     | Existing      | $79,721,026.00  | $71,322,667.00  | -$8,398,359.00  | -10.53     |
| CANADA        | Retail   | unknown      | unknown     | Guest         | $134,994,175.00 | $120,801,407.00 | -$14,192,768.00 | -10.51     |
| OCEANIA       | Retail   | Retirees     | Couples     | Existing      | $293,696,659.00 | $263,006,703.00 | -$30,689,956.00 | -10.45     |
| CANADA        | Retail   | Middle Aged  | Families    | Existing      | $39,957,005.00  | $35,793,827.00  | -$4,163,178.00  | -10.42     |
| SOUTH AMERICA | Retail   | Middle Aged  | Families    | Existing      | $670,404.00     | $601,551.00     | -$68,853.00     | -10.27     |
| SOUTH AMERICA | Retail   | Middle Aged  | Families    | New           | $184,569.00     | $166,048.00     | -$18,521.00     | -10.03     |
| USA           | Shopify  | Young Adults | Families    | Existing      | $3,059,726.00   | $2,754,854.00   | -$304,872.00    | -9.96      |
| ASIA          | Retail   | Retirees     | Families    | Existing      | $242,100,261.00 | $218,226,089.00 | -$23,874,172.00 | -9.86      |
| AFRICA        | Retail   | unknown      | unknown     | New           | $26,403,954.00  | $23,803,011.00  | -$2,600,943.00  | -9.85      |
| CANADA        | Retail   | Retirees     | Couples     | Existing      | $56,405,167.00  | $50,851,456.00  | -$5,553,711.00  | -9.85      |
| OCEANIA       | Retail   | Retirees     | Families    | Existing      | $361,039,197.00 | $325,818,680.00 | -$35,220,517.00 | -9.76      |
| AFRICA        | Retail   | Middle Aged  | Families    | Existing      | $178,849,738.00 | $161,444,678.00 | -$17,405,060.00 | -9.73      |
| USA           | Retail   | unknown      | unknown     | New           | $11,077,330.00  | $10,005,549.00  | -$1,071,781.00  | -9.68      |
| OCEANIA       | Retail   | Young Adults | Couples     | Existing      | $110,609,277.00 | $99,924,539.00  | -$10,684,738.00 | -9.66      |
| CANADA        | Retail   | Young Adults | Couples     | Existing      | $27,766,496.00  | $25,086,480.00  | -$2,680,016.00  | -9.65      |
| SOUTH AMERICA | Retail   | unknown      | unknown     | Guest         | $198,408,608.00 | $179,471,138.00 | -$18,937,470.00 | -9.54      |
| ASIA          | Retail   | Middle Aged  | Couples     | Existing      | $59,324,793.00  | $53,670,415.00  | -$5,654,378.00  | -9.53      |
| SOUTH AMERICA | Retail   | Retirees     | Families    | Existing      | $809,930.00     | $732,789.00     | -$77,141.00     | -9.52      |
| SOUTH AMERICA | Shopify  | Young Adults | Families    | Existing      | $180,882.00     | $163,816.00     | -$17,066.00     | -9.43      |
| EUROPE        | Shopify  | Middle Aged  | Couples     | New           | $34,764.00      | $31,504.00      | -$3,260.00      | -9.38      |
| CANADA        | Retail   | Middle Aged  | Couples     | Existing      | $12,180,964.00  | $11,039,066.00  | -$1,141,898.00  | -9.37      |
| EUROPE        | Retail   | Young Adults | Families    | Existing      | $4,795,499.00   | $4,348,834.00   | -$446,665.00    | -9.31      |
| EUROPE        | Shopify  | Young Adults | Families    | Existing      | $356,895.00     | $324,654.00     | -$32,241.00     | -9.03      |
| CANADA        | Shopify  | Retirees     | Families    | Existing      | $1,481,283.00   | $1,348,863.00   | -$132,420.00    | -8.94      |
| EUROPE        | Shopify  | Middle Aged  | Families    | New           | $26,361.00      | $24,022.00      | -$2,339.00      | -8.87      |
| ASIA          | Retail   | Middle Aged  | Families    | New           | $24,723,594.00  | $22,550,492.00  | -$2,173,102.00  | -8.79      |
| AFRICA        | Retail   | unknown      | unknown     | Guest         | $537,330,728.00 | $490,472,473.00 | -$46,858,255.00 | -8.72      |
| ASIA          | Retail   | Young Adults | Couples     | Existing      | $73,369,997.00  | $67,007,420.00  | -$6,362,577.00  | -8.67      |
| USA           | Retail   | Retirees     | Couples     | Existing      | $96,194,946.00  | $87,943,882.00  | -$8,251,064.00  | -8.58      |
| SOUTH AMERICA | Retail   | Middle Aged  | Couples     | New           | $331,071.00     | $302,826.00     | -$28,245.00     | -8.53      |
| CANADA        | Retail   | Retirees     | Families    | Existing      | $62,563,624.00  | $57,237,216.00  | -$5,326,408.00  | -8.51      |
| EUROPE        | Shopify  | Middle Aged  | Families    | Existing      | $557,831.00     | $510,505.00     | -$47,326.00     | -8.48      |
| USA           | Retail   | Young Adults | Couples     | Existing      | $28,593,263.00  | $26,173,950.00  | -$2,419,313.00  | -8.46      |
| USA           | Retail   | Middle Aged  | Couples     | Existing      | $25,455,438.00  | $23,329,741.00  | -$2,125,697.00  | -8.35      |
| AFRICA        | Retail   | Middle Aged  | Couples     | Existing      | $57,455,661.00  | $52,722,424.00  | -$4,733,237.00  | -8.24      |
| CANADA        | Shopify  | Retirees     | Families    | New           | $55,469.00      | $50,917.00      | -$4,552.00      | -8.21      |
| USA           | Retail   | Retirees     | Families    | Existing      | $102,673,450.00 | $94,260,678.00  | -$8,412,772.00  | -8.19      |
| CANADA        | Retail   | unknown      | unknown     | Existing      | $4,184,894.00   | $3,844,734.00   | -$340,160.00    | -8.13      |
| CANADA        | Shopify  | Young Adults | Families    | Existing      | $1,557,769.00   | $1,431,195.00   | -$126,574.00    | -8.13      |
| OCEANIA       | Shopify  | unknown      | unknown     | Existing      | $1,283,954.00   | $1,183,456.00   | -$100,498.00    | -7.83      |
| ASIA          | Retail   | Young Adults | Families    | New           | $11,057,138.00  | $10,196,889.00  | -$860,249.00    | -7.78      |
| USA           | Shopify  | Retirees     | Families    | Existing      | $2,331,688.00   | $2,150,766.00   | -$180,922.00    | -7.76      |
| AFRICA        | Retail   | Retirees     | Families    | Existing      | $267,853,196.00 | $247,366,208.00 | -$20,486,988.00 | -7.65      |
| OCEANIA       | Retail   | Middle Aged  | Families    | New           | $34,220,790.00  | $31,648,346.00  | -$2,572,444.00  | -7.52      |
| EUROPE        | Retail   | unknown      | unknown     | Existing      | $1,630,561.00   | $1,508,292.00   | -$122,269.00    | -7.50      |
| EUROPE        | Retail   | Middle Aged  | Couples     | Existing      | $5,719,230.00   | $5,290,995.00   | -$428,235.00    | -7.49      |
| CANADA        | Retail   | Retirees     | Couples     | New           | $16,394,353.00  | $15,181,636.00  | -$1,212,717.00  | -7.40      |
| AFRICA        | Retail   | Retirees     | Couples     | Existing      | $244,936,727.00 | $226,985,184.00 | -$17,951,543.00 | -7.33      |
| CANADA        | Retail   | Middle Aged  | Families    | New           | $7,184,333.00   | $6,658,448.00   | -$525,885.00    | -7.32      |
| AFRICA        | Retail   | Young Adults | Couples     | Existing      | $80,760,897.00  | $74,848,450.00  | -$5,912,447.00  | -7.32      |
| USA           | Retail   | Young Adults | Families    | New           | $5,234,910.00   | $4,855,880.00   | -$379,030.00    | -7.24      |
| USA           | Retail   | Middle Aged  | Families    | New           | $11,761,980.00  | $10,911,535.00  | -$850,445.00    | -7.23      |
| USA           | Shopify  | Middle Aged  | Couples     | Existing      | $3,047,966.00   | $2,834,489.00   | -$213,477.00    | -7.00      |
| SOUTH AMERICA | Shopify  | Middle Aged  | Couples     | Existing      | $304,900.00     | $283,700.00     | -$21,200.00     | -6.95      |
| CANADA        | Shopify  | Retirees     | Couples     | Existing      | $1,947,704.00   | $1,814,110.00   | -$133,594.00    | -6.86      |
| EUROPE        | Retail   | unknown      | unknown     | New           | $1,576,033.00   | $1,467,998.00   | -$108,035.00    | -6.85      |
| EUROPE        | Retail   | Middle Aged  | Families    | Existing      | $10,212,120.00  | $9,513,373.00   | -$698,747.00    | -6.84      |
| USA           | Shopify  | Young Adults | Families    | New           | $213,621.00     | $199,130.00     | -$14,491.00     | -6.78      |
| USA           | Retail   | Middle Aged  | Couples     | New           | $10,546,000.00  | $9,834,870.00   | -$711,130.00    | -6.74      |
| OCEANIA       | Retail   | Middle Aged  | Couples     | New           | $34,209,847.00  | $31,956,508.00  | -$2,253,339.00  | -6.59      |
| SOUTH AMERICA | Shopify  | Young Adults | Families    | New           | $16,695.00      | $15,596.00      | -$1,099.00      | -6.58      |
| AFRICA        | Shopify  | Young Adults | Couples     | Existing      | $2,996,517.00   | $2,802,603.00   | -$193,914.00    | -6.47      |
| SOUTH AMERICA | Shopify  | unknown      | unknown     | New           | $85,804.00      | $80,269.00      | -$5,535.00      | -6.45      |
| OCEANIA       | Shopify  | Middle Aged  | Couples     | Existing      | $9,596,655.00   | $8,977,824.00   | -$618,831.00    | -6.45      |
| AFRICA        | Retail   | Young Adults | Families    | New           | $9,244,504.00   | $8,651,239.00   | -$593,265.00    | -6.42      |
| ASIA          | Retail   | Middle Aged  | Couples     | New           | $25,969,154.00  | $24,313,611.00  | -$1,655,543.00  | -6.38      |
| AFRICA        | Shopify  | Retirees     | Families    | New           | $191,082.00     | $178,933.00     | -$12,149.00     | -6.36      |
| CANADA        | Shopify  | Young Adults | Couples     | New           | $132,762.00     | $124,325.00     | -$8,437.00      | -6.35      |
| EUROPE        | Retail   | Retirees     | Families    | Existing      | $13,440,623.00  | $12,586,685.00  | -$853,938.00    | -6.35      |
| OCEANIA       | Retail   | Young Adults | Families    | New           | $15,222,875.00  | $14,259,666.00  | -$963,209.00    | -6.33      |
| AFRICA        | Shopify  | Retirees     | Families    | Existing      | $5,525,647.00   | $5,184,850.00   | -$340,797.00    | -6.17      |
| CANADA        | Shopify  | Middle Aged  | Couples     | Existing      | $1,419,958.00   | $1,333,497.00   | -$86,461.00     | -6.09      |
| CANADA        | Retail   | Young Adults | Families    | New           | $2,818,964.00   | $2,647,537.00   | -$171,427.00    | -6.08      |
| OCEANIA       | Shopify  | Retirees     | Couples     | Existing      | $11,836,608.00  | $11,119,334.00  | -$717,274.00    | -6.06      |
| ASIA          | Retail   | Retirees     | Couples     | New           | $58,036,698.00  | $54,529,370.00  | -$3,507,328.00  | -6.04      |
| CANADA        | Shopify  | Middle Aged  | Families    | Existing      | $2,855,718.00   | $2,684,327.00   | -$171,391.00    | -6.00      |
| AFRICA        | Shopify  | Retirees     | Couples     | Existing      | $6,872,592.00   | $6,462,564.00   | -$410,028.00    | -5.97      |
| SOUTH AMERICA | Shopify  | Young Adults | Couples     | Existing      | $137,043.00     | $128,947.00     | -$8,096.00      | -5.91      |
| SOUTH AMERICA | Retail   | Young Adults | Couples     | New           | $606,045.00     | $570,365.00     | -$35,680.00     | -5.89      |
| CANADA        | Shopify  | Retirees     | Couples     | New           | $191,443.00     | $180,182.00     | -$11,261.00     | -5.88      |
| EUROPE        | Retail   | Young Adults | Couples     | Existing      | $7,608,431.00   | $7,163,133.00   | -$445,298.00    | -5.85      |
| USA           | Shopify  | Retirees     | Couples     | Existing      | $3,759,095.00   | $3,541,376.00   | -$217,719.00    | -5.79      |
| CANADA        | Retail   | Retirees     | Families    | New           | $7,487,414.00   | $7,060,295.00   | -$427,119.00    | -5.70      |
| CANADA        | Retail   | Young Adults | Couples     | New           | $8,902,727.00   | $8,398,853.00   | -$503,874.00    | -5.66      |
| ASIA          | Shopify  | Retirees     | Couples     | Existing      | $5,021,347.00   | $4,738,486.00   | -$282,861.00    | -5.63      |
| USA           | Shopify  | Middle Aged  | Families    | Existing      | $4,420,930.00   | $4,172,450.00   | -$248,480.00    | -5.62      |
| ASIA          | Retail   | Retirees     | Families    | New           | $30,344,431.00  | $28,658,730.00  | -$1,685,701.00  | -5.56      |
| USA           | Shopify  | Young Adults | Couples     | Existing      | $1,467,075.00   | $1,387,719.00   | -$79,356.00     | -5.41      |
| ASIA          | Shopify  | Middle Aged  | Families    | New           | $345,638.00     | $327,615.00     | -$18,023.00     | -5.21      |
| CANADA        | Shopify  | Young Adults | Couples     | Existing      | $1,013,336.00   | $960,698.00     | -$52,638.00     | -5.19      |
| AFRICA        | Retail   | Middle Aged  | Families    | New           | $25,275,010.00  | $23,997,372.00  | -$1,277,638.00  | -5.05      |
| OCEANIA       | Shopify  | Retirees     | Families    | Existing      | $8,776,336.00   | $8,356,287.00   | -$420,049.00    | -4.79      |
| AFRICA        | Retail   | Middle Aged  | Couples     | New           | $20,104,047.00  | $19,144,926.00  | -$959,121.00    | -4.77      |
| ASIA          | Shopify  | Middle Aged  | Couples     | New           | $627,909.00     | $598,371.00     | -$29,538.00     | -4.70      |
| OCEANIA       | Shopify  | Young Adults | Families    | Existing      | $9,061,640.00   | $8,637,793.00   | -$423,847.00    | -4.68      |
| USA           | Retail   | Retirees     | Couples     | New           | $27,230,919.00  | $25,970,320.00  | -$1,260,599.00  | -4.63      |
| OCEANIA       | Retail   | Retirees     | Couples     | New           | $77,213,987.00  | $73,764,307.00  | -$3,449,680.00  | -4.47      |
| OCEANIA       | Shopify  | Middle Aged  | Families    | New           | $693,050.00     | $662,138.00     | -$30,912.00     | -4.46      |
| ASIA          | Shopify  | Middle Aged  | Couples     | Existing      | $4,451,563.00   | $4,257,776.00   | -$193,787.00    | -4.35      |
| OCEANIA       | Shopify  | Middle Aged  | Families    | Existing      | $14,457,712.00  | $13,867,493.00  | -$590,219.00    | -4.08      |
| USA           | Shopify  | unknown      | unknown     | Guest         | $5,087,678.00   | $4,882,339.00   | -$205,339.00    | -4.04      |
| USA           | Retail   | Young Adults | Couples     | New           | $11,060,501.00  | $10,620,030.00  | -$440,471.00    | -3.98      |
| USA           | Shopify  | Retirees     | Couples     | New           | $374,339.00     | $359,523.00     | -$14,816.00     | -3.96      |
| OCEANIA       | Shopify  | Young Adults | Couples     | Existing      | $5,136,547.00   | $4,945,557.00   | -$190,990.00    | -3.72      |
| ASIA          | Shopify  | Young Adults | Families    | Existing      | $4,018,907.00   | $3,876,236.00   | -$142,671.00    | -3.55      |
| AFRICA        | Shopify  | Middle Aged  | Couples     | Existing      | $5,197,144.00   | $5,014,439.00   | -$182,705.00    | -3.52      |
| AFRICA        | Shopify  | Middle Aged  | Families    | Existing      | $9,956,322.00   | $9,610,898.00   | -$345,424.00    | -3.47      |
| SOUTH AMERICA | Shopify  | Retirees     | Families    | Existing      | $75,165.00      | $72,619.00      | -$2,546.00      | -3.39      |
| AFRICA        | Shopify  | Middle Aged  | Families    | New           | $461,310.00     | $446,099.00     | -$15,211.00     | -3.30      |
| ASIA          | Retail   | Young Adults | Couples     | New           | $31,451,093.00  | $30,414,026.00  | -$1,037,067.00  | -3.30      |
| CANADA        | Retail   | Middle Aged  | Couples     | New           | $5,459,973.00   | $5,281,407.00   | -$178,566.00    | -3.27      |
| USA           | Shopify  | Middle Aged  | Families    | New           | $252,499.00     | $244,348.00     | -$8,151.00      | -3.23      |
| ASIA          | Shopify  | Retirees     | Couples     | New           | $519,684.00     | $503,278.00     | -$16,406.00     | -3.16      |
| USA           | Retail   | Retirees     | Families    | New           | $11,742,544.00  | $11,377,674.00  | -$364,870.00    | -3.11      |
| OCEANIA       | Retail   | Young Adults | Couples     | New           | $43,116,854.00  | $41,790,859.00  | -$1,325,995.00  | -3.08      |
| OCEANIA       | Retail   | Retirees     | Families    | New           | $39,861,321.00  | $38,689,241.00  | -$1,172,080.00  | -2.94      |
| CANADA        | Shopify  | unknown      | unknown     | Guest         | $2,961,853.00   | $2,874,984.00   | -$86,869.00     | -2.93      |
| OCEANIA       | Shopify  | unknown      | unknown     | New           | $873,107.00     | $848,175.00     | -$24,932.00     | -2.86      |
| EUROPE        | Shopify  | Young Adults | Couples     | Existing      | $253,763.00     | $246,523.00     | -$7,240.00      | -2.85      |
| EUROPE        | Retail   | unknown      | unknown     | Guest         | $40,163,434.00  | $39,022,975.00  | -$1,140,459.00  | -2.84      |
| EUROPE        | Retail   | Retirees     | Couples     | Existing      | $13,128,043.00  | $12,762,659.00  | -$365,384.00    | -2.78      |
| AFRICA        | Shopify  | Young Adults | Families    | Existing      | $5,231,141.00   | $5,092,280.00   | -$138,861.00    | -2.65      |
| AFRICA        | Retail   | Young Adults | Couples     | New           | $26,778,108.00  | $26,133,324.00  | -$644,784.00    | -2.41      |
| EUROPE        | Shopify  | Retirees     | Couples     | Existing      | $618,102.00     | $603,784.00     | -$14,318.00     | -2.32      |
| AFRICA        | Shopify  | Young Adults | Families    | New           | $292,944.00     | $286,712.00     | -$6,232.00      | -2.13      |
| OCEANIA       | Shopify  | unknown      | unknown     | Guest         | $20,645,562.00  | $20,258,010.00  | -$387,552.00    | -1.88      |
| ASIA          | Shopify  | Retirees     | Families    | Existing      | $3,930,720.00   | $3,865,981.00   | -$64,739.00     | -1.65      |
| OCEANIA       | Shopify  | Young Adults | Families    | New           | $504,469.00     | $497,012.00     | -$7,457.00      | -1.48      |
| AFRICA        | Retail   | Retirees     | Couples     | New           | $60,150,316.00  | $59,297,506.00  | -$852,810.00    | -1.42      |
| AFRICA        | Shopify  | Middle Aged  | Couples     | New           | $594,235.00     | $587,984.00     | -$6,251.00      | -1.05      |
| AFRICA        | Retail   | Retirees     | Families    | New           | $26,388,562.00  | $26,136,386.00  | -$252,176.00    | -0.96      |
| AFRICA        | Shopify  | Young Adults | Couples     | New           | $390,456.00     | $387,294.00     | -$3,162.00      | -0.81      |
| ASIA          | Shopify  | unknown      | unknown     | New           | $507,049.00     | $505,609.00     | -$1,440.00      | -0.28      |
| ASIA          | Shopify  | Middle Aged  | Families    | Existing      | $5,848,621.00   | $5,836,429.00   | -$12,192.00     | -0.21      |
| AFRICA        | Shopify  | unknown      | unknown     | Guest         | $10,544,827.00  | $10,532,223.00  | -$12,604.00     | -0.12      |
| EUROPE        | Retail   | Young Adults | Families    | New           | $425,605.00     | $425,788.00     | $183.00         | 0.04       |
| EUROPE        | Shopify  | Middle Aged  | Couples     | Existing      | $536,310.00     | $537,654.00     | $1,344.00       | 0.25       |
| OCEANIA       | Shopify  | Retirees     | Couples     | New           | $1,060,056.00   | $1,063,892.00   | $3,836.00       | 0.36       |
| AFRICA        | Shopify  | Retirees     | Couples     | New           | $635,183.00     | $637,518.00     | $2,335.00       | 0.37       |
| ASIA          | Shopify  | Young Adults | Couples     | Existing      | $2,202,260.00   | $2,214,783.00   | $12,523.00      | 0.57       |
| ASIA          | Shopify  | Young Adults | Families    | New           | $259,183.00     | $261,150.00     | $1,967.00       | 0.76       |
| CANADA        | Shopify  | Middle Aged  | Families    | New           | $145,247.00     | $146,572.00     | $1,325.00       | 0.91       |
| OCEANIA       | Shopify  | Retirees     | Families    | New           | $316,432.00     | $319,469.00     | $3,037.00       | 0.96       |
| AFRICA        | Shopify  | unknown      | unknown     | Existing      | $665,070.00     | $675,460.00     | $10,390.00      | 1.56       |
| USA           | Shopify  | Young Adults | Couples     | New           | $210,261.00     | $213,975.00     | $3,714.00       | 1.77       |
| SOUTH AMERICA | Shopify  | unknown      | unknown     | Guest         | $4,083,579.00   | $4,171,240.00   | $87,661.00      | 2.15       |
| EUROPE        | Retail   | Young Adults | Couples     | New           | $1,486,275.00   | $1,520,064.00   | $33,789.00      | 2.27       |
| USA           | Shopify  | Retirees     | Families    | New           | $85,070.00      | $87,125.00      | $2,055.00       | 2.42       |
| EUROPE        | Shopify  | unknown      | unknown     | Guest         | $823,559.00     | $845,770.00     | $22,211.00      | 2.70       |
| EUROPE        | Retail   | Middle Aged  | Couples     | New           | $1,142,975.00   | $1,181,275.00   | $38,300.00      | 3.35       |
| EUROPE        | Shopify  | Retirees     | Couples     | New           | $34,267.00      | $35,630.00      | $1,363.00       | 3.98       |
| OCEANIA       | Shopify  | Young Adults | Couples     | New           | $622,984.00     | $647,868.00     | $24,884.00      | 3.99       |
| OCEANIA       | Shopify  | Middle Aged  | Couples     | New           | $1,142,046.00   | $1,196,765.00   | $54,719.00      | 4.79       |
| ASIA          | Shopify  | unknown      | unknown     | Guest         | $9,770,447.00   | $10,261,916.00  | $491,469.00     | 5.03       |
| SOUTH AMERICA | Shopify  | Middle Aged  | Couples     | New           | $75,988.00      | $80,039.00      | $4,051.00       | 5.33       |
| ASIA          | Shopify  | Young Adults | Couples     | New           | $323,743.00     | $344,238.00     | $20,495.00      | 6.33       |
| EUROPE        | Retail   | Retirees     | Families    | New           | $805,881.00     | $860,027.00     | $54,146.00      | 6.72       |
| AFRICA        | Shopify  | unknown      | unknown     | New           | $518,299.00     | $559,034.00     | $40,735.00      | 7.86       |
| EUROPE        | Retail   | Middle Aged  | Families    | New           | $776,447.00     | $840,212.00     | $63,765.00      | 8.21       |
| EUROPE        | Shopify  | Young Adults | Couples     | New           | $21,824.00      | $23,723.00      | $1,899.00       | 8.70       |
| ASIA          | Shopify  | Retirees     | Families    | New           | $156,735.00     | $170,452.00     | $13,717.00      | 8.75       |
| USA           | Shopify  | Middle Aged  | Couples     | New           | $402,169.00     | $438,820.00     | $36,651.00      | 9.11       |
| EUROPE        | Retail   | Retirees     | Couples     | New           | $2,454,485.00   | $2,707,642.00   | $253,157.00     | 10.31      |
| ASIA          | Shopify  | unknown      | unknown     | Existing      | $618,216.00     | $686,147.00     | $67,931.00      | 10.99      |
| SOUTH AMERICA | Shopify  | Middle Aged  | Families    | Existing      | $73,660.00      | $82,062.00      | $8,402.00       | 11.41      |
| USA           | Shopify  | unknown      | unknown     | Existing      | $318,379.00     | $357,259.00     | $38,880.00      | 12.21      |
| EUROPE        | Shopify  | unknown      | unknown     | Existing      | $48,828.00      | $65,503.00      | $16,675.00      | 34.15      |
| EUROPE        | Shopify  | unknown      | unknown     | New           | $28,926.00      | $40,373.00      | $11,447.00      | 39.57      |





