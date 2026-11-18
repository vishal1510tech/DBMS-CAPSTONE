-- ============================================================================
-- Capstone Project: Intelligent Library and Digital Resource Management System
-- Component: 03_security_dcl_tcl.sql (Data Control & Transaction Control Languages)
-- Covers: Roles, Permissions (GRANT/REVOKE), ACID Transactions, SAVEPOINT, ROLLBACK
-- ============================================================================

-- ============================================================================
-- SECTION A: DATA CONTROL LANGUAGE (DCL)
-- Enforces Principle of Least Privilege across academic library stakeholders
-- ============================================================================

-- Note: In standard enterprise RDBMS (PostgreSQL / MySQL 8.0 / Oracle):
-- 1. Create Roles
-- CREATE ROLE role_head_librarian;
-- CREATE ROLE role_desk_assistant;
-- CREATE ROLE role_member_readonly;
-- CREATE ROLE role_finance_auditor;

-- 2. Grant DDL and Full DML to Head Librarian
-- GRANT ALL PRIVILEGES ON resources, book_copies, circulation_transactions TO role_head_librarian;
-- GRANT ALL PRIVILEGES ON fines_and_penalties, fine_payments TO role_head_librarian;

-- 3. Grant Circulation Operation Privileges to Desk Assistants (No schema modification, no fine deletion)
-- GRANT SELECT, INSERT, UPDATE ON circulation_transactions TO role_desk_assistant;
-- GRANT SELECT, UPDATE ON book_copies TO role_desk_assistant;
-- GRANT SELECT, INSERT, UPDATE ON reservations TO role_desk_assistant;
-- GRANT SELECT, INSERT, UPDATE ON fines_and_penalties TO role_desk_assistant;
-- GRANT SELECT ON members, resources, authors, publishers TO role_desk_assistant;

-- 4. Grant Read-Only Privileges to Members (Public OPAC search)
-- GRANT SELECT ON resources, authors, publishers, categories, digital_assets TO role_member_readonly;
-- GRANT SELECT ON book_copies (copy_id, resource_id, rack_location, status) TO role_member_readonly;

-- 5. Grant Financial Privileges to Auditors
-- GRANT SELECT ON fines_and_penalties, fine_payments TO role_finance_auditor;

-- 6. Demonstrate REVOKE (Revoke direct table deletion capability from desk assistant)
-- REVOKE DELETE ON circulation_transactions FROM role_desk_assistant;
-- REVOKE DELETE ON fines_and_penalties FROM role_desk_assistant;


-- ============================================================================
-- SECTION B: TRANSACTION CONTROL LANGUAGE (TCL)
-- Guarantees ACID Properties: Atomicity, Consistency, Isolation, Durability
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TCL SCENARIO 1: ATOMIC BOOK CHECKOUT TRANSACTION (COMMIT)
-- Business Rule: A book copy checkout must atomically:
--   1. Decrement available copies in resources
--   2. Update copy status to 'Issued' in book_copies
--   3. Create a record in circulation_transactions
--   4. Increment the member's current_borrowed_count
-- ----------------------------------------------------------------------------
BEGIN TRANSACTION;

-- Step 1: Decrement available count for Resource ID 1 (Database System Concepts)
UPDATE resources 
SET available_copies = available_copies - 1 
WHERE resource_id = 1 AND available_copies > 0;

-- Step 2: Mark physical copy 104 as 'Issued'
UPDATE book_copies 
SET status = 'Issued' 
WHERE copy_id = 104 AND status = 'Available';

-- Step 3: Insert circulation transaction record
INSERT INTO circulation_transactions (
    transaction_id, copy_id, resource_id, member_id, 
    borrow_date, due_date, return_date, renewal_count, transaction_status
) VALUES (
    5024, 104, 1, 1005, 
    '2024-11-01', '2024-11-15', NULL, 0, 'Active'
);

-- Step 4: Increment member's active borrow tally
UPDATE members 
SET current_borrowed_count = current_borrowed_count + 1 
WHERE member_id = 1005;

-- Atomically commit the entire state transition
COMMIT;


-- ----------------------------------------------------------------------------
-- TCL SCENARIO 2: TRANSACTION ROLLBACK DEMONSTRATION
-- Scenario: Member tries to borrow, but validation discovers policy violation
-- (e.g. member account suspended or copy damaged), so all changes are discarded.
-- ----------------------------------------------------------------------------
BEGIN TRANSACTION;

-- Intended step: update book copy status
UPDATE book_copies 
SET status = 'Issued' 
WHERE copy_id = 105; -- Copy 105 is damaged ('Under Maintenance')

-- Policy check detects item is damaged and member 1010 is 'Suspended'.
-- Rollback discards any uncommitted changes, preserving database consistency.
ROLLBACK;


-- ----------------------------------------------------------------------------
-- TCL SCENARIO 3: SAVEPOINT & PARTIAL ROLLBACK DEMONSTRATION
-- Scenario: Member initiates multi-item bundle borrowing.
-- Book 1 succeeds, Savepoint is set. Book 2 encounters an issue and is aborted,
-- but Book 1 loan is retained and committed successfully.
-- ----------------------------------------------------------------------------
BEGIN TRANSACTION;

-- Process Book 1 (Resource 3, Copy 304)
UPDATE resources SET available_copies = available_copies - 1 WHERE resource_id = 3;
UPDATE book_copies SET status = 'Issued' WHERE copy_id = 304;
INSERT INTO circulation_transactions (transaction_id, copy_id, resource_id, member_id, borrow_date, due_date, transaction_status)
VALUES (5025, 304, 3, 1007, '2024-11-02', '2024-11-16', 'Active');
UPDATE members SET current_borrowed_count = current_borrowed_count + 1 WHERE member_id = 1007;

-- Set Savepoint after successful first loan
SAVEPOINT book1_checked_out;

-- Attempt Book 2 (Resource 4 - Introduction to Algorithms)
-- But Resource 4 has 0 available copies!
-- Intended operation fails validation:
-- Revert only the failed second book attempt while preserving Book 1
ROLLBACK TO SAVEPOINT book1_checked_out;

-- Commit the valid transaction (Book 1 only)
COMMIT;


-- ----------------------------------------------------------------------------
-- TCL SCENARIO 4: FINE SETTLEMENT WITH RECORDED PAYMENT RECEIPT
-- Business Rule: Settling a fine must record the payment ledger entry AND
-- update the fine record's paid_amount and fine_status atomically.
-- ----------------------------------------------------------------------------
BEGIN TRANSACTION;

-- Step 1: Create payment receipt record for Fine ID 9002
INSERT INTO fine_payments (payment_id, fine_id, payment_amount, payment_date, payment_method, receipt_reference)
VALUES (3004, 9002, 50.00, '2024-11-03', 'UPI', 'REC-UPI-20241103-4411');

-- Step 2: Update fine table to Paid (remaining 50.00 paid off)
UPDATE fines_and_penalties 
SET paid_amount = paid_amount + 50.00,
    fine_status = 'Paid'
WHERE fine_id = 9002;

COMMIT;
