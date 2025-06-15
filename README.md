# 🧭 Extracting User Journey Data Using SQL

## 🧠 Case Description

SQL is often just used to fetch raw data from data storage that is later transferred to other software for preprocessing. But this programming language can do more than select data from a table.

This project centers around creating a customer journey data extract as the starting point for later analysis. Here, “user journey” refers to the steps each user goes through while exploring the product or platform before purchasing.

The context is an online subscription-based company offering monthly, quarterly, and annual subscription plans. Using only SQL, we consider all users that purchased a plan and aggregate all visited pages into a sequence string. This user journey will be analyzed in a different project.

## 🎯 Objective

Write a SQL query to extract the user journey of paying users by aggregating all visited pages in a session into a single string, ordered by time, and export the result as a CSV.

## 📄 Data Requirements

The expected output must contain the following columns:

- `user_id`
- `session_id`
- `subscription_type`
- `user_journey`

## 📝 Project Requirements

- Only include users who made their **first purchase** between **January 1 and March 31, 2023 (Q1 2023)**.
- Exclude any test users (those who paid **$0**).
- Only include **page visits before the purchase timestamp**.
- Replace full page URLs with **short aliases** (provided in the Excel file).
- Combine all visited pages (per session) into one **hyphen-separated string**.
- Resulting user journeys are saved **per session**, **per user**.


> **Note:** The database file is too large to be included in this repository.

