-- Increase the maximum length allowed for GROUP_CONCAT to avoid truncated user journey strings
SET SESSION group_concat_max_len = 1000000;

-- Select the database to use
USE user_journey_data;

-- Step 1: Inspect raw front interaction data
SELECT
    visitor_id,
    session_id,
    event_source_url,
    event_destination_url,
    event_date,
    event_name
FROM front_interactions;

-- Step 2: Check mapping between visitor_id and user_id
SELECT
    visitor_id,
    user_id
FROM front_visitors;

-- Step 3: View purchase data and find the first purchase date per user
SELECT
    user_id,
    purchase_id,
    purchase_type,
    purchase_price,
    MIN(DATE(date_purchased)) AS date_purchased
FROM student_purchases
GROUP BY
    user_id,
    purchase_id,
    purchase_type,
    purchase_price;

-- Step 4: Map URLs to alias names for readability
WITH front_interactions_table AS (
    SELECT
        visitor_id,
        session_id,

        -- Convert source URLs to readable page aliases
        CASE
            WHEN event_source_url = "https://365datascience.com/" THEN "Homepage"
            WHEN event_source_url LIKE "%/login/%" THEN "Log in"
            WHEN event_source_url LIKE "%/signup/%" THEN "Sign up"
            WHEN event_source_url LIKE "%/resources-center/%" THEN "Resources center"
            WHEN event_source_url LIKE "%/courses/%" THEN "Courses"
            WHEN event_source_url LIKE "%/career-tracks/%" THEN "Career tracks"
            WHEN event_source_url LIKE "%/upcoming-courses/%" THEN "Upcoming courses"
            WHEN event_source_url LIKE "%/career-track-certificate/%" THEN "Career track certificate"
            WHEN event_source_url LIKE "%/course-certificate/%" THEN "Course certificate"
            WHEN event_source_url LIKE "%/success-stories/%" THEN "Success stories"
            WHEN event_source_url LIKE "%/blog/%" THEN "Blog"
            WHEN event_source_url LIKE "%/pricing/%" THEN "Pricing"
            WHEN event_source_url LIKE "%/about-us/%" THEN "About us"
            WHEN event_source_url LIKE "%/instructors/%" THEN "Instructors"
            WHEN event_source_url LIKE "%/checkout%" AND event_source_url LIKE "%coupon%" THEN "Coupon"
            WHEN event_source_url LIKE "%/checkout%" AND event_source_url NOT LIKE "%coupon%" THEN "Checkout"
            ELSE "Other"
        END AS event_source_url,

        -- Convert destination URLs as well
        CASE
            WHEN event_destination_url = "https://365datascience.com/" THEN "Homepage"
            WHEN event_destination_url LIKE "%/login/%" THEN "Log in"
            WHEN event_destination_url LIKE "%/signup/%" THEN "Sign up"
            WHEN event_destination_url LIKE "%/resources-center/%" THEN "Resources center"
            WHEN event_destination_url LIKE "%/courses/%" THEN "Courses"
            WHEN event_destination_url LIKE "%/career-tracks/%" THEN "Career tracks"
            WHEN event_destination_url LIKE "%/upcoming-courses/%" THEN "Upcoming courses"
            WHEN event_destination_url LIKE "%/career-track-certificate/%" THEN "Career track certificate"
            WHEN event_destination_url LIKE "%/course-certificate/%" THEN "Course certificate"
            WHEN event_destination_url LIKE "%/success-stories/%" THEN "Success stories"
            WHEN event_destination_url LIKE "%/blog/%" THEN "Blog"
            WHEN event_destination_url LIKE "%/pricing/%" THEN "Pricing"
            WHEN event_destination_url LIKE "%/about-us/%" THEN "About us"
            WHEN event_destination_url LIKE "%/instructors/%" THEN "Instructors"
            WHEN event_destination_url LIKE "%/checkout%" AND event_destination_url LIKE "%coupon%" THEN "Coupon"
            WHEN event_destination_url LIKE "%/checkout%" AND event_destination_url NOT LIKE "%coupon%" THEN "Checkout"
            ELSE "Other"
        END AS event_destination_url,

        event_date,
        event_name
    FROM front_interactions
),

-- Step 5: Combine visits with user data and purchases
user_journey_table AS (
    SELECT 
        fit.visitor_id AS visitor_id,
        fv.user_id AS user_id,
        fit.session_id AS session_id,
        fit.event_source_url AS event_source_url,

        CASE
            WHEN purchase_type = 0 THEN 'Monthly'
            WHEN purchase_type = 1 THEN 'Quarterly'
            WHEN purchase_type = 2 THEN 'Annual'
            ELSE 'Other'
        END AS subscription_type,

        fit.event_destination_url AS event_destination_url,
        fit.event_date,
        MIN(sp.date_purchased) AS date_purchased
    FROM front_interactions_table fit
    JOIN front_visitors fv ON fit.visitor_id = fv.visitor_id
    JOIN student_purchases sp ON fv.user_id = sp.user_id
    WHERE 
        sp.purchase_price > 0 -- Remove test users
        AND fit.event_date < sp.date_purchased -- Only pre-purchase interactions
        AND DATE(sp.date_purchased) BETWEEN '2023-01-01' AND '2023-03-31'
    GROUP BY 
        visitor_id, user_id, session_id, event_source_url, subscription_type, event_destination_url, fit.event_date
    ORDER BY fv.user_id, fit.session_id
)

-- Step 6: Aggregate the journey by session
SELECT
    uj.user_id,
    uj.session_id,
    uj.subscription_type,
    GROUP_CONCAT(uj.event_source_url ORDER BY uj.event_date SEPARATOR ' ➡️ ') AS user_journey
FROM user_journey_table uj
GROUP BY 
    uj.user_id,
    uj.session_id,
    uj.subscription_type
ORDER BY uj.user_id;
