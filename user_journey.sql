-- ============================================================================
-- User journey extract for paying users (MySQL 8)
--
-- Output: one row per user x session with the ordered page path visited
--         before the user's FIRST paid purchase.
--   user_id | session_id | subscription_type | user_journey
--   1234    | 98765      | Annual            | Homepage-Courses-Pricing-Checkout
--
-- Rules
--   * Users whose first paid purchase was in Q1 2023 (2023-01-01 .. 2023-03-31)
--   * Test users (purchase_price = 0) excluded
--   * Only page views strictly before that first purchase
--   * URLs mapped to short aliases (see URL_Aliases.xlsx)
-- ============================================================================
SET SESSION group_concat_max_len = 1000000;   -- avoid silently truncated journeys
USE user_journey_data;

WITH
-- 1. First PAID purchase per user. A user's later renewals or upgrades must not
--    pull them into the Q1 cohort or move the "before purchase" cut-off.
first_paid_purchase AS (
    SELECT user_id, purchase_type, date_purchased
    FROM (
        SELECT
            user_id,
            purchase_type,
            date_purchased,
            ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY date_purchased, purchase_id) AS rn
        FROM student_purchases
        WHERE purchase_price > 0                         -- drop test users
    ) p
    WHERE rn = 1
      AND date_purchased >= '2023-01-01'
      AND date_purchased <  '2023-04-01'                 -- half-open range keeps all of 31 March
),

-- 2. Map raw URLs to readable page aliases (order of WHEN clauses matters)
page_views AS (
    SELECT
        visitor_id,
        session_id,
        event_date,
        CASE
            WHEN event_source_url = 'https://365datascience.com/'                    THEN 'Homepage'
            WHEN event_source_url LIKE '%/login/%'                                   THEN 'Log in'
            WHEN event_source_url LIKE '%/signup/%'                                  THEN 'Sign up'
            WHEN event_source_url LIKE '%/resources-center/%'                        THEN 'Resources center'
            WHEN event_source_url LIKE '%/upcoming-courses/%'                        THEN 'Upcoming courses'
            WHEN event_source_url LIKE '%/courses/%'                                 THEN 'Courses'
            WHEN event_source_url LIKE '%/career-track-certificate/%'                THEN 'Career track certificate'
            WHEN event_source_url LIKE '%/career-tracks/%'                           THEN 'Career tracks'
            WHEN event_source_url LIKE '%/course-certificate/%'                      THEN 'Course certificate'
            WHEN event_source_url LIKE '%/success-stories/%'                         THEN 'Success stories'
            WHEN event_source_url LIKE '%/blog/%'                                    THEN 'Blog'
            WHEN event_source_url LIKE '%/pricing/%'                                 THEN 'Pricing'
            WHEN event_source_url LIKE '%/about-us/%'                                THEN 'About us'
            WHEN event_source_url LIKE '%/instructors/%'                             THEN 'Instructors'
            WHEN event_source_url LIKE '%/checkout%' AND event_source_url LIKE '%coupon%' THEN 'Coupon'
            WHEN event_source_url LIKE '%/checkout%'                                 THEN 'Checkout'
            ELSE 'Other'
        END AS page
    FROM front_interactions
),

-- 3. Keep only pre-purchase page views of the Q1 2023 paying users
pre_purchase_views AS (
    SELECT
        fv.user_id,
        pv.session_id,
        CASE fp.purchase_type
            WHEN 0 THEN 'Monthly'
            WHEN 1 THEN 'Quarterly'
            WHEN 2 THEN 'Annual'
            ELSE 'Other'
        END AS subscription_type,
        pv.page,
        pv.event_date
    FROM page_views pv
    JOIN front_visitors      fv ON fv.visitor_id = pv.visitor_id
    JOIN first_paid_purchase fp ON fp.user_id    = fv.user_id
    WHERE pv.event_date < fp.date_purchased
)

-- 4. One ordered, hyphen-separated path per user x session
SELECT
    user_id,
    session_id,
    subscription_type,
    GROUP_CONCAT(page ORDER BY event_date SEPARATOR '-') AS user_journey
FROM pre_purchase_views
GROUP BY user_id, session_id, subscription_type
ORDER BY user_id, session_id;
