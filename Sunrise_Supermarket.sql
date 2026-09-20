--==== TABLE CREATION AND INSERTION OF SAMPLE DATA

-- Create customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(50)
);

INSERT INTO customers VALUES
(1, 'John Smith', 'john@gmail.com', 'Kigali'),
(2, 'Alice Brown', 'alice@gmail.com', 'Musanze'),
(3, 'David Lee', 'david@gmail.com', 'Huye'),
(4, 'Sarah Jones', 'sarah@gmail.com', 'Rubavu'),
(5, 'Michael King', 'michael@gmail.com', 'Kigali'),
(6, 'Emma Wilson', 'emma@gmail.com', 'Muhanga'),
(7, 'Daniel Young', 'daniel@gmail.com', 'Kigali'),
(8, 'Grace Miller', 'grace@gmail.com', 'Nyagatare');



-- Create products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2)
);

-- Insert products
INSERT INTO products VALUES
(1, 'Laptop', 'Electronics', 800.00),
(2, 'Smartphone', 'Electronics', 500.00),
(3, 'Headphones', 'Accessories', 100.00),
(4, 'Keyboard', 'Accessories', 50.00),
(5, 'Mouse', 'Accessories', 30.00),
(6, 'Monitor', 'Electronics', 300.00),
(7, 'Tablet', 'Electronics', 400.00),
(8, 'USB Cable', 'Accessories', 20.00);



-- Create orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date DATE
);

-- Insert orders
INSERT INTO orders VALUES
(101, 1, '2026-01-05'),
(102, 2, '2026-01-10'),
(103, 1, '2026-01-20'),
(104, 3, '2026-02-01'),
(105, 4, '2026-02-10'),
(106, 2, '2026-02-20'),
(107, 1, '2026-03-05'),
(108, 5, '2026-03-15'),
(109, 3, '2026-03-25'),
(110, 6, '2026-04-05'),
(111, 2, '2026-04-15'),
(112, 1, '2026-05-01');



-- Create order items table
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT
);

-- Insert order items
INSERT INTO order_items VALUES
(1, 101, 1, 1),
(2, 101, 3, 2),
(3, 102, 2, 1),
(4, 102, 5, 2),
(5, 103, 6, 1),
(6, 103, 4, 2),
(7, 104, 7, 1),
(8, 104, 8, 3),
(9, 105, 2, 1),
(10, 105, 3, 1),
(11, 106, 1, 1),
(12, 106, 5, 1),
(13, 107, 7, 1),
(14, 107, 3, 2),
(15, 108, 6, 2),
(16, 108, 8, 2),
(17, 109, 1, 1),
(18, 109, 4, 1),
(19, 110, 2, 1),
(20, 110, 5, 3),
(21, 111, 7, 1),
(22, 111, 8, 2),
(23, 112, 1, 1),
(24, 112, 6, 1);



--==== JOIN ====

--(1) List every order with customer name, city, and order date
SELECT orders.order_id, customers.customer_name, customers.city, orders.order_date
FROM orders
INNER JOIN customers ON orders.customer_id = customers.customer_id;

--(2) List every order item with product details
SELECT order_items.order_item_id, products.product_name, products.category, 
products.price, order_items.quantity
FROM order_items
INNER JOIN products ON order_items.product_id = products.product_id;

--(3) List all customers including customers with no orders
SELECT customers.customer_id, customers.customer_name, 
customers.city, orders.order_id, orders.order_date
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id;


--==== CTE ====

-- Find customers whose total spending is above average
WITH customer_totals AS (
    SELECT
        customers.customer_id,
        customers.customer_name,
        SUM(order_items.quantity * products.price) AS total_spend
    FROM customers
    INNER JOIN orders
        ON customers.customer_id = orders.customer_id
    INNER JOIN order_items
        ON orders.order_id = order_items.order_id
    INNER JOIN products
        ON order_items.product_id = products.product_id
    GROUP BY
        customers.customer_id,
        customers.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_spend
FROM customer_totals
WHERE total_spend > (
    SELECT AVG(total_spend)
    FROM customer_totals
)
ORDER BY total_spend DESC;


--==== WINDOW FUNCTION QUERY ====


--(1) Rank customers by total amount spent
WITH customer_totals AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * p.price) AS total_spent
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_spent,
    RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM customer_totals
ORDER BY spending_rank;


--(2) Number each customer's orders
SELECT
    customer_id,
    order_id,
    order_date,
    ROW_NUMBER() OVER (
        PARTITION BY customer_id
        ORDER BY order_date
    ) AS order_number
FROM orders
ORDER BY customer_id, order_number;


--(3) Show running total of revenue
WITH order_revenue AS (
    SELECT
        o.order_id,
        o.order_date,
        SUM(oi.quantity * p.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.order_id, o.order_date
)
SELECT
    order_id,
    order_date,
    revenue,
    SUM(revenue) OVER (
        ORDER BY order_date
    ) AS running_total
FROM order_revenue
ORDER BY order_date;


--(4) Show days between current and previous order
WITH customer_orders AS (
    SELECT
        customer_id,
        order_id,
        order_date,
        LAG(order_date) OVER (
            PARTITION BY customer_id
            ORDER BY order_date
        ) AS previous_order_date
    FROM orders
)
SELECT
    customer_id,
    order_id,
    order_date,
    previous_order_date,
    order_date - previous_order_date AS days_between
FROM customer_orders
WHERE previous_order_date IS NOT NULL
ORDER BY customer_id, order_date;