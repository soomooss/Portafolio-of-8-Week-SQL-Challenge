# 🍕 Case Study #2 - Pizza Runner 
URL https://8weeksqlchallenge.com/case-study-2/

Este proyecto expande el uso de SQL abordando la limpieza de datos y métricas operativas de entrega para una pizzería.

## 🗂️ Índice de Secciones
* [🧼 Fase de Limpieza de Datos (Data Cleansing)](#-fase-de-limpieza-de-datos-data-cleansing)
* [📊 Sección A: Pizza Metrics](#-sección-a-pizza-metrics)
* [🏃‍♂️ Sección B: Runner and Customer Experience](#-sección-b-runner-and-customer-experience)
* [🍪 Sección C: Ingredient Optimisation](#-sección-c-ingredient-optimisation)
* [💰 Sección D: Pricing and Ratings](#-sección-d-pricing-and-ratings)
* [🚀 Sección E: Bonus Challenge](#-sección-e-bonus-challenge)

---

## 🧼 Fase de Limpieza de Datos (Data Cleansing)
```sql
CREATE TEMP TABLE clean_customer_orders AS
	SELECT
		order_id,
		customer_id,
		pizza_id,
		CASE 
			WHEN TRIM(exclusions) = '' OR LOWER(TRIM(exclusions)) = 'null' THEN NULL 
			ELSE exclusions 
		END AS exclusions,
		CASE 
			WHEN TRIM(extras) = '' OR LOWER(TRIM(extras)) = 'null' THEN NULL 
			ELSE extras 
		END AS extras,
		order_time
	FROM pizza_runner.customer_orders;
```
**Resultado:**
| order_id | customer_id | pizza_id | exclusions | extras | order_time          |
|----------|-------------|----------|------------|--------|---------------------|
| 1        | 101         | 1        |            |        | 2020-01-01 18:05:02 |
| 2        | 101         | 1        |            |        | 2020-01-01 19:00:52 |
| 3        | 102         | 1        |            |        | 2020-01-02 23:51:23 |
| 3        | 102         | 2        |            |        | 2020-01-02 23:51:23 |
| 4        | 103         | 1        | 4          |        | 2020-01-04 13:23:46 |
| 4        | 103         | 1        | 4          |        | 2020-01-04 13:23:46 |
| 4        | 103         | 2        | 4          |        | 2020-01-04 13:23:46 |
| 5        | 104         | 1        |            | 1      | 2020-01-08 21:00:29 |
| 6        | 101         | 2        |            |        | 2020-01-08 21:03:13 |
| 7        | 105         | 2        |            | 1      | 2020-01-08 21:20:29 |
| 8        | 102         | 1        |            |        | 2020-01-09 23:54:33 |
| 9        | 103         | 1        | 4          | 1, 5   | 2020-01-10 11:22:59 |
| 10       | 104         | 1        |            |        | 2020-01-11 18:34:49 |
| 10       | 104         | 1        | 2, 6       | 1, 4   | 2020-01-11 18:34:49 |


```sql
CREATE TEMP TABLE clean_runner_orders AS
	SELECT
		order_id,
		runner_id,
		CASE 
			WHEN LOWER(TRIM(pickup_time)) = 'null' OR TRIM(pickup_time) = '' THEN NULL 
			ELSE pickup_time 
		END::TIMESTAMP AS pickup_time,
		CASE 
			WHEN LOWER(TRIM(distance)) = 'null' OR TRIM(distance) = '' THEN NULL 
			ELSE TRIM(REPLACE(LOWER(distance),'km','')) 
		END::NUMERIC AS distance,
		CASE 
			WHEN LOWER(TRIM(duration)) = 'null' OR TRIM(duration) = '' THEN NULL 
			ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g') 
		END::INTEGER AS duration,
		CASE 
			WHEN LOWER(TRIM(cancellation)) = 'null' OR TRIM(cancellation) =  '' THEN NULL 
			ELSE  cancellation 
		END AS cancellation
	FROM pizza_runner.runner_orders;
```
**Resultado:**
| order_id | runner_id | pickup_time         | distance | duration | cancellation            |
|----------|-----------|---------------------|----------|----------|-------------------------|
| 1        | 1         | 2020-01-01 18:15:34 | 20       | 32       |                         |
| 2        | 1         | 2020-01-01 19:10:54 | 20       | 27       |                         |
| 3        | 1         | 2020-01-03 00:12:37 | 13.4     | 20       |                         |
| 4        | 2         | 2020-01-04 13:53:03 | 23.4     | 40       |                         |
| 5        | 3         | 2020-01-08 21:10:57 | 10       | 15       |                         |
| 6        | 3         |                     |          |          | Restaurant Cancellation |
| 7        | 2         | 2020-01-08 21:30:45 | 25       | 25       |                         |
| 8        | 2         | 2020-01-10 00:15:02 | 23.4     | 15       |                         |
| 9        | 2         |                     |          |          | Customer Cancellation   |
| 10       | 1         | 2020-01-11 18:50:20 | 10       | 10       |                         |

---

## 📊 Sección A: Pizza Metrics

### 1. How many pizzas were ordered?
```sql
SELECT 
	COUNT(order_id) AS total_pizzas_ordered
FROM clean_customer_orders;
```
**Resultado:**

| total_pizzas_ordered |
|---|
| 14 |

### 2. How many unique customer orders were made?
```sql
SELECT 
	COUNT(DISTINCT order_id) AS customer_orders
FROM clean_customer_orders;
```
**Resultado:**
| customer_orders |
|-----------------|
| 10              |


### 3. How many successful orders were delivered by each runner?
```sql
SELECT 
	runner_id,
	COUNT(order_id) AS deliveries
FROM clean_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
```
**Resultado:**
| runner_id | deliveries |
|-----------|------------|
| 1         | 4          |
| 2         | 3          |
| 3         | 1          |


### 4. How many of each type of pizza was delivered?
```sql
SELECT 
	pn.pizza_name,
	COUNT(cco.pizza_id) AS number_of_pizzas
FROM clean_customer_orders AS cco
INNER JOIN pizza_runner.pizza_names AS pn
	ON cco.pizza_id = pn.pizza_id
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY pn.pizza_name;
```
**Resultado:**
| pizza_name | number_of_pizzas |
|------------|------------------|
| Vegetarian | 3                |
| Meatlovers | 9                |


### 5. How many Vegetarian and Meatlovers were ordered by each customer?
```sql
SELECT 
	cco.customer_id,
	pn.pizza_name,
	COUNT(cco.pizza_id) AS number_of_pizzas
FROM clean_customer_orders AS cco
INNER JOIN pizza_runner.pizza_names AS pn
	ON cco.pizza_id = pn.pizza_id
GROUP BY cco.customer_id, pn.pizza_name
ORDER BY cco.customer_id;
```
**Resultado:**
| customer_id | pizza_name | number_of_pizzas |
|-------------|------------|------------------|
| 101         | Meatlovers | 2                |
| 101         | Vegetarian | 1                |
| 102         | Meatlovers | 2                |
| 102         | Vegetarian | 1                |
| 103         | Meatlovers | 3                |
| 103         | Vegetarian | 1                |
| 104         | Meatlovers | 3                |
| 105         | Vegetarian | 1                |


### 6. What was the maximum number of pizzas delivered in a single order?
```sql
SELECT 
	cco.order_id,
	COUNT(cco.order_id) AS number_of_pizzas
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.order_id
ORDER BY number_of_pizzas DESC
LIMIT 1;
```
**Resultado:**
| order_id | number_of_pizzas |
|----------|------------------|
| 4        | 3                |

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
SELECT 
	cco.customer_id,
	SUM( CASE WHEN cco.exclusions IS NULL AND cco.extras IS NULL THEN 1 ELSE 0 END) AS sin_cambios,
	SUM( CASE WHEN cco.exclusions IS NOT NULL OR cco.extras IS NOT NULL THEN 1 ELSE 0 END) AS con_cambios
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.customer_id;
```
**Resultado:**
| customer_id | sin_cambios | con_cambios |
|-------------|-------------|-------------|
| 101         | 2           | 0           |
| 102         | 3           | 0           |
| 103         | 0           | 3           |
| 104         | 1           | 2           |
| 105         | 0           | 1           |



### 8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT 
	COUNT(cco.pizza_id) AS pizzas_with_exclusions_and_extras
FROM clean_customer_orders AS cco
INNER JOIN pizza_runner.pizza_names AS pn
	ON cco.pizza_id = pn.pizza_id
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL AND cco.exclusions IS NOT NULL AND cco.extras IS NOT NULL;
```
**Resultado:**
| pizzas_with_exclusions_and_extras |
|-----------------------------------|
| 1                                 |


### 9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT 
	order_time::DATE AS day,
	EXTRACT(HOUR FROM order_time) AS hour_of_the_day,
	COUNT(pizza_id) AS number_of_pizzas
FROM clean_customer_orders
GROUP BY order_time::DATE, EXTRACT(HOUR FROM order_time)
ORDER BY order_time::DATE,EXTRACT(HOUR FROM order_time);
```
**Resultado:**
| day        | hour_of_the_day | number_of_pizzas |
|------------|-----------------|------------------|
| 2020-01-01 | 18              | 1                |
| 2020-01-01 | 19              | 1                |
| 2020-01-02 | 23              | 2                |
| 2020-01-04 | 13              | 3                |
| 2020-01-08 | 21              | 3                |
| 2020-01-09 | 23              | 1                |
| 2020-01-10 | 11              | 1                |
| 2020-01-11 | 18              | 2                |

### 10. What was the volume of orders for each day of the week?
```sql
SELECT 
	TO_CHAR(order_time, 'Day') AS day_of_the_week,
	COUNT(pizza_id) AS total_pizzas_ordered
FROM clean_customer_orders
GROUP BY TO_CHAR(order_time, 'Day'),EXTRACT(DOW FROM order_time)
ORDER BY EXTRACT(DOW FROM order_time);
```
**Resultado:**
| day_of_the_week | total_pizzas_ordered |
|-----------------|----------------------|
| Wednesday       | 5                    |
| Thursday        | 3                    |
| Friday          | 1                    |
| Saturday        | 5                    |

---

## 🏃‍♂️ Sección B: Runner and Customer Experience

### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
WITH week_calculation AS (
	SELECT 
		runner_id,
		(DATE_TRUNC('week',registration_date + INTERVAL '3 days') - INTERVAL '3 days')::DATE AS start_week
	FROM pizza_runner.runners),
ranked_weeks AS (
	SELECT
		runner_id,
		start_week,
		DENSE_RANK() OVER( ORDER BY start_week) AS week_num
	FROM week_calculation
)
SELECT 
	'wk' || week_num AS registration_week,
	COUNT(runner_id) AS runner_signups
FROM ranked_weeks
GROUP BY week_num, registration_week
ORDER BY week_num;
```
**Resultado:**
| registration_week | runner_signups |
|-------------------|----------------|
| wk1               | 2              |
| wk2               | 1              |
| wk3               | 1              |


### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT 
	cro.runner_id ,
	ROUND(AVG( EXTRACT(EPOCH FROM cro.pickup_time - cco.order_time )/60),2) AS avg_time_to_arrive_in_HQ
	FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY 1;
```
**Resultado:**
| runner_id | avg_time_to_arrive_in_hq |
|-----------|--------------------------|
| 1         | 15.68                    |
| 2         | 23.72                    |
| 3         | 10.47                    |


### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
WITH preparation AS (
	SELECT 
		cco.order_id,
		COUNT(cco.order_id) AS number_of_pizzas,
		EXTRACT(EPOCH FROM cro.pickup_time - cco.order_time )/60 AS total_preparation_time
		FROM clean_customer_orders AS cco
	INNER JOIN clean_runner_orders AS cro
		ON cco.order_id = cro.order_id
	WHERE cro.cancellation IS NULL
	GROUP BY cco.order_id,cro.pickup_time,cco.order_time)

SELECT
	number_of_pizzas,
	ROUND(AVG(total_preparation_time),2) as avg_time_per_order,
	ROUND(AVG(total_preparation_time / number_of_pizzas),2) as avg_time_per_pizza
FROM preparation
GROUP BY number_of_pizzas;
```
**Resultado:**
| number_of_pizzas | avg_time_per_order | avg_time_per_pizza |
|------------------|--------------------|--------------------|
| 1                | 12.36              | 12.36              |
| 2                | 18.38              | 9.19               |
| 3                | 29.28              | 9.76               |

### 4. What was the average distance travelled for each customer?
```sql
SELECT 
	customer_id, 
	ROUND(AVG(distance),2) AS distance_in_km
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY customer_id;
```
**Resultado:**
| customer_id | distance_in_km |
|-------------|----------------|
| 101         | 20.00          |
| 102         | 16.73          |
| 103         | 23.40          |
| 104         | 10.00          |
| 105         | 25.00          |

### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
SELECT 
	MAX(duration) - MIN(duration) AS difference_in_time
FROM clean_runner_orders
WHERE cancellation IS NULL;
```
**Resultado:**
| difference_in_time |
|--------------------|
| 30                 |

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
SELECT 
	runner_id,
	order_id,
	distance,
	duration,
	ROUND(distance/(duration/60.0),2) AS speed_kmh
FROM clean_runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id, order_id;
```
**Resultado:**
| runner_id | order_id | distance | duration | speed_kmh |
|-----------|----------|----------|----------|-----------|
| 1         | 1        | 20       | 32       | 37.50     |
| 1         | 2        | 20       | 27       | 44.44     |
| 1         | 3        | 13.4     | 20       | 40.20     |
| 1         | 10       | 10       | 10       | 60.00     |
| 2         | 4        | 23.4     | 40       | 35.10     |
| 2         | 7        | 25       | 25       | 60.00     |
| 2         | 8        | 23.4     | 15       | 93.60     |
| 3         | 5        | 10       | 15       | 40.00     |


### 7. What is the successful delivery percentage for each runner?
```sql
SELECT
	runner_id,
	COUNT(order_id) AS number_of_orders,
	SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) AS successful_del,
	ROUND(100.0 * SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END)/COUNT(order_id),2) AS percentage
FROM clean_runner_orders
GROUP BY runner_id;
```
**Resultado:**
| runner_id | number_of_orders | successful_del | percentage |
|-----------|------------------|----------------|------------|
| 3         | 2                | 1              | 50.00      |
| 2         | 4                | 3              | 75.00      |
| 1         | 4                | 4              | 100.00     |

---
## 🍪 Sección C: Ingredient Optimisation


### 1. What are the standard ingredients for each pizza?
```sql
WITH recipes_ingredients AS (
	SELECT
		pizza_id,
		UNNEST(STRING_TO_ARRAY(toppings, ',')::INTEGER[]) AS topping_id
	FROM pizza_runner.pizza_recipes
)
SELECT
	pn.pizza_name,
	STRING_AGG(pt.topping_name, ', ' ORDER BY pt.topping_name) AS ingredients
FROM recipes_ingredients AS ri
INNER JOIN pizza_runner.pizza_names AS pn
	ON ri.pizza_id = pn.pizza_id
INNER JOIN pizza_runner.pizza_toppings AS pt
	ON ri.topping_id = pt.topping_id
GROUP BY pn.pizza_name;
```
**Resultado:**
| pizza_name | ingredients                                                           |
|------------|-----------------------------------------------------------------------|
| Meatlovers | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| Vegetarian | Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes            |

### 2. What was the most commonly added extra?
```sql
WITH extras AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(extras,',')::INTEGER[]) AS topping_id
	FROM clean_customer_orders
	WHERE extras IS NOT NULL
)
SELECT 
	extras.topping_id,
	pt.topping_name,
	COUNT(extras.topping_id) AS number_of_times
FROM extras
INNER JOIN pizza_runner.pizza_toppings AS pt
	ON extras.topping_id = pt.topping_id
GROUP BY extras.topping_id, pt.topping_name
ORDER BY COUNT(extras.topping_id) DESC
LIMIT 1;
```
**Resultado:**
| topping_id | topping_name | number_of_times |
|------------|--------------|-----------------|
| 1          | Bacon        | 4               |


### 3. What was the most common exclusion?
```sql
WITH exclusion_toppings AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(exclusions, ',')::INTEGER[]) AS topping_id
	FROM clean_customer_orders
	WHERE exclusions IS NOT NULL
)
SELECT
	et.topping_id,
	pt.topping_name,
	COUNT(et.topping_id) AS number_of_times
FROM exclusion_toppings AS et
INNER JOIN pizza_runner.pizza_toppings AS pt
	ON et.topping_id = pt.topping_id
GROUP BY et.topping_id, pt.topping_name
ORDER BY COUNT(et.topping_id) DESC
LIMIT 1;
```
**Resultado:**
| topping_id | topping_name | number_of_times |
|------------|--------------|-----------------|
| 4          | Cheese       | 4               |


### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
	-Meat Lovers
	-Meat Lovers - Exclude Beef
	-Meat Lovers - Extra Bacon
	-Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
```sql
WITH customer_orders AS (
	SELECT
		order_id,
		customer_id,
		pizza_id,
		exclusions,
		extras,
		order_time,
		ROW_NUMBER() OVER( ORDER BY order_id) AS ids
	FROM clean_customer_orders AS cco
	ORDER BY cco.order_id
),

pizza_names AS (
	SELECT
		co.ids,
		pn.pizza_name
	FROM customer_orders AS co
	INNER JOIN pizza_runner.pizza_names AS pn
		ON co.pizza_id = pn.pizza_id
),

exclusions AS (
	SELECT
		co.ids,
		STRING_AGG(pt.topping_name, ', ' ) AS exclusion_list
	FROM customer_orders AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.exclusions,',')::INTEGER[]) AS t_id
	INNER JOIN pizza_runner.pizza_toppings AS pt
		ON t_id = pt.topping_id
	GROUP BY co.ids
),
extras AS(
	SELECT
		co.ids,
		STRING_AGG(pt.topping_name, ', ' ) AS extras_list
	FROM customer_orders AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.extras,',')::INTEGER[]) AS t_id
	INNER JOIN pizza_runner.pizza_toppings AS pt
		ON t_id = pt.topping_id
	GROUP BY co.ids
)

SELECT 
	co.order_id,
	co.customer_id,
	pn.pizza_name || 
		CASE WHEN e.exclusion_list IS NOT NULL THEN ' - Exclude ' || e.exclusion_list ELSE '' END ||
		CASE WHEN x.extras_list IS NOT NULL THEN ' - Extra ' || x.extras_list ELSE '' END AS order_description
FROM customer_orders AS co
INNER JOIN pizza_names AS pn
	ON co.ids = pn.ids
LEFT JOIN exclusions AS e
	ON co.ids = e.ids
LEFT JOIN extras AS x
	ON co.ids = x.ids
ORDER BY co.ids;
```
**Resultado:**
| order_id | customer_id | order_description                                               |
|----------|-------------|-----------------------------------------------------------------|
| 1        | 101         | Meatlovers                                                      |
| 2        | 101         | Meatlovers                                                      |
| 3        | 102         | Meatlovers                                                      |
| 3        | 102         | Vegetarian                                                      |
| 4        | 103         | Meatlovers - Exclude Cheese                                     |
| 4        | 103         | Meatlovers - Exclude Cheese                                     |
| 4        | 103         | Vegetarian - Exclude Cheese                                     |
| 5        | 104         | Meatlovers - Extra Bacon                                        |
| 6        | 101         | Vegetarian                                                      |
| 7        | 105         | Vegetarian - Extra Bacon                                        |
| 8        | 102         | Meatlovers                                                      |
| 9        | 103         | Meatlovers - Exclude Cheese - Extra Bacon, Chicken              |
| 10       | 104         | Meatlovers                                                      |
| 10       | 104         | Meatlovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
	-For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
```sql
WITH customer_orders AS (
	SELECT
		order_id,
		ROW_NUMBER() OVER( ORDER BY order_id) AS record_id,
		customer_id,
		pizza_id,
		exclusions,
		extras,
		order_time
	FROM clean_customer_orders AS cco
	ORDER BY cco.order_id
),
recipe_list AS (
	SELECT 
		co.record_id,
		recipe.ingredients,
		1 AS quantity
	FROM customer_orders AS co
	INNER JOIN pizza_runner.pizza_recipes AS pr
		ON co.pizza_id = pr.pizza_id
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(pr.toppings,',')::INTEGER[]) AS recipe(ingredients)
),
extras_list AS(
	SELECT
		co.record_id,
		ex.ingredients,
		1 AS quantity
	FROM customer_orders AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.extras,',')::INTEGER[]) AS ex(ingredients)
	
),
exclusions_list AS (
	SELECT
		co.record_id,
		exc.ingredients,
		-1 AS quantity
	FROM customer_orders AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.exclusions,',')::INTEGER[]) AS exc(ingredients)
),
all_ingredients AS (
	SELECT record_id, ingredients, quantity FROM recipe_list
	UNION ALL
	SELECT record_id, ingredients, quantity FROM extras_list
	UNION ALL
	SELECT record_id, ingredients, quantity FROM exclusions_list
),
final_recipes AS (
	SELECT
		record_id,
		ingredients,
		SUM(quantity) AS total_quantity
	FROM all_ingredients
	GROUP BY record_id, ingredients
	HAVING SUM(quantity) > 0
	ORDER BY 1,2
),
order_recipes AS(
	SELECT 
		fr.record_id,
		STRING_AGG(CASE 
			WHEN total_quantity > 1 THEN fr.total_quantity || 'x' || pt.topping_name
			ELSE pt.topping_name END, ', '  ORDER BY pt.topping_name )AS ingredients
	FROM final_recipes AS fr
	INNER JOIN pizza_runner.pizza_toppings AS pt
		ON fr.ingredients = pt.topping_id
	GROUP BY fr.record_id
)

SELECT
	co.order_id,
	co.record_id,
	pn.pizza_name || ': '  || ord_rec.ingredients AS pizza_description
FROM customer_orders AS co
INNER JOIN order_recipes AS ord_rec
	ON co.record_id = ord_rec.record_id
INNER JOIN pizza_runner.pizza_names AS pn
	ON co.pizza_id = pn.pizza_id;
```
**Resultado:**
| order_id | record_id | pizza_description                                                                   |
|----------|-----------|-------------------------------------------------------------------------------------|
| 1        | 1         | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 2        | 2         | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 3        | 3         | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 3        | 4         | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 4        | 5         | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
| 4        | 6         | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami           |
| 4        | 7         | Vegetarian: Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes                      |
| 5        | 8         | Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 6        | 9         | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes              |
| 7        | 10        | Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes       |
| 8        | 11        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 9        | 12        | Meatlovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami       |
| 10       | 13        | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami   |
| 10       | 14        | Meatlovers: 2xBacon, Beef, 2xCheese, Chicken, Pepperoni, Salami                     |


### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
```sql
WITH customer_orders_delivered AS (
	SELECT
		cco.order_id,
		ROW_NUMBER() OVER( ORDER BY cco.order_id) AS record_id,
		cco.pizza_id,
		cco.exclusions,
		cco.extras
	FROM clean_customer_orders AS cco
	INNER JOIN clean_runner_orders AS cro
		ON cco.order_id = cro.order_id
	WHERE cro.cancellation IS NULL
	ORDER BY cco.order_id
	
),
recipe_list AS (
	SELECT 
		co.record_id,
		recipe.ingredients,
		1 AS quantity
	FROM customer_orders_delivered AS co
	INNER JOIN pizza_runner.pizza_recipes AS pr
		ON co.pizza_id = pr.pizza_id
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(pr.toppings,',')::INTEGER[]) AS recipe(ingredients)
),
extras_list AS(
	SELECT
		co.record_id,
		ex.ingredients,
		1 AS quantity
	FROM customer_orders_delivered AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.extras,',')::INTEGER[]) AS ex(ingredients)
	
),
exclusions_list AS (
	SELECT
		co.record_id,
		exc.ingredients,
		-1 AS quantity
	FROM customer_orders_delivered AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.exclusions,',')::INTEGER[]) AS exc(ingredients)
),
all_ingredients AS (
	SELECT record_id, ingredients, quantity FROM recipe_list
	UNION ALL
	SELECT record_id, ingredients, quantity FROM extras_list
	UNION ALL
	SELECT record_id, ingredients, quantity FROM exclusions_list
)

SELECT
	ai.ingredients,
	pt.topping_name,
	SUM(ai.quantity) AS total_quantity
FROM all_ingredients AS ai
INNER JOIN pizza_runner.pizza_toppings AS pt
	ON ai.ingredients = pt.topping_id
GROUP BY ai.ingredients, pt.topping_name
ORDER BY 3 DESC;
```
**Resultado:**
| ingredients | topping_name | total_quantity |
|-------------|--------------|----------------|
| 1           | Bacon        | 12             |
| 6           | Mushrooms    | 11             |
| 4           | Cheese       | 10             |
| 5           | Chicken      | 9              |
| 8           | Pepperoni    | 9              |
| 3           | Beef         | 9              |
| 10          | Salami       | 9              |
| 2           | BBQ Sauce    | 8              |
| 9           | Peppers      | 3              |
| 7           | Onions       | 3              |
| 11          | Tomatoes     | 3              |
| 12          | Tomato Sauce | 3              |
---

## 💰 Sección D: Pricing and Ratings

### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
```sql
SELECT
	SUM(
	CASE 
		WHEN pn.pizza_name = 'Meatlovers' THEN 12
		WHEN pn.pizza_name = 'Vegetarian' THEN 10
		ELSE 0
	END) AS money_made
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
INNER JOIN pizza_runner.pizza_names AS pn
	ON cco.pizza_id = pn.pizza_id
WHERE cro.cancellation IS NULL;
```
**Resultado:**
| money_made |
|------------|
| 138        |

### 2. What if there was an additional $1 charge for any pizza extras?
```sql
WITH base AS (
	SELECT
		cco.order_id,
		ROW_NUMBER () OVER (ORDER BY cco.order_id) AS record_id,
		cco.pizza_id,
		pn.pizza_name,
		cco.extras
	FROM clean_customer_orders AS cco
	INNER JOIN clean_runner_orders AS cro
		ON cco.order_id = cro.order_id
	INNER JOIN pizza_runner.pizza_names AS pn
		ON cco.pizza_id = pn.pizza_id
	WHERE cro.cancellation IS NULL
),
m_extras AS (
	SELECT
		b.record_id,
		SUM(1) AS monto_extras
	FROM base AS b
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(extras,',')::INTEGER[]) AS temp(extras)
	GROUP BY b.record_id
)
SELECT
	SUM(
	CASE 
		WHEN b.pizza_name = 'Meatlovers' THEN 12
		WHEN b.pizza_name = 'Vegetarian' THEN 10
		ELSE 0
	END  + COALESCE(m_extras.monto_extras,0)) AS total
FROM base AS b
LEFT JOIN m_extras
ON b.record_id = m_extras.record_id;
```
**Resultado:**
| total |
|-------|
| 142   |



### The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
```sql
CREATE TABLE pizza_runner.runner_rating (
	"order_id" INTEGER,
	"runner_id" INTEGER,
	"rating" INTEGER CHECK (rating BETWEEN 1 AND 5)
);

INSERT INTO pizza_runner.runner_rating
  ("order_id", "runner_id", "rating")
VALUES
  (1, 1, 5 ),
  (2, 1, 4),
  (3, 1, 3),
  (4, 2, 1),
  (5, 3, 5),
  (7, 2, 3),
  (8, 2, 4),
  (10, 1, 5);
```
**Resultado:**
| order_id | runner_id | rating |
|----------|-----------|--------|
| 1        | 1         | 5      |
| 2        | 1         | 4      |
| 3        | 1         | 3      |
| 4        | 2         | 1      |
| 5        | 3         | 5      |
| 7        | 2         | 3      |
| 8        | 2         | 4      |
| 10       | 1         | 5      |

### 4.Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
	-customer_id
	-order_id
	-runner_id
	-rating
	-order_time
	-pickup_time
	-Time between order and pickup
	-Delivery duration
	-Average speed
	-Total number of pizzas
```sql
SELECT 
	cco.customer_id,
	cco.order_id,
	cro.runner_id,
	rr.rating,
	cco.order_time,
	cro.pickup_time,
	ROUND(EXTRACT(EPOCH FROM cro.pickup_time - cco.order_time)/60,2) AS time_between_order_and_pickup,
	cro.duration AS delivery_duration,
	ROUND(cro.distance/(NULLIF(cro.duration,0)/60.0),2) AS avg_speed,
	COUNT(cco.order_id) AS total_number_of_pizzas
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
LEFT JOIN pizza_runner.runner_rating AS rr
	ON cco.order_id = rr.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.customer_id, cco.order_id, cro.runner_id, rr.rating, cco.order_time, cro.pickup_time, cro.duration, cro.distance
ORDER BY cco.order_id;
```
**Resultado:**
| customer_id | order_id | runner_id | rating | order_time          | pickup_time         | time_between_order_and_pickup | delivery_duration | avg_speed | total_number_of_pizzas |
|-------------|----------|-----------|--------|---------------------|---------------------|-------------------------------|-------------------|-----------|------------------------|
| 101         | 1        | 1         | 5      | 2020-01-01 18:05:02 | 2020-01-01 18:15:34 | 10.53                         | 32                | 37.50     | 1                      |
| 101         | 2        | 1         | 4      | 2020-01-01 19:00:52 | 2020-01-01 19:10:54 | 10.03                         | 27                | 44.44     | 1                      |
| 102         | 3        | 1         | 3      | 2020-01-02 23:51:23 | 2020-01-03 00:12:37 | 21.23                         | 20                | 40.20     | 2                      |
| 103         | 4        | 2         | 1      | 2020-01-04 13:23:46 | 2020-01-04 13:53:03 | 29.28                         | 40                | 35.10     | 3                      |
| 104         | 5        | 3         | 5      | 2020-01-08 21:00:29 | 2020-01-08 21:10:57 | 10.47                         | 15                | 40.00     | 1                      |
| 105         | 7        | 2         | 3      | 2020-01-08 21:20:29 | 2020-01-08 21:30:45 | 10.27                         | 25                | 60.00     | 1                      |
| 102         | 8        | 2         | 4      | 2020-01-09 23:54:33 | 2020-01-10 00:15:02 | 20.48                         | 15                | 93.60     | 1                      |
| 104         | 10       | 1         | 5      | 2020-01-11 18:34:49 | 2020-01-11 18:50:20 | 15.52                         | 10                | 60.00     | 2                      |

### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
```sql
WITH resume AS (
	SELECT 
		cco.order_id,
		COUNT(cco.order_id) AS total_pizzas,
		cro.distance,
		SUM(CASE 
			WHEN pn.pizza_name = 'Meatlovers' THEN 12.0
			WHEN pn.pizza_name = 'Vegetarian' THEN 10.0
			END) AS total_price
	FROM clean_customer_orders AS cco
	INNER JOIN clean_runner_orders AS cro
		ON cco.order_id = cro.order_id
	INNER JOIN pizza_runner.pizza_names AS pn
		ON cco.pizza_id = pn.pizza_id
	WHERE cro.cancellation IS NULL
	GROUP BY cco.order_id, cro.distance
)
SELECT 
	SUM(total_price - (distance * 0.30)) AS earnings
FROM resume
```
**Resultado:**
| earnings |
|----------|
| 94.440   |
---
## 🚀 Sección E: Bonus Challenge
### 1. If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

```sql
INSERT INTO pizza_runner.pizza_names 
	("pizza_id", "pizza_name")
	VALUES (3,'Supreme');

--brigde table
CREATE TABLE pizza_runner.pizza_recipes_relational(
	"pizza_id" INTEGER,
	"topping_id" INTEGER,
	PRIMARY KEY (pizza_id, topping_id)
);
INSERT INTO pizza_runner.pizza_recipes_relational ("pizza_id", "topping_id")
	VALUES 	(3,1),(3,2),(3,3),(3,4),(3,5),(3,6),
			(3,7),(3,8),(3,9),(3,10),(3,11),(3,12);
```
**Resultado:**
| pizza_id | pizza_name |
|----------|------------|
| 1        | Meatlovers |
| 2        | Vegetarian |
| 3        | Supreme    |

| pizza_id | topping_id |
|----------|------------|
| 3        | 1          |
| 3        | 2          |
| 3        | 3          |
| 3        | 4          |
| 3        | 5          |
| 3        | 6          |
| 3        | 7          |
| 3        | 8          |
| 3        | 9          |
| 3        | 10         |
| 3        | 11         |
| 3        | 12         |


---








