
-- Create a table to store the original transaction data.
-- The raw table will remain unchanged during analysis.
CREATE TABLE transactions_raw (
    step INT,
    type VARCHAR(20),
    amount DECIMAL(20,2),
    nameOrig VARCHAR(32),
    oldbalanceOrg DECIMAL(20,2),
    newbalanceOrig DECIMAL(20,2),
    nameDest VARCHAR(32),
    oldbalanceDest DECIMAL(20,2),
    newbalanceDest DECIMAL(20,2),
    isFraud TINYINT,
    isFlaggedFraud TINYINT
);

-- Check whether local file importing is enabled.
SHOW VARIABLES LIKE 'local_infile';

-- Enable local file importing at the server level.
SET GLOBAL local_infile = 1;

-- Confirm that local file importing is enabled.
SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- Import the CSV dataset into the raw table.
-- The first row contains column headings, so it is skipped.
LOAD DATA LOCAL INFILE
'C:/Users/user/Downloads/mobile-money-fraud-analysis/PS_20174392719_1491204439457_log.csv'
INTO TABLE transactions_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    step,
    type,
    amount,
    nameOrig,
    oldbalanceOrg,
    newbalanceOrig,
    nameDest,
    oldbalanceDest,
    newbalanceDest,
    isFraud,
    isFlaggedFraud
);

-- Examine the total number of records,
-- the simulated time range and transaction amount distribution.
SELECT
    COUNT(*) AS total_records,
    MIN(step) AS first_step,
    MAX(step) AS last_step,
    MIN(amount) AS minimum_amount,
    MAX(amount) AS maximum_amount,
    ROUND(AVG(amount), 2) AS average_amount
FROM transactions_raw;

-- Count missing values in each column.
-- This checks for SQL NULL values.
SELECT
    COUNT(*) AS total_records,
    SUM(step IS NULL) AS missing_step,
    SUM(type IS NULL) AS missing_type,
    SUM(amount IS NULL) AS missing_amount,
    SUM(nameOrig IS NULL) AS missing_sender,
    SUM(oldbalanceOrg IS NULL) AS missing_sender_balance,
    SUM(newbalanceOrig IS NULL) AS missing_new_sender_balance,
    SUM(nameDest IS NULL) AS missing_recipient,
    SUM(oldbalanceDest IS NULL) AS missing_recipient_balance,
    SUM(newbalanceDest IS NULL) AS missing_new_recipient_balance,
    SUM(isFraud IS NULL) AS missing_fraud_label,
    SUM(isFlaggedFraud IS NULL) AS missing_flagged_label
FROM transactions_raw;

-- Examine transaction frequency and transaction values
-- across the different transaction categories.
SELECT
    type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_amount,
    ROUND(AVG(amount), 2) AS average_amount
FROM transactions_raw
GROUP BY type
ORDER BY transaction_count DESC;

-- Count transactions flagged by the original
-- fraud detection system.
SELECT
    isFlaggedFraud,
    COUNT(*) AS transaction_count
FROM transactions_raw
GROUP BY isFlaggedFraud;

-- Check for negative transaction amounts,
-- negative account balances and invalid binary labels.
SELECT
    SUM(amount < 0) AS negative_amounts,
    SUM(oldbalanceOrg < 0) AS negative_old_sender_balances,
    SUM(newbalanceOrig < 0) AS negative_new_sender_balances,
    SUM(oldbalanceDest < 0) AS negative_old_recipient_balances,
    SUM(newbalanceDest < 0) AS negative_new_recipient_balances,
    SUM(isFraud NOT IN (0, 1)) AS invalid_fraud_labels,
    SUM(isFlaggedFraud NOT IN (0, 1)) AS invalid_flagged_labels
FROM transactions_raw;

-- Group records using all original columns.
-- Any group appearing more than once represents
-- an exact duplicate transaction record.
SELECT
    step,
    type,
    amount,
    nameOrig,
    oldbalanceOrg,
    newbalanceOrig,
    nameDest,
    oldbalanceDest,
    newbalanceDest,
    isFraud,
    isFlaggedFraud,
    COUNT(*) AS duplicate_count
FROM transactions_raw
GROUP BY
    step,
    type,
    amount,
    nameOrig,
    oldbalanceOrg,
    newbalanceOrig,
    nameDest,
    oldbalanceDest,
    newbalanceDest,
    isFraud,
    isFlaggedFraud
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC
LIMIT 20;

SELECT
    isFraud,
    isFlaggedFraud,
    COUNT(*) AS transaction_count
FROM transactions_raw
GROUP BY
    isFraud,
    isFlaggedFraud
ORDER BY
    isFraud,
    isFlaggedFraud;

-- Compare the actual fraud labels with the
-- transactions identified by the original system.
SELECT
    type,
    isFraud,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_amount,
    ROUND(AVG(amount), 2) AS average_amount
FROM transactions_raw
GROUP BY
    type,
    isFraud
ORDER BY
    type,
    isFraud;
    
-- Compare transaction frequency, total value and
-- average value for fraudulent and legitimate transactions
-- across different transaction types.
SELECT
    type,
    COUNT(*) AS total_transactions,
    SUM(CASE
        WHEN isFraud = 1 THEN 1
        ELSE 0
    END) AS fraudulent_transactions,

    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS fraud_rate_pct
FROM transactions_raw
GROUP BY type
ORDER BY fraud_rate_pct DESC;

-- Calculate the proportion of transactions labelled
-- fraudulent within each transaction category.
SELECT
    COUNT(*) AS total_transactions,
    SUM(
        ABS(
            oldbalanceOrg - amount - newbalanceOrig
        ) > 0.01
    ) AS sender_balance_mismatches,
    SUM(
        ABS(
            oldbalanceDest + amount - newbalanceDest
        ) > 0.01
    ) AS recipient_balance_mismatches
FROM transactions_raw;

-- Check whether sender balances reconcile after
-- deducting the transaction amount.
-- Check whether recipient balances reconcile after
-- adding the transaction amount.
SELECT
    type,
    COUNT(*) AS total_transactions,
    SUM(
        ABS(oldbalanceOrg - amount - newbalanceOrig) > 0.01
    ) AS sender_balance_mismatches,
    SUM(
        ABS(oldbalanceDest + amount - newbalanceDest) > 0.01
    ) AS recipient_balance_mismatches
FROM transactions_raw
GROUP BY type
ORDER BY total_transactions DESC;

-- Examine whether balance mismatches are more common
-- among fraudulent or legitimate transactions.
SELECT
    isFraud,
    COUNT(*) AS total_transactions,
    SUM(
        ABS(oldbalanceOrg - amount - newbalanceOrig) > 0.01
    ) AS sender_balance_mismatches,
    SUM(
        ABS(oldbalanceDest + amount - newbalanceDest) > 0.01
    ) AS recipient_balance_mismatches
FROM transactions_raw
GROUP BY isFraud
ORDER BY isFraud;

-- Compare sender and recipient balance mismatches
-- across the different transaction categories.
SELECT
    type,
    isFraud,
    COUNT(*) AS total_transactions,
    SUM(
        ABS(oldbalanceOrg - amount - newbalanceOrig) > 0.01
    ) AS sender_balance_mismatches,
    SUM(
        ABS(oldbalanceDest + amount - newbalanceDest) > 0.01
    ) AS recipient_balance_mismatches
FROM transactions_raw
GROUP BY
    type,
    isFraud
ORDER BY
    type,
    isFraud;

-- Create a new table from the raw data.
-- Add two binary indicators to identify balance mismatches.
-- A tolerance of 0.01 is used to avoid insignificant
-- decimal differences being treated as mismatches.
CREATE TABLE transactions_clean AS
SELECT
    step,
    type,
    amount,
    nameOrig,
    oldbalanceOrg,
    newbalanceOrig,
    nameDest,
    oldbalanceDest,
    newbalanceDest,
    isFraud,
    isFlaggedFraud,
    CASE
        WHEN ABS(oldbalanceOrg - amount - newbalanceOrig) > 0.01
        THEN 1
        ELSE 0
    END AS sender_balance_mismatch,
    CASE
        WHEN ABS(oldbalanceDest + amount - newbalanceDest) > 0.01
        THEN 1
        ELSE 0
    END AS recipient_balance_mismatch
FROM transactions_raw;

-- Confirm that all original records are present.
SELECT COUNT(*) AS total_records
FROM transactions_clean;

-- Examine the structure of the clean table.
DESCRIBE transactions_clean;

-- Check the distribution of sender and recipient
-- balance mismatch combinations.
SELECT
    sender_balance_mismatch,
    recipient_balance_mismatch,
    COUNT(*) AS transaction_count
FROM transactions_clean
GROUP BY
    sender_balance_mismatch,
    recipient_balance_mismatch
ORDER BY
    sender_balance_mismatch,
    recipient_balance_mismatch;
    
-- Calculate key fraud indicators across all transactions.
SELECT
    COUNT(*) AS total_transactions,
    SUM(CASE
        WHEN isFraud = 1 THEN 1
        ELSE 0
    END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS fraud_rate_pct,
    ROUND(
        SUM(CASE
            WHEN isFraud = 1 THEN amount
            ELSE 0
        END),
        2
    ) AS total_fraud_transaction_value,
    ROUND(
        AVG(CASE
            WHEN isFraud = 1 THEN amount
        END),
        2
    ) AS average_fraud_transaction_amount,

    SUM(CASE
        WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1
        ELSE 0
    END) AS fraud_transactions_flagged
FROM transactions_clean;

-- Compare fraudulent transactions across transaction types.
SELECT
    type,
    COUNT(*) AS total_transactions,
    SUM(CASE
        WHEN isFraud = 1 THEN 1
        ELSE 0
    END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS fraud_rate_pct,
    ROUND(
        SUM(CASE
            WHEN isFraud = 1 THEN amount
            ELSE 0
        END),
        2
    ) AS total_fraud_value,
    ROUND(
        AVG(CASE
            WHEN isFraud = 1 THEN amount
        END),
        2
    ) AS average_fraud_amount
FROM transactions_clean
GROUP BY type
ORDER BY fraudulent_transactions DESC;

-- Compare transaction frequency and amount statistics
-- between fraudulent and legitimate transactions.
SELECT
    isFraud,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_transaction_value,
    ROUND(AVG(amount), 2) AS average_transaction_amount,
    ROUND(MIN(amount), 2) AS minimum_transaction_amount,
    ROUND(MAX(amount), 2) AS maximum_transaction_amount
FROM transactions_clean
GROUP BY isFraud
ORDER BY isFraud;

-- Group transactions into amount categories.
-- Calculate the number and percentage of fraudulent
-- transactions within each amount range.
SELECT
    CASE
        WHEN amount < 10000 THEN 'Below 10K'
        WHEN amount < 100000 THEN '10K - 100K'
        WHEN amount < 500000 THEN '100K - 500K'
        WHEN amount < 1000000 THEN '500K - 1M'
        ELSE 'Above 1M'
    END AS amount_range,
    COUNT(*) AS total_transactions,
    SUM(CASE
        WHEN isFraud = 1 THEN 1
        ELSE 0
    END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS fraud_rate_pct
FROM transactions_clean
GROUP BY amount_range
ORDER BY
    CASE amount_range
        WHEN 'Below 10K' THEN 1
        WHEN '10K - 100K' THEN 2
        WHEN '100K - 500K' THEN 3
        WHEN '500K - 1M' THEN 4
        ELSE 5
    END;
    
-- Analyse fraud activity at each simulated hour.
-- Each step represents one simulated hour.
    SELECT
    step,
    COUNT(*) AS total_transactions,
    SUM(CASE
        WHEN isFraud = 1 THEN 1
        ELSE 0
    END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS fraud_rate_pct,
    ROUND(
        SUM(CASE
            WHEN isFraud = 1 THEN amount
            ELSE 0
        END),
        2
    ) AS total_fraud_value
FROM transactions_clean
GROUP BY step
ORDER BY step;

-- Convert simulated hourly steps into 24-hour periods.
-- Steps 1-24 represent day 1, steps 25-48 represent day 2,
-- and so on.
SELECT
    FLOOR((step - 1) / 24) + 1 AS simulated_day,
    COUNT(*) AS total_transactions,
    SUM(CASE
        WHEN isFraud = 1 THEN 1
        ELSE 0
    END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS fraud_rate_pct,
    ROUND(
        SUM(CASE
            WHEN isFraud = 1 THEN amount
            ELSE 0
        END),
        2
    ) AS total_fraud_value
FROM transactions_clean
GROUP BY simulated_day
ORDER BY simulated_day;

-- Group transactions by transaction type and the two
-- balance mismatch indicators.
-- Calculate the fraud rate within each combination.
SELECT
    type,
    sender_balance_mismatch,
    recipient_balance_mismatch,
    COUNT(*) AS total_transactions,
    SUM(CASE
        WHEN isFraud = 1 THEN 1
        ELSE 0
    END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS fraud_rate_pct
FROM transactions_clean
GROUP BY
    type,
    sender_balance_mismatch,
    recipient_balance_mismatch
ORDER BY
    type,
    sender_balance_mismatch,
    recipient_balance_mismatch;
    
-- Compare the original system flags against the
-- dataset fraud labels.
-- True Positive: Fraud-labelled transaction that was flagged.
-- False Negative: Fraud-labelled transaction that was not flagged.
-- False Positive: Legitimate transaction that was flagged.
-- True Negative: Legitimate transaction that was not flagged.
SELECT
    SUM(CASE
        WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1
        ELSE 0
    END) AS true_positives,
    SUM(CASE
        WHEN isFraud = 1 AND isFlaggedFraud = 0 THEN 1
        ELSE 0
    END) AS false_negatives,
    SUM(CASE
        WHEN isFraud = 0 AND isFlaggedFraud = 1 THEN 1
        ELSE 0
    END) AS false_positives,
    SUM(CASE
        WHEN isFraud = 0 AND isFlaggedFraud = 0 THEN 1
        ELSE 0
    END) AS true_negatives
FROM transactions_clean;

-- Calculate the key performance indicators of the
-- original fraud detection system.
-- Detection rate (Recall): Percentage of fraud cases detected.
-- Missed fraud rate: Percentage of fraud cases not detected.
-- Precision: Percentage of flagged cases that were fraud.
-- False positive rate: Percentage of legitimate cases flagged.
-- Accuracy: Percentage of all transactions classified correctly.
SELECT
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1
            ELSE 0
        END) /
        NULLIF(SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END), 0),
        4
    ) AS detection_rate_pct,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 AND isFlaggedFraud = 0 THEN 1
            ELSE 0
        END) /
        NULLIF(SUM(CASE WHEN isFraud = 1 THEN 1 ELSE 0 END), 0),
        4
    ) AS missed_fraud_rate_pct,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 AND isFlaggedFraud = 1 THEN 1
            ELSE 0
        END) /
        NULLIF(SUM(CASE WHEN isFlaggedFraud = 1 THEN 1 ELSE 0 END), 0),
        4
    ) AS precision_pct,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 0 AND isFlaggedFraud = 1 THEN 1
            ELSE 0
        END) /
        NULLIF(SUM(CASE WHEN isFraud = 0 THEN 1 ELSE 0 END), 0),
        4
    ) AS false_positive_rate_pct,
    ROUND(
        100.0 * SUM(CASE
            WHEN isFraud = 1 AND isFlaggedFraud = 1
              OR isFraud = 0 AND isFlaggedFraud = 0
            THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS accuracy_pct
FROM transactions_clean;
