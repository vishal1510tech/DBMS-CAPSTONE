-- ============================================================================
-- Capstone Project: Intelligent Library and Digital Resource Management System
-- Component: 06_views_and_indexing.sql
-- Covers: Minimum 3 Analytical Views, Strategic B-Tree & Composite Indexes,
--         and Query Optimization with EXPLAIN QUERY PLAN.
-- ============================================================================

-- ============================================================================
-- SECTION A: DATABASE VIEWS
-- Simplifies complex queries, hides sensitive data, and provides operational dashboards
-- ============================================================================

-- ----------------------------------------------------------------------------
-- VIEW 1: view_active_circulation_status
-- Operational dashboard for front-desk librarians tracking all active & overdue loans
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS view_active_circulation_status;
CREATE VIEW view_active_circulation_status AS
SELECT 
    ct.transaction_id,
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.member_type,
    m.phone AS member_contact,
    r.title AS resource_title,
    r.resource_type,
    COALESCE(bc.barcode, 'DIGITAL-LICENSE') AS copy_barcode,
    COALESCE(bc.rack_location, 'Digital Cloud Repository') AS location,
    ct.borrow_date,
    ct.due_date,
    ct.transaction_status,
    CASE 
        WHEN ct.transaction_status = 'Overdue' THEN ROUND((JULIANDAY(DATE('now')) - JULIANDAY(ct.due_date)), 0)
        ELSE 0
    END AS days_past_due
FROM circulation_transactions ct
INNER JOIN members m ON ct.member_id = m.member_id
INNER JOIN resources r ON ct.resource_id = r.resource_id
LEFT JOIN book_copies bc ON ct.copy_id = bc.copy_id
WHERE ct.transaction_status IN ('Active', 'Overdue');


-- ----------------------------------------------------------------------------
-- VIEW 2: view_resource_inventory_summary
-- Executive catalog intelligence showing total holdings, active checkouts, and utilization rate
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS view_resource_inventory_summary;
CREATE VIEW view_resource_inventory_summary AS
SELECT 
    r.resource_id,
    r.title,
    r.isbn_issn,
    c.category_name,
    p.name AS publisher_name,
    r.resource_type,
    r.total_copies,
    r.available_copies,
    (r.total_copies - r.available_copies) AS copies_currently_issued,
    COUNT(ct.transaction_id) AS lifetime_borrow_count,
    ROUND((CAST(r.total_copies - r.available_copies AS FLOAT) / NULLIF(r.total_copies, 0)) * 100.0, 1) AS utilization_rate_percent
FROM resources r
INNER JOIN categories c ON r.category_id = c.category_id
INNER JOIN publishers p ON r.publisher_id = p.publisher_id
LEFT JOIN circulation_transactions ct ON r.resource_id = ct.resource_id
GROUP BY r.resource_id, r.title, r.isbn_issn, c.category_name, p.name, r.resource_type, r.total_copies, r.available_copies;


-- ----------------------------------------------------------------------------
-- VIEW 3: view_member_financial_obligations
-- Accounting view tracking penalties assessed, payments received, and pending arrears
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS view_member_financial_obligations;
CREATE VIEW view_member_financial_obligations AS
SELECT 
    m.member_id,
    m.first_name || ' ' || m.last_name AS member_name,
    m.member_type,
    m.membership_status,
    COUNT(fp.fine_id) AS total_penalties_incurred,
    COALESCE(SUM(fp.fine_amount), 0.00) AS total_fine_assessed,
    COALESCE(SUM(fp.paid_amount), 0.00) AS total_fine_paid,
    COALESCE(SUM(fp.fine_amount - fp.paid_amount), 0.00) AS outstanding_balance
FROM members m
LEFT JOIN fines_and_penalties fp ON m.member_id = fp.member_id
GROUP BY m.member_id, m.first_name, m.last_name, m.member_type, m.membership_status;


-- ============================================================================
-- SECTION B: INDEXING STRATEGY
-- Strategic B-Tree and Composite Indexes to accelerate high-frequency lookup workloads
-- ============================================================================

-- 1. Accelerates member profile and checkout lookup
CREATE INDEX IF NOT EXISTS idx_circ_member 
ON circulation_transactions(member_id);

-- 2. Composite Index for Overdue Batch Jobs: covers status filtering and due_date sorting
CREATE INDEX IF NOT EXISTS idx_circ_status_duedate 
ON circulation_transactions(transaction_status, due_date);

-- 3. Composite Index for Physical Copy Inventory Availability
CREATE INDEX IF NOT EXISTS idx_copies_resource_status 
ON book_copies(resource_id, status);

-- 4. Accelerates fast catalog ISBN lookup
CREATE INDEX IF NOT EXISTS idx_resources_isbn 
ON resources(isbn_issn);

-- 5. Composite Index for Reservation Queue Dispatch
CREATE INDEX IF NOT EXISTS idx_reservations_queue 
ON reservations(resource_id, queue_priority, reservation_status);


-- ============================================================================
-- SECTION C: QUERY PLAN VERIFICATION (EXPLAIN QUERY PLAN)
-- Validates index usage and query cost optimization
-- ============================================================================

-- Demonstration 1: Querying overdue records using composite index idx_circ_status_duedate
EXPLAIN QUERY PLAN
SELECT transaction_id, due_date, member_id
FROM circulation_transactions
WHERE transaction_status = 'Overdue'
ORDER BY due_date ASC;

-- Demonstration 2: Available copies lookup using idx_copies_resource_status
EXPLAIN QUERY PLAN
SELECT copy_id, barcode, rack_location
FROM book_copies
WHERE resource_id = 1 AND status = 'Available';
