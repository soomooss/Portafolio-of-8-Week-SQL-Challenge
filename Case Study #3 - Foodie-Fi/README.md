# 🥑 Case Study 3: Foodie-Fi 
URL https://8weeksqlchallenge.com/case-study-3/

## 📌 Business Overview
Foodie-Fi is a subscription-based streaming service dedicated exclusively to food-related content. This project focuses on analyzing customer journey metrics, evaluating subscription growth, measuring plan transition behaviors, and generating a dynamic billing/payment simulation table for the year 2020 using **PostgreSQL**.

---

## 📂 A.Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.
Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
```sql
SELECT
	s.customer_id,
	s.start_date,
	p.plan_name
FROM foodie_fi.subscriptions AS s
INNER JOIN foodie_fi.plans AS p
	ON s.plan_id = p.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
ORDER BY s.customer_id
```
- 1 - trial -> basic
- 2- trial -> pro annual
- 11 - trial -> cancel
- 13 - trial -> basic -> pro mon
- 15 - trial -> pro mon -> cancel
- 16 - trial -> basic -> pro annual
- 18 - trial -> pro mon
- 19 - trial -> pro mon -> pro annual


---

## 📊 B.Data Analysis Questions

### 1. How many customers has Foodie-Fi ever had?
```sql
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM foodie_fi.subscriptions;
```
| total_customers |
|-----------------|
| 1000            |

### 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
```sql
SELECT
	date_trunc('month', s.start_date)::DATE AS month_start,
	COUNT(s.customer_id) AS subscriptions
FROM foodie_fi.subscriptions AS s
WHERE plan_id = 0
GROUP BY month_start
ORDER BY month_start;
```
| month_start | subscriptions |
|-------------|---------------|
| 2020-01-01  | 88            |
| 2020-02-01  | 68            |
| 2020-03-01  | 94            |
| 2020-04-01  | 81            |
| 2020-05-01  | 88            |
| 2020-06-01  | 79            |
| 2020-07-01  | 89            |
| 2020-08-01  | 88            |
| 2020-09-01  | 87            |
| 2020-10-01  | 79            |
| 2020-11-01  | 75            |
| 2020-12-01  | 84            |

### 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
```sql
SELECT
	p.plan_name,
	COUNT(p.plan_name) AS event_count
FROM foodie_fi.subscriptions AS s
INNER JOIN foodie_fi.plans AS p
	ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM start_date) > 2020
GROUP BY p.plan_name
ORDER BY  event_count DESC;
```
| plan_name     | event_count |
|---------------|-------------|
| churn         | 71          |
| pro annual    | 63          |
| pro monthly   | 60          |
| basic monthly | 8           |

### 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
```sql
SELECT
	COUNT(DISTINCT customer_id) AS total_clientes,
	COUNT(customer_id) FILTER( WHERE plan_id = 4) AS cancelaciones,
	ROUND((COUNT(DISTINCT customer_id) FILTER( WHERE plan_id = 4) * 100.0) /  COUNT(DISTINCT customer_id),1) AS porcentaje
FROM foodie_fi.subscriptions;
```
| total_clientes | cancelaciones | porcentaje |
|----------------|---------------|------------|
| 1000           | 307           | 30.7       |

### 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
```sql
WITH ctee AS (
	SELECT
		customer_id,
		plan_id,
		start_date,
		ROW_NUMBER() OVER(
			PARTITION BY customer_id ORDER BY start_date
		) AS row_order
	FROM foodie_fi.subscriptions
)

SELECT
	COUNT(DISTINCT customer_id) AS total_clientes,
	COUNT(customer_id) FILTER(WHERE row_order = 2 AND plan_id =4) AS cancelaciones_despues_de_prueba,
	ROUND((COUNT(customer_id) FILTER(WHERE row_order = 2 AND plan_id =4) *100.0) / COUNT(DISTINCT customer_id),0) AS porcentaje
FROM ctee;
```
| total_clientes | cancelaciones_despues_de_prueba | porcentaje |
|----------------|---------------------------------|------------|
| 1000           | 92                              | 9          |

### 6. What is the number and percentage of customer plans after their initial free trial?
```sql
WITH ctee AS (
	SELECT
		customer_id,
		plan_id,
		start_date,
		ROW_NUMBER() OVER(
			PARTITION BY customer_id ORDER BY start_date
		) AS row_order
	FROM foodie_fi.subscriptions
)

SELECT
	plan_name,
	COUNT(c.plan_id) AS cantidad,
	ROUND((COUNT(c.plan_id) * 100.0) / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions),1) AS porcentaje
FROM ctee AS c
INNER JOIN foodie_fi.plans AS p
	ON c.plan_id = p.plan_id
WHERE c.row_order = 2
GROUP BY plan_name
```
| plan_name     | cantidad | porcentaje |
|---------------|----------|------------|
| basic monthly | 546      | 54.6       |
| churn         | 92       | 9.2        |
| pro annual    | 37       | 3.7        |
| pro monthly   | 325      | 32.5       |

### 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
```sql
WITH ctee AS (
SELECT
		customer_id,
		plan_id,
		start_date,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS order_number
FROM foodie_fi.subscriptions
WHERE start_date <= '2020-12-31'
)

SELECT
	p.plan_name,
	COUNT(c.plan_id) AS cantidad,
	ROUND((COUNT(c.plan_id) * 100.0) / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions WHERE start_date <= '2020-12-31'),2) AS porcentaje
FROM ctee AS c
INNER JOIN foodie_fi.plans AS p
	ON c.plan_id = p.plan_id
WHERE order_number = 1
GROUP BY p.plan_name;
```
| plan_name     | cantidad | porcentaje |
|---------------|----------|------------|
| basic monthly | 224      | 22.40      |
| churn         | 236      | 23.60      |
| pro annual    | 195      | 19.50      |
| pro monthly   | 326      | 32.60      |
| trial         | 19       | 1.90       |

### 8. How many customers have upgraded to an annual plan in 2020?
```sql
SELECT
	COUNT(plan_id)
FROM foodie_fi.subscriptions 
WHERE start_date BETWEEN '2020-01-01'  AND '2020-12-31' AND plan_id = 3;
```
| count |
|-------|
| 195   |

### 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
```sql
WITH annual AS (
	SELECT
		customer_id,
		plan_id,
		start_date AS start_date_annual 
	FROM foodie_fi.subscriptions
	WHERE plan_id = 3
), 
trial AS 
(	
	SELECT
		customer_id,
		plan_id,
		start_date AS start_date_trial
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0
)
SELECT
	ROUND(AVG(a.start_date_annual - t.start_date_trial),0) AS avg_days_to_pay_annual_plan
FROM annual AS a
INNER JOIN trial AS t
	ON a.customer_id = t.customer_id;
```
| avg_days_to_pay_annual_plan |
|-----------------------------|
| 105                         |

### 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
```sql
WITH annual AS (
	SELECT
		customer_id,
		plan_id,
		start_date AS start_date_annual 
	FROM foodie_fi.subscriptions
	WHERE plan_id = 3
), 
trial AS 
(	
	SELECT
		customer_id,
		plan_id,
		start_date AS start_date_trial
	FROM foodie_fi.subscriptions
	WHERE plan_id = 0
),
number_of_days AS (
SELECT
a.start_date_annual - t.start_date_trial AS total_days
FROM annual AS a
INNER JOIN trial AS t
	ON a.customer_id = t.customer_id)

SELECT 
	((total_days -1) / 30 ) * 30 + 1 || ' - ' || ((total_days -1)/30 + 1) * 30 || ' days' AS rango,
	COUNT(total_days) AS total
FROM number_of_days
GROUP BY ((total_days -1) / 30)
ORDER BY ((total_days -1) / 30);
```
| rango          | total |
|----------------|-------|
| 1 - 30 days    | 49    |
| 31 - 60 days   | 24    |
| 61 - 90 days   | 34    |
| 91 - 120 days  | 35    |
| 121 - 150 days | 42    |
| 151 - 180 days | 36    |
| 181 - 210 days | 26    |
| 211 - 240 days | 4     |
| 241 - 270 days | 5     |
| 271 - 300 days | 1     |
| 301 - 330 days | 1     |
| 331 - 360 days | 1     |
### 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
```sql
WITH ctee AS (
	SELECT
		customer_id,
		plan_id,
		start_date,
		LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date) AS next_step
	FROM foodie_fi.subscriptions
)
SELECT COUNT(DISTINCT customer_id) AS total_clientes
FROM ctee
WHERE 
	plan_id = 2 
	AND next_step = 1
	AND start_date BETWEEN '2020-01-01' AND '2020-12-31';
```
| total_clientes |
|----------------|
| 0              |

---

## 💳 C.Challenge Payment Question (Dynamic Billing Engine)
This query builds a full ledger simulation for the year 2020 by expanding recurring payments month-by-month and factoring in prorated upgrade logic.

```sql
WITH fechas_plan AS (
	SELECT
		customer_id,
		plan_id,
		start_date,
		COALESCE(LEAD(start_date) OVER( PARTITION BY customer_id ORDER BY start_date),'2020-12-31') AS fin_plan,
		LEAD(plan_id) OVER(PARTITION BY customer_id ORDER BY start_date)
	FROM foodie_fi.subscriptions
	WHERE start_date <= '2020-12-31'
),
plan_por_mes AS (
	SELECT
		customer_id,
		plan_id,
		GENERATE_SERIES(start_date,fin_plan - INTERVAL '1 day','1 month')::DATE AS payment_date
	FROM fechas_plan
	WHERE plan_id NOT IN (0,4)
),
historial AS (
SELECT
	pm.customer_id,
	pm.plan_id,
	p.plan_name,
	p.price,
	pm.payment_date,
	LAG(pm.plan_id) OVER(PARTITION BY pm.customer_id ORDER BY pm.payment_date) AS plan_anterior,
	LAG(pm.payment_date)OVER(PARTITION BY pm.customer_id ORDER BY pm.payment_date) AS fecha_pago_anterior
FROM plan_por_mes AS pm
INNER JOIN foodie_fi.plans AS p
	ON pm.plan_id = p.plan_id
)
SELECT
	customer_id,
	plan_id,
	plan_name,
	CASE
		WHEN plan_id IN (2,3) AND plan_anterior = 1
		AND (payment_date - fecha_pago_anterior) < 30
		THEN price - 9.90
		ELSE price
	END AS amount,
	payment_date,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY payment_date)
FROM historial;

```
| customer_id | plan_id | plan_name     | amount | payment_date | row_number |
|-------------|---------|---------------|--------|--------------|------------|
| 1           | 1       | basic monthly | 9.90   | 2020-08-08   | 1          |
| 1           | 1       | basic monthly | 9.90   | 2020-09-08   | 2          |
| 1           | 1       | basic monthly | 9.90   | 2020-10-08   | 3          |
| 1           | 1       | basic monthly | 9.90   | 2020-11-08   | 4          |
| 1           | 1       | basic monthly | 9.90   | 2020-12-08   | 5          |
| 2           | 3       | pro annual    | 199.00 | 2020-09-27   | 1          |
| 2           | 3       | pro annual    | 199.00 | 2020-10-27   | 2          |
| 2           | 3       | pro annual    | 199.00 | 2020-11-27   | 3          |
| 2           | 3       | pro annual    | 199.00 | 2020-12-27   | 4          |
| 3           | 1       | basic monthly | 9.90   | 2020-01-20   | 1          |
| 3           | 1       | basic monthly | 9.90   | 2020-02-20   | 2          |
| 3           | 1       | basic monthly | 9.90   | 2020-03-20   | 3          |
| 3           | 1       | basic monthly | 9.90   | 2020-04-20   | 4          |
| 3           | 1       | basic monthly | 9.90   | 2020-05-20   | 5          |
| 3           | 1       | basic monthly | 9.90   | 2020-06-20   | 6          |
| 3           | 1       | basic monthly | 9.90   | 2020-07-20   | 7          |
| 3           | 1       | basic monthly | 9.90   | 2020-08-20   | 8          |
| 3           | 1       | basic monthly | 9.90   | 2020-09-20   | 9          |
| 3           | 1       | basic monthly | 9.90   | 2020-10-20   | 10         |
| 3           | 1       | basic monthly | 9.90   | 2020-11-20   | 11         |
| 3           | 1       | basic monthly | 9.90   | 2020-12-20   | 12         |
| 4           | 1       | basic monthly | 9.90   | 2020-01-24   | 1          |
| 4           | 1       | basic monthly | 9.90   | 2020-02-24   | 2          |
| 4           | 1       | basic monthly | 9.90   | 2020-03-24   | 3          |
| 5           | 1       | basic monthly | 9.90   | 2020-08-10   | 1          |
| 5           | 1       | basic monthly | 9.90   | 2020-09-10   | 2          |
| 5           | 1       | basic monthly | 9.90   | 2020-10-10   | 3          |
| 5           | 1       | basic monthly | 9.90   | 2020-11-10   | 4          |
| 5           | 1       | basic monthly | 9.90   | 2020-12-10   | 5          |
| 6           | 1       | basic monthly | 9.90   | 2020-12-30   | 1          |
| 7           | 1       | basic monthly | 9.90   | 2020-02-12   | 1          |
| 7           | 1       | basic monthly | 9.90   | 2020-03-12   | 2          |
| 7           | 1       | basic monthly | 9.90   | 2020-04-12   | 3          |
| 7           | 1       | basic monthly | 9.90   | 2020-05-12   | 4          |
| 7           | 2       | pro monthly   | 10.00  | 2020-05-22   | 5          |
| 7           | 2       | pro monthly   | 19.90  | 2020-06-22   | 6          |
| 7           | 2       | pro monthly   | 19.90  | 2020-07-22   | 7          |
| 7           | 2       | pro monthly   | 19.90  | 2020-08-22   | 8          |
| 7           | 2       | pro monthly   | 19.90  | 2020-09-22   | 9          |
| 7           | 2       | pro monthly   | 19.90  | 2020-10-22   | 10         |
| 7           | 2       | pro monthly   | 19.90  | 2020-11-22   | 11         |
| 7           | 2       | pro monthly   | 19.90  | 2020-12-22   | 12         |
| 8           | 1       | basic monthly | 9.90   | 2020-06-18   | 1          |
| 8           | 1       | basic monthly | 9.90   | 2020-07-18   | 2          |
| 8           | 2       | pro monthly   | 10.00  | 2020-08-03   | 3          |
| 8           | 2       | pro monthly   | 19.90  | 2020-09-03   | 4          |
| 8           | 2       | pro monthly   | 19.90  | 2020-10-03   | 5          |
| 8           | 2       | pro monthly   | 19.90  | 2020-11-03   | 6          |
| 8           | 2       | pro monthly   | 19.90  | 2020-12-03   | 7          |
| 9           | 3       | pro annual    | 199.00 | 2020-12-14   | 1          |
| 10          | 2       | pro monthly   | 19.90  | 2020-09-26   | 1          |
| 10          | 2       | pro monthly   | 19.90  | 2020-10-26   | 2          |
| 10          | 2       | pro monthly   | 19.90  | 2020-11-26   | 3          |
| 10          | 2       | pro monthly   | 19.90  | 2020-12-26   | 4          |
| 12          | 1       | basic monthly | 9.90   | 2020-09-29   | 1          |
| 12          | 1       | basic monthly | 9.90   | 2020-10-29   | 2          |
| 12          | 1       | basic monthly | 9.90   | 2020-11-29   | 3          |
| 12          | 1       | basic monthly | 9.90   | 2020-12-29   | 4          |
| 13          | 1       | basic monthly | 9.90   | 2020-12-22   | 1          |
| 14          | 1       | basic monthly | 9.90   | 2020-09-29   | 1          |
| 14          | 1       | basic monthly | 9.90   | 2020-10-29   | 2          |
| 14          | 1       | basic monthly | 9.90   | 2020-11-29   | 3          |
| 14          | 1       | basic monthly | 9.90   | 2020-12-29   | 4          |
| 15          | 2       | pro monthly   | 19.90  | 2020-03-24   | 1          |
| 15          | 2       | pro monthly   | 19.90  | 2020-04-24   | 2          |
| 16          | 1       | basic monthly | 9.90   | 2020-06-07   | 1          |
| 16          | 1       | basic monthly | 9.90   | 2020-07-07   | 2          |
| 16          | 1       | basic monthly | 9.90   | 2020-08-07   | 3          |
| 16          | 1       | basic monthly | 9.90   | 2020-09-07   | 4          |
| 16          | 1       | basic monthly | 9.90   | 2020-10-07   | 5          |
| 16          | 3       | pro annual    | 189.10 | 2020-10-21   | 6          |
| 16          | 3       | pro annual    | 199.00 | 2020-11-21   | 7          |
| 16          | 3       | pro annual    | 199.00 | 2020-12-21   | 8          |
| 17          | 1       | basic monthly | 9.90   | 2020-08-03   | 1          |
| 17          | 1       | basic monthly | 9.90   | 2020-09-03   | 2          |
| 17          | 1       | basic monthly | 9.90   | 2020-10-03   | 3          |
| 17          | 1       | basic monthly | 9.90   | 2020-11-03   | 4          |
| 17          | 1       | basic monthly | 9.90   | 2020-12-03   | 5          |
| 17          | 3       | pro annual    | 189.10 | 2020-12-11   | 6          |
| 18          | 2       | pro monthly   | 19.90  | 2020-07-13   | 1          |
| 18          | 2       | pro monthly   | 19.90  | 2020-08-13   | 2          |
| 18          | 2       | pro monthly   | 19.90  | 2020-09-13   | 3          |
| 18          | 2       | pro monthly   | 19.90  | 2020-10-13   | 4          |
| 18          | 2       | pro monthly   | 19.90  | 2020-11-13   | 5          |
| 18          | 2       | pro monthly   | 19.90  | 2020-12-13   | 6          |
| 19          | 2       | pro monthly   | 19.90  | 2020-06-29   | 1          |
| 19          | 2       | pro monthly   | 19.90  | 2020-07-29   | 2          |
| 19          | 3       | pro annual    | 199.00 | 2020-08-29   | 3          |
| 19          | 3       | pro annual    | 199.00 | 2020-09-29   | 4          |
| 19          | 3       | pro annual    | 199.00 | 2020-10-29   | 5          |
| 19          | 3       | pro annual    | 199.00 | 2020-11-29   | 6          |
| 19          | 3       | pro annual    | 199.00 | 2020-12-29   | 7          |
| 20          | 1       | basic monthly | 9.90   | 2020-04-15   | 1          |
| 20          | 1       | basic monthly | 9.90   | 2020-05-15   | 2          |
| 20          | 3       | pro annual    | 189.10 | 2020-06-05   | 3          |
| 20          | 3       | pro annual    | 199.00 | 2020-07-05   | 4          |
| 20          | 3       | pro annual    | 199.00 | 2020-08-05   | 5          |
| 20          | 3       | pro annual    | 199.00 | 2020-09-05   | 6          |
| 20          | 3       | pro annual    | 199.00 | 2020-10-05   | 7          |
| 20          | 3       | pro annual    | 199.00 | 2020-11-05   | 8          |
| 20          | 3       | pro annual    | 199.00 | 2020-12-05   | 9          |
| 21          | 1       | basic monthly | 9.90   | 2020-02-11   | 1          |
| 21          | 1       | basic monthly | 9.90   | 2020-03-11   | 2          |
| 21          | 1       | basic monthly | 9.90   | 2020-04-11   | 3          |
| 21          | 1       | basic monthly | 9.90   | 2020-05-11   | 4          |
| 21          | 2       | pro monthly   | 10.00  | 2020-06-03   | 5          |
| 21          | 2       | pro monthly   | 19.90  | 2020-07-03   | 6          |
| 21          | 2       | pro monthly   | 19.90  | 2020-08-03   | 7          |
| 21          | 2       | pro monthly   | 19.90  | 2020-09-03   | 8          |
| 22          | 2       | pro monthly   | 19.90  | 2020-01-17   | 1          |
| 22          | 2       | pro monthly   | 19.90  | 2020-02-17   | 2          |
| 22          | 2       | pro monthly   | 19.90  | 2020-03-17   | 3          |
| 22          | 2       | pro monthly   | 19.90  | 2020-04-17   | 4          |
| 22          | 2       | pro monthly   | 19.90  | 2020-05-17   | 5          |
| 22          | 2       | pro monthly   | 19.90  | 2020-06-17   | 6          |
| 22          | 2       | pro monthly   | 19.90  | 2020-07-17   | 7          |
| 22          | 2       | pro monthly   | 19.90  | 2020-08-17   | 8          |
| 22          | 2       | pro monthly   | 19.90  | 2020-09-17   | 9          |
| 22          | 2       | pro monthly   | 19.90  | 2020-10-17   | 10         |
| 22          | 2       | pro monthly   | 19.90  | 2020-11-17   | 11         |
| 22          | 2       | pro monthly   | 19.90  | 2020-12-17   | 12         |
| 23          | 3       | pro annual    | 199.00 | 2020-05-20   | 1          |
| 23          | 3       | pro annual    | 199.00 | 2020-06-20   | 2          |
| 23          | 3       | pro annual    | 199.00 | 2020-07-20   | 3          |
| 23          | 3       | pro annual    | 199.00 | 2020-08-20   | 4          |
| 23          | 3       | pro annual    | 199.00 | 2020-09-20   | 5          |
| 23          | 3       | pro annual    | 199.00 | 2020-10-20   | 6          |
| 23          | 3       | pro annual    | 199.00 | 2020-11-20   | 7          |
| 23          | 3       | pro annual    | 199.00 | 2020-12-20   | 8          |
| 24          | 2       | pro monthly   | 19.90  | 2020-11-17   | 1          |
| 24          | 2       | pro monthly   | 19.90  | 2020-12-17   | 2          |
| 25          | 1       | basic monthly | 9.90   | 2020-05-17   | 1          |
| 25          | 2       | pro monthly   | 19.90  | 2020-06-16   | 2          |
| 25          | 2       | pro monthly   | 19.90  | 2020-07-16   | 3          |
| 25          | 2       | pro monthly   | 19.90  | 2020-08-16   | 4          |
| 25          | 2       | pro monthly   | 19.90  | 2020-09-16   | 5          |
| 25          | 2       | pro monthly   | 19.90  | 2020-10-16   | 6          |
| 25          | 2       | pro monthly   | 19.90  | 2020-11-16   | 7          |
| 25          | 2       | pro monthly   | 19.90  | 2020-12-16   | 8          |
| 26          | 2       | pro monthly   | 19.90  | 2020-12-15   | 1          |
| 27          | 2       | pro monthly   | 19.90  | 2020-08-31   | 1          |
| 27          | 2       | pro monthly   | 19.90  | 2020-09-30   | 2          |
| 27          | 2       | pro monthly   | 19.90  | 2020-10-30   | 3          |
| 27          | 2       | pro monthly   | 19.90  | 2020-11-30   | 4          |
| 27          | 2       | pro monthly   | 19.90  | 2020-12-30   | 5          |
| 28          | 3       | pro annual    | 199.00 | 2020-07-07   | 1          |
| 28          | 3       | pro annual    | 199.00 | 2020-08-07   | 2          |
| 28          | 3       | pro annual    | 199.00 | 2020-09-07   | 3          |
| 28          | 3       | pro annual    | 199.00 | 2020-10-07   | 4          |
| 28          | 3       | pro annual    | 199.00 | 2020-11-07   | 5          |
| 28          | 3       | pro annual    | 199.00 | 2020-12-07   | 6          |
| 29          | 2       | pro monthly   | 19.90  | 2020-01-30   | 1          |
| 29          | 2       | pro monthly   | 19.90  | 2020-02-29   | 2          |
| 29          | 2       | pro monthly   | 19.90  | 2020-03-29   | 3          |
| 29          | 2       | pro monthly   | 19.90  | 2020-04-29   | 4          |
| 29          | 2       | pro monthly   | 19.90  | 2020-05-29   | 5          |
| 29          | 2       | pro monthly   | 19.90  | 2020-06-29   | 6          |
| 29          | 2       | pro monthly   | 19.90  | 2020-07-29   | 7          |
| 29          | 2       | pro monthly   | 19.90  | 2020-08-29   | 8          |
| 29          | 2       | pro monthly   | 19.90  | 2020-09-29   | 9          |
| 29          | 2       | pro monthly   | 19.90  | 2020-10-29   | 10         |
| 29          | 2       | pro monthly   | 19.90  | 2020-11-29   | 11         |
| 29          | 2       | pro monthly   | 19.90  | 2020-12-29   | 12         |
| 30          | 1       | basic monthly | 9.90   | 2020-05-06   | 1          |
| 30          | 1       | basic monthly | 9.90   | 2020-06-06   | 2          |
| 30          | 1       | basic monthly | 9.90   | 2020-07-06   | 3          |
| 30          | 1       | basic monthly | 9.90   | 2020-08-06   | 4          |
| 30          | 1       | basic monthly | 9.90   | 2020-09-06   | 5          |
| 30          | 1       | basic monthly | 9.90   | 2020-10-06   | 6          |
| 30          | 1       | basic monthly | 9.90   | 2020-11-06   | 7          |
| 30          | 1       | basic monthly | 9.90   | 2020-12-06   | 8          |
| 31          | 2       | pro monthly   | 19.90  | 2020-06-29   | 1          |
| 31          | 2       | pro monthly   | 19.90  | 2020-07-29   | 2          |
| 31          | 2       | pro monthly   | 19.90  | 2020-08-29   | 3          |
| 31          | 2       | pro monthly   | 19.90  | 2020-09-29   | 4          |
| 31          | 2       | pro monthly   | 19.90  | 2020-10-29   | 5          |
| 31          | 3       | pro annual    | 199.00 | 2020-11-29   | 6          |
| 31          | 3       | pro annual    | 199.00 | 2020-12-29   | 7          |
| 32          | 1       | basic monthly | 9.90   | 2020-06-19   | 1          |
| 32          | 2       | pro monthly   | 10.00  | 2020-07-18   | 2          |
| 32          | 2       | pro monthly   | 19.90  | 2020-08-18   | 3          |
| 32          | 2       | pro monthly   | 19.90  | 2020-09-18   | 4          |
| 32          | 2       | pro monthly   | 19.90  | 2020-10-18   | 5          |
| 32          | 2       | pro monthly   | 19.90  | 2020-11-18   | 6          |
| 32          | 2       | pro monthly   | 19.90  | 2020-12-18   | 7          |
| 33          | 2       | pro monthly   | 19.90  | 2020-09-10   | 1          |
| 33          | 2       | pro monthly   | 19.90  | 2020-10-10   | 2          |
| 33          | 2       | pro monthly   | 19.90  | 2020-11-10   | 3          |
| 33          | 2       | pro monthly   | 19.90  | 2020-12-10   | 4          |
| 34          | 1       | basic monthly | 9.90   | 2020-12-27   | 1          |
| 35          | 2       | pro monthly   | 19.90  | 2020-09-10   | 1          |
| 35          | 2       | pro monthly   | 19.90  | 2020-10-10   | 2          |
| 35          | 2       | pro monthly   | 19.90  | 2020-11-10   | 3          |
| 35          | 2       | pro monthly   | 19.90  | 2020-12-10   | 4          |
| 36          | 2       | pro monthly   | 19.90  | 2020-03-03   | 1          |
| 36          | 2       | pro monthly   | 19.90  | 2020-04-03   | 2          |
| 36          | 2       | pro monthly   | 19.90  | 2020-05-03   | 3          |
| 36          | 2       | pro monthly   | 19.90  | 2020-06-03   | 4          |
| 36          | 2       | pro monthly   | 19.90  | 2020-07-03   | 5          |
| 36          | 2       | pro monthly   | 19.90  | 2020-08-03   | 6          |
| 36          | 2       | pro monthly   | 19.90  | 2020-09-03   | 7          |
| 36          | 2       | pro monthly   | 19.90  | 2020-10-03   | 8          |
| 36          | 2       | pro monthly   | 19.90  | 2020-11-03   | 9          |
| 36          | 2       | pro monthly   | 19.90  | 2020-12-03   | 10         |
| 37          | 1       | basic monthly | 9.90   | 2020-08-12   | 1          |
| 37          | 1       | basic monthly | 9.90   | 2020-09-12   | 2          |
| 37          | 1       | basic monthly | 9.90   | 2020-10-12   | 3          |
| 37          | 2       | pro monthly   | 19.90  | 2020-11-11   | 4          |
| 37          | 2       | pro monthly   | 19.90  | 2020-12-11   | 5          |
| 38          | 2       | pro monthly   | 19.90  | 2020-10-09   | 1          |
| 38          | 3       | pro annual    | 199.00 | 2020-11-09   | 2          |
| 38          | 3       | pro annual    | 199.00 | 2020-12-09   | 3          |
| 39          | 1       | basic monthly | 9.90   | 2020-06-04   | 1          |
| 39          | 1       | basic monthly | 9.90   | 2020-07-04   | 2          |
| 39          | 1       | basic monthly | 9.90   | 2020-08-04   | 3          |
| 39          | 2       | pro monthly   | 10.00  | 2020-08-25   | 4          |
| 40          | 1       | basic monthly | 9.90   | 2020-01-29   | 1          |
| 40          | 1       | basic monthly | 9.90   | 2020-02-29   | 2          |
| 40          | 2       | pro monthly   | 10.00  | 2020-03-25   | 3          |
| 40          | 2       | pro monthly   | 19.90  | 2020-04-25   | 4          |
| 40          | 2       | pro monthly   | 19.90  | 2020-05-25   | 5          |
| 40          | 2       | pro monthly   | 19.90  | 2020-06-25   | 6          |
| 40          | 2       | pro monthly   | 19.90  | 2020-07-25   | 7          |
| 40          | 2       | pro monthly   | 19.90  | 2020-08-25   | 8          |
| 40          | 2       | pro monthly   | 19.90  | 2020-09-25   | 9          |
| 40          | 2       | pro monthly   | 19.90  | 2020-10-25   | 10         |
| 40          | 2       | pro monthly   | 19.90  | 2020-11-25   | 11         |
| 40          | 2       | pro monthly   | 19.90  | 2020-12-25   | 12         |
| 41          | 2       | pro monthly   | 19.90  | 2020-05-23   | 1          |
| 41          | 2       | pro monthly   | 19.90  | 2020-06-23   | 2          |
| 41          | 2       | pro monthly   | 19.90  | 2020-07-23   | 3          |
| 41          | 2       | pro monthly   | 19.90  | 2020-08-23   | 4          |
| 41          | 2       | pro monthly   | 19.90  | 2020-09-23   | 5          |
| 41          | 2       | pro monthly   | 19.90  | 2020-10-23   | 6          |
| 41          | 2       | pro monthly   | 19.90  | 2020-11-23   | 7          |
| 41          | 2       | pro monthly   | 19.90  | 2020-12-23   | 8          |
| 42          | 1       | basic monthly | 9.90   | 2020-11-03   | 1          |
| 42          | 1       | basic monthly | 9.90   | 2020-12-03   | 2          |
| 43          | 1       | basic monthly | 9.90   | 2020-08-20   | 1          |
| 43          | 1       | basic monthly | 9.90   | 2020-09-20   | 2          |
| 43          | 1       | basic monthly | 9.90   | 2020-10-20   | 3          |
| 43          | 1       | basic monthly | 9.90   | 2020-11-20   | 4          |
| 43          | 2       | pro monthly   | 10.00  | 2020-12-18   | 5          |
| 44          | 3       | pro annual    | 199.00 | 2020-03-24   | 1          |
| 44          | 3       | pro annual    | 199.00 | 2020-04-24   | 2          |
| 44          | 3       | pro annual    | 199.00 | 2020-05-24   | 3          |
| 44          | 3       | pro annual    | 199.00 | 2020-06-24   | 4          |
| 44          | 3       | pro annual    | 199.00 | 2020-07-24   | 5          |
| 44          | 3       | pro annual    | 199.00 | 2020-08-24   | 6          |
| 44          | 3       | pro annual    | 199.00 | 2020-09-24   | 7          |
| 44          | 3       | pro annual    | 199.00 | 2020-10-24   | 8          |
| 44          | 3       | pro annual    | 199.00 | 2020-11-24   | 9          |
| 44          | 3       | pro annual    | 199.00 | 2020-12-24   | 10         |
| 45          | 1       | basic monthly | 9.90   | 2020-02-18   | 1          |
| 45          | 1       | basic monthly | 9.90   | 2020-03-18   | 2          |
| 45          | 1       | basic monthly | 9.90   | 2020-04-18   | 3          |
| 45          | 1       | basic monthly | 9.90   | 2020-05-18   | 4          |
| 45          | 1       | basic monthly | 9.90   | 2020-06-18   | 5          |
| 45          | 1       | basic monthly | 9.90   | 2020-07-18   | 6          |
| 45          | 2       | pro monthly   | 10.00  | 2020-08-12   | 7          |
| 45          | 2       | pro monthly   | 19.90  | 2020-09-12   | 8          |
| 45          | 2       | pro monthly   | 19.90  | 2020-10-12   | 9          |
| 45          | 2       | pro monthly   | 19.90  | 2020-11-12   | 10         |
| 45          | 2       | pro monthly   | 19.90  | 2020-12-12   | 11         |
| 46          | 1       | basic monthly | 9.90   | 2020-04-26   | 1          |
| 46          | 1       | basic monthly | 9.90   | 2020-05-26   | 2          |
| 46          | 1       | basic monthly | 9.90   | 2020-06-26   | 3          |
| 46          | 2       | pro monthly   | 10.00  | 2020-07-06   | 4          |
| 46          | 3       | pro annual    | 199.00 | 2020-08-06   | 5          |
| 46          | 3       | pro annual    | 199.00 | 2020-09-06   | 6          |
| 46          | 3       | pro annual    | 199.00 | 2020-10-06   | 7          |
| 46          | 3       | pro annual    | 199.00 | 2020-11-06   | 8          |
| 46          | 3       | pro annual    | 199.00 | 2020-12-06   | 9          |
| 47          | 1       | basic monthly | 9.90   | 2020-06-13   | 1          |
| 47          | 1       | basic monthly | 9.90   | 2020-07-13   | 2          |
| 47          | 1       | basic monthly | 9.90   | 2020-08-13   | 3          |
| 47          | 1       | basic monthly | 9.90   | 2020-09-13   | 4          |
| 47          | 1       | basic monthly | 9.90   | 2020-10-13   | 5          |
| 47          | 3       | pro annual    | 189.10 | 2020-10-26   | 6          |
| 47          | 3       | pro annual    | 199.00 | 2020-11-26   | 7          |
| 47          | 3       | pro annual    | 199.00 | 2020-12-26   | 8          |
| 48          | 1       | basic monthly | 9.90   | 2020-01-18   | 1          |
| 48          | 1       | basic monthly | 9.90   | 2020-02-18   | 2          |
| 48          | 1       | basic monthly | 9.90   | 2020-03-18   | 3          |
| 48          | 1       | basic monthly | 9.90   | 2020-04-18   | 4          |
| 48          | 1       | basic monthly | 9.90   | 2020-05-18   | 5          |
| 49          | 2       | pro monthly   | 19.90  | 2020-05-01   | 1          |
| 49          | 2       | pro monthly   | 19.90  | 2020-06-01   | 2          |
| 49          | 2       | pro monthly   | 19.90  | 2020-07-01   | 3          |
| 49          | 3       | pro annual    | 199.00 | 2020-08-01   | 4          |
| 49          | 3       | pro annual    | 199.00 | 2020-09-01   | 5          |
| 49          | 3       | pro annual    | 199.00 | 2020-10-01   | 6          |
| 49          | 3       | pro annual    | 199.00 | 2020-11-01   | 7          |
| 49          | 3       | pro annual    | 199.00 | 2020-12-01   | 8          |
| 50          | 2       | pro monthly   | 19.90  | 2020-07-28   | 1          |
| 50          | 2       | pro monthly   | 19.90  | 2020-08-28   | 2          |
| 50          | 2       | pro monthly   | 19.90  | 2020-09-28   | 3          |
| 50          | 2       | pro monthly   | 19.90  | 2020-10-28   | 4          |
| 50          | 2       | pro monthly   | 19.90  | 2020-11-28   | 5          |
| 50          | 2       | pro monthly   | 19.90  | 2020-12-28   | 6          |
| 51          | 1       | basic monthly | 9.90   | 2020-01-26   | 1          |
| 51          | 1       | basic monthly | 9.90   | 2020-02-26   | 2          |
| 51          | 3       | pro annual    | 189.10 | 2020-03-09   | 3          |
| 51          | 3       | pro annual    | 199.00 | 2020-04-09   | 4          |
| 51          | 3       | pro annual    | 199.00 | 2020-05-09   | 5          |
| 51          | 3       | pro annual    | 199.00 | 2020-06-09   | 6          |
| 51          | 3       | pro annual    | 199.00 | 2020-07-09   | 7          |
| 51          | 3       | pro annual    | 199.00 | 2020-08-09   | 8          |
| 51          | 3       | pro annual    | 199.00 | 2020-09-09   | 9          |
| 51          | 3       | pro annual    | 199.00 | 2020-10-09   | 10         |
| 51          | 3       | pro annual    | 199.00 | 2020-11-09   | 11         |
| 51          | 3       | pro annual    | 199.00 | 2020-12-09   | 12         |
| 52          | 1       | basic monthly | 9.90   | 2020-06-07   | 1          |
| 53          | 1       | basic monthly | 9.90   | 2020-01-25   | 1          |
| 53          | 1       | basic monthly | 9.90   | 2020-02-25   | 2          |
| 53          | 1       | basic monthly | 9.90   | 2020-03-25   | 3          |
| 53          | 1       | basic monthly | 9.90   | 2020-04-25   | 4          |
| 53          | 1       | basic monthly | 9.90   | 2020-05-25   | 5          |
| 53          | 1       | basic monthly | 9.90   | 2020-06-25   | 6          |
| 53          | 1       | basic monthly | 9.90   | 2020-07-25   | 7          |
| 53          | 1       | basic monthly | 9.90   | 2020-08-25   | 8          |
| 53          | 1       | basic monthly | 9.90   | 2020-09-25   | 9          |
| 53          | 1       | basic monthly | 9.90   | 2020-10-25   | 10         |
| 53          | 1       | basic monthly | 9.90   | 2020-11-25   | 11         |
| 53          | 1       | basic monthly | 9.90   | 2020-12-25   | 12         |
| 54          | 2       | pro monthly   | 19.90  | 2020-05-30   | 1          |
| 54          | 2       | pro monthly   | 19.90  | 2020-06-30   | 2          |
| 54          | 2       | pro monthly   | 19.90  | 2020-07-30   | 3          |
| 54          | 2       | pro monthly   | 19.90  | 2020-08-30   | 4          |
| 54          | 2       | pro monthly   | 19.90  | 2020-09-30   | 5          |
| 54          | 2       | pro monthly   | 19.90  | 2020-10-30   | 6          |
| 54          | 2       | pro monthly   | 19.90  | 2020-11-30   | 7          |
| 54          | 2       | pro monthly   | 19.90  | 2020-12-30   | 8          |
| 55          | 1       | basic monthly | 9.90   | 2020-10-29   | 1          |
| 55          | 1       | basic monthly | 9.90   | 2020-11-29   | 2          |
| 55          | 1       | basic monthly | 9.90   | 2020-12-29   | 3          |
| 56          | 3       | pro annual    | 199.00 | 2020-01-10   | 1          |
| 56          | 3       | pro annual    | 199.00 | 2020-02-10   | 2          |
| 56          | 3       | pro annual    | 199.00 | 2020-03-10   | 3          |
| 56          | 3       | pro annual    | 199.00 | 2020-04-10   | 4          |
| 56          | 3       | pro annual    | 199.00 | 2020-05-10   | 5          |
| 56          | 3       | pro annual    | 199.00 | 2020-06-10   | 6          |
| 56          | 3       | pro annual    | 199.00 | 2020-07-10   | 7          |
| 56          | 3       | pro annual    | 199.00 | 2020-08-10   | 8          |
| 56          | 3       | pro annual    | 199.00 | 2020-09-10   | 9          |
| 56          | 3       | pro annual    | 199.00 | 2020-10-10   | 10         |
| 56          | 3       | pro annual    | 199.00 | 2020-11-10   | 11         |
| 56          | 3       | pro annual    | 199.00 | 2020-12-10   | 12         |
| 57          | 2       | pro monthly   | 19.90  | 2020-03-10   | 1          |
| 57          | 2       | pro monthly   | 19.90  | 2020-04-10   | 2          |
| 57          | 2       | pro monthly   | 19.90  | 2020-05-10   | 3          |
| 57          | 2       | pro monthly   | 19.90  | 2020-06-10   | 4          |
| 57          | 2       | pro monthly   | 19.90  | 2020-07-10   | 5          |
| 57          | 2       | pro monthly   | 19.90  | 2020-08-10   | 6          |
| 57          | 2       | pro monthly   | 19.90  | 2020-09-10   | 7          |
| 57          | 2       | pro monthly   | 19.90  | 2020-10-10   | 8          |
| 57          | 2       | pro monthly   | 19.90  | 2020-11-10   | 9          |
| 57          | 2       | pro monthly   | 19.90  | 2020-12-10   | 10         |
| 58          | 1       | basic monthly | 9.90   | 2020-07-11   | 1          |
| 58          | 1       | basic monthly | 9.90   | 2020-08-11   | 2          |
| 58          | 1       | basic monthly | 9.90   | 2020-09-11   | 3          |
| 58          | 3       | pro annual    | 189.10 | 2020-09-24   | 4          |
| 58          | 3       | pro annual    | 199.00 | 2020-10-24   | 5          |
| 58          | 3       | pro annual    | 199.00 | 2020-11-24   | 6          |
| 58          | 3       | pro annual    | 199.00 | 2020-12-24   | 7          |
| 59          | 1       | basic monthly | 9.90   | 2020-11-06   | 1          |
| 59          | 1       | basic monthly | 9.90   | 2020-12-06   | 2          |
| 60          | 1       | basic monthly | 9.90   | 2020-06-24   | 1          |
| 60          | 1       | basic monthly | 9.90   | 2020-07-24   | 2          |
| 60          | 1       | basic monthly | 9.90   | 2020-08-24   | 3          |
| 60          | 1       | basic monthly | 9.90   | 2020-09-24   | 4          |
| 60          | 1       | basic monthly | 9.90   | 2020-10-24   | 5          |
| 60          | 1       | basic monthly | 9.90   | 2020-11-24   | 6          |
| 60          | 1       | basic monthly | 9.90   | 2020-12-24   | 7          |
| 61          | 1       | basic monthly | 9.90   | 2020-09-07   | 1          |
| 61          | 1       | basic monthly | 9.90   | 2020-10-07   | 2          |
| 61          | 1       | basic monthly | 9.90   | 2020-11-07   | 3          |
| 61          | 1       | basic monthly | 9.90   | 2020-12-07   | 4          |
| 62          | 1       | basic monthly | 9.90   | 2020-10-19   | 1          |
| 62          | 1       | basic monthly | 9.90   | 2020-11-19   | 2          |
| 62          | 1       | basic monthly | 9.90   | 2020-12-19   | 3          |
| 63          | 1       | basic monthly | 9.90   | 2020-06-04   | 1          |
| 64          | 1       | basic monthly | 9.90   | 2020-03-15   | 1          |
| 64          | 2       | pro monthly   | 10.00  | 2020-04-03   | 2          |
| 65          | 1       | basic monthly | 9.90   | 2020-05-19   | 1          |
| 65          | 1       | basic monthly | 9.90   | 2020-06-19   | 2          |
| 65          | 1       | basic monthly | 9.90   | 2020-07-19   | 3          |
| 65          | 1       | basic monthly | 9.90   | 2020-08-19   | 4          |
| 65          | 1       | basic monthly | 9.90   | 2020-09-19   | 5          |
| 65          | 2       | pro monthly   | 10.00  | 2020-10-09   | 6          |
| 65          | 2       | pro monthly   | 19.90  | 2020-11-09   | 7          |
| 65          | 2       | pro monthly   | 19.90  | 2020-12-09   | 8          |
| 66          | 1       | basic monthly | 9.90   | 2020-08-06   | 1          |
| 66          | 1       | basic monthly | 9.90   | 2020-09-06   | 2          |
| 66          | 3       | pro annual    | 189.10 | 2020-10-04   | 3          |
| 66          | 3       | pro annual    | 199.00 | 2020-11-04   | 4          |
| 66          | 3       | pro annual    | 199.00 | 2020-12-04   | 5          |
| 67          | 2       | pro monthly   | 19.90  | 2020-08-21   | 1          |
| 67          | 2       | pro monthly   | 19.90  | 2020-09-21   | 2          |
| 67          | 2       | pro monthly   | 19.90  | 2020-10-21   | 3          |
| 67          | 2       | pro monthly   | 19.90  | 2020-11-21   | 4          |
| 67          | 2       | pro monthly   | 19.90  | 2020-12-21   | 5          |
| 68          | 3       | pro annual    | 199.00 | 2020-04-17   | 1          |
| 68          | 3       | pro annual    | 199.00 | 2020-05-17   | 2          |
| 68          | 3       | pro annual    | 199.00 | 2020-06-17   | 3          |
| 68          | 3       | pro annual    | 199.00 | 2020-07-17   | 4          |
| 68          | 3       | pro annual    | 199.00 | 2020-08-17   | 5          |
| 68          | 3       | pro annual    | 199.00 | 2020-09-17   | 6          |
| 68          | 3       | pro annual    | 199.00 | 2020-10-17   | 7          |
| 68          | 3       | pro annual    | 199.00 | 2020-11-17   | 8          |
| 68          | 3       | pro annual    | 199.00 | 2020-12-17   | 9          |
| 69          | 1       | basic monthly | 9.90   | 2020-03-14   | 1          |
| 69          | 2       | pro monthly   | 19.90  | 2020-04-14   | 2          |
| 69          | 2       | pro monthly   | 19.90  | 2020-05-14   | 3          |
| 69          | 2       | pro monthly   | 19.90  | 2020-06-14   | 4          |
| 69          | 2       | pro monthly   | 19.90  | 2020-07-14   | 5          |
| 69          | 2       | pro monthly   | 19.90  | 2020-08-14   | 6          |
| 69          | 2       | pro monthly   | 19.90  | 2020-09-14   | 7          |
| 69          | 2       | pro monthly   | 19.90  | 2020-10-14   | 8          |
| 69          | 2       | pro monthly   | 19.90  | 2020-11-14   | 9          |
| 69          | 2       | pro monthly   | 19.90  | 2020-12-14   | 10         |
| 70          | 1       | basic monthly | 9.90   | 2020-07-13   | 1          |
| 70          | 1       | basic monthly | 9.90   | 2020-08-13   | 2          |
| 70          | 1       | basic monthly | 9.90   | 2020-09-13   | 3          |
| 70          | 1       | basic monthly | 9.90   | 2020-10-13   | 4          |
| 70          | 1       | basic monthly | 9.90   | 2020-11-13   | 5          |
| 70          | 1       | basic monthly | 9.90   | 2020-12-13   | 6          |
| 71          | 2       | pro monthly   | 19.90  | 2020-07-30   | 1          |
| 71          | 2       | pro monthly   | 19.90  | 2020-08-30   | 2          |
| 71          | 2       | pro monthly   | 19.90  | 2020-09-30   | 3          |
| 71          | 2       | pro monthly   | 19.90  | 2020-10-30   | 4          |
| 71          | 2       | pro monthly   | 19.90  | 2020-11-30   | 5          |
| 72          | 2       | pro monthly   | 19.90  | 2020-12-17   | 1          |
| 73          | 1       | basic monthly | 9.90   | 2020-03-31   | 1          |
| 73          | 1       | basic monthly | 9.90   | 2020-04-30   | 2          |
| 73          | 2       | pro monthly   | 10.00  | 2020-05-13   | 3          |
| 73          | 2       | pro monthly   | 19.90  | 2020-06-13   | 4          |
| 73          | 2       | pro monthly   | 19.90  | 2020-07-13   | 5          |
| 73          | 2       | pro monthly   | 19.90  | 2020-08-13   | 6          |
| 73          | 2       | pro monthly   | 19.90  | 2020-09-13   | 7          |
| 73          | 3       | pro annual    | 199.00 | 2020-10-13   | 8          |
| 73          | 3       | pro annual    | 199.00 | 2020-11-13   | 9          |
| 73          | 3       | pro annual    | 199.00 | 2020-12-13   | 10         |
| 74          | 1       | basic monthly | 9.90   | 2020-05-31   | 1          |
| 74          | 1       | basic monthly | 9.90   | 2020-06-30   | 2          |
| 74          | 1       | basic monthly | 9.90   | 2020-07-30   | 3          |
| 74          | 1       | basic monthly | 9.90   | 2020-08-30   | 4          |
| 74          | 1       | basic monthly | 9.90   | 2020-09-30   | 5          |
| 74          | 3       | pro annual    | 189.10 | 2020-10-01   | 6          |
| 74          | 3       | pro annual    | 199.00 | 2020-11-01   | 7          |
| 74          | 3       | pro annual    | 199.00 | 2020-12-01   | 8          |
| 75          | 1       | basic monthly | 9.90   | 2020-07-21   | 1          |
| 75          | 1       | basic monthly | 9.90   | 2020-08-21   | 2          |
| 75          | 1       | basic monthly | 9.90   | 2020-09-21   | 3          |
| 75          | 1       | basic monthly | 9.90   | 2020-10-21   | 4          |
| 75          | 2       | pro monthly   | 10.00  | 2020-11-19   | 5          |
| 75          | 2       | pro monthly   | 19.90  | 2020-12-19   | 6          |
| 76          | 3       | pro annual    | 199.00 | 2020-09-07   | 1          |
| 76          | 3       | pro annual    | 199.00 | 2020-10-07   | 2          |
| 76          | 3       | pro annual    | 199.00 | 2020-11-07   | 3          |
| 76          | 3       | pro annual    | 199.00 | 2020-12-07   | 4          |
| 77          | 2       | pro monthly   | 19.90  | 2020-04-25   | 1          |
| 77          | 2       | pro monthly   | 19.90  | 2020-05-25   | 2          |
| 77          | 2       | pro monthly   | 19.90  | 2020-06-25   | 3          |
| 77          | 2       | pro monthly   | 19.90  | 2020-07-25   | 4          |
| 77          | 2       | pro monthly   | 19.90  | 2020-08-25   | 5          |
| 77          | 2       | pro monthly   | 19.90  | 2020-09-25   | 6          |
| 77          | 3       | pro annual    | 199.00 | 2020-10-25   | 7          |
| 77          | 3       | pro annual    | 199.00 | 2020-11-25   | 8          |
| 77          | 3       | pro annual    | 199.00 | 2020-12-25   | 9          |
| 78          | 2       | pro monthly   | 19.90  | 2020-09-10   | 1          |
| 78          | 2       | pro monthly   | 19.90  | 2020-10-10   | 2          |
| 78          | 2       | pro monthly   | 19.90  | 2020-11-10   | 3          |
| 78          | 2       | pro monthly   | 19.90  | 2020-12-10   | 4          |
| 79          | 2       | pro monthly   | 19.90  | 2020-08-06   | 1          |
| 79          | 2       | pro monthly   | 19.90  | 2020-09-06   | 2          |
| 79          | 2       | pro monthly   | 19.90  | 2020-10-06   | 3          |
| 79          | 2       | pro monthly   | 19.90  | 2020-11-06   | 4          |
| 79          | 2       | pro monthly   | 19.90  | 2020-12-06   | 5          |
| 80          | 2       | pro monthly   | 19.90  | 2020-09-30   | 1          |
| 80          | 2       | pro monthly   | 19.90  | 2020-10-30   | 2          |
| 80          | 2       | pro monthly   | 19.90  | 2020-11-30   | 3          |
| 80          | 2       | pro monthly   | 19.90  | 2020-12-30   | 4          |
| 81          | 2       | pro monthly   | 19.90  | 2020-06-05   | 1          |
| 81          | 2       | pro monthly   | 19.90  | 2020-07-05   | 2          |
| 81          | 2       | pro monthly   | 19.90  | 2020-08-05   | 3          |
| 81          | 2       | pro monthly   | 19.90  | 2020-09-05   | 4          |
| 81          | 2       | pro monthly   | 19.90  | 2020-10-05   | 5          |
| 82          | 1       | basic monthly | 9.90   | 2020-05-09   | 1          |
| 82          | 1       | basic monthly | 9.90   | 2020-06-09   | 2          |
| 82          | 1       | basic monthly | 9.90   | 2020-07-09   | 3          |
| 82          | 1       | basic monthly | 9.90   | 2020-08-09   | 4          |
| 82          | 1       | basic monthly | 9.90   | 2020-09-09   | 5          |
| 82          | 1       | basic monthly | 9.90   | 2020-10-09   | 6          |
| 82          | 1       | basic monthly | 9.90   | 2020-11-09   | 7          |
| 82          | 1       | basic monthly | 9.90   | 2020-12-09   | 8          |
| 83          | 1       | basic monthly | 9.90   | 2020-05-25   | 1          |
| 83          | 1       | basic monthly | 9.90   | 2020-06-25   | 2          |
| 83          | 1       | basic monthly | 9.90   | 2020-07-25   | 3          |
| 83          | 1       | basic monthly | 9.90   | 2020-08-25   | 4          |
| 83          | 1       | basic monthly | 9.90   | 2020-09-25   | 5          |
| 83          | 1       | basic monthly | 9.90   | 2020-10-25   | 6          |
| 83          | 2       | pro monthly   | 10.00  | 2020-10-29   | 7          |
| 83          | 2       | pro monthly   | 19.90  | 2020-11-29   | 8          |
| 83          | 2       | pro monthly   | 19.90  | 2020-12-29   | 9          |
| 84          | 1       | basic monthly | 9.90   | 2020-06-21   | 1          |
| 85          | 1       | basic monthly | 9.90   | 2020-08-20   | 1          |
| 85          | 1       | basic monthly | 9.90   | 2020-09-20   | 2          |
| 85          | 1       | basic monthly | 9.90   | 2020-10-20   | 3          |
| 85          | 1       | basic monthly | 9.90   | 2020-11-20   | 4          |
| 85          | 1       | basic monthly | 9.90   | 2020-12-20   | 5          |
| 86          | 3       | pro annual    | 199.00 | 2020-07-17   | 1          |
| 86          | 3       | pro annual    | 199.00 | 2020-08-17   | 2          |
| 86          | 3       | pro annual    | 199.00 | 2020-09-17   | 3          |
| 86          | 3       | pro annual    | 199.00 | 2020-10-17   | 4          |
| 86          | 3       | pro annual    | 199.00 | 2020-11-17   | 5          |
| 86          | 3       | pro annual    | 199.00 | 2020-12-17   | 6          |
| 87          | 2       | pro monthly   | 19.90  | 2020-08-15   | 1          |
| 87          | 3       | pro annual    | 199.00 | 2020-09-15   | 2          |
| 87          | 3       | pro annual    | 199.00 | 2020-10-15   | 3          |
| 87          | 3       | pro annual    | 199.00 | 2020-11-15   | 4          |
| 87          | 3       | pro annual    | 199.00 | 2020-12-15   | 5          |
| 89          | 2       | pro monthly   | 19.90  | 2020-03-12   | 1          |
| 89          | 2       | pro monthly   | 19.90  | 2020-04-12   | 2          |
| 89          | 2       | pro monthly   | 19.90  | 2020-05-12   | 3          |
| 89          | 2       | pro monthly   | 19.90  | 2020-06-12   | 4          |
| 89          | 2       | pro monthly   | 19.90  | 2020-07-12   | 5          |
| 89          | 2       | pro monthly   | 19.90  | 2020-08-12   | 6          |
| 90          | 1       | basic monthly | 9.90   | 2020-12-02   | 1          |
| 91          | 2       | pro monthly   | 19.90  | 2020-09-15   | 1          |
| 91          | 2       | pro monthly   | 19.90  | 2020-10-15   | 2          |
| 91          | 2       | pro monthly   | 19.90  | 2020-11-15   | 3          |
| 91          | 2       | pro monthly   | 19.90  | 2020-12-15   | 4          |
| 92          | 1       | basic monthly | 9.90   | 2020-11-09   | 1          |
| 92          | 1       | basic monthly | 9.90   | 2020-12-09   | 2          |
| 93          | 2       | pro monthly   | 19.90  | 2020-03-21   | 1          |
| 93          | 2       | pro monthly   | 19.90  | 2020-04-21   | 2          |
| 93          | 2       | pro monthly   | 19.90  | 2020-05-21   | 3          |
| 93          | 2       | pro monthly   | 19.90  | 2020-06-21   | 4          |
| 93          | 2       | pro monthly   | 19.90  | 2020-07-21   | 5          |
| 93          | 2       | pro monthly   | 19.90  | 2020-08-21   | 6          |
| 94          | 2       | pro monthly   | 19.90  | 2020-12-16   | 1          |
| 95          | 1       | basic monthly | 9.90   | 2020-11-09   | 1          |
| 95          | 1       | basic monthly | 9.90   | 2020-12-09   | 2          |
| 96          | 1       | basic monthly | 9.90   | 2020-08-29   | 1          |
| 96          | 1       | basic monthly | 9.90   | 2020-09-29   | 2          |
| 96          | 1       | basic monthly | 9.90   | 2020-10-29   | 3          |
| 96          | 1       | basic monthly | 9.90   | 2020-11-29   | 4          |
| 96          | 1       | basic monthly | 9.90   | 2020-12-29   | 5          |
| 97          | 1       | basic monthly | 9.90   | 2020-11-05   | 1          |
| 97          | 1       | basic monthly | 9.90   | 2020-12-05   | 2          |
| 98          | 1       | basic monthly | 9.90   | 2020-01-12   | 1          |
| 98          | 2       | pro monthly   | 10.00  | 2020-01-22   | 2          |
| 98          | 2       | pro monthly   | 19.90  | 2020-02-22   | 3          |
| 98          | 2       | pro monthly   | 19.90  | 2020-03-22   | 4          |
| 100         | 1       | basic monthly | 9.90   | 2020-06-09   | 1          |
| 100         | 1       | basic monthly | 9.90   | 2020-07-09   | 2          |
| 100         | 1       | basic monthly | 9.90   | 2020-08-09   | 3          |
| 100         | 1       | basic monthly | 9.90   | 2020-09-09   | 4          |
| 100         | 2       | pro monthly   | 10.00  | 2020-09-11   | 5          |
| 100         | 2       | pro monthly   | 19.90  | 2020-10-11   | 6          |
| 100         | 2       | pro monthly   | 19.90  | 2020-11-11   | 7          |
| 100         | 2       | pro monthly   | 19.90  | 2020-12-11   | 8          |
| 101         | 1       | basic monthly | 9.90   | 2020-06-15   | 1          |
| 101         | 1       | basic monthly | 9.90   | 2020-07-15   | 2          |
| 101         | 3       | pro annual    | 189.10 | 2020-07-20   | 3          |
| 101         | 3       | pro annual    | 199.00 | 2020-08-20   | 4          |
| 101         | 3       | pro annual    | 199.00 | 2020-09-20   | 5          |
| 101         | 3       | pro annual    | 199.00 | 2020-10-20   | 6          |
| 101         | 3       | pro annual    | 199.00 | 2020-11-20   | 7          |
| 101         | 3       | pro annual    | 199.00 | 2020-12-20   | 8          |
| 102         | 1       | basic monthly | 9.90   | 2020-06-09   | 1          |
| 102         | 2       | pro monthly   | 10.00  | 2020-06-18   | 2          |
| 102         | 2       | pro monthly   | 19.90  | 2020-07-18   | 3          |
| 102         | 2       | pro monthly   | 19.90  | 2020-08-18   | 4          |
| 102         | 2       | pro monthly   | 19.90  | 2020-09-18   | 5          |
| 102         | 2       | pro monthly   | 19.90  | 2020-10-18   | 6          |
| 102         | 2       | pro monthly   | 19.90  | 2020-11-18   | 7          |
| 103         | 2       | pro monthly   | 19.90  | 2020-07-31   | 1          |
| 103         | 2       | pro monthly   | 19.90  | 2020-08-31   | 2          |
| 103         | 2       | pro monthly   | 19.90  | 2020-09-30   | 3          |
| 104         | 2       | pro monthly   | 19.90  | 2020-04-05   | 1          |
| 104         | 2       | pro monthly   | 19.90  | 2020-05-05   | 2          |
| 104         | 2       | pro monthly   | 19.90  | 2020-06-05   | 3          |
| 104         | 2       | pro monthly   | 19.90  | 2020-07-05   | 4          |
| 104         | 2       | pro monthly   | 19.90  | 2020-08-05   | 5          |
| 104         | 2       | pro monthly   | 19.90  | 2020-09-05   | 6          |
| 104         | 2       | pro monthly   | 19.90  | 2020-10-05   | 7          |
| 104         | 2       | pro monthly   | 19.90  | 2020-11-05   | 8          |
| 104         | 2       | pro monthly   | 19.90  | 2020-12-05   | 9          |
| 105         | 1       | basic monthly | 9.90   | 2020-09-27   | 1          |
| 105         | 3       | pro annual    | 189.10 | 2020-10-22   | 2          |
| 105         | 3       | pro annual    | 199.00 | 2020-11-22   | 3          |
| 105         | 3       | pro annual    | 199.00 | 2020-12-22   | 4          |
| 106         | 3       | pro annual    | 199.00 | 2020-08-09   | 1          |
| 106         | 3       | pro annual    | 199.00 | 2020-09-09   | 2          |
| 106         | 3       | pro annual    | 199.00 | 2020-10-09   | 3          |
| 106         | 3       | pro annual    | 199.00 | 2020-11-09   | 4          |
| 106         | 3       | pro annual    | 199.00 | 2020-12-09   | 5          |
| 107         | 1       | basic monthly | 9.90   | 2020-01-19   | 1          |
| 107         | 1       | basic monthly | 9.90   | 2020-02-19   | 2          |
| 107         | 1       | basic monthly | 9.90   | 2020-03-19   | 3          |
| 107         | 2       | pro monthly   | 10.00  | 2020-03-23   | 4          |
| 107         | 2       | pro monthly   | 19.90  | 2020-04-23   | 5          |
| 107         | 2       | pro monthly   | 19.90  | 2020-05-23   | 6          |
| 107         | 2       | pro monthly   | 19.90  | 2020-06-23   | 7          |
| 107         | 2       | pro monthly   | 19.90  | 2020-07-23   | 8          |
| 107         | 2       | pro monthly   | 19.90  | 2020-08-23   | 9          |
| 107         | 2       | pro monthly   | 19.90  | 2020-09-23   | 10         |
| 107         | 2       | pro monthly   | 19.90  | 2020-10-23   | 11         |
| 107         | 2       | pro monthly   | 19.90  | 2020-11-23   | 12         |
| 107         | 2       | pro monthly   | 19.90  | 2020-12-23   | 13         |
| 109         | 1       | basic monthly | 9.90   | 2020-10-19   | 1          |
| 109         | 1       | basic monthly | 9.90   | 2020-11-19   | 2          |
| 109         | 1       | basic monthly | 9.90   | 2020-12-19   | 3          |
| 110         | 2       | pro monthly   | 19.90  | 2020-05-19   | 1          |
| 110         | 2       | pro monthly   | 19.90  | 2020-06-19   | 2          |
| 110         | 2       | pro monthly   | 19.90  | 2020-07-19   | 3          |
| 110         | 2       | pro monthly   | 19.90  | 2020-08-19   | 4          |
| 110         | 2       | pro monthly   | 19.90  | 2020-09-19   | 5          |
| 110         | 2       | pro monthly   | 19.90  | 2020-10-19   | 6          |
| 110         | 2       | pro monthly   | 19.90  | 2020-11-19   | 7          |
| 110         | 2       | pro monthly   | 19.90  | 2020-12-19   | 8          |
| 111         | 3       | pro annual    | 199.00 | 2020-09-01   | 1          |
| 111         | 3       | pro annual    | 199.00 | 2020-10-01   | 2          |
| 111         | 3       | pro annual    | 199.00 | 2020-11-01   | 3          |
| 111         | 3       | pro annual    | 199.00 | 2020-12-01   | 4          |
| 112         | 2       | pro monthly   | 19.90  | 2020-10-27   | 1          |
| 112         | 2       | pro monthly   | 19.90  | 2020-11-27   | 2          |
| 112         | 2       | pro monthly   | 19.90  | 2020-12-27   | 3          |
| 113         | 1       | basic monthly | 9.90   | 2020-04-17   | 1          |
| 113         | 1       | basic monthly | 9.90   | 2020-05-17   | 2          |
| 113         | 1       | basic monthly | 9.90   | 2020-06-17   | 3          |
| 113         | 1       | basic monthly | 9.90   | 2020-07-17   | 4          |
| 113         | 1       | basic monthly | 9.90   | 2020-08-17   | 5          |
| 113         | 2       | pro monthly   | 10.00  | 2020-09-13   | 6          |
| 113         | 2       | pro monthly   | 19.90  | 2020-10-13   | 7          |
| 114         | 1       | basic monthly | 9.90   | 2020-06-12   | 1          |
| 114         | 1       | basic monthly | 9.90   | 2020-07-12   | 2          |
| 114         | 1       | basic monthly | 9.90   | 2020-08-12   | 3          |
| 114         | 1       | basic monthly | 9.90   | 2020-09-12   | 4          |
| 114         | 3       | pro annual    | 189.10 | 2020-09-13   | 5          |
| 114         | 3       | pro annual    | 199.00 | 2020-10-13   | 6          |
| 114         | 3       | pro annual    | 199.00 | 2020-11-13   | 7          |
| 114         | 3       | pro annual    | 199.00 | 2020-12-13   | 8          |
| 115         | 3       | pro annual    | 199.00 | 2020-08-21   | 1          |
| 115         | 3       | pro annual    | 199.00 | 2020-09-21   | 2          |
| 115         | 3       | pro annual    | 199.00 | 2020-10-21   | 3          |
| 115         | 3       | pro annual    | 199.00 | 2020-11-21   | 4          |
| 115         | 3       | pro annual    | 199.00 | 2020-12-21   | 5          |
| 116         | 1       | basic monthly | 9.90   | 2020-05-30   | 1          |
| 116         | 1       | basic monthly | 9.90   | 2020-06-30   | 2          |
| 116         | 1       | basic monthly | 9.90   | 2020-07-30   | 3          |
| 116         | 1       | basic monthly | 9.90   | 2020-08-30   | 4          |
| 117         | 1       | basic monthly | 9.90   | 2020-05-29   | 1          |
| 117         | 1       | basic monthly | 9.90   | 2020-06-29   | 2          |
| 117         | 1       | basic monthly | 9.90   | 2020-07-29   | 3          |
| 117         | 1       | basic monthly | 9.90   | 2020-08-29   | 4          |
| 117         | 1       | basic monthly | 9.90   | 2020-09-29   | 5          |
| 117         | 1       | basic monthly | 9.90   | 2020-10-29   | 6          |
| 117         | 3       | pro annual    | 189.10 | 2020-11-14   | 7          |
| 117         | 3       | pro annual    | 199.00 | 2020-12-14   | 8          |
| 118         | 1       | basic monthly | 9.90   | 2020-01-31   | 1          |
| 118         | 1       | basic monthly | 9.90   | 2020-02-29   | 2          |
| 118         | 1       | basic monthly | 9.90   | 2020-03-29   | 3          |
| 118         | 1       | basic monthly | 9.90   | 2020-04-29   | 4          |
| 118         | 1       | basic monthly | 9.90   | 2020-05-29   | 5          |
| 118         | 1       | basic monthly | 9.90   | 2020-06-29   | 6          |
| 119         | 1       | basic monthly | 9.90   | 2020-11-16   | 1          |
| 119         | 1       | basic monthly | 9.90   | 2020-12-16   | 2          |
| 120         | 2       | pro monthly   | 19.90  | 2020-05-21   | 1          |
| 120         | 2       | pro monthly   | 19.90  | 2020-06-21   | 2          |
| 120         | 2       | pro monthly   | 19.90  | 2020-07-21   | 3          |
| 120         | 2       | pro monthly   | 19.90  | 2020-08-21   | 4          |
| 120         | 3       | pro annual    | 199.00 | 2020-09-21   | 5          |
| 120         | 3       | pro annual    | 199.00 | 2020-10-21   | 6          |
| 120         | 3       | pro annual    | 199.00 | 2020-11-21   | 7          |
| 120         | 3       | pro annual    | 199.00 | 2020-12-21   | 8          |
| 121         | 1       | basic monthly | 9.90   | 2020-06-25   | 1          |
| 121         | 1       | basic monthly | 9.90   | 2020-07-25   | 2          |
| 121         | 1       | basic monthly | 9.90   | 2020-08-25   | 3          |
| 121         | 1       | basic monthly | 9.90   | 2020-09-25   | 4          |
| 121         | 3       | pro annual    | 189.10 | 2020-10-07   | 5          |
| 121         | 3       | pro annual    | 199.00 | 2020-11-07   | 6          |
| 121         | 3       | pro annual    | 199.00 | 2020-12-07   | 7          |
| 123         | 1       | basic monthly | 9.90   | 2020-03-19   | 1          |
| 123         | 1       | basic monthly | 9.90   | 2020-04-19   | 2          |
| 124         | 1       | basic monthly | 9.90   | 2020-03-24   | 1          |
| 124         | 1       | basic monthly | 9.90   | 2020-04-24   | 2          |
| 124         | 1       | basic monthly | 9.90   | 2020-05-24   | 3          |
| 124         | 3       | pro annual    | 189.10 | 2020-06-20   | 4          |
| 124         | 3       | pro annual    | 199.00 | 2020-07-20   | 5          |
| 124         | 3       | pro annual    | 199.00 | 2020-08-20   | 6          |
| 124         | 3       | pro annual    | 199.00 | 2020-09-20   | 7          |
| 124         | 3       | pro annual    | 199.00 | 2020-10-20   | 8          |
| 124         | 3       | pro annual    | 199.00 | 2020-11-20   | 9          |
| 124         | 3       | pro annual    | 199.00 | 2020-12-20   | 10         |
| 125         | 1       | basic monthly | 9.90   | 2020-08-14   | 1          |
| 125         | 1       | basic monthly | 9.90   | 2020-09-14   | 2          |
| 125         | 1       | basic monthly | 9.90   | 2020-10-14   | 3          |
| 125         | 1       | basic monthly | 9.90   | 2020-11-14   | 4          |
| 126         | 1       | basic monthly | 9.90   | 2020-09-22   | 1          |
| 126         | 1       | basic monthly | 9.90   | 2020-10-22   | 2          |
| 126         | 1       | basic monthly | 9.90   | 2020-11-22   | 3          |
| 126         | 1       | basic monthly | 9.90   | 2020-12-22   | 4          |
| 127         | 2       | pro monthly   | 19.90  | 2020-05-30   | 1          |
| 127         | 2       | pro monthly   | 19.90  | 2020-06-30   | 2          |
| 127         | 2       | pro monthly   | 19.90  | 2020-07-30   | 3          |
| 129         | 1       | basic monthly | 9.90   | 2020-07-30   | 1          |
| 129         | 1       | basic monthly | 9.90   | 2020-08-30   | 2          |
| 129         | 1       | basic monthly | 9.90   | 2020-09-30   | 3          |
| 129         | 1       | basic monthly | 9.90   | 2020-10-30   | 4          |
| 129         | 1       | basic monthly | 9.90   | 2020-11-30   | 5          |
| 129         | 1       | basic monthly | 9.90   | 2020-12-30   | 6          |
| 130         | 2       | pro monthly   | 19.90  | 2020-09-29   | 1          |
| 130         | 2       | pro monthly   | 19.90  | 2020-10-29   | 2          |
| 130         | 2       | pro monthly   | 19.90  | 2020-11-29   | 3          |
| 130         | 2       | pro monthly   | 19.90  | 2020-12-29   | 4          |
| 131         | 3       | pro annual    | 199.00 | 2020-10-23   | 1          |
| 131         | 3       | pro annual    | 199.00 | 2020-11-23   | 2          |
| 131         | 3       | pro annual    | 199.00 | 2020-12-23   | 3          |
| 132         | 1       | basic monthly | 9.90   | 2020-10-25   | 1          |
| 132         | 1       | basic monthly | 9.90   | 2020-11-25   | 2          |
| 132         | 1       | basic monthly | 9.90   | 2020-12-25   | 3          |
| 133         | 1       | basic monthly | 9.90   | 2020-04-05   | 1          |
| 133         | 1       | basic monthly | 9.90   | 2020-05-05   | 2          |
| 133         | 1       | basic monthly | 9.90   | 2020-06-05   | 3          |
| 133         | 1       | basic monthly | 9.90   | 2020-07-05   | 4          |
| 133         | 3       | pro annual    | 189.10 | 2020-07-11   | 5          |
| 133         | 3       | pro annual    | 199.00 | 2020-08-11   | 6          |
| 133         | 3       | pro annual    | 199.00 | 2020-09-11   | 7          |
| 133         | 3       | pro annual    | 199.00 | 2020-10-11   | 8          |
| 133         | 3       | pro annual    | 199.00 | 2020-11-11   | 9          |
| 133         | 3       | pro annual    | 199.00 | 2020-12-11   | 10         |
| 134         | 2       | pro monthly   | 19.90  | 2020-07-09   | 1          |
| 134         | 2       | pro monthly   | 19.90  | 2020-08-09   | 2          |
| 134         | 2       | pro monthly   | 19.90  | 2020-09-09   | 3          |
| 134         | 2       | pro monthly   | 19.90  | 2020-10-09   | 4          |
| 134         | 2       | pro monthly   | 19.90  | 2020-11-09   | 5          |
| 134         | 2       | pro monthly   | 19.90  | 2020-12-09   | 6          |
| 137         | 2       | pro monthly   | 19.90  | 2020-08-19   | 1          |
| 137         | 2       | pro monthly   | 19.90  | 2020-09-19   | 2          |
| 137         | 2       | pro monthly   | 19.90  | 2020-10-19   | 3          |
| 137         | 2       | pro monthly   | 19.90  | 2020-11-19   | 4          |
| 137         | 2       | pro monthly   | 19.90  | 2020-12-19   | 5          |
| 138         | 1       | basic monthly | 9.90   | 2020-11-02   | 1          |
| 138         | 1       | basic monthly | 9.90   | 2020-12-02   | 2          |
| 138         | 2       | pro monthly   | 10.00  | 2020-12-25   | 3          |
| 139         | 2       | pro monthly   | 19.90  | 2020-07-24   | 1          |
| 139         | 2       | pro monthly   | 19.90  | 2020-08-24   | 2          |
| 139         | 2       | pro monthly   | 19.90  | 2020-09-24   | 3          |
| 139         | 2       | pro monthly   | 19.90  | 2020-10-24   | 4          |
| 139         | 2       | pro monthly   | 19.90  | 2020-11-24   | 5          |
| 139         | 2       | pro monthly   | 19.90  | 2020-12-24   | 6          |
| 141         | 1       | basic monthly | 9.90   | 2020-04-26   | 1          |
| 141         | 1       | basic monthly | 9.90   | 2020-05-26   | 2          |
| 141         | 1       | basic monthly | 9.90   | 2020-06-26   | 3          |
| 141         | 1       | basic monthly | 9.90   | 2020-07-26   | 4          |
| 141         | 1       | basic monthly | 9.90   | 2020-08-26   | 5          |
| 141         | 1       | basic monthly | 9.90   | 2020-09-26   | 6          |
| 141         | 3       | pro annual    | 189.10 | 2020-10-18   | 7          |
| 141         | 3       | pro annual    | 199.00 | 2020-11-18   | 8          |
| 141         | 3       | pro annual    | 199.00 | 2020-12-18   | 9          |
| 142         | 2       | pro monthly   | 19.90  | 2020-06-06   | 1          |
| 142         | 2       | pro monthly   | 19.90  | 2020-07-06   | 2          |
| 142         | 2       | pro monthly   | 19.90  | 2020-08-06   | 3          |
| 142         | 2       | pro monthly   | 19.90  | 2020-09-06   | 4          |
| 142         | 2       | pro monthly   | 19.90  | 2020-10-06   | 5          |
| 142         | 2       | pro monthly   | 19.90  | 2020-11-06   | 6          |
| 142         | 2       | pro monthly   | 19.90  | 2020-12-06   | 7          |
| 143         | 1       | basic monthly | 9.90   | 2020-12-27   | 1          |
| 144         | 1       | basic monthly | 9.90   | 2020-09-11   | 1          |
| 144         | 1       | basic monthly | 9.90   | 2020-10-11   | 2          |
| 144         | 1       | basic monthly | 9.90   | 2020-11-11   | 3          |
| 144         | 1       | basic monthly | 9.90   | 2020-12-11   | 4          |
| 145         | 2       | pro monthly   | 19.90  | 2020-01-24   | 1          |
| 145         | 2       | pro monthly   | 19.90  | 2020-02-24   | 2          |
| 145         | 2       | pro monthly   | 19.90  | 2020-03-24   | 3          |
| 145         | 2       | pro monthly   | 19.90  | 2020-04-24   | 4          |
| 145         | 2       | pro monthly   | 19.90  | 2020-05-24   | 5          |
| 145         | 2       | pro monthly   | 19.90  | 2020-06-24   | 6          |
| 145         | 2       | pro monthly   | 19.90  | 2020-07-24   | 7          |
| 145         | 2       | pro monthly   | 19.90  | 2020-08-24   | 8          |
| 145         | 2       | pro monthly   | 19.90  | 2020-09-24   | 9          |
| 145         | 2       | pro monthly   | 19.90  | 2020-10-24   | 10         |
| 145         | 2       | pro monthly   | 19.90  | 2020-11-24   | 11         |
| 145         | 2       | pro monthly   | 19.90  | 2020-12-24   | 12         |
| 146         | 1       | basic monthly | 9.90   | 2020-07-12   | 1          |
| 146         | 1       | basic monthly | 9.90   | 2020-08-12   | 2          |
| 146         | 1       | basic monthly | 9.90   | 2020-09-12   | 3          |
| 146         | 1       | basic monthly | 9.90   | 2020-10-12   | 4          |
| 146         | 2       | pro monthly   | 10.00  | 2020-10-28   | 5          |
| 146         | 2       | pro monthly   | 19.90  | 2020-11-28   | 6          |
| 147         | 2       | pro monthly   | 19.90  | 2020-12-25   | 1          |
| 148         | 2       | pro monthly   | 19.90  | 2020-03-19   | 1          |
| 148         | 2       | pro monthly   | 19.90  | 2020-04-19   | 2          |
| 148         | 2       | pro monthly   | 19.90  | 2020-05-19   | 3          |
| 148         | 2       | pro monthly   | 19.90  | 2020-06-19   | 4          |
| 148         | 2       | pro monthly   | 19.90  | 2020-07-19   | 5          |
| 148         | 2       | pro monthly   | 19.90  | 2020-08-19   | 6          |
| 148         | 2       | pro monthly   | 19.90  | 2020-09-19   | 7          |
| 148         | 2       | pro monthly   | 19.90  | 2020-10-19   | 8          |
| 148         | 2       | pro monthly   | 19.90  | 2020-11-19   | 9          |
| 148         | 2       | pro monthly   | 19.90  | 2020-12-19   | 10         |
| 149         | 1       | basic monthly | 9.90   | 2020-12-26   | 1          |
| 150         | 2       | pro monthly   | 19.90  | 2020-02-12   | 1          |
| 150         | 2       | pro monthly   | 19.90  | 2020-03-12   | 2          |
| 150         | 2       | pro monthly   | 19.90  | 2020-04-12   | 3          |
| 150         | 2       | pro monthly   | 19.90  | 2020-05-12   | 4          |
| 150         | 2       | pro monthly   | 19.90  | 2020-06-12   | 5          |
| 150         | 2       | pro monthly   | 19.90  | 2020-07-12   | 6          |
| 150         | 2       | pro monthly   | 19.90  | 2020-08-12   | 7          |
| 150         | 2       | pro monthly   | 19.90  | 2020-09-12   | 8          |
| 150         | 2       | pro monthly   | 19.90  | 2020-10-12   | 9          |
| 150         | 2       | pro monthly   | 19.90  | 2020-11-12   | 10         |
| 150         | 2       | pro monthly   | 19.90  | 2020-12-12   | 11         |
| 151         | 1       | basic monthly | 9.90   | 2020-09-14   | 1          |
| 151         | 2       | pro monthly   | 10.00  | 2020-09-17   | 2          |
| 151         | 2       | pro monthly   | 19.90  | 2020-10-17   | 3          |
| 151         | 2       | pro monthly   | 19.90  | 2020-11-17   | 4          |
| 151         | 2       | pro monthly   | 19.90  | 2020-12-17   | 5          |
| 152         | 1       | basic monthly | 9.90   | 2020-10-21   | 1          |
| 152         | 1       | basic monthly | 9.90   | 2020-11-21   | 2          |
| 152         | 1       | basic monthly | 9.90   | 2020-12-21   | 3          |
| 153         | 2       | pro monthly   | 19.90  | 2020-12-05   | 1          |
| 154         | 1       | basic monthly | 9.90   | 2020-03-25   | 1          |
| 154         | 1       | basic monthly | 9.90   | 2020-04-25   | 2          |
| 154         | 2       | pro monthly   | 10.00  | 2020-05-01   | 3          |
| 154         | 2       | pro monthly   | 19.90  | 2020-06-01   | 4          |
| 154         | 2       | pro monthly   | 19.90  | 2020-07-01   | 5          |
| 154         | 2       | pro monthly   | 19.90  | 2020-08-01   | 6          |
| 154         | 2       | pro monthly   | 19.90  | 2020-09-01   | 7          |
| 154         | 2       | pro monthly   | 19.90  | 2020-10-01   | 8          |
| 154         | 2       | pro monthly   | 19.90  | 2020-11-01   | 9          |
| 154         | 2       | pro monthly   | 19.90  | 2020-12-01   | 10         |
| 157         | 1       | basic monthly | 9.90   | 2020-04-30   | 1          |
| 157         | 3       | pro annual    | 189.10 | 2020-05-11   | 2          |
| 157         | 3       | pro annual    | 199.00 | 2020-06-11   | 3          |
| 157         | 3       | pro annual    | 199.00 | 2020-07-11   | 4          |
| 157         | 3       | pro annual    | 199.00 | 2020-08-11   | 5          |
| 157         | 3       | pro annual    | 199.00 | 2020-09-11   | 6          |
| 157         | 3       | pro annual    | 199.00 | 2020-10-11   | 7          |
| 157         | 3       | pro annual    | 199.00 | 2020-11-11   | 8          |
| 157         | 3       | pro annual    | 199.00 | 2020-12-11   | 9          |
| 158         | 1       | basic monthly | 9.90   | 2020-03-09   | 1          |
| 158         | 1       | basic monthly | 9.90   | 2020-04-09   | 2          |
| 158         | 2       | pro monthly   | 19.90  | 2020-05-09   | 3          |
| 158         | 2       | pro monthly   | 19.90  | 2020-06-09   | 4          |
| 158         | 2       | pro monthly   | 19.90  | 2020-07-09   | 5          |
| 158         | 2       | pro monthly   | 19.90  | 2020-08-09   | 6          |
| 158         | 2       | pro monthly   | 19.90  | 2020-09-09   | 7          |
| 158         | 2       | pro monthly   | 19.90  | 2020-10-09   | 8          |
| 158         | 2       | pro monthly   | 19.90  | 2020-11-09   | 9          |
| 158         | 2       | pro monthly   | 19.90  | 2020-12-09   | 10         |
| 159         | 2       | pro monthly   | 19.90  | 2020-09-16   | 1          |
| 159         | 2       | pro monthly   | 19.90  | 2020-10-16   | 2          |
| 159         | 2       | pro monthly   | 19.90  | 2020-11-16   | 3          |
| 159         | 2       | pro monthly   | 19.90  | 2020-12-16   | 4          |
| 160         | 1       | basic monthly | 9.90   | 2020-11-23   | 1          |
| 160         | 1       | basic monthly | 9.90   | 2020-12-23   | 2          |
| 163         | 2       | pro monthly   | 19.90  | 2020-12-30   | 1          |
| 164         | 2       | pro monthly   | 19.90  | 2020-12-04   | 1          |
| 165         | 1       | basic monthly | 9.90   | 2020-10-12   | 1          |
| 165         | 3       | pro annual    | 189.10 | 2020-11-08   | 2          |
| 165         | 3       | pro annual    | 199.00 | 2020-12-08   | 3          |
| 166         | 1       | basic monthly | 9.90   | 2020-07-10   | 1          |
| 166         | 1       | basic monthly | 9.90   | 2020-08-10   | 2          |
| 166         | 1       | basic monthly | 9.90   | 2020-09-10   | 3          |
| 167         | 2       | pro monthly   | 19.90  | 2020-05-14   | 1          |
| 167         | 2       | pro monthly   | 19.90  | 2020-06-14   | 2          |
| 167         | 2       | pro monthly   | 19.90  | 2020-07-14   | 3          |
| 167         | 2       | pro monthly   | 19.90  | 2020-08-14   | 4          |
| 167         | 2       | pro monthly   | 19.90  | 2020-09-14   | 5          |
| 167         | 2       | pro monthly   | 19.90  | 2020-10-14   | 6          |
| 167         | 2       | pro monthly   | 19.90  | 2020-11-14   | 7          |
| 167         | 2       | pro monthly   | 19.90  | 2020-12-14   | 8          |
| 168         | 2       | pro monthly   | 19.90  | 2020-03-14   | 1          |
| 168         | 2       | pro monthly   | 19.90  | 2020-04-14   | 2          |
| 168         | 2       | pro monthly   | 19.90  | 2020-05-14   | 3          |
| 168         | 2       | pro monthly   | 19.90  | 2020-06-14   | 4          |
| 168         | 2       | pro monthly   | 19.90  | 2020-07-14   | 5          |
| 168         | 2       | pro monthly   | 19.90  | 2020-08-14   | 6          |
| 168         | 2       | pro monthly   | 19.90  | 2020-09-14   | 7          |
| 168         | 2       | pro monthly   | 19.90  | 2020-10-14   | 8          |
| 168         | 2       | pro monthly   | 19.90  | 2020-11-14   | 9          |
| 168         | 2       | pro monthly   | 19.90  | 2020-12-14   | 10         |
| 170         | 1       | basic monthly | 9.90   | 2020-04-25   | 1          |
| 170         | 1       | basic monthly | 9.90   | 2020-05-25   | 2          |
| 170         | 1       | basic monthly | 9.90   | 2020-06-25   | 3          |
| 170         | 1       | basic monthly | 9.90   | 2020-07-25   | 4          |
| 170         | 1       | basic monthly | 9.90   | 2020-08-25   | 5          |
| 170         | 2       | pro monthly   | 10.00  | 2020-08-28   | 6          |
| 170         | 2       | pro monthly   | 19.90  | 2020-09-28   | 7          |
| 170         | 2       | pro monthly   | 19.90  | 2020-10-28   | 8          |
| 170         | 2       | pro monthly   | 19.90  | 2020-11-28   | 9          |
| 170         | 3       | pro annual    | 199.00 | 2020-12-28   | 10         |
| 171         | 2       | pro monthly   | 19.90  | 2020-12-05   | 1          |
| 172         | 1       | basic monthly | 9.90   | 2020-12-12   | 1          |
| 173         | 2       | pro monthly   | 19.90  | 2020-07-01   | 1          |
| 173         | 2       | pro monthly   | 19.90  | 2020-08-01   | 2          |
| 173         | 2       | pro monthly   | 19.90  | 2020-09-01   | 3          |
| 173         | 2       | pro monthly   | 19.90  | 2020-10-01   | 4          |
| 173         | 2       | pro monthly   | 19.90  | 2020-11-01   | 5          |
| 173         | 2       | pro monthly   | 19.90  | 2020-12-01   | 6          |
| 174         | 1       | basic monthly | 9.90   | 2020-02-08   | 1          |
| 174         | 1       | basic monthly | 9.90   | 2020-03-08   | 2          |
| 174         | 1       | basic monthly | 9.90   | 2020-04-08   | 3          |
| 174         | 1       | basic monthly | 9.90   | 2020-05-08   | 4          |
| 174         | 1       | basic monthly | 9.90   | 2020-06-08   | 5          |
| 174         | 1       | basic monthly | 9.90   | 2020-07-08   | 6          |
| 174         | 3       | pro annual    | 189.10 | 2020-07-10   | 7          |
| 174         | 3       | pro annual    | 199.00 | 2020-08-10   | 8          |
| 174         | 3       | pro annual    | 199.00 | 2020-09-10   | 9          |
| 174         | 3       | pro annual    | 199.00 | 2020-10-10   | 10         |
| 174         | 3       | pro annual    | 199.00 | 2020-11-10   | 11         |
| 174         | 3       | pro annual    | 199.00 | 2020-12-10   | 12         |
| 175         | 2       | pro monthly   | 19.90  | 2020-08-22   | 1          |
| 175         | 2       | pro monthly   | 19.90  | 2020-09-22   | 2          |
| 175         | 2       | pro monthly   | 19.90  | 2020-10-22   | 3          |
| 175         | 2       | pro monthly   | 19.90  | 2020-11-22   | 4          |
| 176         | 1       | basic monthly | 9.90   | 2020-09-20   | 1          |
| 176         | 1       | basic monthly | 9.90   | 2020-10-20   | 2          |
| 176         | 1       | basic monthly | 9.90   | 2020-11-20   | 3          |
| 176         | 1       | basic monthly | 9.90   | 2020-12-20   | 4          |
| 177         | 2       | pro monthly   | 19.90  | 2020-05-08   | 1          |
| 177         | 2       | pro monthly   | 19.90  | 2020-06-08   | 2          |
| 177         | 2       | pro monthly   | 19.90  | 2020-07-08   | 3          |
| 177         | 2       | pro monthly   | 19.90  | 2020-08-08   | 4          |
| 177         | 2       | pro monthly   | 19.90  | 2020-09-08   | 5          |
| 179         | 2       | pro monthly   | 19.90  | 2020-06-20   | 1          |
| 179         | 2       | pro monthly   | 19.90  | 2020-07-20   | 2          |
| 179         | 2       | pro monthly   | 19.90  | 2020-08-20   | 3          |
| 179         | 2       | pro monthly   | 19.90  | 2020-09-20   | 4          |
| 180         | 1       | basic monthly | 9.90   | 2020-11-07   | 1          |
| 180         | 1       | basic monthly | 9.90   | 2020-12-07   | 2          |
| 181         | 2       | pro monthly   | 19.90  | 2020-02-18   | 1          |
| 181         | 2       | pro monthly   | 19.90  | 2020-03-18   | 2          |
| 181         | 2       | pro monthly   | 19.90  | 2020-04-18   | 3          |
| 181         | 2       | pro monthly   | 19.90  | 2020-05-18   | 4          |
| 181         | 2       | pro monthly   | 19.90  | 2020-06-18   | 5          |
| 181         | 2       | pro monthly   | 19.90  | 2020-07-18   | 6          |
| 181         | 2       | pro monthly   | 19.90  | 2020-08-18   | 7          |
| 181         | 2       | pro monthly   | 19.90  | 2020-09-18   | 8          |
| 181         | 2       | pro monthly   | 19.90  | 2020-10-18   | 9          |
| 181         | 2       | pro monthly   | 19.90  | 2020-11-18   | 10         |
| 181         | 2       | pro monthly   | 19.90  | 2020-12-18   | 11         |
| 182         | 1       | basic monthly | 9.90   | 2020-10-03   | 1          |
| 182         | 1       | basic monthly | 9.90   | 2020-11-03   | 2          |
| 182         | 1       | basic monthly | 9.90   | 2020-12-03   | 3          |
| 183         | 2       | pro monthly   | 19.90  | 2020-10-02   | 1          |
| 183         | 2       | pro monthly   | 19.90  | 2020-11-02   | 2          |
| 183         | 2       | pro monthly   | 19.90  | 2020-12-02   | 3          |
| 184         | 1       | basic monthly | 9.90   | 2020-02-23   | 1          |
| 184         | 1       | basic monthly | 9.90   | 2020-03-23   | 2          |
| 184         | 1       | basic monthly | 9.90   | 2020-04-23   | 3          |
| 184         | 1       | basic monthly | 9.90   | 2020-05-23   | 4          |
| 184         | 1       | basic monthly | 9.90   | 2020-06-23   | 5          |
| 184         | 1       | basic monthly | 9.90   | 2020-07-23   | 6          |
| 184         | 1       | basic monthly | 9.90   | 2020-08-23   | 7          |
| 184         | 1       | basic monthly | 9.90   | 2020-09-23   | 8          |
| 184         | 1       | basic monthly | 9.90   | 2020-10-23   | 9          |
| 184         | 1       | basic monthly | 9.90   | 2020-11-23   | 10         |
| 184         | 1       | basic monthly | 9.90   | 2020-12-23   | 11         |
| 185         | 2       | pro monthly   | 19.90  | 2020-12-10   | 1          |
| 186         | 2       | pro monthly   | 19.90  | 2020-10-07   | 1          |
| 186         | 2       | pro monthly   | 19.90  | 2020-11-07   | 2          |
| 186         | 2       | pro monthly   | 19.90  | 2020-12-07   | 3          |
| 187         | 3       | pro annual    | 199.00 | 2020-09-26   | 1          |
| 187         | 3       | pro annual    | 199.00 | 2020-10-26   | 2          |
| 187         | 3       | pro annual    | 199.00 | 2020-11-26   | 3          |
| 187         | 3       | pro annual    | 199.00 | 2020-12-26   | 4          |
| 188         | 1       | basic monthly | 9.90   | 2020-02-29   | 1          |
| 188         | 1       | basic monthly | 9.90   | 2020-03-29   | 2          |
| 188         | 1       | basic monthly | 9.90   | 2020-04-29   | 3          |
| 188         | 1       | basic monthly | 9.90   | 2020-05-29   | 4          |
| 188         | 1       | basic monthly | 9.90   | 2020-06-29   | 5          |
| 188         | 1       | basic monthly | 9.90   | 2020-07-29   | 6          |
| 188         | 1       | basic monthly | 9.90   | 2020-08-29   | 7          |
| 188         | 1       | basic monthly | 9.90   | 2020-09-29   | 8          |
| 188         | 1       | basic monthly | 9.90   | 2020-10-29   | 9          |
| 188         | 1       | basic monthly | 9.90   | 2020-11-29   | 10         |
| 188         | 1       | basic monthly | 9.90   | 2020-12-29   | 11         |
| 189         | 2       | pro monthly   | 19.90  | 2020-12-16   | 1          |
| 190         | 1       | basic monthly | 9.90   | 2020-04-27   | 1          |
| 190         | 1       | basic monthly | 9.90   | 2020-05-27   | 2          |
| 190         | 1       | basic monthly | 9.90   | 2020-06-27   | 3          |
| 190         | 1       | basic monthly | 9.90   | 2020-07-27   | 4          |
| 190         | 1       | basic monthly | 9.90   | 2020-08-27   | 5          |
| 190         | 3       | pro annual    | 189.10 | 2020-09-04   | 6          |
| 190         | 3       | pro annual    | 199.00 | 2020-10-04   | 7          |
| 190         | 3       | pro annual    | 199.00 | 2020-11-04   | 8          |
| 190         | 3       | pro annual    | 199.00 | 2020-12-04   | 9          |
| 191         | 2       | pro monthly   | 19.90  | 2020-01-09   | 1          |
| 191         | 2       | pro monthly   | 19.90  | 2020-02-09   | 2          |
| 191         | 2       | pro monthly   | 19.90  | 2020-03-09   | 3          |
| 191         | 2       | pro monthly   | 19.90  | 2020-04-09   | 4          |
| 191         | 2       | pro monthly   | 19.90  | 2020-05-09   | 5          |
| 191         | 2       | pro monthly   | 19.90  | 2020-06-09   | 6          |
| 191         | 2       | pro monthly   | 19.90  | 2020-07-09   | 7          |
| 191         | 2       | pro monthly   | 19.90  | 2020-08-09   | 8          |

---
