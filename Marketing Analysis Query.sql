--Calculating conversion rate by Combining Customer with Product.
SELECT 
  COUNT(DISTINCT CASE WHEN Action='Purchase' 
        THEN CONCAT(Customer_ID,'-',Product_ID) END)
   * 100 /
  COUNT(DISTINCT CASE WHEN Action='View' 
        THEN CONCAT(Customer_ID,'-',Product_ID) END)
  AS conversion_rate
FROM journey;


--Conversion from different stages for different Product IDs.
With funnel_counts AS (
SELECT
Product_ID,
COUNT(DISTINCT CASE WHEN Stage = 'homepage' THEN Customer_ID END) AS homepage_visitors,
COUNT(DISTINCT CASE WHEN Stage = 'productpage' THEN Customer_ID END) AS product_viewers,
COUNT(DISTINCT CASE WHEN Stage = 'checkout' THEN Customer_ID END) AS checkout_starters,
COUNT(DISTINCT CASE WHEN Stage = 'checkout' AND Action = 'purchase' THEN Customer_ID END) AS purchasers
FROM journey
GROUP BY Product_ID
)
SELECT
fc.Product_ID, fc.homepage_visitors, fc.product_viewers, fc.checkout_starters, fc.purchasers,
CASE WHEN fc.homepage_visitors > 0 THEN 100 * fc.product_viewers / fc.homepage_visitors ELSE NULL END AS view_rate_hp_to_pp,
CASE WHEN fc.product_viewers > 0 THEN 100 * fc.checkout_starters / fc.product_viewers ELSE NULL END AS checkout_start_rate,
CASE WHEN fc.checkout_starters > 0 THEN 100 * fc.purchasers / fc.checkout_starters ELSE NULL END AS checkout_completion_rate,
CASE WHEN fc.homepage_visitors > 0 THEN 100 * fc.purchasers / fc.homepage_visitors ELSE NULL END AS overall_conversion_rate
FROM funnel_counts fc
ORDER BY overall_conversion_rate DESC;



--Conversion from different stages for different Countries.
WITH journey_segment AS (
SELECT Journey_ID, Customer_ID, j.Product_ID, Stage, Action FROM Journey j
),
funnel_segment AS (
SELECT Country, City, 
COUNT(DISTINCT CASE WHEN Stage = 'homepage' THEN j.Customer_ID END) AS homepage_visitors,
COUNT(DISTINCT CASE WHEN Stage = 'productpage' THEN j.Customer_ID END) AS product_viewers,
COUNT(DISTINCT CASE WHEN Stage = 'checkout' THEN j.Customer_ID END) AS checkout_starters, 
COUNT(DISTINCT CASE WHEN Stage = 'checkout' AND Action = 'purchase' THEN j.Customer_ID END) AS purchasers
FROM journey_segment j
JOIN Products   p ON j.Product_ID  = p.Product_ID 
JOIN Customers  c ON j.Customer_ID = c.Customer_ID
GROUP BY c.Country, c.City
)
SELECT Country, homepage_visitors, product_viewers, checkout_starters, purchasers,
CASE WHEN homepage_visitors > 0 THEN 100 * product_viewers / homepage_visitors END AS view_rate_hp_to_pp,
CASE WHEN product_viewers > 0 THEN 100 * checkout_starters / product_viewers END AS checkout_start_rate,
CASE WHEN checkout_starters > 0 THEN 100 * purchasers / checkout_starters END AS checkout_completion_rate,
CASE WHEN homepage_visitors > 0 THEN 100 * purchasers / homepage_visitors END AS overall_conversion_rate
FROM funnel_segment
ORDER BY overall_conversion_rate;


--Drop Off from Checkout staters' stage for different Product.
WITH journey_clean AS (
    SELECT
        Customer_ID,
        ProductName,
        Stage,
        Action
    FROM Journey j
    join products p
    on p.product_ID = j.product_ID
),
checkout_stats AS (
    SELECT
        ProductName,
        COUNT(DISTINCT CASE WHEN Stage = 'checkout'
                            THEN Customer_ID END) AS checkout_starters,
        COUNT(DISTINCT CASE WHEN Stage = 'checkout'
                         AND Action = 'purchase'
                            THEN Customer_ID END) AS purchasers
    FROM journey_clean
    GROUP BY ProductName
)
SELECT
    ProductName,
    checkout_starters,
    (checkout_starters - purchasers) AS checkout_dropoffs,
    CASE WHEN checkout_starters > 0
         THEN 100 * (checkout_starters - purchasers) / checkout_starters
    END AS checkout_dropoff_rate
FROM checkout_stats
ORDER BY checkout_dropoff_rate DESC;




--Engagement summary and ctr from different media.
SELECT ContentType,
    COUNT(*) AS posts,
    SUM(Likes) AS total_likes,
    SUM(Views) AS total_views,
    SUM(Clicks) AS total_clicks,
    CASE WHEN SUM(Views)  > 0 THEN 100 * SUM(Clicks) / SUM(Views)  END AS ctr,
    CASE WHEN SUM(Clicks) > 0 THEN 100 * SUM(Likes)  / SUM(Clicks) END AS likes_per_click
FROM engagement
GROUP BY ContentType 
ORDER BY total_likes DESC;

--Engagement summary and ctr for different products.
SELECT
    ProductName,
    COUNT(*)        AS posts,
    SUM(Views)      AS total_views,
    SUM(Clicks)     AS total_clicks,
    SUM(Likes)      AS total_likes,
    CASE WHEN SUM(Views) > 0
         THEN 100 * SUM(Clicks) / SUM(Views) END AS ctr,
    CASE WHEN SUM(Clicks) > 0
         THEN 100 * SUM(Likes)  / SUM(Clicks) END AS likes_per_click
FROM engagement e
join products p
on p.product_ID = e.product_ID
GROUP BY ProductName;





-- Summary of Review Sentiment For different Products Name.
SELECT
    p.ProductName,
    COUNT(*) AS review_count,
    AVG(rs.Ratings) AS avg_rating,
    SUM(CASE WHEN rs.SentimentCategory LIKE 'Negative%' THEN 1 ELSE 0 END) AS negative_reviews,
    SUM(CASE WHEN rs.SentimentCategory LIKE 'Mixed Negative%' THEN 1 ELSE 0 END) AS mixed_negative_reviews,
    SUM(CASE WHEN rs.SentimentCategory LIKE 'Positive%' THEN 1 ELSE 0 END) AS positive_reviews
FROM reviews_sentiment rs
JOIN Products p 
ON rs.Product_ID = p.Product_ID
GROUP BY p.ProductName
ORDER BY review_count DESC;


-- Summary of Review Sentiment For different Countries.
SELECT
    Country,
    COUNT(*) AS reviews,
    AVG(Ratings) AS avg_rating,
    SUM(CASE WHEN SentimentCategory LIKE 'Positive%' THEN 1 ELSE 0 END) AS positive_reviews,
  sum(Case when sentimentCategory Like 'Mixed Positive%' then 1 else 0 End) as Mixed_Positive_Reviews,
  sum(Case when sentimentCategory Like 'Neutral%' then 1 else 0 End) as Neutral_reviews,
  SUM(CASE WHEN SentimentCategory LIKE 'Negative%' THEN 1 ELSE 0 END) AS Negative_reviews,
    SUM(CASE WHEN SentimentCategory LIKE 'Mixed Negative%' THEN 1 ELSE 0 END) AS Mixed_negative_reviews
FROM reviews_sentiment rs
join customers c
on rs.customer_ID = c.customer_id
GROUP BY Country
ORDER BY reviews DESC;


-- Summary of Review Sentiment For different Age Group.
SELECT
    age_group,
    COUNT(*) AS reviews,
    AVG(Ratings) AS avg_rating,
    SUM(CASE WHEN SentimentCategory LIKE 'Positive%' THEN 1 ELSE 0 END) AS positive_reviews,
  sum(Case when sentimentCategory Like 'Mixed Positive%' then 1 else 0 End) as Mixed_Positive_Reviews,
  sum(Case when sentimentCategory Like 'Neutral%' then 1 else 0 End) as Neutral_reviews,
  SUM(CASE WHEN SentimentCategory LIKE 'Negative%' THEN 1 ELSE 0 END) AS Negative_reviews,
    SUM(CASE WHEN SentimentCategory LIKE 'Mixed Negative%' THEN 1 ELSE 0 END) AS Mixed_negative_reviews
FROM reviews_sentiment rs
join customers c
on rs.customer_ID = c.customer_id
GROUP BY age_group
ORDER BY reviews DESC;