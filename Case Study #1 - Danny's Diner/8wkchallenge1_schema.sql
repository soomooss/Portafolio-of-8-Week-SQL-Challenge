--URL https://8weeksqlchallenge.com/case-study-1/

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT 
	s.customer_id as client, 
	SUM(m.price) as amount_spent
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu  AS m
	ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


-- 2. How many days has each customer visited the restaurant?
SELECT 
	customer_id,
	COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?
WITH ctee AS (SELECT 
		customer_id,
		order_date,
		product_id,
		DENSE_RANK () OVER(
			PARTITION BY customer_id
			ORDER BY order_date
		) AS rank_order
FROM dannys_diner.sales)

SELECT 
	c.customer_id,
	c.order_date,
	m.product_name
FROM ctee AS c
LEFT JOIN dannys_diner.menu AS m
	ON c.product_id = m.product_id
WHERE c.rank_order = 1
GROUP BY c.customer_id,c.order_date,m.product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	s.product_id,
	m.product_name, 
	COUNT(s.product_id) AS number_of_times_sale
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY number_of_times_sale DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
--numero de veces comprado por cada cliente
WITH ctee AS (SELECT 
	customer_id,
	product_id,
	COUNT(product_id) AS number_sales,
	DENSE_RANK() OVER(
		PARTITION BY customer_id
		ORDER BY COUNT(product_id) DESC
	) AS product_rank
FROM dannys_diner.sales AS s
GROUP BY customer_id, product_id)

SELECT 
	c.customer_id,
	c.product_rank,
	c.product_id, 
	m.product_name
FROM ctee AS c
INNER JOIN dannys_diner.menu AS m
	ON c.product_id = m.product_id
WHERE c.product_rank = 1
ORDER BY c.customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
WITH ctee AS (SELECT 
	mem.customer_id,
	mem.join_date,
	s.order_date,
	s.product_id,
	DENSE_RANK () OVER(
		PARTITION BY mem.customer_id
		ORDER BY order_date) 
	AS rank_num
FROM dannys_diner.members AS mem
LEFT JOIN dannys_diner.sales AS s
	ON mem.customer_id = s.customer_id
WHERE mem.join_date <= s.order_date)

SELECT 
	c.customer_id,
	c.join_date,
	c.order_date,
	c.product_id,
	m.product_name
FROM ctee AS c
INNER JOIN dannys_diner.menu AS m
	ON c.product_id = m.product_id
WHERE rank_num = 1;


-- 7. Which item was purchased just before the customer became a member?
WITH ctee AS (SELECT 
	mem.customer_id,
	mem.join_date,
	s.order_date,
	s.product_id,
	DENSE_RANK () OVER(
		PARTITION BY mem.customer_id
		ORDER BY order_date DESC) 
	AS rank_num
FROM dannys_diner.members AS mem
LEFT JOIN dannys_diner.sales AS s
	ON mem.customer_id = s.customer_id
WHERE mem.join_date > s.order_date)

SELECT 
	c.customer_id,
	c.join_date,
	c.order_date,
	c.product_id,
	m.product_name
FROM ctee AS c
INNER JOIN dannys_diner.menu AS m
	ON c.product_id = m.product_id
WHERE rank_num = 1
ORDER BY c.customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
	mem.customer_id,
	COUNT(s.product_id) AS total_items,
	SUM(m.price) AS total_spent
FROM dannys_diner.members AS mem
LEFT JOIN dannys_diner.sales AS s
	ON mem.customer_id = s.customer_id
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
WHERE mem.join_date > s.order_date
GROUP BY mem.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
--cada 1 dolar son diez puntos
--por cada comprar de sushi se multiplica por 20 

SELECT 
	s.customer_id,
	SUM(CASE WHEN m.product_name = 'sushi' THEN m.price * 20 ELSE m.price * 10 END) AS points
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1;



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?

--la primera semana cuando se dieron de alta los clientes obtuvieron 20 por cada dolar en todos los items y despues lo normal 
--cuantos puntos tuvieron los cliente A y B al final de enero

SELECT 
	mem.customer_id,
	SUM(
		CASE WHEN s.order_date >= mem.join_date AND s.order_date <= mem.join_date + 6 THEN m.price * 20 
		WHEN m.product_name = 'sushi' THEN m.price * 20 
		ELSE m.price * 10 END) AS january_points
FROM dannys_diner.members AS mem
LEFT JOIN dannys_diner.sales AS s
	ON mem.customer_id = s.customer_id
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
WHERE order_date <= '2021-01-31'
GROUP BY mem.customer_id
ORDER BY 1;

--Bonus questions
--Join All The Things
--Poner si en la fecha de la compra era miembro o no, si no esta en el de members poner no
SELECT 
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	CASE 
		WHEN s.order_date >= mem.join_date AND mem.join_date IS NOT NULL THEN 'Y' ELSE 'N' END AS member
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members AS mem
	ON s.customer_id = mem.customer_id;


--Rank All The Things
--por un ranking a los items por cliente desde que se hicieron miembros el ranking es para ver
--cuando hicieron la compra

WITH ctee AS (SELECT 
	s.customer_id,
	s.order_date,
	m.product_name,
	m.price,
	CASE 
		WHEN s.order_date >= mem.join_date AND mem.join_date IS NOT NULL THEN 'Y' ELSE 'N' END AS member
FROM dannys_diner.sales AS s
INNER JOIN dannys_diner.menu AS m
	ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members AS mem
	ON s.customer_id = mem.customer_id)

SELECT 
*,
	CASE WHEN member = 'Y' 
		THEN 
			DENSE_RANK() OVER(
				PARTITION BY customer_id,member
				ORDER BY order_date
			)
		ELSE NULL
		END AS ranking
FROM ctee;



