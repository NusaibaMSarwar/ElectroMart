-- Show all categories
SELECT * FROM products_category;

-- Show all products
SELECT * FROM products_product;

-- Test Product-Category foreign key relationship
SELECT
    p.name AS product_name,
    c.name AS category_name,
    p.brand,
    p.price,
    p.stock
FROM products_product AS p
JOIN products_category AS c
    ON p.category_id = c.id;

-- Show available products only
SELECT
    name,
    brand,
    price,
    stock,
    rating
FROM products_product
WHERE is_available = TRUE;

-- Show products with low stock
SELECT
    name,
    stock
FROM products_product
WHERE stock < 10;