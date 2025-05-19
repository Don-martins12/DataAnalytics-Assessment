-- Customer Lifetime Value Estimation
-- Calculates CLV based on account tenure and transaction volume

WITH 
-- Calculate customer transaction metrics
customer_transactions AS (
    SELECT 
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        u.date_joined,
        COUNT(s.id) AS total_transactions,
        SUM(s.amount) AS total_amount,
        AVG(s.amount) AS avg_transaction_amount
    FROM 
        users_customuser u
    LEFT JOIN 
        savings_savingsaccount s ON u.id = s.owner_id
    WHERE 
        s.transaction_status = 'success'
        AND s.amount > 0
    GROUP BY 
        u.id, u.first_name, u.last_name, u.date_joined
),

-- Calculate account tenure and CLV
customer_clv AS (
    SELECT 
        customer_id,
        name,
        TIMESTAMPDIFF(MONTH, date_joined, CURRENT_DATE) AS tenure_months,
        total_transactions,
        -- CLV formula: (total_transactions/tenure)*12*(avg_amount*0.001)
        (total_transactions / NULLIF(TIMESTAMPDIFF(MONTH, date_joined, CURRENT_DATE), 0)) * 12 * (avg_transaction_amount * 0.001) AS estimated_clv
    FROM 
        customer_transactions
    WHERE 
        TIMESTAMPDIFF(MONTH, date_joined, CURRENT_DATE) > 0  -- Exclude customers who joined this month
)

-- Final output
SELECT 
    customer_id,
    name,
    tenure_months,
    total_transactions,
    ROUND(estimated_clv, 2) AS estimated_clv
FROM 
    customer_clv
ORDER BY 
    estimated_clv DESC;