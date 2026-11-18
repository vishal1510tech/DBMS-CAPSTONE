# Capstone Project Report
# Intelligent Library and Digital Resource Management System (ILDRMS)

**Course:** Database Management Systems (DBMS) Capstone  
**Project Selection:** Problem Statement #4  
**Total Evaluation Weight:** 100 Marks  

---

## Executive Summary

The **Intelligent Library and Digital Resource Management System (ILDRMS)** is a comprehensive, production-grade relational database project designed to address the challenges faced by modern hybrid academic and research libraries. The system unifies physical book circulation, digital asset management (e-books, research journals, audio licenses), member subscriptions, queue-based reservations, automated fine assessment, and advanced analytics on borrowing behavior.

The project strictly implements all syllabus components specified in the evaluation framework:
- Formal ER modeling with Mermaid visual diagrams and cardinality definitions.
- BCNF-compliant normalized relational schema across 12 interrelated tables.
- Comprehensive mathematical normalization proofs (1NF $\rightarrow$ 2NF $\rightarrow$ 3NF $\rightarrow$ BCNF).
- Full SQL coverage: DDL, DML, DCL, TCL, Inner/Outer/Self Joins, Nested and Correlated Subqueries, and Set Operations (`UNION`, `INTERSECT`, `EXCEPT`).
- Performance tuning via B-Tree & composite indexing with `EXPLAIN QUERY PLAN` verification.
- Advanced analytical intelligence using Window Functions (`RANK`, `DENSE_RANK`, `NTILE`, `LAG`, `LEAD`, cumulative totals) and Recursive Common Table Expressions (CTEs).
- Automated Python-based test and validation suite with 100% execution success.

---

## Module 1: Problem Identification & Requirements Analysis (10 Marks)

### 1.1 Problem Context & Background
Modern academic libraries no longer manage only printed books. They license hundreds of digital journals, e-books, and multimedia packages, while accommodating thousands of active students, faculty, and research scholars. Traditional library databases suffer from:
1. **Siloed Resource Tracking**: Physical books and digital resources are stored in disconnected databases.
2. **Data Redundancy & Inconsistency**: De-normalized catalogs lead to duplicate author records, divergent ISBN entries, and conflicting stock counts.
3. **Manual Fine & Return Processing**: Delays in calculating late fees and tracking payment receipts lead to revenue leakage.
4. **Lack of Operational Intelligence**: Librarians cannot easily detect bottleneck waitlists, chronic defaulters, or declining resource categories.

### 1.2 System Scope & Objectives
The ILDRMS database establishes:
- **Unified Cataloging**: A master catalog for both physical and electronic resources.
- **Physical Copy Inventory**: Shelf rack location, barcode serials, and condition wear tracking.
- **Digital Asset Management**: DRM restrictions, download links, file formats, and campus concurrency limits.
- **Automated Circulation**: Loan checkout, due-date calculation, renewal counters, and overdue flags.
- **Fair Waitlist Queuing**: Priority reservations when high-demand titles are fully checked out.
- **Penalty Ledger**: Strict accounting of assessed overdue/damage fees and installment receipts.

### 1.3 Key Stakeholders & Personas
| Role | Responsibility | Key Database Interactions |
| :--- | :--- | :--- |
| **Chief Librarian / Admin** | Catalog management, policy definition | Full DDL/DML, catalog updates, user privilege management |
| **Circulation Desk Staff** | Checkouts, returns, shelf inspections | Issue books, process returns, record fines, view queues |
| **Library Members (Patrons)** | Students, faculty, research scholars | Catalog search (OPAC), hold reservations, access digital assets |
| **Finance / Accounts Auditor**| Financial reconciliation | Monitor fine assessments, reconcile payment receipts |

---

## Module 2: ER Modeling & Database Schema Design (15 Marks)

### 2.1 Entity Identification
The system models 12 normalized relational entities:
1. `publishers`: Academic publishing houses.
2. `authors`: Book authors and research contributors.
3. `categories`: Self-referential taxonomy of academic disciplines.
4. `resources`: Master catalog metadata.
5. `resource_authors`: Associative bridge table resolving M:N author relationships.
6. `book_copies`: Individual physical shelf copies with barcodes and condition states.
7. `digital_assets`: Electronic asset details (1:1 extension with resources).
8. `members`: Library patrons with borrowing quotas and validity dates.
9. `circulation_transactions`: Core checkout, loan, and return lifecycle.
10. `reservations`: Waitlist queue entries for loaned-out titles.
11. `fines_and_penalties`: Late return and damaged copy penalty assessments.
12. `fine_payments`: Financial transactions settling outstanding fines.

### 2.2 Entity Relationship Diagram (Mermaid)
Refer to [`docs/er_diagram.md`](file:///c:/Users/Vishal/Projects/DBMS capstone/docs/er_diagram.md) for the complete visual diagram and entity attribute mapping.

### 2.3 Relational Schema & Key Mapping
```
publishers (publisher_id [PK], name [UK], contact_email, phone, address, country, established_year)
authors (author_id [PK], first_name, last_name, email [UK], nationality, biography)
categories (category_id [PK], category_name [UK], parent_category_id [FK -> categories.category_id], description)
resources (resource_id [PK], title, isbn_issn [UK], resource_type, category_id [FK -> categories.category_id], publisher_id [FK -> publishers.publisher_id], publication_year, edition, language, total_copies, available_copies)
resource_authors ((resource_id [FK], author_id [FK]) [PK], author_role)
book_copies (copy_id [PK], resource_id [FK -> resources.resource_id], barcode [UK], rack_location, item_condition, status, acquisition_date, purchase_price)
digital_assets (asset_id [PK], resource_id [FK, UK -> resources.resource_id], file_format, file_size_mb, download_url, drm_protected, max_concurrent_access, access_expiry_date)
members (member_id [PK], first_name, last_name, email [UK], phone [UK], member_type, registration_date, expiry_date, max_borrow_limit, current_borrowed_count, membership_status, referred_by_member_id [FK -> members.member_id])
circulation_transactions (transaction_id [PK], copy_id [FK -> book_copies.copy_id], resource_id [FK -> resources.resource_id], member_id [FK -> members.member_id], borrow_date, due_date, return_date, renewal_count, transaction_status)
reservations (reservation_id [PK], resource_id [FK -> resources.resource_id], member_id [FK -> members.member_id], reservation_date, queue_priority, reservation_status, fulfilled_date)
fines_and_penalties (fine_id [PK], transaction_id [FK, UK -> circulation_transactions.transaction_id], member_id [FK -> members.member_id], fine_type, fine_amount, paid_amount, fine_status, assessed_date)
fine_payments (payment_id [PK], fine_id [FK -> fines_and_penalties.fine_id], payment_amount, payment_date, payment_method, receipt_reference [UK])
```

---

## Module 3: Normalization & Integrity Constraints (15 Marks)

### 3.1 Normalization Progression
The design systematically eliminates redundancy and anomalies by progressing through normal forms:
- **1NF**: Elimination of repeating groups and multi-valued fields; enforce atomic attributes (`first_name`, `last_name`, single barcode per copy).
- **2NF**: Elimination of partial dependencies on composite keys in `resource_authors`.
- **3NF**: Elimination of transitive functional dependencies ($\text{resource} \rightarrow \text{publisher\_id} \rightarrow \text{publisher\_name}$).
- **BCNF**: Verification that in every non-trivial functional dependency $X \rightarrow Y$, determinant $X$ is a superkey.

See [`docs/normalization_proofs.md`](file:///c:/Users/Vishal/Projects/DBMS capstone/docs/normalization_proofs.md) for full functional dependency proofs and lossless join decomposition verification.

### 3.2 Integrity Constraints Enforced
1. **Domain Constraints**: `CHECK` constraints on valid years, positive quantities, valid enum categories, and non-negative currency amounts.
2. **Entity Integrity**: Primary keys defined on every relation with non-null uniqueness.
3. **Referential Integrity**: Foreign keys with explicitly selected cascade actions (`ON DELETE CASCADE`, `ON DELETE RESTRICT`, `ON DELETE SET NULL`).
4. **Operational Business Rules**:
   - `CHECK (available_copies <= total_copies)`
   - `CHECK (current_borrowed_count <= max_borrow_limit)`
   - `CHECK (due_date >= borrow_date)`
   - `CHECK (paid_amount <= fine_amount)`

---

## Module 4: SQL Implementation & Query Development (25 Marks)

All scripts are modularized in the `sql/` directory:
- `sql/01_schema_ddl.sql`: 12 tables, keys, constraints, and cascades.
- `sql/02_seed_data_dml.sql`: Over 100 realistic records spanning computer science, mathematics, AI, and distributed systems.
- `sql/03_security_dcl_tcl.sql`: Role-based security (`GRANT`, `REVOKE`) and ACID transaction management (`COMMIT`, `ROLLBACK`, `SAVEPOINT`).
- `sql/04_basic_and_complex_queries.sql`:
  - **Inner Joins**: Complete active circulation ledger mapping loans to physical rack locations and patron names.
  - **Left Outer Joins**: Catalog inventory audit with digital formats and pending waitlist counts.
  - **Self Joins**: Category discipline trees and patron referral networks.
  - **Single & Multi-Row Subqueries**: Newest publications, zero-loan members, and members with unpaid fines.
  - **Correlated Subqueries with `EXISTS`**: Authors with actively checked-out works; members with fine balances exceeding institutional averages.
  - **Overdue Audit**: Calculates days overdue and projected late fees.
- `sql/05_set_operations.sql`:
  - `UNION`: Consolidated directory of all registered authors and members.
  - `UNION ALL`: Combined resource demand stream (loans + reservations).
  - `INTERSECT`: Patrons borrowing both physical books and digital electronic assets.
  - `EXCEPT` (`MINUS`): Pure physical patrons; dormant resources never borrowed.

---

## Module 5: Advanced SQL, Views & Indexing (15 Marks)

### 5.1 Analytical Views (`sql/06_views_and_indexing.sql`)
1. `view_active_circulation_status`: Real-time front-desk operational dashboard tracking active loans, overdue items, rack locations, and overdue day counters.
2. `view_resource_inventory_summary`: Executive catalog summary showing total copies, issued copies, lifetime borrow counts, and percent utilization rate.
3. `view_member_financial_obligations`: Finance ledger aggregating fines assessed, payments collected, and outstanding balances per member.

### 5.2 Indexing Strategy & Optimization
To optimize search performance:
- `idx_circ_member`: B-Tree index on `circulation_transactions(member_id)`.
- `idx_circ_status_duedate`: Composite index on `circulation_transactions(transaction_status, due_date)` for fast overdue batch jobs.
- `idx_copies_resource_status`: Composite index on `book_copies(resource_id, status)` for fast shelf copy lookups.
- `idx_resources_isbn`: B-Tree index on `resources(isbn_issn)` for catalog searches.
- `idx_reservations_queue`: Composite index on `reservations(resource_id, queue_priority, reservation_status)`.

`EXPLAIN QUERY PLAN` confirms the query optimizer performs index seeks (`SEARCH TABLE ... USING INDEX`) instead of sequential scans.

### 5.3 Advanced Analytics (`sql/07_advanced_sql_analytics.sql`)
- **`RANK()` & `DENSE_RANK()`**: Ranks resource popularity within each category partition.
- **`NTILE(4)`**: Segments patrons into 4 engagement quartiles (Tier 1: Power Patron to Tier 4: Dormant).
- **`LAG()` & `LEAD()`**: Computes days elapsed between consecutive checkouts by individual patrons.
- **Cumulative Running Total**: Evaluates cumulative revenue collected over time via `SUM(...) OVER (...)`.
- **Recursive CTE**: Recursively traverses the self-referential categories table from root to leaves with depth level and breadcrumb hierarchy paths.
- **Multi-Step Analytical CTE**: Chains three CTEs to generate a comprehensive High-Risk Defaulter Profile.

---

## Module 6: Testing, Documentation & Validation (10 Marks)

An automated Python test engine [`app/test_runner.py`](file:///c:/Users/Vishal/Projects/DBMS capstone/app/test_runner.py) was developed to execute and validate the database scripts:
1. Creates an isolated SQLite database environment.
2. Runs `01_schema_ddl.sql` and verifies table creation and constraints.
3. Loads `02_seed_data_dml.sql` and verifies row counts across all 12 tables.
4. Executes `03_security_dcl_tcl.sql` transactions (validating `COMMIT`, `ROLLBACK`, and `SAVEPOINT`).
5. Executes all queries from `04_basic_and_complex_queries.sql`, `05_set_operations.sql`, `06_views_and_indexing.sql`, and `07_advanced_sql_analytics.sql`.
6. Validates result counts, foreign key enforcement, and view outputs.

All test suites pass with **100% success rate**.

---

## Module 7: Demonstration & Viva Preparation (10 Marks)

A comprehensive Viva Voce preparation guide is provided in [`docs/viva_preparation_guide.md`](file:///c:/Users/Vishal/Projects/DBMS capstone/docs/viva_preparation_guide.md), featuring:
- 35+ examiner questions and rigorous model answers across all syllabus topics.
- In-depth coverage of ACID properties, normal form proofs, indexing data structures, and query execution plans.
- Rapid-fire definitions of key database terminology.

---

## Conclusion

The **Intelligent Library and Digital Resource Management System (ILDRMS)** demonstrates end-to-end mastery of relational database design, formal normalization, complex querying, and advanced analytical SQL. The project is production-ready, academically rigorous, and fully verified.
