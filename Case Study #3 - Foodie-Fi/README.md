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

### 
```sql

```

### 
```sql

```

### 
```sql

```

### 
```sql

```

### 
```sql

```

### 
```sql

```

### 
```sql

```

### 
```sql

```

---

## 💳 Section C: Challenge Payment Question (Dynamic Billing Engine)
This query builds a full ledger simulation for the year 2020 by expanding recurring payments month-by-month and factoring in prorated upgrade logic.

```sql

```

---
