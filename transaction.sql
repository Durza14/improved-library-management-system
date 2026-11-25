PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

UPDATE BOOK_COPY
SET availability_status = 'Checked Out'
WHERE copy_id = 2
AND availability_status = 'Available';

INSERT INTO LOAN (
    loan_id,
    copy_id,
    member_id,
    checkout_date,
    due_date,
    return_date
)
VALUES (
    9,
    2,
    4,
    '2026-11-24',
    '2026-12-08',
    NULL
);

SELECT
    BOOK.title,
    BOOK_COPY.copy_id,
    BOOK_COPY.availability_status,
    MEMBER.first_name,
    MEMBER.last_name,
    LOAN.checkout_date,
    LOAN.due_date
FROM LOAN
INNER JOIN BOOK_COPY
    ON LOAN.copy_id = BOOK_COPY.copy_id
INNER JOIN BOOK
    ON BOOK_COPY.book_id = BOOK.book_id
INNER JOIN MEMBER
    ON LOAN.member_id = MEMBER.member_id
WHERE LOAN.loan_id = 9;

ROLLBACK;

