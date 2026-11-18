-- ============================================================================
-- Capstone Project: Intelligent Library and Digital Resource Management System
-- Component: 02_seed_data_dml.sql (Data Manipulation Language - Seed Data)
-- Target RDBMS: Standard SQL / SQLite3 / PostgreSQL / MySQL 8.0+ compatible
-- ============================================================================

-- Clean existing data
DELETE FROM fine_payments;
DELETE FROM fines_and_penalties;
DELETE FROM reservations;
DELETE FROM circulation_transactions;
DELETE FROM digital_assets;
DELETE FROM book_copies;
DELETE FROM resource_authors;
DELETE FROM resources;
DELETE FROM categories;
DELETE FROM members;
DELETE FROM authors;
DELETE FROM publishers;

-- ============================================================================
-- 1. SEED: PUBLISHERS
-- ============================================================================
INSERT INTO publishers (publisher_id, name, contact_email, phone, address, country, established_year) VALUES
(1, 'MIT Press', 'info@mitpress.edu', '+1-617-253-5646', 'One Broadway 12th Floor, Cambridge MA', 'USA', 1962),
(2, 'O''Reilly Media', 'orders@oreilly.com', '+1-707-827-7000', '1005 Gravenstein Highway North, Sebastopol CA', 'USA', 1978),
(3, 'Springer Nature', 'support@springer.com', '+49-6221-4870', 'Tiergartenstrasse 17, Heidelberg', 'Germany', 1842),
(4, 'Pearson Education', 'contact@pearson.com', '+44-20-7010-2000', '80 Strand, London', 'UK', 1844),
(5, 'Cambridge University Press', 'academic@cambridge.org', '+44-1223-358351', 'University Printing House, Cambridge', 'UK', 1534),
(6, 'McGraw-Hill Education', 'customer.service@mheducation.com', '+1-800-338-3987', '1325 Avenue of the Americas, New York NY', 'USA', 1888),
(7, 'IEEE Computer Society', 'help@computer.org', '+1-714-821-8380', '10662 Los Vaqueros Circle, Los Alamitos CA', 'USA', 1946),
(8, 'Packt Publishing', 'customercare@packtpub.com', '+44-121-659-9840', 'Livery Place 35 Livery St, Birmingham', 'UK', 2004);

-- ============================================================================
-- 2. SEED: AUTHORS
-- ============================================================================
INSERT INTO authors (author_id, first_name, last_name, email, nationality, biography) VALUES
(1, 'Abraham', 'Silberschatz', 'avi@cs.yale.edu', 'American', 'Professor of Computer Science at Yale University; database pioneer.'),
(2, 'Henry', 'Korth', 'korth@lehigh.edu', 'American', 'Professor of Computer Science & Engineering at Lehigh University.'),
(3, 'Martin', 'Kleppmann', 'martin@kleppmann.com', 'British', 'Associate Professor at University of Cambridge; distributed systems researcher.'),
(4, 'Stuart', 'Russell', 'russell@berkeley.edu', 'British', 'Professor of Computer Science at UC Berkeley; AI luminary.'),
(5, 'Peter', 'Norvig', 'peter@norvig.com', 'American', 'Director of Research at Google; fellow of AAAI and ACM.'),
(6, 'Thomas', 'Cormen', 'thc@cs.dartmouth.edu', 'American', 'Professor Emeritus of Computer Science at Dartmouth College.'),
(7, 'Charles', 'Leiserson', 'cel@mit.edu', 'American', 'Professor of Computer Science and Engineering at MIT.'),
(8, 'Ronald', 'Rivest', 'rivest@mit.edu', 'American', 'MIT Professor and Turing Award laureate for RSA cryptography.'),
(9, 'Clifford', 'Stein', 'cliff@ieor.columbia.edu', 'American', 'Professor of Industrial Engineering and Computer Science at Columbia.'),
(10, 'Ian', 'Goodfellow', 'ian.goodfellow@deepmind.com', 'American', 'Renowned AI researcher; inventor of Generative Adversarial Networks.'),
(11, 'Yoshua', 'Bengio', 'yoshua.bengio@mila.quebec', 'Canadian', 'Turing Award laureate 2018; scientific director of Mila.'),
(12, 'Christopher', 'Bishop', 'cmbishop@microsoft.com', 'British', 'Technical Fellow and Laboratory Director at Microsoft Research AI.');

-- ============================================================================
-- 3. SEED: CATEGORIES (Hierarchical Tree)
-- ============================================================================
INSERT INTO categories (category_id, category_name, parent_category_id, description) VALUES
(1, 'Computer Science', NULL, 'Foundational and applied computing disciplines'),
(2, 'Mathematics & Statistics', NULL, 'Pure, applied mathematics, probability and statistics'),
(3, 'Engineering & Robotics', NULL, 'Hardware, automation, robotics and systems engineering'),
(4, 'Artificial Intelligence', 1, 'Intelligent agents, machine learning, and NLP'),
(5, 'Database Management', 1, 'Data modeling, relational systems, NoSQL, and query engines'),
(6, 'Algorithms & Complexity', 1, 'Data structures, algorithm design, graph theories'),
(7, 'Distributed Systems', 1, 'Cloud architecture, distributed consensus, data replication'),
(8, 'Machine Learning', 4, 'Supervised, unsupervised, reinforcement learning'),
(9, 'Deep Learning', 8, 'Deep neural architectures, CNNs, Transformers, LLMs'),
(10, 'Relational Databases', 5, 'ACID, SQL, normalization, relational algebra'),
(11, 'Linear Algebra & Optimization', 2, 'Vector spaces, matrix decomposition, mathematical programming');

-- ============================================================================
-- 4. SEED: RESOURCES (Master Catalog)
-- ============================================================================
INSERT INTO resources (resource_id, title, isbn_issn, resource_type, category_id, publisher_id, publication_year, edition, language, total_copies, available_copies) VALUES
(1, 'Database System Concepts', '978-0078022159', 'Physical Book', 10, 6, 2020, '7th Edition', 'English', 5, 2),
(2, 'Designing Data-Intensive Applications', '978-1449373320', 'Physical Book', 7, 2, 2017, '1st Edition', 'English', 4, 1),
(3, 'Artificial Intelligence: A Modern Approach', '978-0134610993', 'Physical Book', 4, 4, 2021, '4th Edition', 'English', 6, 3),
(4, 'Introduction to Algorithms (CLRS)', '978-0262046305', 'Physical Book', 6, 1, 2022, '4th Edition', 'English', 6, 0),
(5, 'Deep Learning (Adaptive Computation)', '978-0262035613', 'Physical Book', 9, 1, 2016, '1st Edition', 'English', 3, 2),
(6, 'Pattern Recognition and Machine Learning', '978-0387310732', 'E-Book', 8, 3, 2011, '1st Edition', 'English', 10, 10),
(7, 'Database Systems: Complete Book', '978-0131873254', 'Physical Book', 10, 4, 2008, '2nd Edition', 'English', 3, 1),
(8, 'Journal of ACM: Autonomous Database Tuning', '0004-5411-2023', 'Journal', 5, 7, 2023, 'Vol. 70 Iss. 4', 'English', 2, 2),
(9, 'IEEE Transactions on Knowledge Engineering', '1041-4347-2024', 'Journal', 4, 7, 2024, 'Vol. 36 Iss. 1', 'English', 1, 1),
(10, 'High Performance Browser Networking (E-Edition)', '978-1449344047', 'E-Book', 7, 2, 2013, '1st Edition', 'English', 15, 15),
(11, 'Clean Architecture Audio Masterclass', '978-0134494166', 'Audiobook', 1, 4, 2018, 'Unabridged', 'English', 8, 7),
(12, 'Mathematics for Machine Learning', '978-1108455145', 'E-Book', 11, 5, 2020, '1st Edition', 'English', 12, 12);

-- ============================================================================
-- 5. SEED: RESOURCE_AUTHORS (Bridge Table)
-- ============================================================================
INSERT INTO resource_authors (resource_id, author_id, author_role) VALUES
(1, 1, 'Primary Author'), -- Silberschatz on DB Concepts
(1, 2, 'Co-Author'),      -- Korth on DB Concepts
(2, 3, 'Primary Author'), -- Kleppmann on DDIA
(3, 4, 'Primary Author'), -- Russell on AI
(3, 5, 'Co-Author'),      -- Norvig on AI
(4, 6, 'Primary Author'), -- Cormen on CLRS
(4, 7, 'Co-Author'),      -- Leiserson
(4, 8, 'Co-Author'),      -- Rivest
(4, 9, 'Co-Author'),      -- Stein
(5, 10, 'Primary Author'), -- Goodfellow on Deep Learning
(5, 11, 'Co-Author'),     -- Bengio on Deep Learning
(6, 12, 'Primary Author'), -- Bishop on PRML
(7, 1, 'Co-Author'),      -- Silberschatz on DB Complete Book
(8, 2, 'Primary Author'), -- Korth on Autonomous DB Tuning
(9, 4, 'Co-Author'),      -- Russell on IEEE TKDE
(10, 3, 'Co-Author'),     -- Kleppmann contributor
(11, 3, 'Co-Author'),     -- Audio contributor
(12, 12, 'Co-Author');    -- Bishop contributor

-- ============================================================================
-- 6. SEED: BOOK_COPIES (Physical Barcoded Inventory)
-- ============================================================================
INSERT INTO book_copies (copy_id, resource_id, barcode, rack_location, item_condition, status, acquisition_date, purchase_price) VALUES
-- Copies of Resource 1: Database System Concepts (Total: 5, Available: 2, Issued: 2, Maint: 1)
(101, 1, 'BC-DBS-001-A', 'Rack CS-01-A', 'Good', 'Available', '2021-01-15', 3800.00),
(102, 1, 'BC-DBS-001-B', 'Rack CS-01-A', 'Good', 'Issued', '2021-01-15', 3800.00),
(103, 1, 'BC-DBS-001-C', 'Rack CS-01-A', 'New', 'Issued', '2022-03-10', 4100.00),
(104, 1, 'BC-DBS-001-D', 'Rack CS-01-A', 'Good', 'Available', '2022-03-10', 4100.00),
(105, 1, 'BC-DBS-001-E', 'Rack CS-01-A', 'Damaged', 'Under Maintenance', '2021-01-15', 3800.00),

-- Copies of Resource 2: Designing Data-Intensive Applications (Total: 4, Available: 1, Issued: 3)
(201, 2, 'BC-DIS-002-A', 'Rack CS-02-B', 'New', 'Issued', '2021-06-20', 2900.00),
(202, 2, 'BC-DIS-002-B', 'Rack CS-02-B', 'Good', 'Issued', '2021-06-20', 2900.00),
(203, 2, 'BC-DIS-002-C', 'Rack CS-02-B', 'Good', 'Issued', '2022-08-14', 3100.00),
(204, 2, 'BC-DIS-002-D', 'Rack CS-02-B', 'Good', 'Available', '2022-08-14', 3100.00),

-- Copies of Resource 3: Artificial Intelligence (Total: 6, Available: 3, Issued: 3)
(301, 3, 'BC-AI-003-A', 'Rack CS-04-A', 'Good', 'Issued', '2021-09-01', 5200.00),
(302, 3, 'BC-AI-003-B', 'Rack CS-04-A', 'Good', 'Issued', '2021-09-01', 5200.00),
(303, 3, 'BC-AI-003-C', 'Rack CS-04-A', 'New', 'Issued', '2022-11-05', 5400.00),
(304, 3, 'BC-AI-003-D', 'Rack CS-04-A', 'Good', 'Available', '2022-11-05', 5400.00),
(305, 3, 'BC-AI-003-E', 'Rack CS-04-A', 'Good', 'Available', '2023-02-12', 5400.00),
(306, 3, 'BC-AI-003-F', 'Rack CS-04-A', 'New', 'Available', '2023-02-12', 5400.00),

-- Copies of Resource 4: CLRS Algorithms (Total: 6, Available: 0 - 100% Issued/Borrowed)
(401, 4, 'BC-ALG-004-A', 'Rack CS-03-C', 'Fair', 'Issued', '2020-02-10', 4500.00),
(402, 4, 'BC-ALG-004-B', 'Rack CS-03-C', 'Good', 'Issued', '2020-02-10', 4500.00),
(403, 4, 'BC-ALG-004-C', 'Rack CS-03-C', 'Good', 'Issued', '2022-04-18', 4900.00),
(404, 4, 'BC-ALG-004-D', 'Rack CS-03-C', 'New', 'Issued', '2022-04-18', 4900.00),
(405, 4, 'BC-ALG-004-E', 'Rack CS-03-C', 'Good', 'Issued', '2023-01-20', 4900.00),
(406, 4, 'BC-ALG-004-F', 'Rack CS-03-C', 'Good', 'Issued', '2023-01-20', 4900.00),

-- Copies of Resource 5: Deep Learning (Total: 3, Available: 2, Issued: 1)
(501, 5, 'BC-DL-005-A', 'Rack CS-05-B', 'New', 'Issued', '2022-05-15', 3600.00),
(502, 5, 'BC-DL-005-B', 'Rack CS-05-B', 'Good', 'Available', '2022-05-15', 3600.00),
(503, 5, 'BC-DL-005-C', 'Rack CS-05-B', 'Good', 'Available', '2023-07-10', 3800.00),

-- Copies of Resource 7: Database Complete Book (Total: 3, Available: 1, Issued: 2)
(701, 7, 'BC-DBC-007-A', 'Rack CS-01-B', 'Fair', 'Issued', '2019-08-25', 2800.00),
(702, 7, 'BC-DBC-007-B', 'Rack CS-01-B', 'Good', 'Issued', '2019-08-25', 2800.00),
(703, 7, 'BC-DBC-007-C', 'Rack CS-01-B', 'Good', 'Available', '2021-09-12', 3000.00);

-- ============================================================================
-- 7. SEED: DIGITAL_ASSETS
-- ============================================================================
INSERT INTO digital_assets (asset_id, resource_id, file_format, file_size_mb, download_url, drm_protected, max_concurrent_access, access_expiry_date) VALUES
(1, 6, 'PDF', 14.80, 'https://digital.library.edu/assets/pdf/prml-bishop.pdf', 'Y', 50, '2028-12-31'),
(2, 8, 'PDF', 3.25, 'https://digital.library.edu/assets/journals/jacm-autotune-2023.pdf', 'Y', 20, '2027-06-30'),
(3, 9, 'PDF', 4.10, 'https://digital.library.edu/assets/journals/ieee-tkde-2024-v36.pdf', 'Y', 25, '2027-12-31'),
(4, 10, 'EPUB', 8.60, 'https://digital.library.edu/assets/epub/high-perf-browser-net.epub', 'N', 100, '2029-12-31'),
(5, 11, 'MP3', 450.00, 'https://digital.library.edu/assets/audio/clean-arch-masterclass.mp3', 'Y', 10, '2026-12-31'),
(6, 12, 'PDF', 18.40, 'https://digital.library.edu/assets/pdf/math-for-ml-cambridge.pdf', 'N', 80, '2029-05-31');

-- ============================================================================
-- 8. SEED: MEMBERS
-- ============================================================================
INSERT INTO members (member_id, first_name, last_name, email, phone, member_type, registration_date, expiry_date, max_borrow_limit, current_borrowed_count, membership_status, referred_by_member_id) VALUES
(1001, 'Aarav', 'Sharma', 'aarav.sharma@campus.edu', '+91-9876543210', 'Student', '2023-08-01', '2027-07-31', 4, 2, 'Active', NULL),
(1002, 'Dr. Priya', 'Nair', 'priya.nair@campus.edu', '+91-9876543211', 'Faculty', '2020-01-10', '2030-12-31', 10, 4, 'Active', NULL),
(1003, 'Rohan', 'Verma', 'rohan.verma@campus.edu', '+91-9876543212', 'Student', '2023-08-05', '2027-07-31', 4, 3, 'Active', 1001),
(1004, 'Ananya', 'Iyer', 'ananya.iyer@campus.edu', '+91-9876543213', 'Researcher', '2022-09-01', '2026-08-31', 6, 3, 'Active', 1002),
(1005, 'Vikram', 'Malhotra', 'vikram.m@campus.edu', '+91-9876543214', 'Student', '2022-08-10', '2026-07-31', 4, 1, 'Active', 1001),
(1006, 'Dr. Rajesh', 'Kulkarni', 'rajesh.k@campus.edu', '+91-9876543215', 'Faculty', '2019-06-15', '2029-06-14', 10, 2, 'Active', NULL),
(1007, 'Sneha', 'Patel', 'sneha.patel@campus.edu', '+91-9876543216', 'Student', '2024-01-12', '2028-01-11', 4, 1, 'Active', 1003),
(1008, 'Karan', 'Mehta', 'karan.m@alumni.edu', '+91-9876543217', 'Alumni', '2023-11-01', '2025-10-31', 2, 0, 'Active', 1005),
(1009, 'Neha', 'Deshmukh', 'neha.d@campus.edu', '+91-9876543218', 'Student', '2022-08-01', '2024-07-31', 4, 0, 'Expired', NULL),
(1010, 'Tanvi', 'Joshi', 'tanvi.j@campus.edu', '+91-9876543219', 'Student', '2023-09-15', '2027-09-14', 4, 1, 'Suspended', 1003);

-- ============================================================================
-- 9. SEED: CIRCULATION_TRANSACTIONS
-- ============================================================================
INSERT INTO circulation_transactions (transaction_id, copy_id, resource_id, member_id, borrow_date, due_date, return_date, renewal_count, transaction_status) VALUES
-- Past transactions (Returned on time or late)
(5001, 101, 1, 1001, '2024-01-10', '2024-01-24', '2024-01-22', 0, 'Returned'),
(5002, 201, 2, 1003, '2024-01-15', '2024-01-29', '2024-02-05', 0, 'Returned'), -- 7 days late
(5003, 301, 3, 1005, '2024-02-01', '2024-02-15', '2024-02-14', 0, 'Returned'),
(5004, 401, 4, 1004, '2024-02-10', '2024-02-24', '2024-03-05', 1, 'Returned'), -- 10 days late
(5005, 501, 5, 1002, '2024-03-01', '2024-03-31', '2024-03-28', 0, 'Returned'),

-- Overdue transactions (Currently active past due date)
(5006, 102, 1, 1003, '2024-09-01', '2024-09-15', NULL, 0, 'Overdue'),          -- Chronic overdue
(5007, 202, 2, 1010, '2024-09-10', '2024-09-24', NULL, 0, 'Overdue'),          -- Overdue, led to suspension
(5008, 402, 4, 1007, '2024-09-20', '2024-10-04', NULL, 0, 'Overdue'),          -- Overdue

-- Currently Active Loans (Not overdue)
(5009, 103, 1, 1001, '2024-10-10', '2024-10-24', NULL, 0, 'Active'),
(5010, 203, 2, 1002, '2024-10-05', '2024-11-04', NULL, 0, 'Active'),
(5011, 302, 3, 1002, '2024-10-08', '2024-11-07', NULL, 0, 'Active'),
(5012, 303, 3, 1004, '2024-10-12', '2024-10-26', NULL, 0, 'Active'),
(5013, 403, 4, 1001, '2024-10-14', '2024-10-28', NULL, 0, 'Active'),
(5014, 404, 4, 1002, '2024-10-15', '2024-11-14', NULL, 0, 'Active'),
(5015, 405, 4, 1003, '2024-10-11', '2024-10-25', NULL, 0, 'Active'),
(5016, 406, 4, 1004, '2024-10-16', '2024-10-30', NULL, 0, 'Active'),
(5017, 501, 5, 1006, '2024-10-02', '2024-11-01', NULL, 0, 'Active'),
(5018, 701, 7, 1006, '2024-10-05', '2024-11-04', NULL, 0, 'Active'),
(5019, 702, 7, 1005, '2024-10-09', '2024-10-23', NULL, 0, 'Active'),

-- Digital Resource Access Checkouts (Copy ID is NULL for digital)
(5020, NULL, 6, 1001, '2024-09-01', '2024-10-01', '2024-09-28', 0, 'Returned'),
(5021, NULL, 6, 1004, '2024-10-01', '2024-11-01', NULL, 1, 'Active'),
(5022, NULL, 10, 1002, '2024-10-05', '2024-11-05', NULL, 0, 'Active'),
(5023, NULL, 12, 1003, '2024-10-12', '2024-11-12', NULL, 0, 'Active');

-- ============================================================================
-- 10. SEED: RESERVATIONS
-- ============================================================================
INSERT INTO reservations (reservation_id, resource_id, member_id, reservation_date, queue_priority, reservation_status, fulfilled_date) VALUES
(8001, 4, 1005, '2024-10-15', 1, 'Pending', NULL),   -- CLRS is 100% issued, Vikram waiting
(8002, 4, 1008, '2024-10-16', 2, 'Pending', NULL),   -- Karan queue #2
(8003, 1, 1007, '2024-10-12', 1, 'Pending', NULL),   -- Sneha waiting for DB Concepts
(8004, 2, 1001, '2024-08-01', 1, 'Fulfilled', '2024-08-10'), -- Fulfilled in the past
(8005, 3, 1009, '2024-02-10', 1, 'Expired', NULL),   -- Expired reservation
(8006, 5, 1004, '2024-07-01', 1, 'Cancelled', NULL); -- Cancelled by user

-- ============================================================================
-- 11. SEED: FINES_AND_PENALTIES
-- ============================================================================
INSERT INTO fines_and_penalties (fine_id, transaction_id, member_id, fine_type, fine_amount, paid_amount, fine_status, assessed_date) VALUES
-- Transaction 5002: 7 days late @ Rs 10/day = Rs 70.00 (Fully Paid)
(9001, 5002, 1003, 'Overdue Late Fee', 70.00, 70.00, 'Paid', '2024-02-05'),

-- Transaction 5004: 10 days late @ Rs 10/day = Rs 100.00 (Partially Paid)
(9002, 5004, 1004, 'Overdue Late Fee', 100.00, 50.00, 'Partially Paid', '2024-03-05'),

-- Transaction 5006: Chronic overdue late fee = Rs 350.00 (Unpaid)
(9003, 5006, 1003, 'Overdue Late Fee', 350.00, 0.00, 'Unpaid', '2024-10-01'),

-- Transaction 5007: Overdue fee on suspended account = Rs 280.00 (Unpaid)
(9004, 5007, 1010, 'Overdue Late Fee', 280.00, 0.00, 'Unpaid', '2024-10-01'),

-- Transaction 5008: Overdue fee = Rs 120.00 (Unpaid)
(9005, 5008, 1007, 'Overdue Late Fee', 120.00, 0.00, 'Unpaid', '2024-10-15'),

-- Damaged Copy Fine (Copy 105: Damaged condition during inspection)
(9006, 5001, 1001, 'Damaged Item Fee', 450.00, 450.00, 'Paid', '2024-01-23');

-- ============================================================================
-- 12. SEED: FINE_PAYMENTS
-- ============================================================================
INSERT INTO fine_payments (payment_id, fine_id, payment_amount, payment_date, payment_method, receipt_reference) VALUES
(3001, 9001, 70.00, '2024-02-06', 'UPI', 'REC-UPI-20240206-8812'),
(3002, 9002, 50.00, '2024-03-10', 'Net Banking', 'REC-NB-20240310-9941'),
(3003, 9006, 450.00, '2024-01-24', 'Credit Card', 'REC-CC-20240124-1123');
