# User Journey Extraction for Paying Users (SQL)

**Business question:** Which page paths do users follow before they buy a subscription, and what does that tell us about how pages like *Pricing*, *Courses* and *Checkout* support conversion?

This project builds the **analysis-ready dataset** for that question: one row per user and session, with the ordered page path a paying user took *before* their first purchase. It is the standard first step for funnel, path and attribution analysis. Doing the cleaning in SQL keeps the logic reproducible and close to the warehouse.

**Stack:** MySQL 8 · CTEs · window functions · `GROUP_CONCAT` · ~1.6 M front-end interactions, ~246 K visitors, ~3.5 K purchases

---

## Output

| user_id | session_id | subscription_type | user_journey |
|---|---|---|---|
| 1234 | 98765 | Annual | `Homepage-Courses-Pricing-Checkout` |

## Business rules applied

| Rule | Why it matters |
|---|---|
| First **paid** purchase per user (`ROW_NUMBER`), in Q1 2023 | Renewals and upgrades must not put a user in the wrong cohort or move the "before purchase" cut-off |
| `purchase_price > 0` | Removes test accounts that would distort conversion paths |
| Only page views **before** the first purchase | The journey describes the decision process, not activity after purchase |
| URL → alias mapping ([`URL_Aliases.xlsx`](URL_Aliases.xlsx)) | Turns thousands of URLs into ~17 page types that stakeholders can read |
| `group_concat_max_len` raised | MySQL silently cuts strings at 1,024 characters by default, which would truncate long journeys |

## How this dataset is used next

- **Path analysis:** the most common paths into Checkout, and how often *Pricing* appears before a purchase.
- **Page influence:** for each page, the share of converting sessions it appears in, compared by plan type (Monthly, Quarterly, Annual).
- **Journey length:** sessions and pages before purchase as an indicator of friction.
- **Coupon impact:** how many paths go through *Coupon* and whether they lead to annual plans.

## Files

| File | Content |
|---|---|
| [`user_journey.sql`](user_journey.sql) | Full extraction query |
| [`URL_Aliases.xlsx`](URL_Aliases.xlsx) | URL → page alias mapping |

> The source database (~1.6 M rows) is too large for this repository.

*Dataset: 365 Data Science, used as a guided case study.*
