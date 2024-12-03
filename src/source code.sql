-- Retrieve the total number of orders placed
SELECT 
    COUNT(orders.order_id) AS total_orders
FROM
    pizzahut.orders
;

-- Calculate the total revenue generated from pizza sales

SELECT 
    SUM(ord_dt.quantity * price) AS revenue
FROM
    pizzahut.order_details AS ord_dt
        INNER JOIN
    pizzahut.pizzas AS piz ON ord_dt.pizza_id = piz.pizza_id;

-- Identify the highest-priced pizza

SELECT 
    pizza_types.name, pizzas.price
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY price DESC
LIMIT 1;

-- Identify the most common pizza size ordered

SELECT 
    size, SUM(quantity)
FROM
    pizzahut.pizzas
        JOIN
    pizzahut.order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY size
ORDER BY SUM(quantity) DESC
LIMIT 1;

-- List the top 5 most ordered pizza types along with their quantities

SELECT 
    name, SUM(quantity) AS total_orders
FROM
    pizzahut.order_details
        JOIN
    pizzahut.pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizzahut.pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY name
ORDER BY SUM(quantity) DESC
LIMIT 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered

SELECT 
    category, SUM(quantity) AS total_orders
FROM
    pizzahut.order_details
        JOIN
    pizzahut.pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizzahut.pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY category
ORDER BY SUM(quantity);

-- Determine the distribution of orders by hour of the day

SELECT 
    HOUR(order_time), COUNT(order_id)
FROM
    orders
GROUP BY HOUR(order_time);

-- Join relevant tables to find the category-wise distribution of pizzas

SELECT 
    category, COUNT(name)
FROM
    pizzahut.pizza_types
GROUP BY category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.

SELECT 
    ROUND(AVG(total_orders), 0) as avg_pizza_ordered
FROM
    (SELECT 
        (order_date), SUM(quantity) AS total_orders
    FROM
        pizzahut.orders
    JOIN pizzahut.order_details ON orders.order_id = order_details.order_id
    GROUP BY (order_date)) AS quantity_ordered;

-- Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    name, SUM(quantity * price) AS revenue
FROM
    pizzahut.order_details
        JOIN
    pizzahut.pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY name
ORDER BY revenue DESC
LIMIT 3;