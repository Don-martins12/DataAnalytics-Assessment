-- Account Inactivity Alert
-- Identifies active accounts with no deposits in the last 365 days

WITH 
-- Get the most recent transaction date for each active plan
last_transactions AS (
    SELECT 
        p.id AS plan_id,
        p.owner_id,
        p.plan_type_id,
        MAX(s.transaction_date) AS last_transaction_date,
        DATEDIFF(CURRENT_DATE, MAX(s.transaction_date)) AS inactivity_days
    FROM 
        plans_plan p
    LEFT JOIN 
        savings_savingsaccount s ON p.id = s.plan_id
    WHERE 
        p.is_deleted = 0 
        AND p.is_archived = 0
        AND s.transaction_status = 'success'
        AND s.amount > 0
    GROUP BY 
        p.id, p.owner_id, p.plan_type_id
)

-- Final result: inactive accounts
SELECT 
    plan_id,
    owner_id,
    CASE 
        WHEN plan_type_id = 1 THEN 'Savings'
        WHEN plan_type_id = 2 THEN 'Investment'
        ELSE 'Other'
    END AS type,
    last_transaction_date,
    inactivity_days
FROM 
    last_transactions
WHERE 
    inactivity_days >= 365
    OR (last_transaction_date IS NULL AND inactivity_days IS NULL)
ORDER BY 
    inactivity_days DESC;