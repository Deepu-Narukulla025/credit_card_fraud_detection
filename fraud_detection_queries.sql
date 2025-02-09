-- Checking the Total Number of Transactions & Fraud Cases
SELECT 
    COUNT(*) AS total_transactions, 
    SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS fraud_transactions,
    SUM(CASE WHEN Class = 0 THEN 1 ELSE 0 END) AS non_fraud_transactions,
    ROUND((SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS fraud_percentage
FROM credit_card_transactions;

-- Check Missing or Null Values
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Time IS NULL THEN 1 ELSE 0 END) AS missing_time,
    SUM(CASE WHEN Amount IS NULL THEN 1 ELSE 0 END) AS missing_amount,
    SUM(CASE WHEN Class IS NULL THEN 1 ELSE 0 END) AS missing_class
FROM credit_card_transactions;

-- Finding the Average Transaction Amount (Fraud vs. Non-Fraud)
SELECT 
    Class,
    COUNT(*) AS total_transactions,
    AVG(Amount) AS avg_transaction_amount,
    MAX(Amount) AS max_transaction_amount,
    MIN(Amount) AS min_transaction_amount
FROM credit_card_transactions
GROUP BY Class;

--- Detect High-Risk Users (Frequent Fraudsters)
-- Finding the Most Frequent Transaction Amounts in Fraud Cases
SELECT Amount, COUNT(*) AS frequency
FROM credit_card_transactions
WHERE Class = 1
GROUP BY Amount
ORDER BY frequency DESC
LIMIT 10;

-- Finding Transactions with Extremely High Amounts
WITH Ranked AS (
    SELECT Amount, NTILE(100) OVER (ORDER BY Amount) AS Percentile
    FROM credit_card_transactions
)
SELECT * 
FROM Ranked
WHERE Percentile = 99;

-- Analysing Fraud Trends Over Time
SELECT 
    FLOOR(Time / 3600) AS hour_of_day,
    COUNT(*) AS fraud_count
FROM credit_card_transactions
WHERE Class = 1
GROUP BY hour_of_day
ORDER BY fraud_count DESC;
-- select * from cte where hour_of_day=0;

-- Fraud Patterns in V1–V28 Features
SELECT 
    Class,
AVG(V1) AS avg_V1, AVG(V2) AS avg_V2, AVG(V3) AS avg_V3, AVG(V4) AS avg_V4, AVG(V5) AS avg_V5,AVG(V6) AS avg_V6, AVG(V7) AS avg_7, AVG(V8) AS avg_V8,
AVG(V9) AS avg_V9, AVG(V10) AS avg_V10, AVG(V11) AS avg_V11, AVG(V12) AS avg_V12, AVG(V13) AS avg_V13, AVG(V14) AS avg_V14, AVG(V15) AS avg_V15, AVG(V16) AS avg_V16, 
AVG(V17) AS avg_V17, AVG(V18) AS avg_V18, AVG(V19) AS avg_V19, AVG(V20) AS avg_V20, AVG(V21) AS avg_V21, AVG(V22) AS avg_V22, AVG(V23) AS avg_V23, AVG(V24) AS avg_V24, AVG(V25) AS avg_V25, 
AVG(V26) AS avg_V26, AVG(V27) AS avg_V27,AVG(V28) AS avg_V28 FROM credit_card_transactions
GROUP BY Class;

-- Detect Outliers in V1–V28 for Fraud Cases
SELECT * 
FROM credit_card_transactions
WHERE Class = 1
AND (V1 > (SELECT AVG(V1) + 3 * STDDEV(V1) FROM credit_card_transactions) 
	OR V1 < (SELECT AVG(V1) - 3 * STDDEV(V1) FROM credit_card_transactions) );
  
--- Fraud Detection Rules
-- Rule 1: Flag High-Value Transactions (Possible Fraud)
SELECT * 
FROM credit_card_transactions
WHERE Amount > (SELECT AVG(Amount) + 3 * STDDEV(Amount) FROM credit_card_transactions);

-- Rule 2: Identify Rapid Consecutive Transactions
SELECT a.*
FROM credit_card_transactions a
JOIN credit_card_transactions b
ON a.Time BETWEEN b.Time AND b.Time + 60  -- Transactions within 1 minute
AND a.Amount = b.Amount  -- Same transaction amount
AND a.Class = 1  -- Fraud transactions only
AND a.row_id <> b.row_id;

SELECT a.*
FROM credit_card_transactions a
JOIN credit_card_transactions b
ON a.Time BETWEEN b.Time AND b.Time + 60  
AND a.Amount = b.Amount  
AND a.Class = 1  
AND (a.Time <> b.Time OR a.Amount <> b.Amount); 
-- Rule 3: Detect Unusual Spending Patterns
      select amount,count(*)
	  from credit_card_transactions where class=1 group by 
	amount order by amount desc ;

SELECT * 
FROM credit_card_transactions
WHERE Amount > 1000 -- High-risk threshold
AND Class = 1;

--- Customer Segmentation (High-Risk vs. Low-Risk Groups)
-- High-Risk Transactions (Frequent Fraud Amounts)
SELECT Amount, COUNT(*) AS fraud_count
FROM credit_card_transactions
WHERE Class = 1
GROUP BY Amount
HAVING COUNT(*) > 5
ORDER BY fraud_count DESC;

-- Segmenting Transactions Based on Amount
SELECT 
    CASE 
        WHEN Amount < 50 THEN 'Low Risk'
        WHEN Amount BETWEEN 50 AND 500 THEN 'Medium Risk'
        ELSE 'High Risk'
    END AS risk_level,
    COUNT(*) AS transaction_count,
    SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS fraud_count
 -- SUM(CASE WHEN Class = 0 THEN 1 ELSE 0 END) AS nonfraud_count
FROM credit_card_transactions
GROUP BY risk_level;

-- fraud patterns across different metrics
SELECT 
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS fraud_cases,
    ROUND((SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS fraud_rate,
    AVG(CASE WHEN Class = 1 THEN Amount ELSE NULL END) AS avg_fraud_amount,
    MAX(CASE WHEN Class = 1 THEN Amount ELSE NULL END) AS max_fraud_amount,
    (SELECT Amount FROM credit_card_transactions WHERE Class = 1 GROUP BY Amount ORDER BY COUNT(*) DESC LIMIT 1) AS most_frequent_fraud_amount;

-- Optimizing SQL Queries for Faster Fraud Detection 
-- Use Indexing for Faster Searches
-- Adding Index on Key Fraud Detection Columns

-- EXPLAIN SELECT * FROM credit_card_transactions WHERE Class = 1;
CREATE INDEX idx_class ON credit_card_transactions(Class);
CREATE INDEX idx_amount ON credit_card_transactions(Amount);
CREATE INDEX idx_time ON credit_card_transactions(Time);

EXPLAIN SELECT * FROM credit_card_transactions WHERE Class = 1;

--  Optimize Fraud Query Using WHERE Instead of CASE
SELECT 
    COUNT(*) AS total_fraud, 
    SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS fraud_cases
FROM credit_card_transactions;

SELECT COUNT(*) AS fraud_cases
FROM credit_card_transactions
WHERE Class = 1;

-- EXPLAIN to Analyze Query Performance
EXPLAIN SELECT Amount, COUNT(*) AS fraud_count
FROM credit_card_transactions
WHERE Class = 1
GROUP BY Amount
HAVING COUNT(*) > 5
ORDER BY fraud_count DESC;

-- Reduce Data Scanned with Indexed Subqueries
-- Optimize High-Value Transaction Detection
SELECT * 
FROM credit_card_transactions
WHERE Amount > (
    SELECT AVG(Amount) + 3 * STDDEV(Amount) 
    FROM credit_card_transactions 
    WHERE Class = 1  -- Only scan fraud cases
);

-- Partition the Table for Faster Processing
/* ALTER TABLE credit_card_transactions 
PARTITION BY LIST (Class) (
    PARTITION fraud VALUES IN (1),
    PARTITION non_fraud VALUES IN (0)
) */ 
select * from credit_card_transactions;

-- Optimising Fraud Report Query
 /* FILTER (WHERE Class = 1) */

SELECT 
    (SELECT COUNT(*) FROM credit_card_transactions) AS total_transactions,
    (SELECT COUNT(*) FROM credit_card_transactions WHERE Class = 1) AS fraud_cases,
    (SELECT ROUND(AVG(Amount), 2) FROM credit_card_transactions WHERE Class = 1) AS avg_fraud_amount,
    (SELECT MAX(Amount) FROM credit_card_transactions WHERE Class = 1) AS max_fraud_amount,
    (SELECT Amount FROM credit_card_transactions 
     WHERE Class = 1 
     GROUP BY Amount 
     ORDER BY COUNT(*) DESC 
     LIMIT 1) AS most_frequent_fraud_amount;
