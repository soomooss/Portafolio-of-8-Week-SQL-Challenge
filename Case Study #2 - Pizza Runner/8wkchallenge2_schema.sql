--URL https://8weeksqlchallenge.com/case-study-2/

CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, 2021-01-01),
  (2, 2021-01-03),
  (3, 2021-01-08),
  (4, 2021-01-15);


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  (1, 101, 1, , , 2020-01-01 18:05:02),
  (2, 101, 1, , , 2020-01-01 19:00:52),
  (3, 102, 1, , , 2020-01-02 23:51:23),
  (3, 102, 2, , NULL, 2020-01-02 23:51:23),
  (4, 103, 1, 4, , 2020-01-04 13:23:46),
  (4, 103, 1, 4, , 2020-01-04 13:23:46),
  (4, 103, 2, 4, , 2020-01-04 13:23:46),
  (5, 104, 1, null, 1, 2020-01-08 21:00:29),
  (6, 101, 2, null, null, 2020-01-08 21:03:13),
  (7, 105, 2, null, 1, 2020-01-08 21:20:29),
  (8, 102, 1, null, null, 2020-01-09 23:54:33),
  (9, 103, 1, 4, 1, 5, 2020-01-10 11:22:59),
  (10, 104, 1, null, null, 2020-01-11 18:34:49),
  (10, 104, 1, 2, 6, 1, 4, 2020-01-11 18:34:49);


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  (1, 1, 2020-01-01 18:15:34, 20km, 32 minutes, ),
  (2, 1, 2020-01-01 19:10:54, 20km, 27 minutes, ),
  (3, 1, 2020-01-03 00:12:37, 13.4km, 20 mins, NULL),
  (4, 2, 2020-01-04 13:53:03, 23.4, 40, NULL),
  (5, 3, 2020-01-08 21:10:57, 10, 15, NULL),
  (6, 3, null, null, null, Restaurant Cancellation),
  (7, 2, 2020-01-08 21:30:45, 25km, 25mins, null),
  (8, 2, 2020-01-10 00:15:02, 23.4 km, 15 minute, null),
  (9, 2, null, null, null, Customer Cancellation),
  (10, 1, 2020-01-11 18:50:20, 10km, 10minutes, null);


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, Meatlovers),
  (2, Vegetarian);


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, 1, 2, 3, 4, 5, 6, 8, 10),
  (2, 4, 6, 7, 9, 11, 12);


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, Bacon),
  (2, BBQ Sauce),
  (3, Beef),
  (4, Cheese),
  (5, Chicken),
  (6, Mushrooms),
  (7, Onions),
  (8, Pepperoni),
  (9, Peppers),
  (10, Salami),
  (11, Tomatoes),
  (12, Tomato Sauce);

/*Before you start writing your SQL queries however - you might want to investigate the data, you may want to do something with 
some of those null values and data types in the customer_orders and runner_orders tables!
 Data cleaning with temporary tables
	--customer_orders
	--runner_orders*/

CREATE TEMP TABLE clean_customer_orders AS
	SELECT
		order_id,
		customer_id,
		pizza_id,
		CASE WHEN exclusions =  OR exclusions = null THEN NULL ELSE exclusions END AS exclusions,
		CASE WHEN extras =  OR extras = null THEN NULL ELSE extras END AS extras,
		order_time
	FROM pizza_runner.customer_orders;


CREATE TEMP TABLE clean_runner_orders AS
	SELECT
		order_id,
		runner_id,
		CASE WHEN pickup_time = null OR pickup_time =  THEN NULL ELSE pickup_time END::TIMESTAMP AS pickup_time,
		CASE WHEN distance = null OR distance =  THEN NULL ELSE TRIM(REPLACE(distance,km,)) END:: NUMERIC AS distance,
		CASE WHEN duration = null OR duration =  THEN NULL ELSE TRIM(REPLACE(REPLACE(REPLACE(duration,minutes,),minute,),mins,)) END::INTEGER AS duration,
		CASE WHEN cancellation = null OR cancellation =  THEN NULL ELSE  cancellation END AS cancellation
	FROM pizza_runner.runner_orders;


--A. Pizza Metrics
--1 How many pizzas were ordered?
SELECT 
	COUNT(order_id) AS pizzas_ordered
FROM clean_customer_orders;

--2 How many unique customer orders were made?
SELECT 
	COUNT(DISTINCT order_id) AS customer_orders
FROM clean_customer_orders;

--3 How many successful orders were delivered by each runner?
SELECT 
	runner_id,
	COUNT(order_id) AS deliveries
FROM clean_runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

--4 How many of each type of pizza was delivered?
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


--5 How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
	cco.customer_id,
	pn.pizza_name,
	COUNT(cco.pizza_id) AS number_of_pizzas
FROM clean_customer_orders AS cco
INNER JOIN pizza_runner.pizza_names AS pn
	ON cco.pizza_id = pn.pizza_id
GROUP BY cco.customer_id, pn.pizza_name
ORDER BY cco.customer_id;

--6 What was the maximum number of pizzas delivered in a single order?
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


--7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
	cco.customer_id,
	SUM( CASE WHEN cco.exclusions IS NULL AND cco.extras IS NULL THEN 1 ELSE 0 END) AS sin_cambios,
	SUM( CASE WHEN cco.exclusions IS NOT NULL OR cco.extras IS NOT NULL THEN 1 ELSE 0 END) AS con_cambios
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY cco.customer_id;

--8 How many pizzas were delivered that had both exclusions and extras?
SELECT 
	COUNT(cco.pizza_id) AS pizzas_with_exclusions_and_extras
FROM clean_customer_orders AS cco
INNER JOIN pizza_runner.pizza_names AS pn
	ON cco.pizza_id = pn.pizza_id
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL AND cco.exclusions IS NOT NULL AND cco.extras IS NOT NULL;


--9 What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	order_time::DATE AS day,
	EXTRACT(HOUR FROM order_time) AS hour_of_the_day,
	COUNT(pizza_id) AS number_of_pizzas
FROM clean_customer_orders
GROUP BY order_time::DATE, EXTRACT(HOUR FROM order_time)
ORDER BY order_time::DATE,EXTRACT(HOUR FROM order_time);

--10 What was the volume of orders for each day of the week?
SELECT 
	TO_CHAR(order_time, Day) AS day_of_the_week,
	COUNT(pizza_id) AS total_pizzas_ordered
FROM clean_customer_orders
GROUP BY TO_CHAR(order_time, Day),EXTRACT(DOW FROM order_time)
ORDER BY EXTRACT(DOW FROM order_time);


--B. Runner and Customer Experience

--1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
WITH week_calculation AS (
	SELECT 
		runner_id,
		(DATE_TRUNC(week,registration_date + INTERVAL 3 days) - INTERVAL 3 days)::DATE AS start_week
	FROM pizza_runner.runners),
ranked_weeks AS (
	SELECT
		runner_id,
		start_week,
		DENSE_RANK() OVER( ORDER BY start_week) AS week_num
	FROM week_calculation
)
SELECT 
	wk || week_num AS registration_week,
	COUNT(runner_id) AS runner_signups
FROM ranked_weeks
GROUP BY week_num, registration_week
ORDER BY week_num;

--2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT 
	cro.runner_id ,
	ROUND(AVG( EXTRACT(EPOCH FROM cro.pickup_time - cco.order_time )/60),2) AS avg_time_to_arrive_in_HQ
	FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY 1;

--3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
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

--4 What was the average distance travelled for each customer?
SELECT 
	customer_id, 
	ROUND(AVG(distance),2) AS distance_in_km
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
WHERE cro.cancellation IS NULL
GROUP BY customer_id;

--5 What was the difference between the longest and shortest delivery times for all orders?
SELECT 
	MAX(duration) - MIN(duration) AS difference_in_time
FROM clean_runner_orders
WHERE cancellation IS NULL;

--6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
	runner_id,
	order_id,
	distance,
	duration,
	ROUND(distance/(duration/60.0),2) AS speed_kmh
FROM clean_runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id, order_id;


--7 What is the successful delivery percentage for each runner?
SELECT
	runner_id,
	COUNT(order_id) AS number_of_orders,
	SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) AS successful_del,
	ROUND(100.0 * SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END)/COUNT(order_id),2) AS percentage
FROM clean_runner_orders
GROUP BY runner_id;


--C. Ingredient Optimisation

--1 What are the standard ingredients for each pizza?
WITH recipes_ingredients AS (
	SELECT
		pizza_id,
		UNNEST(STRING_TO_ARRAY(toppings, ,)::INTEGER[]) AS topping_id
	FROM pizza_runner.pizza_recipes
)
SELECT
	pn.pizza_name,
	STRING_AGG(pt.topping_name, ,  ORDER BY pt.topping_name) AS ingredients
FROM recipes_ingredients AS ri
INNER JOIN pizza_runner.pizza_names AS pn
	ON ri.pizza_id = pn.pizza_id
INNER JOIN pizza_runner.pizza_toppings AS pt
	ON ri.topping_id = pt.topping_id
GROUP BY pn.pizza_name;

--2 What was the most commonly added extra?
WITH extras AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(extras,,)::INTEGER[]) AS topping_id
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



--3 What was the most common exclusion?
WITH exclusion_toppings AS (
	SELECT
		UNNEST(STRING_TO_ARRAY(exclusions, ,)::INTEGER[]) AS topping_id
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

	
/*4 Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/

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
		STRING_AGG(pt.topping_name, , ) AS exclusion_list
	FROM customer_orders AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.exclusions,,)::INTEGER[]) AS t_id
	INNER JOIN pizza_runner.pizza_toppings AS pt
		ON t_id = pt.topping_id
	GROUP BY co.ids
),
extras AS(
	SELECT
		co.ids,
		STRING_AGG(pt.topping_name, , ) AS extras_list
	FROM customer_orders AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.extras,,)::INTEGER[]) AS t_id
	INNER JOIN pizza_runner.pizza_toppings AS pt
		ON t_id = pt.topping_id
	GROUP BY co.ids
)

SELECT 
	co.order_id,
	co.customer_id,
	pn.pizza_name || 
		CASE WHEN e.exclusion_list IS NOT NULL THEN  - Exclude  || e.exclusion_list ELSE  END ||
		CASE WHEN x.extras_list IS NOT NULL THEN  - Extra  || x.extras_list ELSE  END AS order_description
FROM customer_orders AS co
INNER JOIN pizza_names AS pn
	ON co.ids = pn.ids
LEFT JOIN exclusions AS e
	ON co.ids = e.ids
LEFT JOIN extras AS x
	ON co.ids = x.ids
ORDER BY co.ids;

--5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

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
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(pr.toppings,,)::INTEGER[]) AS recipe(ingredients)
),
extras_list AS(
	SELECT
		co.record_id,
		ex.ingredients,
		1 AS quantity
	FROM customer_orders AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.extras,,)::INTEGER[]) AS ex(ingredients)
	
),
exclusions_list AS (
	SELECT
		co.record_id,
		exc.ingredients,
		-1 AS quantity
	FROM customer_orders AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.exclusions,,)::INTEGER[]) AS exc(ingredients)
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
			WHEN total_quantity > 1 THEN fr.total_quantity || x || pt.topping_name
			ELSE pt.topping_name END, ,  ORDER BY pt.topping_name )AS ingredients
	FROM final_recipes AS fr
	INNER JOIN pizza_runner.pizza_toppings AS pt
		ON fr.ingredients = pt.topping_id
	GROUP BY fr.record_id
)

SELECT
	co.order_id,
	co.record_id,
	pn.pizza_name || :  || ord_rec.ingredients
FROM customer_orders AS co
INNER JOIN order_recipes AS ord_rec
	ON co.record_id = ord_rec.record_id
INNER JOIN pizza_runner.pizza_names AS pn
	ON co.pizza_id = pn.pizza_id;

--6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

WITH customer_orders_delivered AS (
	SELECT
		cco.order_id,
		ROW_NUMBER() OVER( ORDER BY order_id) AS record_id,
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
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(pr.toppings,,)::INTEGER[]) AS recipe(ingredients)
),
extras_list AS(
	SELECT
		co.record_id,
		ex.ingredients,
		1 AS quantity
	FROM customer_orders_delivered AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.extras,,)::INTEGER[]) AS ex(ingredients)
	
),
exclusions_list AS (
	SELECT
		co.record_id,
		exc.ingredients,
		-1 AS quantity
	FROM customer_orders_delivered AS co
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(co.exclusions,,)::INTEGER[]) AS exc(ingredients)
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





--D. Pricing and Ratings
--1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

SELECT
	SUM(
	CASE 
		WHEN pn.pizza_name = Meatlovers THEN 12
		WHEN pn.pizza_name = Vegetarian THEN 10
		ELSE 0
	END) AS money_made
FROM clean_customer_orders AS cco
INNER JOIN clean_runner_orders AS cro
	ON cco.order_id = cro.order_id
INNER JOIN pizza_runner.pizza_names AS pn
	ON cco.pizza_id = pn.pizza_id
WHERE cro.cancellation IS NULL


--2 What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra

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
	CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(extras,,)::INTEGER[]) AS temp(extras)
	GROUP BY b.record_id
)
SELECT
	SUM(
	CASE 
		WHEN b.pizza_name = Meatlovers THEN 12
		WHEN b.pizza_name = Vegetarian THEN 10
		ELSE 0
	END  + COALESCE(m_extras.monto_extras,0)) AS total
FROM base AS b
LEFT JOIN m_extras
ON b.record_id = m_extras.record_id

/* 3
The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset 
- generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
*/

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


/*4
Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
	customer_id
	order_id
	runner_id
	rating
	order_time
	pickup_time
	Time between order and pickup
	Delivery duration
	Average speed
	Total number of pizzas
*/

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


/* 5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
- how much money does Pizza Runner have left over after these deliveries?*/
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

/*
E. Bonus Questions
If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
*/

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
	
SELECT *
FROM pizza_runner.pizza_names;

SELECT *
FROM pizza_runner.pizza_recipes_relational;










