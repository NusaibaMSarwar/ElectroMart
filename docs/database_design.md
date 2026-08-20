# ElectroMart Database Design

## Database Technology

- Database: PostgreSQL
- Backend Framework: Django
- Database Name: `electromart_db`

## Main Entities

### Category

| Field | Type | Description |
|---|---|---|
| id | Primary Key | Unique category ID |
| name | String | Category name |
| slug | String | Unique URL-friendly name |
| description | Text | Category details |
| created_at | DateTime | Creation time |

### Product

| Field | Type | Description |
|---|---|---|
| id | Primary Key | Unique product ID |
| category_id | Foreign Key | References Category |
| name | String | Product name |
| slug | String | Unique URL-friendly name |
| brand | String | Product brand |
| description | Text | Product details |
| price | Decimal | Product price |
| stock | Integer | Available quantity |
| image | Image | Product image |
| rating | Decimal | Product rating |
| is_available | Boolean | Product availability |
| created_at | DateTime | Creation time |
| updated_at | DateTime | Last update time |

### CartItem

| Field | Type | Description |
|---|---|---|
| id | Primary Key | Unique cart item ID |
| user_id | Foreign Key | References User |
| product_id | Foreign Key | References Product |
| quantity | Integer | Product quantity |
| added_at | DateTime | Added time |

### WishlistItem

| Field | Type | Description |
|---|---|---|
| id | Primary Key | Unique wishlist item ID |
| user_id | Foreign Key | References User |
| product_id | Foreign Key | References Product |
| added_at | DateTime | Added time |

### Order

| Field | Type | Description |
|---|---|---|
| id | Primary Key | Unique order ID |
| user_id | Foreign Key | References User |
| full_name | String | Customer name |
| phone | String | Customer phone |
| address | Text | Shipping address |
| payment_method | String | Cash on Delivery |
| status | String | Pending, Processing, Shipped, or Delivered |
| total_amount | Decimal | Total order value |
| ordered_at | DateTime | Order time |
| updated_at | DateTime | Last update time |

### OrderItem

| Field | Type | Description |
|---|---|---|
| id | Primary Key | Unique order item ID |
| order_id | Foreign Key | References Order |
| product_id | Foreign Key | References Product |
| product_name | String | Product name at order time |
| price | Decimal | Product price at order time |
| quantity | Integer | Ordered quantity |

### Review

| Field | Type | Description |
|---|---|---|
| id | Primary Key | Unique review ID |
| user_id | Foreign Key | References User |
| product_id | Foreign Key | References Product |
| rating | Integer | Star rating |
| comment | Text | Customer review |
| created_at | DateTime | Review time |
| updated_at | DateTime | Last update time |

## Entity Relationships

```text
Category 1 --- Many Product
User 1 --- Many CartItem
Product 1 --- Many CartItem
User 1 --- Many WishlistItem
Product 1 --- Many WishlistItem
User 1 --- Many Order
Order 1 --- Many OrderItem
Product 1 --- Many OrderItem
User 1 --- Many Review
Product 1 --- Many Review

```

## Database Rules

- Category names and slugs must be unique.
- Product slugs must be unique.
- A user can add the same product only once to the cart; quantity will be updated.
- A user can add the same product only once to the wishlist.
- Order status follows: Pending -> Processing -> Shipped -> Delivered.
- OrderItem saves product name and price to preserve invoice history.
- Products with existing orders cannot be deleted.
- Only verified buyers with delivered orders should be allowed to submit reviews.

## Database Testing

The Product-Category relationship was tested successfully using PostgreSQL Query Tool.

```sql
SELECT
    p.name AS product_name,
    c.name AS category_name,
    p.brand,
    p.price,
    p.stock
FROM products_product AS p
JOIN products_category AS c
    ON p.category_id = c.id;
```