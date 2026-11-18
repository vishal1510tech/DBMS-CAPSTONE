-- ============================================================================
-- Capstone Project: Intelligent Library and Digital Resource Management System
-- Component: 04_basic_and_complex_queries.sql
-- Covers: Inner Joins, Left/Right/Self Joins, Nested Subqueries, Correlated Subqueries,
--         Overdue tracking, and resource circulation analytics.
-- ============================================================================

-- ============================================================================
-- 1. INNER JOIN: ACTIVE PHYSICAL CIRCULATION LEDGER
-- Retrieves active loans, mapping resource titles, copy barcodes, rack locations,
-- member names, and due dates.
-- ============================================================================
SELECT 
    ct.transaction_id,
    r.title AS resource_title,
    bc.barcode,
    bc.rack_location,
    m.first_name || ' ' || m.last_name AS borrower_name,
    m.member_type,
    ct.borrow_date,
    ct.due_date,
    ct.transaction_status
FROM circulation_transactions ct
INNER JOIN resources r ON ct.resource_id = r.resource_id
INNER JOIN book_copies bc ON ct.copy_id = bc.copy_id
INNER JOIN members m ON ct.member_id = m.member_id
WHERE ct.transaction_status IN ('Active', 'Overdue')
ORDER BY ct.due_date ASC;


-- ============================================================================
-- 2. LEFT OUTER JOIN: COMPLETE RESOURCE INVENTORY & DIGITAL ASSET STATUS
-- Displays all catalog resources regardless of whether they have digital assets
-- or active reservations.
-- ============================================================================
SELECT 
    r.resource_id,
    r.title,
    r.resource_type,
    p.name AS publisher_name,
    c.category_name,
    COALESCE(da.file_format, 'Physical Only') AS digital_format,
    COALESCE(da.download_url, 'N/A') AS access_link,
    COUNT(resv.reservation_id) AS total_pending_reservations
FROM resources r
INNER JOIN publishers p ON r.publisher_id = p.publisher_id
INNER JOIN categories c ON r.category_id = c.category_id
LEFT JOIN digital_assets da ON r.resource_id = da.resource_id
LEFT JOIN reservations resv ON r.resource_id = resv.resource_id AND resv.reservation_status = 'Pending'
GROUP BY r.resource_id, r.title, r.resource_type, p.name, c.category_name, da.file_format, da.download_url
ORDER BY total_pending_reservations DESC, r.title ASC;


-- ============================================================================
-- 3. LEFT/RIGHT OUTER JOIN PATTERN: INACTIVE MEMBER DISCOVERY
-- Identifies registered members who have never initiated any borrowing transaction.
-- ============================================================================
SELECT 
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.member_type,
    m.registration_date,
    m.membership_status
FROM members m
LEFT JOIN circulation_transactions ct ON m.member_id = ct.member_id
WHERE ct.transaction_id IS NULL;


-- ============================================================================
-- 4. SELF JOIN: HIERARCHICAL CATEGORY STRUCTURE
-- Joins the categories table to itself to display subcategories with parent categories.
-- ============================================================================
SELECT 
    sub.category_id AS subcategory_id,
    sub.category_name AS subcategory_name,
    COALESCE(parent.category_name, '[Top-Level Root]') AS parent_category_name,
    sub.description
FROM categories sub
LEFT JOIN categories parent ON sub.parent_category_id = parent.category_id
ORDER BY parent.category_name NULLS FIRST, sub.category_name ASC;


-- ============================================================================
-- 5. SELF JOIN: MEMBER REFERRAL NETWORK
-- Identifies peer-to-peer referral relationships among library members.
-- ============================================================================
SELECT 
    ref.member_id AS referring_member_id,
    ref.first_name || ' ' || ref.last_name AS referrer_name,
    ref.member_type AS referrer_type,
    m.member_id AS new_member_id,
    m.first_name || ' ' || m.last_name AS referred_member_name,
    m.registration_date AS join_date
FROM members m
INNER JOIN members ref ON m.referred_by_member_id = ref.member_id
ORDER BY ref.member_id ASC;


-- ============================================================================
-- 6. NESTED SUBQUERY (Single-Row): RESOURCES PUBLISHED IN THE MOST RECENT YEAR
-- Finds all catalog resources published in the newest publication year in the DB.
-- ============================================================================
SELECT 
    resource_id,
    title,
    isbn_issn,
    publication_year,
    resource_type
FROM resources
WHERE publication_year = (
    SELECT MAX(publication_year) 
    FROM resources
);


-- ============================================================================
-- 7. NESTED SUBQUERY WITH `IN`: MEMBERS WITH OUTSTANDING UNPAID FINES
-- Identifies member details for all individuals with unpaid or partial penalties.
-- ============================================================================
SELECT 
    member_id,
    first_name || ' ' || last_name AS member_name,
    email,
    phone,
    membership_status
FROM members
WHERE member_id IN (
    SELECT DISTINCT member_id 
    FROM fines_and_penalties 
    WHERE fine_status IN ('Unpaid', 'Partially Paid')
);


-- ============================================================================
-- 8. CORRELATED SUBQUERY: HIGH-DEFICIT PENALTY MEMBERS
-- Identifies members whose total unpaid penalties exceed the average unpaid fine
-- assessed across the entire library system.
-- ============================================================================
SELECT 
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.member_type,
    (
        SELECT SUM(fp.fine_amount - fp.paid_amount)
        FROM fines_and_penalties fp
        WHERE fp.member_id = m.member_id
          AND fp.fine_status IN ('Unpaid', 'Partially Paid')
    ) AS total_unpaid_fine
FROM members m
WHERE (
    SELECT COALESCE(SUM(fp.fine_amount - fp.paid_amount), 0)
    FROM fines_and_penalties fp
    WHERE fp.member_id = m.member_id
      AND fp.fine_status IN ('Unpaid', 'Partially Paid')
) > (
    SELECT AVG(fine_amount - paid_amount)
    FROM fines_and_penalties
    WHERE fine_status IN ('Unpaid', 'Partially Paid')
);


-- ============================================================================
-- 9. CORRELATED SUBQUERY WITH `EXISTS`: AUTHORS WITH ACTIVELY BORROWED WORKS
-- Employs EXISTS to locate authors who currently have at least one book copy
-- on active loan by a student or researcher.
-- ============================================================================
SELECT 
    a.author_id,
    a.first_name || ' ' || a.last_name AS author_name,
    a.nationality
FROM authors a
WHERE EXISTS (
    SELECT 1 
    FROM resource_authors ra
    INNER JOIN circulation_transactions ct ON ra.resource_id = ct.resource_id
    WHERE ra.author_id = a.author_id 
      AND ct.transaction_status = 'Active'
);


-- ============================================================================
-- 10. COMPLEX QUERY: OVERDUE AUDIT & AUTOMATED FINE PROJECTION
-- Evaluates overdue checkouts, days past due, borrower contact, and projected penalty.
-- ============================================================================
SELECT 
    ct.transaction_id,
    m.first_name || ' ' || m.last_name AS delinquent_member,
    m.email,
    m.phone,
    r.title AS resource_title,
    bc.barcode,
    ct.borrow_date,
    ct.due_date,
    DATE('now') AS evaluation_date,
    (JULIANDAY(DATE('now')) - JULIANDAY(ct.due_date)) AS days_overdue,
    ROUND((JULIANDAY(DATE('now')) - JULIANDAY(ct.due_date)) * 10.00, 2) AS calculated_penalty_rs
FROM circulation_transactions ct
INNER JOIN members m ON ct.member_id = m.member_id
INNER JOIN resources r ON ct.resource_id = r.resource_id
LEFT JOIN book_copies bc ON ct.copy_id = bc.copy_id
WHERE ct.transaction_status = 'Overdue'
ORDER BY days_overdue DESC;


-- ============================================================================
-- 11. AGGREGATE COMPLEX QUERY: TOP FREQUENTLY BORROWED RESOURCES
-- Calculates total circulation volume per resource with author and category details.
-- ============================================================================
SELECT 
    r.resource_id,
    r.title,
    c.category_name,
    p.name AS publisher_name,
    COUNT(ct.transaction_id) AS total_borrow_count,
    r.total_copies,
    r.available_copies
FROM resources r
INNER JOIN categories c ON r.category_id = c.category_id
INNER JOIN publishers p ON r.publisher_id = p.publisher_id
LEFT JOIN circulation_transactions ct ON r.resource_id = ct.resource_id
GROUP BY r.resource_id, r.title, c.category_name, p.name, r.total_copies, r.available_copies
ORDER BY total_borrow_count DESC, r.title ASC;
