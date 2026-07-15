# 🧺 Case Study #5 - Data Mart
URL https://8weeksqlchallenge.com/case-study-5/
URL https://www.db-fiddle.com/f/jmnwogTsUE8hGqkZv9H7E8/8

## 📌 Business Overview
In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.
Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.
The key business question he wants you to help him answer are the following:

-What was the quantifiable impact of the changes introduced in June 2020?
-Which platform, region, segment and customer types were the most impacted by this change?
-What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?


---

## A.Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

-Convert the week_date to a DATE format
-Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
-Add a month_number with the calendar month for each week_date value as the 3rd column
-Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
-Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
(1=Young Adults,2=Middle Aged,3 or 4	=Retirees)
-Add a new demographic column using the following mapping for the first letter in the segment values:
(C=Couples,F=Families)
-Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
-Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

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

### 
```sql

```
**Results:**

### 
```sql

```
**Results:**

### 
```sql

```
**Results:**


---
##
### 
```sql

```
**Results:**





