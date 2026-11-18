-- ============================================================================
-- Capstone Project: Intelligent Library and Digital Resource Management System
-- Component: 01_schema_ddl.sql (Data Definition Language)
-- Target RDBMS: Standard SQL / SQLite3 / PostgreSQL / MySQL 8.0+ compatible
-- ============================================================================

-- Drop tables in reverse order of foreign key dependencies
DROP TABLE IF EXISTS fine_payments;
DROP TABLE IF EXISTS fines_and_penalties;
DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS circulation_transactions;
DROP TABLE IF EXISTS digital_assets;
DROP TABLE IF EXISTS book_copies;
DROP TABLE IF EXISTS resource_authors;
DROP TABLE IF EXISTS resources;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS publishers;

-- ============================================================================
-- 1. PUBLISHERS TABLE
-- Stores publishing houses releasing books, journals, and digital assets
-- ============================================================================
CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    contact_email VARCHAR(100),
    phone VARCHAR(25),
    address VARCHAR(255),
    country VARCHAR(60) NOT NULL DEFAULT 'India',
    established_year INTEGER CHECK (established_year BETWEEN 1400 AND 2100)
);

-- ============================================================================
-- 2. AUTHORS TABLE
-- Stores individual authors, editors, and research contributors
-- ============================================================================
CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(100) UNIQUE,
    nationality VARCHAR(60) DEFAULT 'International',
    biography TEXT
);

-- ============================================================================
-- 3. CATEGORIES TABLE (Self-Referential / Hierarchical)
-- Supports subcategories (e.g., Computer Science -> Artificial Intelligence)
-- Facilitates Recursive Common Table Expressions (CTEs)
-- ============================================================================
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE,
    parent_category_id INTEGER,
    description TEXT,
    CONSTRAINT fk_category_parent FOREIGN KEY (parent_category_id) 
        REFERENCES categories(category_id) ON DELETE SET NULL
);

-- ============================================================================
-- 4. RESOURCES TABLE (Master Resource Catalog)
-- Holds metadata common to physical books, e-books, journals, and audiobooks
-- ============================================================================
CREATE TABLE resources (
    resource_id INTEGER PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    isbn_issn VARCHAR(20) NOT NULL UNIQUE,
    resource_type VARCHAR(30) NOT NULL CHECK (resource_type IN ('Physical Book', 'E-Book', 'Journal', 'Audiobook', 'Conference Proceeding')),
    category_id INTEGER NOT NULL,
    publisher_id INTEGER NOT NULL,
    publication_year INTEGER CHECK (publication_year BETWEEN 1800 AND 2100),
    edition VARCHAR(30) DEFAULT '1st Edition',
    language VARCHAR(40) DEFAULT 'English',
    total_copies INTEGER NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies INTEGER NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    CONSTRAINT fk_resource_category FOREIGN KEY (category_id) 
        REFERENCES categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_resource_publisher FOREIGN KEY (publisher_id) 
        REFERENCES publishers(publisher_id) ON DELETE RESTRICT,
    CONSTRAINT chk_copy_count CHECK (available_copies <= total_copies)
);

-- ============================================================================
-- 5. RESOURCE_AUTHORS TABLE (Many-to-Many Bridge)
-- Resolves M:N relationship between resources and multiple co-authors
-- ============================================================================
CREATE TABLE resource_authors (
    resource_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    author_role VARCHAR(40) DEFAULT 'Primary Author' CHECK (author_role IN ('Primary Author', 'Co-Author', 'Editor', 'Translator')),
    PRIMARY KEY (resource_id, author_id),
    CONSTRAINT fk_resauth_resource FOREIGN KEY (resource_id) 
        REFERENCES resources(resource_id) ON DELETE CASCADE,
    CONSTRAINT fk_resauth_author FOREIGN KEY (author_id) 
        REFERENCES authors(author_id) ON DELETE CASCADE
);

-- ============================================================================
-- 6. BOOK_COPIES TABLE (Physical Inventory Item Tracking)
-- Tracks individual physical copies, barcodes, rack locations, and item condition
-- ============================================================================
CREATE TABLE book_copies (
    copy_id INTEGER PRIMARY KEY,
    resource_id INTEGER NOT NULL,
    barcode VARCHAR(50) NOT NULL UNIQUE,
    rack_location VARCHAR(50) NOT NULL,
    item_condition VARCHAR(20) NOT NULL DEFAULT 'Good' CHECK (item_condition IN ('New', 'Good', 'Fair', 'Damaged', 'Lost')),
    status VARCHAR(20) NOT NULL DEFAULT 'Available' CHECK (status IN ('Available', 'Issued', 'Reserved', 'Under Maintenance')),
    acquisition_date DATE NOT NULL,
    purchase_price DECIMAL(10,2) CHECK (purchase_price >= 0),
    CONSTRAINT fk_copy_resource FOREIGN KEY (resource_id) 
        REFERENCES resources(resource_id) ON DELETE CASCADE
);

-- ============================================================================
-- 7. DIGITAL_ASSETS TABLE
-- Specific extension for electronic resources: e-books, journals, audio licenses
-- ============================================================================
CREATE TABLE digital_assets (
    asset_id INTEGER PRIMARY KEY,
    resource_id INTEGER NOT NULL UNIQUE,
    file_format VARCHAR(15) NOT NULL CHECK (file_format IN ('PDF', 'EPUB', 'MOBI', 'MP3', 'HTML')),
    file_size_mb DECIMAL(6,2) NOT NULL CHECK (file_size_mb > 0),
    download_url VARCHAR(255) NOT NULL,
    drm_protected CHAR(1) NOT NULL DEFAULT 'Y' CHECK (drm_protected IN ('Y', 'N')),
    max_concurrent_access INTEGER NOT NULL DEFAULT 5 CHECK (max_concurrent_access >= 1),
    access_expiry_date DATE,
    CONSTRAINT fk_asset_resource FOREIGN KEY (resource_id) 
        REFERENCES resources(resource_id) ON DELETE CASCADE
);

-- ============================================================================
-- 8. MEMBERS TABLE
-- Students, Faculty, Research Scholars with borrowing limits and active status
-- ============================================================================
CREATE TABLE members (
    member_id INTEGER PRIMARY KEY,
    first_name VARCHAR(60) NOT NULL,
    last_name VARCHAR(60) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(25) NOT NULL UNIQUE,
    member_type VARCHAR(20) NOT NULL CHECK (member_type IN ('Student', 'Faculty', 'Researcher', 'Alumni', 'Staff')),
    registration_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    max_borrow_limit INTEGER NOT NULL DEFAULT 3 CHECK (max_borrow_limit BETWEEN 1 AND 20),
    current_borrowed_count INTEGER NOT NULL DEFAULT 0 CHECK (current_borrowed_count >= 0),
    membership_status VARCHAR(15) NOT NULL DEFAULT 'Active' CHECK (membership_status IN ('Active', 'Suspended', 'Expired')),
    referred_by_member_id INTEGER,
    CONSTRAINT fk_member_referred FOREIGN KEY (referred_by_member_id) 
        REFERENCES members(member_id) ON DELETE SET NULL,
    CONSTRAINT chk_member_expiry CHECK (expiry_date >= registration_date),
    CONSTRAINT chk_borrow_limit CHECK (current_borrowed_count <= max_borrow_limit)
);

-- ============================================================================
-- 9. CIRCULATION_TRANSACTIONS TABLE
-- Complete lifecycle of resource loans: checkout, renewals, due dates, returns
-- ============================================================================
CREATE TABLE circulation_transactions (
    transaction_id INTEGER PRIMARY KEY,
    copy_id INTEGER,                      -- NULL if digital checkout
    resource_id INTEGER NOT NULL,          -- Direct resource reference
    member_id INTEGER NOT NULL,
    borrow_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,                     -- NULL while still on loan
    renewal_count INTEGER NOT NULL DEFAULT 0 CHECK (renewal_count BETWEEN 0 AND 5),
    transaction_status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (transaction_status IN ('Active', 'Returned', 'Overdue', 'Lost')),
    CONSTRAINT fk_circ_copy FOREIGN KEY (copy_id) 
        REFERENCES book_copies(copy_id) ON DELETE SET NULL,
    CONSTRAINT fk_circ_resource FOREIGN KEY (resource_id) 
        REFERENCES resources(resource_id) ON DELETE CASCADE,
    CONSTRAINT fk_circ_member FOREIGN KEY (member_id) 
        REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_due_date CHECK (due_date >= borrow_date),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= borrow_date)
);

-- ============================================================================
-- 10. RESERVATIONS TABLE
-- Waitlist management for copies that are currently checked out
-- ============================================================================
CREATE TABLE reservations (
    reservation_id INTEGER PRIMARY KEY,
    resource_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    reservation_date DATE NOT NULL,
    queue_priority INTEGER NOT NULL DEFAULT 1 CHECK (queue_priority >= 1),
    reservation_status VARCHAR(20) NOT NULL DEFAULT 'Pending' CHECK (reservation_status IN ('Pending', 'Fulfilled', 'Cancelled', 'Expired')),
    fulfilled_date DATE,
    CONSTRAINT fk_resv_resource FOREIGN KEY (resource_id) 
        REFERENCES resources(resource_id) ON DELETE CASCADE,
    CONSTRAINT fk_resv_member FOREIGN KEY (member_id) 
        REFERENCES members(member_id) ON DELETE CASCADE
);

-- ============================================================================
-- 11. FINES_AND_PENALTIES TABLE
-- Late returns and damaged item fines
-- ============================================================================
CREATE TABLE fines_and_penalties (
    fine_id INTEGER PRIMARY KEY,
    transaction_id INTEGER NOT NULL UNIQUE,
    member_id INTEGER NOT NULL,
    fine_type VARCHAR(30) NOT NULL CHECK (fine_type IN ('Overdue Late Fee', 'Damaged Item Fee', 'Lost Book Replacement Fee')),
    fine_amount DECIMAL(8,2) NOT NULL CHECK (fine_amount >= 0),
    paid_amount DECIMAL(8,2) NOT NULL DEFAULT 0.00 CHECK (paid_amount >= 0),
    fine_status VARCHAR(15) NOT NULL DEFAULT 'Unpaid' CHECK (fine_status IN ('Unpaid', 'Partially Paid', 'Paid', 'Waived')),
    assessed_date DATE NOT NULL,
    CONSTRAINT fk_fine_trans FOREIGN KEY (transaction_id) 
        REFERENCES circulation_transactions(transaction_id) ON DELETE CASCADE,
    CONSTRAINT fk_fine_member FOREIGN KEY (member_id) 
        REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT chk_paid_not_exceed CHECK (paid_amount <= fine_amount)
);

-- ============================================================================
-- 12. FINE_PAYMENTS TABLE
-- Ledger recording settlement payments made by members
-- ============================================================================
CREATE TABLE fine_payments (
    payment_id INTEGER PRIMARY KEY,
    fine_id INTEGER NOT NULL,
    payment_amount DECIMAL(8,2) NOT NULL CHECK (payment_amount > 0),
    payment_date DATE NOT NULL,
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('UPI', 'Credit Card', 'Debit Card', 'Net Banking', 'Cash')),
    receipt_reference VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT fk_pay_fine FOREIGN KEY (fine_id) 
        REFERENCES fines_and_penalties(fine_id) ON DELETE CASCADE
);
