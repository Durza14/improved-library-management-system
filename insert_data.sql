INSERT INTO BOOK (book_id, ISBN, title, publication_year, publisher)
VALUES
(1, '9780743273565', 'The Great Gatsby', 1925, 'Scribner'),
(2, '9780451524935', '1984', 1949, 'Signet Classics'),
(3, '9780061120084', 'To Kill a Mockingbird', 1960, 'Harper Perennial'),
(4, '9780316769488', 'The Catcher in the Rye', 1951, 'Little, Brown'),
(5, '9780141439518', 'Pride and Prejudice', 1813, 'Penguin Classics'),
(6, '9780141439471', 'Frankenstein', 1818, 'Penguin Classics');

INSERT INTO AUTHOR (author_id, first_name, last_name)
VALUES
(1, 'F. Scott', 'Fitzgerald'),
(2, 'George', 'Orwell'),
(3, 'Harper', 'Lee'),
(4, 'J. D.', 'Salinger'),
(5, 'Jane', 'Austen'),
(6, 'Mary', 'Shelley');

INSERT INTO GENRE (genre_id, genre_name)
VALUES
(1, 'Classic'),
(2, 'Dystopian'),
(3, 'Fiction'),
(4, 'Romance'),
(5, 'Gothic'),
(6, 'Science Fiction');

INSERT INTO MEMBER (member_id, first_name, last_name, email, phone, registration_date)
VALUES
(1, 'Alice', 'Johnson', 'alice@example.com', '555-0101', '2025-01-10'),
(2, 'Bob', 'Smith', 'bob@example.com', '555-0102', '2025-02-15'),
(3, 'Charlie', 'Brown', 'charlie@example.com', '555-0103', '2025-03-20'),
(4, 'Diana', 'Miller', 'diana@example.com', '555-0104', '2025-04-05'),
(5, 'Ethan', 'Davis', 'ethan@example.com', '555-0105', '2025-05-12'),
(6, 'Fiona', 'Wilson', 'fiona@example.com', '555-0106', '2025-06-18');

INSERT INTO BOOK_COPY (copy_id, book_id, condition, availability_status, shelf_location)
VALUES
(1, 1, 'Good', 'Checked Out', 'A1'),
(2, 1, 'Good', 'Available', 'A1'),
(3, 2, 'New', 'Checked Out', 'B2'),
(4, 2, 'Fair', 'Available', 'B2'),
(5, 3, 'Good', 'Checked Out', 'C1'),
(6, 4, 'Fair', 'Available', 'C2'),
(7, 5, 'Good', 'Available', 'D1'),
(8, 6, 'Damaged', 'Damaged', 'D2');

INSERT INTO BOOK_AUTHOR (book_id, author_id)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6);

INSERT INTO BOOK_GENRE (book_id, genre_id)
VALUES
(1, 1),
(1, 3),
(2, 1),
(2, 2),
(3, 1),
(3, 3),
(4, 1),
(5, 1),
(5, 4),
(6, 1),
(6, 3),
(6, 5),
(6, 6);

INSERT INTO LOAN (loan_id, copy_id, member_id, checkout_date, due_date, return_date)
VALUES
(1, 1, 1, '2026-10-01', '2026-10-15', NULL),
(2, 3, 2, '2026-10-05', '2026-10-19', NULL),
(3, 5, 3, '2026-10-10', '2026-10-24', NULL),
(4, 2, 4, '2026-08-01', '2026-08-15', '2026-08-14'),
(5, 4, 1, '2026-08-10', '2026-08-24', '2026-08-30'),
(6, 6, 5, '2026-09-01', '2026-09-15', '2026-09-20'),
(7, 7, 6, '2026-09-10', '2026-09-24', '2026-09-22'),
(8, 8, 2, '2026-09-15', '2026-09-29', '2026-09-28');

INSERT INTO FINE (fine_id, loan_id, amount, date_assessed, date_paid)
VALUES
(1, 5, 3.00, '2026-08-31', '2026-09-02'),
(2, 6, 5.00, '2026-09-21', NULL),
(3, 4, 1.50, '2026-08-16', '2026-08-18'),
(4, 8, 2.00, '2026-09-30', NULL);

INSERT INTO WAITLIST (waitlist_id, book_id, member_id, date_added, status, notification_date)
VALUES
(1, 1, 5, '2026-10-15', 'Waiting', NULL),
(2, 2, 4, '2026-10-16', 'Notified', '2026-10-20'),
(3, 3, 6, '2026-10-17', 'Waiting', NULL),
(4, 5, 2, '2026-10-18', 'Cancelled', NULL);
