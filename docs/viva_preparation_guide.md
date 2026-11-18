# Capstone Viva Voce & Demonstration Guide
## Intelligent Library and Digital Resource Management System (ILDRMS)

This comprehensive guide prepares students to score full marks (10/10) in the Capstone Viva Voce examination. It contains 35+ examiner questions with precise, rigorous model answers organized by syllabus component.

---

## Section 1: Project Architecture & Domain Understanding

### Q1: What is the core problem statement of your Capstone Project?
**Model Answer:**  
The project designs and implements an enterprise-grade relational database for an **Intelligent Library and Digital Resource Management System (ILDRMS)**. Traditional library software often treats physical and electronic resources in silos and lacks automated circulation intelligence. Our system provides unified tracking of physical books, electronic resources (e-books, journals, audio licenses), patrons, circulation lifecycles, waitlists, and fine penalties, while generating analytical intelligence into borrowing behaviors, chronic defaulters, and inventory utilization.

### Q2: Why did you choose a Relational Database Management System (RDBMS) instead of a NoSQL document store?
**Model Answer:**  
Library circulation requires strict **ACID transactions** (Atomicity, Consistency, Isolation, Durability). For example, when a copy is checked out, multiple operations must happen simultaneously: copy availability drops, a loan record is created, and the member's active borrow tally is incremented. If any step fails, the system must rollback. Furthermore, library data is inherently structured with strong referential relationships (M:N between books and authors, 1:N between resources and physical copies), which relational algebra and SQL normalize to avoid redundancy and eliminate update/deletion anomalies.

### Q3: How does your database distinguish between a abstract "Resource" and an individual "Book Copy"?
**Model Answer:**  
We separated the conceptual work from its physical manifestations by creating two distinct entities:
- `resources`: Stores title-level metadata (Title, ISBN, Publisher, Category, Edition, Language).
- `book_copies`: Stores item-level physical inventory (Copy ID, unique scannable barcode, physical rack location, item condition, and real-time status: Available/Issued/Maintenance).  
This cleanly handles scenarios where the library owns 10 copies of the same textbook spread across different shelves.

---

## Section 2: ER Modeling & Database Schema Design

### Q4: Explain the difference between Primary Key, Candidate Key, Foreign Key, and Superkey in your schema.
**Model Answer:**  
- **Superkey**: Any set of attributes that uniquely identifies a row (e.g., `{member_id, email, phone}`).
- **Candidate Key**: A minimal superkey with no redundant attributes (e.g., `member_id`, `email`, and `phone` are each candidate keys in `members`).
- **Primary Key**: The candidate key formally chosen by the database designer to identify tuples (e.g., `member_id`).
- **Foreign Key**: An attribute in a child table matching a primary key in a parent table to enforce referential integrity (e.g., `category_id` in `resources` referencing `category_id` in `categories`).

### Q5: How did you resolve the Many-to-Many ($M:N$) relationship between Authors and Resources?
**Model Answer:**  
In relational theory, $M:N$ relationships cannot be directly modeled with foreign keys without causing repeating groups or multivalued columns. We introduced an associative bridge entity called `resource_authors` with a composite primary key `(resource_id, author_id)` and a descriptive attribute `author_role` (e.g., 'Primary Author', 'Co-Author', 'Editor').

### Q6: What is a Self-Referencing relationship, and where is it implemented in your database?
**Model Answer:**  
A self-referencing (unary) relationship occurs when a table's foreign key references its own primary key. We implemented it in two tables:
1. `categories.parent_category_id -> categories.category_id`: Models hierarchical category trees (e.g., Computer Science $\rightarrow$ Artificial Intelligence $\rightarrow$ Deep Learning).
2. `members.referred_by_member_id -> members.member_id`: Tracks patron referral networks.

### Q7: What are the referential integrity actions you used (e.g., ON DELETE CASCADE vs ON DELETE RESTRICT)?
**Model Answer:**  
- `ON DELETE CASCADE`: Used for dependent child records that have no independent meaning without the parent (e.g., deleting a resource cascades to its physical copies in `book_copies` and loan logs in `circulation_transactions`).
- `ON DELETE RESTRICT`: Used for foundational master entities (e.g., a publisher cannot be deleted if active resources reference that publisher).
- `ON DELETE SET NULL`: Used for non-vital links (e.g., if a referring member account is removed, `referred_by_member_id` is set to NULL).

---

## Section 3: Normalization & Integrity Constraints

### Q8: What is 1NF and how did you guarantee it?
**Model Answer:**  
1NF requires that all attribute values are atomic (indivisible) and that there are no repeating groups. In our design, rather than storing comma-separated author names or barcode lists inside strings, every entity has atomic fields (such as `first_name` and `last_name`), and multiple authors/copies are stored as individual rows across normalized bridge tables.

### Q9: Define 2NF. What type of functional dependency does 2NF eliminate?
**Model Answer:**  
A relation is in 2NF if it is in 1NF and contains **no partial functional dependencies**—every non-prime attribute must depend on the whole candidate key, not a proper subset of a composite key. We resolved 2NF in the `resource_authors` bridge table by keeping only attributes dependent on both `(resource_id, author_id)`, while moving book titles and author biographies into their respective primary tables.

### Q10: What is 3NF? How does it differ from 2NF?
**Model Answer:**  
3NF requires the relation to be in 2NF and contain **no transitive functional dependencies** ($X \rightarrow Y$ and $Y \rightarrow Z$, where non-key $Z$ depends on non-key $Y$). For example, placing `publisher_name` in the `resources` table would create $\text{resource\_id} \rightarrow \text{publisher\_id} \rightarrow \text{publisher\_name}$. We moved publishers into their own table, satisfying 3NF.

### Q11: Explain BCNF (Boyce-Codd Normal Form) and why your schema satisfies it.
**Model Answer:**  
BCNF is a stricter form of 3NF where for **every** non-trivial functional dependency $X \rightarrow Y$, the determinant $X$ must be a **superkey**. In our schema, in every table (e.g., `book_copies`, `resources`, `members`), every determinant is a primary key or unique candidate key (e.g., `barcode` or `isbn_issn`).

### Q12: What are Insertion, Deletion, and Update anomalies? Give a concrete example.
**Model Answer:**  
- **Insertion Anomaly**: If publishers were merged into resources, we couldn't add a newly contracted publisher until the library procured at least one book from them.
- **Update Anomaly**: If an author's email was stored on every book record, updating their email would require modifying multiple rows; missing one results in inconsistent data.
- **Deletion Anomaly**: If publisher details were only stored in the book row, deleting the last remaining book by that publisher would inadvertently erase all records of the publisher itself.

---

## Section 4: SQL Fundamentals (DDL, DML, DCL, TCL)

### Q13: What is the difference between DDL, DML, DCL, and TCL?
**Model Answer:**  
- **DDL (Data Definition Language)**: Defines schema structures (`CREATE`, `ALTER`, `DROP`, `TRUNCATE`).
- **DML (Data Manipulation Language)**: Modifies and queries data tuples (`INSERT`, `SELECT`, `UPDATE`, `DELETE`).
- **DCL (Data Control Language)**: Manages permissions and security policies (`GRANT`, `REVOKE`).
- **TCL (Transaction Control Language)**: Manages transaction boundaries and data durability (`COMMIT`, `ROLLBACK`, `SAVEPOINT`).

### Q14: Explain the ACID properties with an example from your project.
**Model Answer:**  
- **Atomicity**: During book checkout, updating copy status, inserting a loan record, and incrementing member tally all happen together; if any fails, all rollback.
- **Consistency**: Database invariants (e.g., `CHECK (available_copies <= total_copies)`) are strictly preserved before and after execution.
- **Isolation**: Concurrent checkouts by two users do not interfere or cause race conditions on the last available copy.
- **Durability**: Once `COMMIT` executes, records are written to persistent storage and survive server crashes.

### Q15: What is a `SAVEPOINT` in TCL, and when would you use it?
**Model Answer:**  
A `SAVEPOINT` establishes an intermediate checkpoint within a multi-step transaction. It allows rolling back a portion of the transaction without aborting the preceding operations. In our project (`03_security_dcl_tcl.sql`), when a patron attempts a multi-item checkout, if Book 1 succeeds and Book 2 fails validation, we `ROLLBACK TO SAVEPOINT` Book 1, preserving Book 1's checkout while aborting Book 2.

---

## Section 5: Complex Joins, Subqueries & Set Operations

### Q16: Differentiate between `INNER JOIN`, `LEFT OUTER JOIN`, and `FULL OUTER JOIN`.
**Model Answer:**  
- `INNER JOIN`: Returns only rows with matching keys in both tables (e.g., resources that currently have physical copies).
- `LEFT OUTER JOIN`: Returns all rows from the left table and matched rows from the right table, substituting `NULL` where no match exists (e.g., all members, even those who have never borrowed a book).
- `FULL OUTER JOIN`: Returns all rows from both tables, filling `NULL` on either side where matches do not exist.

### Q17: What is a Self-Join? Give an example from your queries.
**Model Answer:**  
A Self-Join joins a table to itself using aliases. We used a self-join in `categories` to join child categories with their parent categories:
```sql
SELECT sub.category_name, parent.category_name 
FROM categories sub 
LEFT JOIN categories parent ON sub.parent_category_id = parent.category_id;
```

### Q18: What is the fundamental difference between a Correlated Subquery and a Regular Nested Subquery?
**Model Answer:**  
- **Regular Nested Subquery**: Evaluates once independently before the outer query runs. Its result is then used by the outer query (e.g., finding books whose year equals `SELECT MAX(publication_year) FROM resources`).
- **Correlated Subquery**: References columns from the outer query table, executing once for **every candidate row** evaluated by the outer query (e.g., finding members whose fine arrears exceed the system-wide average fine).

### Q19: What is the difference between `UNION` and `UNION ALL`?
**Model Answer:**  
- `UNION`: Combines result sets and performs an implicit `DISTINCT` sort operation to remove duplicate rows.
- `UNION ALL`: Combines result sets without removing duplicates, making it computationally faster when duplicates are acceptable or impossible.

### Q20: How do `INTERSECT` and `EXCEPT` work?
**Model Answer:**  
- `INTERSECT`: Returns rows that appear in **both** query result sets (e.g., patrons who borrow both physical books and digital assets).
- `EXCEPT` (called `MINUS` in Oracle): Returns rows present in the first query but absent in the second query (e.g., catalog items that have never appeared in any circulation transaction).

---

## Section 6: Views, Indexing & Query Optimization

### Q21: What is a Database View, and what are its advantages?
**Model Answer:**  
A View is a virtual table defined by a stored SQL query. It does not store redundant data physically (unless materialized). Key advantages:
1. **Security & Abstraction**: Hides sensitive columns (e.g., patron passwords or internal costs).
2. **Query Simplification**: Encapsulates 4-way joins into simple `SELECT * FROM view_name`.
3. **Consistency**: Provides a single standardized definition of business metrics like "active overdue loans".

### Q22: What is an Index, and how does a B-Tree index work?
**Model Answer:**  
An index is an auxiliary data structure that enables fast search and retrieval of rows without scanning the entire table. Most RDBMS use balanced trees (**B-Trees**), where keys are kept in sorted order across root, branch, and leaf nodes, reducing search time complexity from $O(N)$ (table scan) to $O(\log N)$ (index seek).

### Q23: What is a Composite Index? When does index column ordering matter?
**Model Answer:**  
A Composite Index is created on two or more columns, such as `(transaction_status, due_date)`. The ordering matters because of the **Leftmost Prefix Rule**: the index can satisfy queries filtering on `transaction_status` alone or `transaction_status AND due_date`, but cannot be used efficiently for queries filtering only on `due_date`.

### Q24: What information does `EXPLAIN QUERY PLAN` provide?
**Model Answer:**  
`EXPLAIN QUERY PLAN` displays the execution plan chosen by the query optimizer. It shows whether the engine will perform a full table scan (`SCAN TABLE`) or an efficient index search (`SEARCH TABLE ... USING INDEX`), allowing developers to detect performance bottlenecks.

---

## Section 7: Advanced SQL: Window Functions & CTEs

### Q25: How does a Window Function differ from a standard `GROUP BY` aggregation?
**Model Answer:**  
- `GROUP BY`: Collapses multiple rows into a single summary row, losing individual row identities.
- `WINDOW FUNCTION`: Performs an aggregate or ranking calculation across a set of rows (the "window") while **retaining individual row identity and detail**.

### Q26: What is the difference between `RANK()`, `DENSE_RANK()`, and `ROW_NUMBER()`?
**Model Answer:**  
When ties occur (e.g., two books each have 5 checkouts):
- `ROW_NUMBER()`: Assigns strictly sequential unique integers (e.g., 1, 2, 3, 4).
- `RANK()`: Assigns identical ranks to ties and skips subsequent numbers (e.g., 1, 1, 3, 4).
- `DENSE_RANK()`: Assigns identical ranks to ties without skipping numbers (e.g., 1, 1, 2, 3).

### Q27: Explain how `LAG()` and `LEAD()` work with an example.
**Model Answer:**  
- `LAG(column, offset)` accesses values from a preceding row in the same partition.
- `LEAD(column, offset)` accesses values from a succeeding row.  
In our project (`07_advanced_sql_analytics.sql`), we used `LAG(borrow_date)` to calculate the number of days elapsed between successive checkouts by each member.

### Q28: What is a Common Table Expression (CTE), and what is a Recursive CTE?
**Model Answer:**  
- **CTE (`WITH ... AS`)**: A named temporary result set existing within the scope of a single query, improving modularity and readability over nested subqueries.
- **Recursive CTE**: A CTE that references itself. It consists of an **Anchor Member** (base query) and a **Recursive Member** combined with `UNION ALL`, terminating when the recursive query yields an empty set. We used it to recursively traverse category hierarchies.

---

## Section 8: Rapid-Fire Technical Definitions

| Term | 1-Sentence Academic Definition |
| :--- | :--- |
| **Referential Integrity** | A database state where all foreign key values reference existing primary key values in the parent table or are null. |
| **Domain Constraint** | A rule restricting attribute values to a valid set or range (e.g., `CHECK (fine_amount >= 0)`). |
| **Lossless-Join** | A property of decomposition ensuring that the natural join of decomposed tables produces exactly the original relation without spurious tuples. |
| **Dependency Preservation**| A property where all functional dependencies in $R$ can be verified from the decomposed relations without computing joins. |
| **Dirty Read** | Reading uncommitted data written by a concurrent transaction that could subsequently rollback. |
| **Clustered Index** | An index that determines the physical storage order of rows in the table (typically the primary key). |
| **Correlated Subquery** | An inner query evaluated repeatedly for each candidate row processed by the outer query. |
