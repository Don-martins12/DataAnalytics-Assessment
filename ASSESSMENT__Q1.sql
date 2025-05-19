-- =============================================
-- High-Value Customers with Multiple Products
-- Identifies customers with both funded savings and investment plans
-- Sorted by total deposits (descending)
-- =============================================

WITH 
-- Customers with at least one funded savings plan
funded_savings_customers AS (
    SELECT DISTINCT 
        p.owner_id
    FROM 
        plans_plan p
    JOIN 
        savings_savingsaccount s ON p.id = s.plan_id
    WHERE 
        p.plan_type_id = 1  -- Savings plans
        AND p.is_deleted = 0  -- Active plans only
        AND p.is_archived = 0  -- Non-archived plans
        AND s.amount > 0  -- Has actual deposits
        AND s.transaction_status = 'success'  -- Successful transactions
),

-- Customers with at least one funded investment plan
funded_investment_customers AS (
    SELECT DISTINCT 
        p.owner_id
    FROM 
        plans_plan p
    JOIN 
        savings_savingsaccount s ON p.id = s.plan_id
    WHERE 
        p.plan_type_id = 2  -- Investment plans
        AND p.is_deleted = 0
        AND p.is_archived = 0
        AND s.amount > 0
        AND s.transaction_status = 'success'
),

-- Customers with both plan types (core requirement)
target_customers AS (
    SELECT owner_id FROM funded_savings_customers
    INTERSECT
    SELECT owner_id FROM funded_investment_customers
),

-- Count savings plans per customer
savings_counts AS (
    SELECT 
        p.owner_id,
        COUNT(DISTINCT p.id) AS savings_count
    FROM 
        plans_plan p
    JOIN 
        savings_savingsaccount s ON p.id = s.plan_id
    WHERE 
        p.plan_type_id = 1
        AND p.is_deleted = 0
        AND p.is_archived = 0
        AND s.amount > 0
        AND s.transaction_status = 'success'
    GROUP BY 
        p.owner_id
),

-- Count investment plans per customer
investment_counts AS (
    SELECT 
        p.owner_id,
        COUNT(DISTINCT p.id) AS investment_count
    FROM 
        plans_plan p
    JOIN 
        savings_savingsaccount s ON p.id = s.plan_id
    WHERE 
        p.plan_type_id = 2
        AND p.is_deleted = 0
        AND p.is_archived = 0
        AND s.amount > 0
        AND s.transaction_status = 'success'
    GROUP BY 
        p.owner_id
),

-- Calculate total deposits across all plans
total_deposits AS (
    SELECT 
        p.owner_id,
        SUM(s.amount) AS total_deposits
    FROM 
        plans_plan p
    JOIN 
        savings_savingsaccount s ON p.id = s.plan_id
    WHERE 
        p.is_deleted = 0
        AND p.is_archived = 0
        AND s.amount > 0
        AND s.transaction_status = 'success'
    GROUP BY 
        p.owner_id
)

-- Final result matching exact expected output format
SELECT 
    u.id AS owner_id,
    COALESCE(NULLIF(u.name, ''), 
             TRIM(CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')))) AS name,
    COALESCE(sc.savings_count, 0) AS savings_count,
    COALESCE(ic.investment_count, 0) AS investment_count,
    ROUND(COALESCE(td.total_deposits, 0), 2) AS total_deposits
FROM 
    users_customuser u
JOIN 
    target_customers tc ON u.id = tc.owner_id
LEFT JOIN 
    savings_counts sc ON u.id = sc.owner_id
LEFT JOIN 
    investment_counts ic ON u.id = ic.owner_id
LEFT JOIN 
    total_deposits td ON u.id = td.owner_id
WHERE 
    u.is_active = 1
    AND u.is_account_deleted = 0
ORDER BY 
    total_deposits DESC;