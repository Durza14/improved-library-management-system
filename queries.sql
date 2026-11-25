-- Requirement 1: Filtering and Sorting
-- Lists books published before 1950 from oldest to newest.
SELECT
    title,
    publication_year,
    publisher
FROM BOOK
WHERE publication_year < 1950
ORDER BY publication_year ASC;


-- Requirement 2: INNER JOIN
-- Lists members who have borrowed books along with checkout and due dates.
SELECT
    MEMBER.first_name,
    MEMBER.last_name,
    LOAN.copy_id,
    LOAN.checkout_date,
    LOAN.due_date
FROM MEMBER
INNER JOIN LOAN
    ON MEMBER.member_id = LOAN.member_id
ORDER BY MEMBER.last_name, LOAN.checkout_date;


-- Requirement 3: LEFT JOIN
-- Counts active loans per book, including books with zero active loans.
SELECT
    BOOK.title,
    COUNT(LOAN.loan_id) AS active_loan_count
FROM BOOK
LEFT JOIN BOOK_COPY
    ON BOOK.book_id = BOOK_COPY.book_id
LEFT JOIN LOAN
    ON BOOK_COPY.copy_id = LOAN.copy_id
    AND LOAN.return_date IS NULL
GROUP BY BOOK.book_id, BOOK.title
ORDER BY BOOK.title;


-- Requirement 4: Three-Table Join
-- Shows which members borrowed which book titles and when.
SELECT
    MEMBER.first_name,
    MEMBER.last_name,
    BOOK.title,
    LOAN.checkout_date,
    LOAN.due_date,
    LOAN.return_date
FROM MEMBER
INNER JOIN LOAN
    ON MEMBER.member_id = LOAN.member_id
INNER JOIN BOOK_COPY
    ON LOAN.copy_id = BOOK_COPY.copy_id
INNER JOIN BOOK
    ON BOOK_COPY.book_id = BOOK.book_id
ORDER BY LOAN.checkout_date;


-- Requirement 5: Aggregate Query
-- Ranks books by total checkouts to identify which books are borrowed most often.
SELECT
    BOOK.title,
    COUNT(LOAN.loan_id) AS total_checkouts
FROM BOOK
INNER JOIN BOOK_COPY
    ON BOOK.book_id = BOOK_COPY.book_id
INNER JOIN LOAN
    ON BOOK_COPY.copy_id = LOAN.copy_id
GROUP BY BOOK.book_id, BOOK.title
ORDER BY total_checkouts DESC;


-- Requirement 6: GROUP BY and HAVING
-- Finds books with at least one waiting member to identify where more copies are needed.
SELECT
    BOOK.title,
    COUNT(WAITLIST.waitlist_id) AS waitlist_size
FROM BOOK
INNER JOIN WAITLIST
    ON BOOK.book_id = WAITLIST.book_id
WHERE WAITLIST.status = 'Waiting'
GROUP BY BOOK.book_id, BOOK.title
HAVING COUNT(WAITLIST.waitlist_id) >= 1
ORDER BY waitlist_size DESC;


-- Requirement 7: Subquery
-- Finds catalog books written by Jane Austen.
SELECT
    title,
    publication_year,
    publisher
FROM BOOK
WHERE book_id IN (
    SELECT BOOK_AUTHOR.book_id
    FROM BOOK_AUTHOR
    INNER JOIN AUTHOR
        ON BOOK_AUTHOR.author_id = AUTHOR.author_id
    WHERE AUTHOR.first_name = 'Jane'
    AND AUTHOR.last_name = 'Austen'
)
ORDER BY title;


-- Requirement 8: Set Operation
-- Combines distinct member IDs from loans and waitlists.
SELECT member_id
FROM LOAN

UNION

SELECT member_id
FROM WAITLIST;


-- Requirement 9: View
-- Shows active loan due dates to estimate when checked-out books will return.
SELECT
    book_title,
    copy_id,
    first_name,
    last_name,
    checkout_date,
    due_date
FROM CURRENT_LOANS
ORDER BY due_date ASC;
