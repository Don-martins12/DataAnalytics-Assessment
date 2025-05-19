WITH 
-- Calculate monthly transaction counts per customer
monthly_transactions AS (
    SELECT 
        s.owner_id,
        DATE_FORMAT(s.transaction_date, '%Y-%m') AS month,
        COUNT(*) AS transaction_count
    FROM 
        savings_savingsaccount s
    WHERE 
        s.transaction_status = 'success'  -- Only count successful transactions
        AND s.amount > 0  -- Only count actual deposits
    GROUP BY 
        s.owner_id, 
        DATE_FORMAT(s.transaction_date, '%Y-%m')
),

-- Calculate average transactions per month per customer
customer_avg_transactions AS (
    SELECT 
        owner_id,
        AVG(transaction_count) AS avg_transactions_per_month
    FROM 
        monthly_transactions
    GROUP BY 
        owner_id
),

-- Categorize customers by frequency
frequency_categories AS (
    SELECT 
        CASE 
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_month >= 3 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category,
        COUNT(*) AS customer_count,
        ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month
    FROM 
        customer_avg_transactions
    GROUP BY 
        CASE 
            WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
            WHEN avg_transactions_per_month >= 3 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END
)

-- Final output matching requested format
SELECT 
    frequency_category,
    customer_count,
    avg_transactions_per_month
FROM 
    frequency_categories
WHERE 
    frequency_category IN ('High Frequency', 'Medium Frequency')
ORDER BY 
    CASE 
        WHEN frequency_category = 'High Frequency' THEN 1
        WHEN frequency_category = 'Medium Frequency' THEN 2
        ELSE 3
    END;