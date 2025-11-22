/* ============================================================================
   PROJECT: Magist Marketplace Analysis for Eniac
   FILE   : magist_market_analysis.sql
   AUTHOR : (your name)
   NOTES  : Core analysis queries for orders, catalogue, pricing, tech segment,
            delivery performance, and review scores.
   ============================================================================ */


/* ============================================================================
   4.1 Order Volume and Growth Trends
   Query: Overview of Order Volume and Time Span
   Purpose:
     - Count total number of orders in the Magist marketplace dataset
     - Identify the earliest and latest purchase timestamps
     - Establish the time range of available data
   ============================================================================ */

SELECT
    COUNT(*) AS total_orders,                           -- Total number of orders
    MIN(order_purchase_timestamp) AS first_order_date,  -- First recorded order
    MAX(order_purchase_timestamp) AS last_order_date    -- Last recorded order
FROM orders;


/* ============================================================================
   4.1 Order Volume and Growth Trends
   Query: Monthly Order Volume (Growth Trend Analysis)
   Purpose:
     - Count the number of orders per month
     - Identify growth patterns across 2017 and 2018
     - Provide data for visualising order trends over time
   ============================================================================ */

SELECT
    YEAR(order_purchase_timestamp)  AS year,          -- Year component
    MONTH(order_purchase_timestamp) AS month_number,  -- Month (1–12)
    COUNT(order_id)                 AS orders_in_month
FROM orders
GROUP BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp)
ORDER BY
    YEAR(order_purchase_timestamp),
    MONTH(order_purchase_timestamp);


/* ============================================================================
   4.1 Yearly Revenue (Realised Sales)
   Query: Total Revenue per Year
   Purpose:
     - Calculate the sum of all payments for delivered orders
     - Measure annual revenue levels for Magist
     - Provide revenue data for Eniac’s market assessment (2017–2018)
   ============================================================================ */

SELECT
    YEAR(o.order_purchase_timestamp) AS year,
    ROUND(SUM(op.payment_value), 2)  AS total_revenue
FROM orders AS o
JOIN order_payments AS op
    ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'  -- Only completed orders
GROUP BY
    YEAR(o.order_purchase_timestamp)
ORDER BY
    year;


/* ============================================================================
   4.2 Product Catalogue and Category Diversity
   Query Block: Product Catalogue and Category Diversity
   Purpose:
     - Count how many unique products exist on Magist
     - Identify which categories have the largest number of products
   ============================================================================ */

-- 1) Total number of unique products in the catalogue
SELECT 
    COUNT(DISTINCT product_id) AS total_unique_products
FROM products;

-- 2) Number of products per category (top categories by catalogue size)
SELECT
    p.product_category_name         AS category_pt,  -- Original (Portuguese)
    t.product_category_name_english AS category_en,  -- Translated (English)
    COUNT(p.product_id)             AS number_of_products
FROM products AS p
LEFT JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
GROUP BY
    p.product_category_name,
    t.product_category_name_english
ORDER BY
    number_of_products DESC
LIMIT 20;


/* ============================================================================
   4.3 Price and Payment Structure
   Query Block: Price and Payment Structure
   Purpose:
     - Describe the price range of products sold on Magist
     - Describe the range of payment values per transaction
     - Identify the highest-value order on the platform
   ============================================================================ */

-- 1) Price range of individual items (per order line)
SELECT
    MIN(price) AS cheapest_item_price,
    MAX(price) AS most_expensive_item_price
FROM order_items;

-- 2) Range of individual payment records
--    (one row per payment fragment; some orders have multiple payments)
SELECT
    MIN(payment_value) AS smallest_payment_value,
    MAX(payment_value) AS largest_payment_value
FROM order_payments;

-- 3) Highest total payment for a single order
--    (summing all payment fragments belonging to the same order)
SELECT
    order_id,
    SUM(payment_value) AS total_order_payment
FROM order_payments
GROUP BY
    order_id
ORDER BY
    total_order_payment DESC
LIMIT 1;


/* ============================================================================
   5.0(a) Category Price Profile Analysis (Initial Tech Categories)
   Purpose:
     - Compare the price structure of all initial tech-related categories
     - Identify which categories contain low-, mid-, and high-value items
     - Provide objective justification for the refined tech segment
   Categories initially considered:
     'computers', 'computers_accessories', 'electronics', 'audio', 'telephony'
   ============================================================================ */

WITH tech_items AS (
    SELECT
        oi.order_item_id,
        oi.price,
        t.product_category_name_english AS category
    FROM order_items AS oi
    JOIN products AS p
        ON oi.product_id = p.product_id
    JOIN product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE t.product_category_name_english IN (
        'computers',
        'computers_accessories',
        'electronics',
        'audio',
        'telephony'
    )
),

price_profile AS (
    SELECT
        category,
        COUNT(*) AS total_items,

        -- Low-value segment
        SUM(price < 50) AS low_range,
        ROUND(100 * SUM(price < 50) / COUNT(*), 2) AS pct_low_range,

        -- Mid-value segment
        SUM(price >= 50 AND price < 100) AS mid_range,
        ROUND(100 * SUM(price >= 50 AND price < 100) / COUNT(*), 2) AS pct_mid_range,

        -- Premium segment (>= 100)
        SUM(price >= 100) AS premium,
        ROUND(100 * SUM(price >= 100) / COUNT(*), 2) AS pct_premium
    FROM tech_items
    GROUP BY
        category
)

SELECT *
FROM price_profile
ORDER BY total_items DESC;


/* ============================================================================
   5.0(b) Price Levels of Tech Products (Refined Tech Segment)
   Refined tech segment:
     - Categories: computers, computers_accessories, electronics, audio, telephony
     - Price threshold: price >= 100
   Purpose:
     - Evaluate whether items in the refined tech segment reflect premium pricing
   ============================================================================ */

WITH refined_tech_items AS (
    SELECT
        t.product_category_name_english AS category,
        oi.price
    FROM order_items AS oi
    JOIN products AS p
        ON oi.product_id = p.product_id
    JOIN product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE 
        t.product_category_name_english IN (
            'computers',
            'computers_accessories',
            'electronics',
            'audio',
            'telephony'
        )
        AND oi.price >= 100
)

SELECT
    category,
    COUNT(*)             AS total_items,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(MIN(price), 2) AS min_price,
    ROUND(MAX(price), 2) AS max_price
FROM refined_tech_items
GROUP BY
    category
ORDER BY
    avg_price DESC;


/* ============================================================================
   5.1 Tech Market Share (overall)
   Refined tech segment:
     - Categories: computers, computers_accessories, electronics, audio, telephony
     - Price threshold: price >= 100
   Purpose:
     - Measure how large the refined tech segment is relative to all items sold
   ============================================================================ */

SELECT 
    ROUND(
        100.0 * SUM(
            CASE
                WHEN 
                    t.product_category_name_english IN (
                        'computers',
                        'computers_accessories',
                        'electronics',
                        'audio',
                        'telephony'
                    )
                    AND oi.price >= 100
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS pct_refined_tech_items_overall
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name;


/* ============================================================================
   5.1 Tech Market Share (monthly)
   Refined tech segment:
     - Categories: computers, computers_accessories, electronics, audio, telephony
     - Price threshold: price >= 100
   Produces a time series for Tableau or other visualisation tools.
   ============================================================================ */

SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(*)                                         AS total_items_sold,
    SUM(
        CASE
            WHEN 
                t.product_category_name_english IN (
                    'computers',
                    'computers_accessories',
                    'electronics',
                    'audio',
                    'telephony'
                )
                AND oi.price >= 100
            THEN 1 ELSE 0
        END
    )                                                AS refined_tech_items,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN 
                    t.product_category_name_english IN (
                        'computers',
                        'computers_accessories',
                        'electronics',
                        'audio',
                        'telephony'
                    )
                    AND oi.price >= 100
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    )                                                AS pct_refined_tech_items
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name
JOIN orders AS o
    ON oi.order_id = o.order_id
GROUP BY
    purchase_month
ORDER BY
    purchase_month;


/* ============================================================================
   5.2 Seller Structure in the Refined Tech Segment
   Refined tech segment:
     - Categories: computers, computers_accessories, electronics, audio, telephony
     - Price threshold: price >= 100
   Output:
     - Top sellers by number of refined tech items sold
     - Share of each seller in total refined tech volume
   ============================================================================ */

WITH refined_tech_items AS (
    SELECT
        oi.seller_id,
        oi.price,
        t.product_category_name_english AS category
    FROM order_items AS oi
    JOIN products AS p
        ON oi.product_id = p.product_id
    JOIN product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE 
        t.product_category_name_english IN (
            'computers',
            'computers_accessories',
            'electronics',
            'audio',
            'telephony'
        )
        AND oi.price >= 100
),

seller_agg AS (
    SELECT
        seller_id,
        COUNT(*) AS tech_items_sold
    FROM refined_tech_items
    GROUP BY
        seller_id
),

total_tech AS (
    SELECT
        SUM(tech_items_sold) AS total_tech_items
    FROM seller_agg
)

SELECT
    sa.seller_id,
    sa.tech_items_sold,
    ROUND(100.0 * sa.tech_items_sold / tt.total_tech_items, 2) AS pct_of_tech_items
FROM seller_agg AS sa
CROSS JOIN total_tech AS tt
ORDER BY
    sa.tech_items_sold DESC
LIMIT 20;   -- Top 20 tech sellers


/* ============================================================================
   6.1 Delivery Performance (All Items)
   Purpose:
     - Compute average delivery delay (delivered date minus estimated date)
     - Compute on-time vs delayed delivery percentages
   ============================================================================ */

WITH delivered_orders AS (
    SELECT
        order_id,
        TIMESTAMPDIFF(
            DAY,
            order_estimated_delivery_date,
            order_delivered_customer_date
        ) AS delay_days
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
)

SELECT
    ROUND(AVG(delay_days), 2)                        AS avg_delay_days,
    ROUND(100 * SUM(delay_days <= 0) / COUNT(*), 2) AS pct_on_time,
    ROUND(100 * SUM(delay_days > 0)  / COUNT(*), 2) AS pct_delayed
FROM delivered_orders;


/* ============================================================================
   6.1 Delivery Performance – Refined Tech Segment
   Refined tech segment:
     - Categories: computers, computers_accessories, electronics, audio, telephony
     - Price threshold: price >= 100
   ============================================================================ */

WITH tech_orders AS (
    SELECT
        o.order_id,
        TIMESTAMPDIFF(
            DAY,
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date
        ) AS delay_days
    FROM orders AS o
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    JOIN products AS p
        ON oi.product_id = p.product_id
    JOIN product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
      AND t.product_category_name_english IN (
          'computers',
          'computers_accessories',
          'electronics',
          'audio',
          'telephony'
      )
      AND oi.price >= 100
)

SELECT
    ROUND(AVG(delay_days), 2)                        AS avg_delay_days,
    ROUND(100 * SUM(delay_days <= 0) / COUNT(*), 2) AS pct_on_time,
    ROUND(100 * SUM(delay_days > 0)  / COUNT(*), 2) AS pct_delayed
FROM tech_orders;


/* ============================================================================
   6.1 Combined Delivery Comparison: Platform vs Refined Tech Segment
   Includes:
     - delay_days        (delivered date minus estimated date)
     - abs_delivery_days (delivered date minus purchase date)
     - est_delivery_days (estimated date minus purchase date)
   ============================================================================ */

WITH base AS (
    SELECT
        'ALL_ITEMS' AS segment,
        TIMESTAMPDIFF(
            DAY,
            order_estimated_delivery_date,
            order_delivered_customer_date
        ) AS delay_days,
        TIMESTAMPDIFF(
            DAY,
            order_purchase_timestamp,
            order_delivered_customer_date
        ) AS abs_delivery_days,
        TIMESTAMPDIFF(
            DAY,
            order_purchase_timestamp,
            order_estimated_delivery_date
        ) AS est_delivery_days
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date IS NOT NULL
      AND order_estimated_delivery_date IS NOT NULL
      AND order_purchase_timestamp IS NOT NULL
),

tech AS (
    SELECT
        'TECH_SEGMENT' AS segment,
        TIMESTAMPDIFF(
            DAY,
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date
        ) AS delay_days,
        TIMESTAMPDIFF(
            DAY,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date
        ) AS abs_delivery_days,
        TIMESTAMPDIFF(
            DAY,
            o.order_purchase_timestamp,
            o.order_estimated_delivery_date
        ) AS est_delivery_days
    FROM orders AS o
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    JOIN products AS p
        ON oi.product_id = p.product_id
    JOIN product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
      AND o.order_purchase_timestamp IS NOT NULL
      AND t.product_category_name_english IN (
          'computers',
          'computers_accessories',
          'electronics',
          'audio',
          'telephony'
      )
      AND oi.price >= 100
),

combined AS (
    SELECT segment, delay_days, abs_delivery_days, est_delivery_days FROM base
    UNION ALL
    SELECT segment, delay_days, abs_delivery_days, est_delivery_days FROM tech
)

SELECT
    segment,
    ROUND(AVG(delay_days), 2)        AS avg_delay_days,
    ROUND(AVG(abs_delivery_days), 2) AS avg_abs_delivery_days,
    ROUND(AVG(est_delivery_days), 2) AS avg_estimated_delivery_days,
    ROUND(100 * SUM(delay_days <= 0) / COUNT(*), 2) AS pct_on_time,
    ROUND(100 * SUM(delay_days > 0)  / COUNT(*), 2) AS pct_delayed
FROM combined
GROUP BY
    segment;


/* ============================================================================
   7. Customer Satisfaction – Review Scores
   Comparison: All Items vs Refined Tech Segment
   Refined tech segment:
     - Categories: computers, computers_accessories, electronics, audio, telephony
     - Price threshold: price >= 100
   ============================================================================ */

WITH all_reviews AS (
    SELECT
        'ALL_ITEMS' AS segment,
        r.review_score
    FROM order_reviews AS r
    WHERE r.review_score IS NOT NULL
),

tech_reviews AS (
    SELECT
        'TECH_SEGMENT' AS segment,
        r.review_score
    FROM order_reviews AS r
    JOIN orders AS o
        ON r.order_id = o.order_id
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    JOIN products AS p
        ON oi.product_id = p.product_id
    JOIN product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE r.review_score IS NOT NULL
      AND t.product_category_name_english IN (
          'computers',
          'computers_accessories',
          'electronics',
          'audio',
          'telephony'
      )
      AND oi.price >= 100
),

combined AS (
    SELECT * FROM all_reviews
    UNION ALL
    SELECT * FROM tech_reviews
)

SELECT
    segment,
    ROUND(AVG(review_score), 2)                        AS avg_review_score,
    ROUND(100 * SUM(review_score <= 2) / COUNT(*), 2) AS pct_low_scores,
    ROUND(100 * SUM(review_score = 5)  / COUNT(*), 2) AS pct_five_star
FROM combined
GROUP BY
    segment;


/* ============================================================================
   Rating Distribution – All Items
   Counts and percentages of review scores 1–5
   ============================================================================ */

SELECT
    review_score,
    COUNT(*) AS count_reviews,
    ROUND(
        100 * COUNT(*) / (
            SELECT COUNT(*) FROM order_reviews WHERE review_score IS NOT NULL
        ),
        2
    ) AS pct_reviews
FROM order_reviews
WHERE review_score IS NOT NULL
GROUP BY
    review_score
ORDER BY
    review_score;


/* ============================================================================
   Rating Distribution – Refined Tech Segment (price >= 100)
   Refined tech segment:
     - Categories: computers, computers_accessories, electronics, audio, telephony
   ============================================================================ */

WITH tech_reviews AS (
    SELECT
        r.review_score
    FROM order_reviews AS r
    JOIN orders AS o
        ON r.order_id = o.order_id
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    JOIN products AS p
        ON oi.product_id = p.product_id
    JOIN product_category_name_translation AS t
        ON p.product_category_name = t.product_category_name
    WHERE r.review_score IS NOT NULL
      AND t.product_category_name_english IN (
          'computers',
          'computers_accessories',
          'electronics',
          'audio',
          'telephony'
      )
      AND oi.price >= 100
)

SELECT
    review_score,
    COUNT(*) AS count_reviews,
    ROUND(
        100 * COUNT(*) / (
            SELECT COUNT(*) FROM tech_reviews
        ),
        2
    ) AS pct_reviews
FROM tech_reviews
GROUP BY
    review_score
ORDER BY
    review_score;
