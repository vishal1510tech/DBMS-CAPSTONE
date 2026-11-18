-- ============================================================================
-- Capstone Project: Intelligent Library and Digital Resource Management System
-- Component: 05_set_operations.sql
-- Covers: UNION, UNION ALL, INTERSECT, and EXCEPT (MINUS)
-- ============================================================================

-- ============================================================================
-- 1. UNION: CONSOLIDATED DIRECTORY OF ALL REGISTERED STAKEHOLDERS
-- Combines unique contact directory from authors and members, eliminating duplicates.
-- ============================================================================
SELECT 
    first_name, 
    last_name, 
    email, 
    'Author' AS stakeholder_role
FROM authors
WHERE email IS NOT NULL

UNION

SELECT 
    first_name, 
    last_name, 
    email, 
    'Library Member' AS stakeholder_role
FROM members
ORDER BY last_name, first_name;


-- ============================================================================
-- 2. UNION ALL: UNIFIED STREAM OF RESOURCE DEMAND SIGNALS
-- Combines direct circulation borrow requests and pending reservation requests
-- into a single comprehensive demand audit trail (retaining duplicates).
-- ============================================================================
SELECT 
    r.title,
    ct.member_id,
    ct.borrow_date AS event_date,
    'Physical/Digital Loan' AS interaction_type
FROM circulation_transactions ct
INNER JOIN resources r ON ct.resource_id = r.resource_id

UNION ALL

SELECT 
    r.title,
    resv.member_id,
    resv.reservation_date AS event_date,
    'Waitlist Reservation' AS interaction_type
FROM reservations resv
INNER JOIN resources r ON resv.resource_id = r.resource_id
ORDER BY event_date DESC;


-- ============================================================================
-- 3. INTERSECT: HYBRID RESOURCE CONSUMERS (PHYSICAL & DIGITAL)
-- Identifies versatile members who have engaged with BOTH physical book loans
-- AND digital electronic assets.
-- ============================================================================
-- Members who have borrowed at least one physical copy:
SELECT 
    m.member_id,
    m.first_name,
    m.last_name,
    m.member_type
FROM members m
INNER JOIN circulation_transactions ct ON m.member_id = ct.member_id
WHERE ct.copy_id IS NOT NULL

INTERSECT

-- Members who have checked out at least one digital resource:
SELECT 
    m.member_id,
    m.first_name,
    m.last_name,
    m.member_type
FROM members m
INNER JOIN circulation_transactions ct ON m.member_id = ct.member_id
WHERE ct.copy_id IS NULL;


-- ============================================================================
-- 4. EXCEPT (MINUS in Oracle): PURE PHYSICAL PATRONS
-- Finds members who have borrowed physical inventory but NEVER checked out
-- any digital electronic resource.
-- ============================================================================
SELECT 
    m.member_id,
    m.first_name,
    m.last_name,
    m.email
FROM members m
INNER JOIN circulation_transactions ct ON m.member_id = ct.member_id
WHERE ct.copy_id IS NOT NULL

EXCEPT

SELECT 
    m.member_id,
    m.first_name,
    m.last_name,
    m.email
FROM members m
INNER JOIN circulation_transactions ct ON m.member_id = ct.member_id
WHERE ct.copy_id IS NULL;


-- ============================================================================
-- 5. EXCEPT (MINUS): DORMANT CATALOG RESOURCES
-- Identifies catalog resources that have NEVER been borrowed by any member.
-- Useful for inventory re-evaluation and shelf pruning.
-- ============================================================================
SELECT 
    resource_id,
    title,
    resource_type
FROM resources

EXCEPT

SELECT DISTINCT
    r.resource_id,
    r.title,
    r.resource_type
FROM resources r
INNER JOIN circulation_transactions ct ON r.resource_id = ct.resource_id;
