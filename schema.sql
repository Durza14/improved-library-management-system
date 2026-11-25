
PRAGMA foreign_keys = ON;

DROP VIEW IF EXISTS CURRENT_LOANS;

DROP TABLE IF EXISTS FINE;
DROP TABLE IF EXISTS WAITLIST;
DROP TABLE IF EXISTS LOAN;
DROP TABLE IF EXISTS BOOK_AUTHOR;
DROP TABLE IF EXISTS BOOK_GENRE;
DROP TABLE IF EXISTS BOOK_COPY;
DROP TABLE IF EXISTS MEMBER;
DROP TABLE IF EXISTS AUTHOR;
DROP TABLE IF EXISTS GENRE;
DROP TABLE IF EXISTS BOOK;

CREATE TABLE BOOK (
    book_id INTEGER PRIMARY KEY,
    ISBN TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    publication_year INTEGER,
    publisher TEXT,
    CHECK (
        publication_year IS NULL
        OR publication_year BETWEEN 0 AND 2026
    )
);

CREATE TABLE BOOK_COPY (
    copy_id INTEGER PRIMARY KEY,
    book_id INTEGER NOT NULL,
    condition TEXT NOT NULL DEFAULT 'New',
    availability_status TEXT NOT NULL DEFAULT 'Available',
    shelf_location TEXT,
    FOREIGN KEY (book_id) REFERENCES BOOK(book_id),
    CHECK (condition IN ('New', 'Good', 'Fair', 'Poor', 'Damaged')),
    CHECK (
        availability_status IN (
            'Available',
            'Checked Out',
            'Lost',
            'Damaged',
            'Reserved'
        )
    )
);

CREATE TABLE AUTHOR (
    author_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL
);

CREATE TABLE BOOK_AUTHOR (
    book_id INTEGER NOT NULL,
    author_id INTEGER NOT NULL,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES BOOK(book_id),
    FOREIGN KEY (author_id) REFERENCES AUTHOR(author_id)
);

CREATE TABLE GENRE (
    genre_id INTEGER PRIMARY KEY,
    genre_name TEXT NOT NULL UNIQUE
);

CREATE TABLE BOOK_GENRE (
    book_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (book_id, genre_id),
    FOREIGN KEY (book_id) REFERENCES BOOK(book_id),
    FOREIGN KEY (genre_id) REFERENCES GENRE(genre_id)
);

CREATE TABLE MEMBER (
    member_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    registration_date TEXT NOT NULL
);

CREATE TABLE LOAN (
    loan_id INTEGER PRIMARY KEY,
    copy_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    checkout_date TEXT NOT NULL,
    due_date TEXT NOT NULL,
    return_date TEXT,
    FOREIGN KEY (copy_id) REFERENCES BOOK_COPY(copy_id),
    FOREIGN KEY (member_id) REFERENCES MEMBER(member_id),
    CHECK (due_date >= checkout_date),
    CHECK (return_date IS NULL OR return_date >= checkout_date)
);

CREATE TABLE FINE (
    fine_id INTEGER PRIMARY KEY,
    loan_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    date_assessed TEXT NOT NULL,
    date_paid TEXT,
    FOREIGN KEY (loan_id) REFERENCES LOAN(loan_id),
    CHECK (amount >= 0),
    CHECK (date_paid IS NULL OR date_paid >= date_assessed)
);

CREATE TABLE WAITLIST (
    waitlist_id INTEGER PRIMARY KEY,
    book_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    date_added TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Waiting',
    notification_date TEXT,
    FOREIGN KEY (book_id) REFERENCES BOOK(book_id),
    FOREIGN KEY (member_id) REFERENCES MEMBER(member_id),
    CHECK (
        status IN ('Waiting', 'Notified', 'Fulfilled', 'Cancelled')
    ),
    CHECK (
        notification_date IS NULL
        OR notification_date >= date_added
    )
);


CREATE INDEX idx_waitlist_book_status_date
ON WAITLIST(book_id, status, date_added);

CREATE UNIQUE INDEX idx_one_active_loan_per_copy
ON LOAN(copy_id)
WHERE return_date IS NULL;


CREATE VIEW CURRENT_LOANS AS
SELECT
    LOAN.loan_id,
    BOOK.title AS book_title,
    BOOK.ISBN,
    BOOK_COPY.copy_id,
    MEMBER.member_id,
    MEMBER.first_name,
    MEMBER.last_name,
    MEMBER.email,
    LOAN.checkout_date,
    LOAN.due_date
FROM LOAN
JOIN BOOK_COPY
    ON LOAN.copy_id = BOOK_COPY.copy_id
JOIN BOOK
    ON BOOK_COPY.book_id = BOOK.book_id
JOIN MEMBER
    ON LOAN.member_id = MEMBER.member_id
WHERE LOAN.return_date IS NULL;

