# Normalization Proofs & Relational Schema Decomposition
## Intelligent Library and Digital Resource Management System (ILDRMS)

---

## 1. Introduction & Theoretical Foundations

Database normalization is the formal process of structuring a relational database in accordance with a series of normal forms (1NF, 2NF, 3NF, BCNF) to:
1. **Eliminate Data Redundancy**: Avoid storing the same facts repeatedly.
2. **Prevent Modification Anomalies**:
   - **Insertion Anomaly**: Inability to record certain facts without artificially adding unrelated records.
   - **Update Anomaly**: Inconsistencies arising when one duplicate record is updated while others remain untouched.
   - **Deletion Anomaly**: Unintentional loss of critical facts when deleting an unrelated tuple.
3. **Guarantee Integrity & Lossless Reconstruction**: Ensure that natural joins across decomposed tables preserve all original data without generating spurious tuples.

---

## 2. Unnormalized Form (UNF) Analysis

Consider an unnormalized legacy spreadsheet representation used by a traditional library ledger:

```
LIBRARY_UNF(
    TransactionID, MemberID, MemberName, MemberEmail, MemberType,
    ResourceID, Title, ISBN, PublisherName, PublisherEmail, CategoryName,
    AuthorsList [Repeating Group], CopyBarcodesList [Repeating Group],
    BorrowDate, DueDate, ReturnDate, FineAmount, PaymentReceipts [Repeating Group]
)
```

### Critical Anomalies in UNF:
- **Repeating Groups**: Multiple authors, barcodes, and payments crammed into delimited string fields.
- **Update Anomaly**: If publisher email or author name changes, thousands of transaction rows must be found and edited.
- **Insertion Anomaly**: A new book cannot be added to the catalog until someone borrows it (if TransactionID is part of the key).
- **Deletion Anomaly**: If member records are purged after an old loan, all metadata about the book title, publisher, and authors might be permanently lost.

---

## 3. First Normal Form (1NF)

### Definition:
A relation $R$ is in **First Normal Form (1NF)** if and only if:
1. All domain attribute values are **atomic** (indivisible single values).
2. There are no repeating groups or multi-valued attributes.
3. Each record possesses a unique identifying primary key.

### Decomposition into 1NF:
We extract multi-valued attributes into their own tuples and ensure atomic columns:
- Split `MemberName` into atomic attributes `first_name` and `last_name`.
- Eliminate repeating author arrays by flattening into individual rows.
- Eliminate repeating copy barcode lists by associating one physical copy per item record.

**Flattened Relation Schema at 1NF:**
```
UNF_FLATTENED(
    transaction_id, copy_id, resource_id, author_id, member_id,
    first_name, last_name, member_email, member_type,
    title, isbn, publication_year, category_id, category_name,
    publisher_id, publisher_name, publisher_email,
    author_name, author_email, barcode, rack_location,
    borrow_date, due_date, return_date, fine_amount
)
```
- **Composite Primary Key at 1NF:** `{transaction_id, author_id, copy_id}`

---

## 4. Second Normal Form (2NF)

### Definition:
A relation $R$ is in **Second Normal Form (2NF)** if and only if:
1. It is already in **1NF**.
2. **No non-prime attribute is partially dependent on any candidate key**. Every non-key attribute must depend on the **whole candidate key**, not just a subset.

### Functional Dependency (FD) Analysis at 1NF:
Let the composite candidate key be $\{ \text{transaction\_id}, \text{author\_id}, \text{copy\_id} \}$:
- $FD_1: \{ \text{transaction\_id} \} \rightarrow \text{member\_id}, \text{borrow\_date}, \text{due\_date}, \text{return\_date}$
  *(Partial Dependency: Depends solely on transaction_id, not author_id or copy_id)*
- $FD_2: \{ \text{copy\_id} \} \rightarrow \text{resource\_id}, \text{barcode}, \text{rack\_location}$
  *(Partial Dependency: Depends solely on copy_id)*
- $FD_3: \{ \text{author\_id} \} \rightarrow \text{author\_name}, \text{author\_email}$
  *(Partial Dependency: Depends solely on author_id)*
- $FD_4: \{ \text{resource\_id} \} \rightarrow \text{title}, \text{isbn}, \text{category\_id}, \text{publisher\_id}$
  *(Partial Dependency: Does not require transaction_id or author_id)*

### Resolution to 2NF:
We decompose $R$ by isolating partially dependent attributes into separate relations where each attribute depends on the full primary key of that specific entity:

1. `AUTHORS_2NF` ($\underline{\text{author\_id}}$, first_name, last_name, email, nationality)
2. `RESOURCES_2NF` ($\underline{\text{resource\_id}}$, title, isbn_issn, category_id, category_name, publisher_id, publisher_name, publication_year)
3. `RESOURCE_AUTHORS_2NF` ($\underline{\text{resource\_id}, \text{author\_id}}$, author_role) — *Full dependency on composite key*
4. `BOOK_COPIES_2NF` ($\underline{\text{copy\_id}}$, resource_id, barcode, rack_location, status)
5. `MEMBERS_2NF` ($\underline{\text{member\_id}}$, first_name, last_name, email, member_type)
6. `CIRCULATION_2NF` ($\underline{\text{transaction\_id}}$, copy_id, resource_id, member_id, borrow_date, due_date, return_date)

**Conclusion:** All partial dependencies are eliminated. The schema is strictly in **2NF**.

---

## 5. Third Normal Form (3NF)

### Definition:
A relation $R$ is in **Third Normal Form (3NF)** if and only if:
1. It is in **2NF**.
2. **No non-prime attribute is transitively dependent on any candidate key**.
   Formally, for every non-trivial functional dependency $X \rightarrow Y$:
   - Either $X$ is a superkey of $R$, OR
   - $Y$ is a prime attribute (part of a candidate key).

### Transitive Functional Dependency Analysis on 2NF Relations:
In `RESOURCES_2NF`:
- Candidate Key: $\text{resource\_id}$
- Dependencies:
  - $\text{resource\_id} \rightarrow \text{publisher\_id}$
  - $\text{publisher\_id} \rightarrow \text{publisher\_name}, \text{publisher\_email}, \text{country}$
  - Transitive Dependency: $\text{resource\_id} \rightarrow \text{publisher\_name}$ through $\text{publisher\_id}$!
  - Similarly: $\text{resource\_id} \rightarrow \text{category\_id}$, and $\text{category\_id} \rightarrow \text{category\_name}, \text{description}$
  - Transitive Dependency: $\text{resource\_id} \rightarrow \text{category\_name}$ through $\text{category\_id}$!

In `CIRCULATION_2NF` + `FINES`:
- If `fine_amount` was placed in `CIRCULATION`:
  $\text{transaction\_id} \rightarrow \text{return\_date} \rightarrow \text{fine\_amount}$.

### Resolution to 3NF:
Decompose relations to remove intermediate determinants into their own independent tables:

1. Extract `publishers`:
   - Schema: $\underline{\text{publisher\_id}}$, name, contact_email, phone, address, country, established_year
   - Candidate Key: $\text{publisher\_id}$
2. Extract `categories`:
   - Schema: $\underline{\text{category\_id}}$, category_name, parent_category_id, description
   - Candidate Key: $\text{category\_id}$
3. Normalized `resources`:
   - Schema: $\underline{\text{resource\_id}}$, title, isbn_issn, resource_type, category_id, publisher_id, publication_year, edition, language
   - All non-key attributes depend directly and solely on $\text{resource\_id}$.
4. Extract `fines_and_penalties`:
   - Schema: $\underline{\text{fine\_id}}$, transaction_id, member_id, fine_type, fine_amount, paid_amount, fine_status, assessed_date
   - Eliminates calculation transitivity from circulation transactions.

**Conclusion:** All transitive dependencies are removed. The schema satisfies **3NF**.

---

## 6. Boyce-Codd Normal Form (BCNF)

### Definition:
A relation $R$ is in **Boyce-Codd Normal Form (BCNF)** if and only if:
For every non-trivial functional dependency $X \rightarrow Y$, **$X$ is a superkey of $R$**.

BCNF is a stricter version of 3NF. In 3NF, the condition allowing $Y$ to be a prime attribute permits situations where a non-trivial dependency has a determinant $X$ that is not a superkey. BCNF strictly disallows this.

### Evaluation of ILDRMS Schema against BCNF:

#### Case 1: `book_copies` Table
- Attributes: $\{ \text{copy\_id}, \text{resource\_id}, \text{barcode}, \text{rack\_location}, \text{status}, \text{acquisition\_date}, \text{purchase\_price} \}$
- Functional Dependencies:
  - $FD_A: \text{copy\_id} \rightarrow \text{resource\_id}, \text{barcode}, \text{rack\_location}, \text{status}, \dots$
  - $FD_B: \text{barcode} \rightarrow \text{copy\_id}, \text{resource\_id}, \text{rack\_location}, \text{status}, \dots$
- Superkey Evaluation:
  - Both $\text{copy\_id}$ and $\text{barcode}$ uniquely determine all attributes.
  - Candidate Keys = $\{ \text{copy\_id} \}$, $\{ \text{barcode} \}$.
  - In both $FD_A$ and $FD_B$, the determinant is a candidate key (and therefore a superkey).
  - **Verdict**: Strictly in **BCNF**.

#### Case 2: `resources` Table
- Attributes: $\{ \text{resource\_id}, \text{title}, \text{isbn\_issn}, \text{resource\_type}, \text{category\_id}, \text{publisher\_id}, \dots \}$
- Functional Dependencies:
  - $FD_A: \text{resource\_id} \rightarrow \text{title}, \text{isbn\_issn}, \dots$
  - $FD_B: \text{isbn\_issn} \rightarrow \text{resource\_id}, \text{title}, \dots$
- Superkey Evaluation:
  - Determinants $\text{resource\_id}$ and $\text{isbn\_issn}$ are each valid candidate keys.
  - **Verdict**: Strictly in **BCNF**.

#### Case 3: `resource_authors` (M:N Bridge)
- Attributes: $\{ \text{resource\_id}, \text{author\_id}, \text{author\_role} \}$
- Functional Dependency:
  - $\{ \text{resource\_id}, \text{author\_id} \} \rightarrow \text{author\_role}$
- Superkey Evaluation:
  - Determinant $\{ \text{resource\_id}, \text{author\_id} \}$ is the compound primary key of the table.
  - **Verdict**: Strictly in **BCNF**.

#### Case 4: `reservations`
- Attributes: $\{ \text{reservation\_id}, \text{resource\_id}, \text{member\_id}, \text{reservation\_date}, \text{queue\_priority}, \text{reservation\_status} \}$
- Primary Key: $\text{reservation\_id}$
- Natural Business Key / Alternate Key: $\{ \text{resource\_id}, \text{member\_id}, \text{reservation\_status} \}$ (A member cannot hold multiple active pending reservations for the exact same resource title).
- Determinants are candidate keys.
- **Verdict**: Strictly in **BCNF**.

---

## 7. Mathematical Proof of Lossless-Join Decomposition

### Theorem:
Let $R$ be decomposed into $R_1$ and $R_2$. The decomposition is **lossless** if and only if the common attributes $(R_1 \cap R_2)$ form a superkey of at least one of the decomposed relations:
$$(R_1 \cap R_2) \rightarrow R_1 \quad \text{OR} \quad (R_1 \cap R_2) \rightarrow R_2$$

### Verification on `resources` and `publishers`:
- $R = \text{RESOURCES\_COMBINED}(\text{resource\_id}, \text{title}, \text{publisher\_id}, \text{publisher\_name})$
- $R_1 = \text{resources}(\underline{\text{resource\_id}}, \text{title}, \text{publisher\_id})$
- $R_2 = \text{publishers}(\underline{\text{publisher\_id}}, \text{publisher\_name})$
- Common Attribute: $(R_1 \cap R_2) = \{ \text{publisher\_id} \}$
- Since $\text{publisher\_id}$ is the Primary Key of $R_2$, the functional dependency:
  $$\{ \text{publisher\_id} \} \rightarrow R_2 \quad (\text{publisher\_id} \rightarrow \text{publisher\_name})$$
  holds universally.
- **Q.E.D.**: The decomposition is guaranteed **lossless**. No spurious tuples can be generated upon joining.

---

## 8. Summary Normalization Matrix

| Table Name | Normal Form Achieved | Primary Key | Alternate / Candidate Key | Determinants |
| :--- | :---: | :--- | :--- | :--- |
| `publishers` | **BCNF** | `publisher_id` | `name` | `publisher_id`, `name` |
| `authors` | **BCNF** | `author_id` | `email` | `author_id`, `email` |
| `categories` | **BCNF** | `category_id` | `category_name` | `category_id`, `category_name` |
| `resources` | **BCNF** | `resource_id` | `isbn_issn` | `resource_id`, `isbn_issn` |
| `resource_authors` | **BCNF** | `(resource_id, author_id)`| None | `(resource_id, author_id)` |
| `book_copies` | **BCNF** | `copy_id` | `barcode` | `copy_id`, `barcode` |
| `digital_assets` | **BCNF** | `asset_id` | `resource_id` | `asset_id`, `resource_id` |
| `members` | **BCNF** | `member_id` | `email`, `phone` | `member_id`, `email`, `phone` |
| `circulation_transactions` | **BCNF** | `transaction_id` | None | `transaction_id` |
| `reservations` | **BCNF** | `reservation_id` | None | `reservation_id` |
| `fines_and_penalties` | **BCNF** | `fine_id` | `transaction_id` | `fine_id`, `transaction_id` |
| `fine_payments` | **BCNF** | `payment_id` | `receipt_reference` | `payment_id`, `receipt_reference` |
