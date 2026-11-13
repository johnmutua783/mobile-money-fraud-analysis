# Mobile Money Fraud Analysis

## Project Overview

This project analyses a large synthetic mobile-money transaction dataset to understand fraudulent transaction patterns, assess transaction risk, and evaluate how effectively the original fraud-flagging system identified suspicious activity.

The analysis was carried out using **MySQL** for data preparation and analysis, and **Power BI** for interactive data visualisation.

The project focuses on turning transaction-level data into clear findings that could help a business understand where fraud is concentrated, which transaction patterns deserve closer attention, and where fraud-detection controls may be falling short.

## Business Questions

The analysis was guided by the following questions:

1. How many transactions are recorded, and what proportion are labelled as fraudulent?
2. Which transaction types account for the most fraud cases?
3. Which transaction types have the highest fraud rates and fraud transaction values?
4. How does the fraud rate vary across transaction amount ranges?
5. How do sender and recipient balance mismatches vary across transaction types?
6. How did the original system perform when flagging fraudulent transactions?

## Tools Used

- **MySQL** – data import, cleaning, validation, exploratory analysis, and advanced SQL analysis.
- **Power BI Desktop** – data modelling, DAX measures, and dashboard development.

## Dataset

The project uses a synthetic mobile-money transaction dataset containing **6,362,620 transaction records**.

The data includes fields such as:

- `step` – simulated hourly time-step in the dataset.
- `type` – transaction type, such as TRANSFER, CASH_OUT, PAYMENT, DEBIT, and CASH_IN.
- `amount` – transaction amount.
- `oldbalanceOrg` and `newbalanceOrig` – sender balance before and after the transaction.
- `oldbalanceDest` and `newbalanceDest` – recipient balance before and after the transaction.
- `isFraud` – dataset label indicating whether a transaction is classified as fraudulent.
- `isFlaggedFraud` – flag indicating whether the original system flagged the transaction.

**Data note:** The dataset's currency is not specified. Amounts and transaction values are therefore described in dataset units rather than being labelled as KES, USD, or another currency. The dataset is synthetic, and its labels should not be interpreted as verified real-world fraud outcomes.

## Data Preparation and Quality Checks

The original imported table was retained as `transactions_raw`. A separate cleaned table, `transactions_clean`, was created for analysis.

Preparation and validation included:

- Checking the total number of records.
- Checking for missing values.
- Checking for negative transaction amounts and balances.
- Validating fraud-label values.
- Checking for exact duplicate rows.
- Reviewing sender and recipient balance behaviour.
- Creating additional balance-mismatch indicators for analysis.

Two additional fields were created:

- `sender_balance_mismatch`
- `recipient_balance_mismatch`

These indicators compare the observed balance changes with simplified expected balance equations, using a small tolerance. They are analytical indicators, not proof of fraud or data corruption. The balance equations do not apply uniformly to every transaction type in this synthetic dataset.

### Data Quality Summary

| Check | Result |
|---|---:|
| Total records | 6,362,620 |
| Missing values | 0 |
| Negative amounts / balances | 0 |
| Invalid fraud labels | 0 |
| Exact duplicate rows | 0 |

## Analysis Approach

### 1. SQL Analysis

SQL was used to profile the data and answer the business questions. The analysis covered:

- Transaction volume by type.
- Fraudulent and legitimate transaction counts.
- Fraud rate by transaction type.
- Fraud transaction value and average fraud amount.
- Fraud rate across transaction amount bands.
- Simulated daily transaction and fraud trends.
- Sender and recipient balance mismatch patterns.
- Original fraud-flagging system performance.

The simulated `step` field represents an hourly counter, not a real date or timestamp. For trend analysis, it was grouped into simulated days using 24 steps per day.

### 2. Power BI Dashboard

The Power BI report was kept to **two pages** to make the findings straightforward and easy to follow.

#### Page 1 – Fraud Overview

This page provides a high-level view of the dataset and the overall fraud situation.

It includes:

- Total transactions.
- Fraudulent transactions.
- Fraud rate.
- Total fraud transaction value.
- Fraudulent transaction counts by transaction type.
- Fraud trends by simulated day.
- A transaction-type slicer.

#### Page 2 – Fraud Patterns & Behaviour

This page explores patterns associated with fraudulent transactions.

It includes:

- Fraud rate by transaction amount range.
- Fraud transaction value by transaction type.
- Sender and recipient balance mismatch rates by transaction type.
- A transaction-type slicer.

The dashboard intentionally excludes a more complex matrix visual and a separate detection-effectiveness page in order to keep the report focused and accessible.

## Key Findings

### Overall Fraud

- The dataset contains **6,362,620 transactions**.
- **8,213 transactions** are labelled as fraudulent.
- The overall fraud rate is approximately **0.1291%**.
- The total value of transactions labelled as fraudulent is **12,056,415,427.84 dataset units**.
- The average amount of a fraud-labelled transaction is approximately **1,467,967.30 dataset units**.

The total fraud transaction value is the sum of amounts associated with fraud-labelled records. It should not be treated as confirmed financial loss.

### Fraud by Transaction Type

| Transaction type | Fraud cases | Fraud rate |
|---|---:|---:|
| CASH_OUT | 4,116 | 0.1840% |
| TRANSFER | 4,097 | 0.7688% |
| PAYMENT | 0 | 0% |
| DEBIT | 0 | 0% |
| CASH_IN | 0 | 0% |

- CASH_OUT recorded the highest number of fraud-labelled transactions.
- TRANSFER had the highest fraud rate at **0.7688%**.
- The TRANSFER fraud rate was approximately **4.18 times** the CASH_OUT fraud rate.

### Fraud by Transaction Amount

| Amount range | Fraud cases | Fraud rate |
|---|---:|---:|
| Below 10K | 278 | 0.0216% |
| 10K - 100K | 1,429 | 0.0638% |
| 100K - 500K | 2,642 | 0.1058% |
| 500K - 1M | 1,158 | 0.5523% |
| Above 1M | 2,706 | 2.0716% |

The fraud rate increased across the transaction amount bands. Transactions above 1 million dataset units had the highest observed fraud rate, at **2.0716%**. This is an association in the dataset, not evidence that a high transaction amount causes fraud.

### Balance Behaviour

The analysis identified sender and recipient balance mismatches across the dataset. These patterns varied by transaction type.

A notable result was that **4,076 of 6,150 TRANSFER transactions** where the sender balance reconciled but the recipient balance did not were labelled as fraudulent, giving that specific group a fraud rate of **66.2764%**.

This result applies only to that specific combination of transaction type and balance indicators. Balance mismatches should be interpreted in the context of transaction type and the synthetic dataset's behaviour; they are not, on their own, proof of fraud.

### Original Fraud-Flagging System

The original system flagged only **16 of the 8,213 fraud-labelled transactions**.

| Metric | Result |
|---|---:|
| True positives | 16 |
| False negatives | 8,197 |
| False positives | 0 |
| True negatives | 6,354,407 |
| Detection rate (recall) | 0.1948% |
| Missed fraud rate | 99.8052% |
| Precision | 100% |
| Accuracy | 99.8712% |

Although the system recorded 99.8712% accuracy, it missed almost all fraud-labelled transactions. This illustrates why accuracy alone can be misleading when a dataset is highly imbalanced. Detection rate (recall) is especially important when evaluating how many fraudulent transactions a system actually identifies.

## Business Recommendations

Based on the patterns observed in this dataset:

1. **Review TRANSFER transactions more closely.** They had the highest fraud rate and the highest total fraud transaction value.
2. **Apply risk-based checks to high-value transactions.** Higher amount bands showed higher observed fraud rates, so transaction amount can be considered alongside other risk indicators.
3. **Use transaction-type-specific balance rules.** Balance mismatches should be interpreted according to transaction type rather than treated as a universal fraud signal.
4. **Improve fraud detection coverage.** The original system flagged very few fraud-labelled records, indicating that its detection approach would need substantial improvement in this dataset.
5. **Monitor recall as well as accuracy.** A system should be assessed on how much fraud it detects, not just its overall percentage of correct classifications.

These recommendations are based on patterns in a synthetic dataset and would need validation against real operational data before being used in a live fraud-monitoring environment.


## Conclusion

This project demonstrates how SQL and Power BI can be used together to investigate a large transaction dataset, identify fraud patterns, examine balance behaviour, and evaluate the performance of an existing fraud-flagging process.

The analysis highlights the importance of looking beyond overall transaction counts and accuracy. Transaction type, amount range, balance behaviour, and fraud-detection recall provide additional insight into where risks may be concentrated and where controls may need improvement.

---

**Disclaimer:** This project is for learning and portfolio demonstration. It uses synthetic data and does not establish actual financial losses, real-world fraud, or the performance of a production financial institution's fraud-detection system.
