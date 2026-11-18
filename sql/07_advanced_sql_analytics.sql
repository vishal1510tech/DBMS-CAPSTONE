-- ============================================================================
-- Capstone Project: Intelligent Library and Digital Resource Management System
-- Component: 07_advanced_sql_analytics.sql
-- Covers: Window Functions (ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD, Cumulative SUM)
--         and Common Table Expressions (CTEs, including Recursive Category Hierarchy)
-- ============================================================================

-- ============================================================================
-- SECTION A: ADVANCED WINDOW FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. RANK() & DENSE_RANK(): RESOURCE POPULARITY RANKING WITHIN EACH CATEGORY
-- Ranks resources by borrow demand partitioned by category to highlight top titles.
-- ----------------------------------------------------------------------------
WITH ResourceCirculationStats AS (
    SELECT 
        r.resource_id,
        r.title,
        c.category_name,
        COUNT(ct.transaction_id) AS borrow_count
    FROM resources r
    INNER JOIN categories c ON r.category_id = c.category_id
    LEFT JOIN circulation_transactions ct ON r.resource_id = ct.resource_id
    GROUP BY r.resource_id, r.title, c.category_name
)
SELECT 
    category_name,
    title,
    borrow_count,
    RANK() OVER (
        PARTITION BY category_name 
        ORDER BY borrow_count DESC
    ) AS category_popularity_rank,
    DENSE_RANK() OVER (
        ORDER BY borrow_count DESC
    ) AS global_dense_rank
FROM ResourceCirculationStats
ORDER BY category_name, category_popularity_rank;


-- ----------------------------------------------------------------------------
-- 2. NTILE(4): MEMBER PATRONAGE QUARTILE SEGMENTATION
-- Segments registered patrons into 4 tiers (Quartile 1: Power Users to Quartile 4: Dormant)
-- ----------------------------------------------------------------------------
WITH MemberActivity AS (
    SELECT 
        m.member_id,
        m.first_name || ' ' || m.last_name AS member_name,
        m.member_type,
        COUNT(ct.transaction_id) AS lifetime_transactions
    FROM members m
    LEFT JOIN circulation_transactions ct ON m.member_id = ct.member_id
    GROUP BY m.member_id, m.first_name, m.last_name, m.member_type
)
SELECT 
    member_id,
    member_name,
    member_type,
    lifetime_transactions,
    NTILE(4) OVER (
        ORDER BY lifetime_transactions DESC
    ) AS patron_activity_quartile,
    CASE NTILE(4) OVER (ORDER BY lifetime_transactions DESC)
        WHEN 1 THEN 'Tier 1: Power Patron'
        WHEN 2 THEN 'Tier 2: Regular Borrower'
        WHEN 3 THEN 'Tier 3: Occasional Reader'
        WHEN 4 THEN 'Tier 4: Infrequent / Inactive'
    END AS patron_segment_label
FROM MemberActivity
ORDER BY lifetime_transactions DESC, member_id ASC;


-- ----------------------------------------------------------------------------
-- 3. LAG() & LEAD(): BORROWING CADENCE & INTERVAL ANALYSIS
-- Computes the days elapsed between successive checkouts by each individual member.
-- ----------------------------------------------------------------------------
WITH MemberLoanChronology AS (
    SELECT 
        ct.member_id,
        m.first_name || ' ' || m.last_name AS member_name,
        ct.transaction_id,
        r.title,
        ct.borrow_date,
        LAG(ct.borrow_date, 1) OVER (
            PARTITION BY ct.member_id 
            ORDER BY ct.borrow_date
        ) AS previous_borrow_date,
        LEAD(ct.borrow_date, 1) OVER (
            PARTITION BY ct.member_id 
            ORDER BY ct.borrow_date
        ) AS next_borrow_date
    FROM circulation_transactions ct
    INNER JOIN members m ON ct.member_id = m.member_id
    INNER JOIN resources r ON ct.resource_id = r.resource_id
)
SELECT 
    member_name,
    title,
    borrow_date,
    previous_borrow_date,
    ROUND(JULIANDAY(borrow_date) - JULIANDAY(previous_borrow_date), 0) AS days_since_last_checkout,
    next_borrow_date
FROM MemberLoanChronology
ORDER BY member_name, borrow_date;


-- ----------------------------------------------------------------------------
-- 4. CUMULATIVE RUNNING TOTALS & MOVING AGGREGATES
-- Computes cumulative fine payments collected chronologically across the fiscal year.
-- ----------------------------------------------------------------------------
SELECT 
    fp.payment_id,
    fp.payment_date,
    fp.payment_amount,
    fp.payment_method,
    SUM(fp.payment_amount) OVER (
        ORDER BY fp.payment_date, fp.payment_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue_collected,
    AVG(fp.payment_amount) OVER (
        ORDER BY fp.payment_date, fp.payment_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_last_3_receipts
FROM fine_payments fp
ORDER BY fp.payment_date ASC;


-- ============================================================================
-- SECTION B: COMMON TABLE EXPRESSIONS (CTEs)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 5. RECURSIVE CTE: HIERARCHICAL CATEGORY TAXONOMY TREE
-- Traverses the self-referential categories table recursively from root
-- categories down through all nested subdisciplines with depth level and full path.
-- ----------------------------------------------------------------------------
WITH RECURSIVE CategoryHierarchy AS (
    -- Anchor member: select top-level root categories (parent_category_id is NULL)
    SELECT 
        category_id,
        category_name,
        parent_category_id,
        0 AS depth_level,
        category_name AS full_hierarchy_path
    FROM categories
    WHERE parent_category_id IS NULL

    UNION ALL

    -- Recursive member: join children to the hierarchy accumulated so far
    SELECT 
        c.category_id,
        c.category_name,
        c.parent_category_id,
        ch.depth_level + 1 AS depth_level,
        ch.full_hierarchy_path || ' -> ' || c.category_name AS full_hierarchy_path
    FROM categories c
    INNER JOIN CategoryHierarchy ch ON c.parent_category_id = ch.category_id
)
SELECT 
    category_id,
    depth_level,
    full_hierarchy_path
FROM CategoryHierarchy
ORDER BY full_hierarchy_path ASC;


-- ----------------------------------------------------------------------------
-- 6. MULTI-STEP ANALYTICAL CTE: HIGH-RISK DEFAULTER PROFILE
-- Chains multiple CTEs to detect members who combine:
-- (a) active overdue loans,
-- (b) accumulated unpaid fines, and
-- (c) outstanding waitlist reservations.
-- ----------------------------------------------------------------------------
WITH MemberOverdueCount AS (
    SELECT 
        member_id,
        COUNT(transaction_id) AS overdue_books_count
    FROM circulation_transactions
    WHERE transaction_status = 'Overdue'
    GROUP BY member_id
),
MemberUnpaidFines AS (
    SELECT 
        member_id,
        SUM(fine_amount - paid_amount) AS total_unpaid_amount
    FROM fines_and_penalties
    WHERE fine_status IN ('Unpaid', 'Partially Paid')
    GROUP BY member_id
),
MemberActiveWaitlists AS (
    SELECT 
        member_id,
        COUNT(reservation_id) AS pending_reservations_count
    FROM reservations
    WHERE reservation_status = 'Pending'
    GROUP BY member_id
)
SELECT 
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.member_type,
    m.membership_status,
    COALESCE(moc.overdue_books_count, 0) AS overdue_count,
    COALESCE(muf.total_unpaid_amount, 0.00) AS total_fine_arrears,
    COALESCE(maw.pending_reservations_count, 0) AS active_reservations,
    CASE 
        WHEN COALESCE(muf.total_unpaid_amount, 0) > 200.00 OR COALESCE(moc.overdue_books_count, 0) >= 1 
            THEN 'HIGH RISK - SUSPEND PRIVILEGES'
        ELSE 'STANDARD STANDING'
    END AS risk_assessment
FROM members m
LEFT JOIN MemberOverdueCount moc ON m.member_id = moc.member_id
LEFT JOIN MemberUnpaidFines muf ON m.member_id = muf.member_id
LEFT JOIN MemberActiveWaitlists maw ON m.member_id = maw.member_id
WHERE COALESCE(moc.overdue_books_count, 0) > 0 OR COALESCE(muf.total_unpaid_amount, 0) > 0
ORDER BY total_fine_arrears DESC, overdue_count DESC;
