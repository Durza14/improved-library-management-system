#!/usr/bin/env python3
"""Interactive command-line application for the Improved Library Management System."""

import sqlite3
from datetime import date
from pathlib import Path

DATABASE_FILE = Path(__file__).resolve().parent / "library.db"


def connect_database():
    """Open the SQLite database and enable foreign-key enforcement."""
    connection = sqlite3.connect(DATABASE_FILE)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection


def pause():
    input("\nPress Enter to return to the menu...")


def read_required(prompt):
    while True:
        value = input(prompt).strip()
        if value:
            return value
        print("This value is required.")


def read_integer(prompt, minimum=1):
    while True:
        value = input(prompt).strip()
        try:
            number = int(value)
            if number >= minimum:
                return number
            print("Enter a number greater than or equal to", minimum)
        except ValueError:
            print("Please enter a valid whole number.")


def read_date(prompt, default_today=False):
    while True:
        value = input(prompt).strip()
        if not value and default_today:
            return date.today().isoformat()
        try:
            return date.fromisoformat(value).isoformat()
        except ValueError:
            print("Enter a valid date in YYYY-MM-DD format.")


def print_rows(rows, empty_message="No records found."):
    if not rows:
        print(empty_message)
        return

    headers = list(rows[0].keys())
    values = [[str(row[header]) if row[header] is not None else "" for header in headers]
              for row in rows]
    widths = []
    for index, header in enumerate(headers):
        widths.append(max(len(header), max(len(row[index]) for row in values)))

    print(" | ".join(headers[index].ljust(widths[index]) for index in range(len(headers))))
    print("-+-".join("-" * width for width in widths))
    for row in values:
        print(" | ".join(row[index].ljust(widths[index]) for index in range(len(headers))))


def search_catalog(connection):
    keyword = input("Search by title, author, or genre (leave blank to show all books): ").strip()
    pattern = "%" + keyword + "%"
    rows = connection.execute(
        """
        SELECT
            BOOK.book_id,
            BOOK.title,
            BOOK.publication_year,
            BOOK.publisher,
            GROUP_CONCAT(DISTINCT AUTHOR.first_name || ' ' || AUTHOR.last_name) AS authors,
            GROUP_CONCAT(DISTINCT GENRE.genre_name) AS genres,
            (
                SELECT COUNT(*)
                FROM BOOK_COPY
                WHERE BOOK_COPY.book_id = BOOK.book_id
                  AND BOOK_COPY.availability_status = 'Available'
            ) AS available_copies
        FROM BOOK
        LEFT JOIN BOOK_AUTHOR ON BOOK.book_id = BOOK_AUTHOR.book_id
        LEFT JOIN AUTHOR ON BOOK_AUTHOR.author_id = AUTHOR.author_id
        LEFT JOIN BOOK_GENRE ON BOOK.book_id = BOOK_GENRE.book_id
        LEFT JOIN GENRE ON BOOK_GENRE.genre_id = GENRE.genre_id
        WHERE BOOK.title LIKE ?
           OR (AUTHOR.first_name || ' ' || AUTHOR.last_name) LIKE ?
           OR GENRE.genre_name LIKE ?
           OR ? = ''
        GROUP BY BOOK.book_id
        ORDER BY BOOK.title
        """,
        (pattern, pattern, pattern, keyword),
    ).fetchall()
    print_rows(rows)


def view_member_loans(connection):
    member_id = read_integer("Member ID: ")
    member = connection.execute(
        "SELECT first_name, last_name FROM MEMBER WHERE member_id = ?",
        (member_id,),
    ).fetchone()
    if member is None:
        print("No member exists with that ID.")
        return

    print("\nLoan history for {} {}:".format(member["first_name"], member["last_name"]))
    rows = connection.execute(
        """
        SELECT
            LOAN.loan_id,
            BOOK.title,
            LOAN.copy_id,
            LOAN.checkout_date,
            LOAN.due_date,
            LOAN.return_date,
            CASE WHEN LOAN.return_date IS NULL THEN 'Active' ELSE 'Returned' END AS loan_status
        FROM LOAN
        JOIN BOOK_COPY ON LOAN.copy_id = BOOK_COPY.copy_id
        JOIN BOOK ON BOOK_COPY.book_id = BOOK.book_id
        WHERE LOAN.member_id = ?
        ORDER BY LOAN.checkout_date DESC
        """,
        (member_id,),
    ).fetchall()
    print_rows(rows, "This member has no loan history.")


def register_member(connection):
    first_name = read_required("First name: ")
    last_name = read_required("Last name: ")
    email = read_required("Email: ")
    phone = input("Phone (optional): ").strip() or None
    registration_date = read_date("Registration date [YYYY-MM-DD, Enter for today]: ",
                                   default_today=True)

    if "@" not in email or "." not in email.split("@")[-1]:
        print("Please enter an email address in a valid format.")
        return

    try:
        connection.execute(
            """
            INSERT INTO MEMBER (first_name, last_name, email, phone, registration_date)
            VALUES (?, ?, ?, ?, ?)
            """,
            (first_name, last_name, email, phone, registration_date),
        )
        connection.commit()
        print("Member registered. New member ID:", connection.execute(
            "SELECT last_insert_rowid()"
        ).fetchone()[0])
    except sqlite3.IntegrityError as error:
        connection.rollback()
        if "MEMBER.email" in str(error):
            print("That email address is already registered.")
        else:
            print("The member could not be added because the data violates a database rule.")


def add_book_and_copy(connection):
    isbn = read_required("ISBN: ")
    title = read_required("Book title: ")
    year_text = input("Publication year (optional): ").strip()
    publisher = input("Publisher (optional): ").strip() or None
    condition = input("Copy condition [New/Good/Fair/Poor/Damaged] (default Good): ").strip()
    if not condition:
        condition = "Good"

    if year_text:
        try:
            publication_year = int(year_text)
            if publication_year < 0 or publication_year > date.today().year:
                print("Publication year is outside the valid range.")
                return
        except ValueError:
            print("Publication year must be a whole number.")
            return
    else:
        publication_year = None

    if condition not in ("New", "Good", "Fair", "Poor", "Damaged"):
        print("Condition must be New, Good, Fair, Poor, or Damaged.")
        return

    shelf_location = input("Shelf location (optional): ").strip() or None

    try:
        connection.execute("BEGIN")
        cursor = connection.execute(
            """
            INSERT INTO BOOK (ISBN, title, publication_year, publisher)
            VALUES (?, ?, ?, ?)
            """,
            (isbn, title, publication_year, publisher),
        )
        book_id = cursor.lastrowid
        connection.execute(
            """
            INSERT INTO BOOK_COPY
                (book_id, condition, availability_status, shelf_location)
            VALUES (?, ?, 'Available', ?)
            """,
            (book_id, condition, shelf_location),
        )
        connection.commit()
        copy_id = connection.execute("SELECT last_insert_rowid()").fetchone()[0]
        print("Book and first copy added successfully.")
        print("Book ID:", book_id, "| Copy ID:", copy_id)
    except sqlite3.IntegrityError:
        connection.rollback()
        print("The book could not be added. Check that the ISBN is unique and all values are valid.")


def check_out_copy(connection):
    member_id = read_integer("Member ID: ")
    copy_id = read_integer("Copy ID: ")
    due_date = read_date("Due date [YYYY-MM-DD]: ")
    checkout_date = date.today().isoformat()

    member = connection.execute(
        "SELECT member_id FROM MEMBER WHERE member_id = ?", (member_id,)
    ).fetchone()
    copy = connection.execute(
        """
        SELECT copy_id, availability_status
        FROM BOOK_COPY
        WHERE copy_id = ?
        """,
        (copy_id,),
    ).fetchone()

    if member is None:
        print("No member exists with that ID.")
        return
    if copy is None:
        print("No copy exists with that ID.")
        return
    if copy["availability_status"] != "Available":
        print("That copy is not available. Current status:", copy["availability_status"])
        return
    if due_date < checkout_date:
        print("The due date cannot be earlier than the checkout date.")
        return

    try:
        connection.execute("BEGIN")
        connection.execute(
            """
            UPDATE BOOK_COPY
            SET availability_status = 'Checked Out'
            WHERE copy_id = ? AND availability_status = 'Available'
            """,
            (copy_id,),
        )
        if connection.execute("SELECT changes()").fetchone()[0] != 1:
            connection.rollback()
            print("The copy is no longer available. Please try again.")
            return

        cursor = connection.execute(
            """
            INSERT INTO LOAN (copy_id, member_id, checkout_date, due_date)
            VALUES (?, ?, ?, ?)
            """,
            (copy_id, member_id, checkout_date, due_date),
        )
        loan_id = cursor.lastrowid
        connection.commit()
        print("Checkout completed. Loan ID:", loan_id)
    except sqlite3.IntegrityError:
        connection.rollback()
        print("Checkout failed because the requested loan violates a database rule.")


def return_copy(connection):
    loan_id = read_integer("Loan ID to return: ")
    loan = connection.execute(
        """
        SELECT copy_id, return_date
        FROM LOAN
        WHERE loan_id = ?
        """,
        (loan_id,),
    ).fetchone()

    if loan is None:
        print("No loan exists with that ID.")
        return
    if loan["return_date"] is not None:
        print("That loan has already been returned.")
        return

    return_date = read_date("Return date [YYYY-MM-DD, Enter for today]: ",
                            default_today=True)
    active_loan = connection.execute(
        "SELECT checkout_date FROM LOAN WHERE loan_id = ?", (loan_id,)
    ).fetchone()
    if return_date < active_loan["checkout_date"]:
        print("The return date cannot be earlier than the checkout date.")
        return

    try:
        connection.execute("BEGIN")
        connection.execute(
            "UPDATE LOAN SET return_date = ? WHERE loan_id = ? AND return_date IS NULL",
            (return_date, loan_id),
        )
        connection.execute(
            "UPDATE BOOK_COPY SET availability_status = 'Available' WHERE copy_id = ?",
            (loan["copy_id"],),
        )
        connection.commit()
        print("Book return completed. Copy", loan["copy_id"], "is now available.")
    except sqlite3.IntegrityError:
        connection.rollback()
        print("Return failed because the update violates a database rule.")


def join_waitlist(connection):
    member_id = read_integer("Member ID: ")
    book_id = read_integer("Book ID: ")

    if connection.execute(
        "SELECT 1 FROM MEMBER WHERE member_id = ?", (member_id,)
    ).fetchone() is None:
        print("No member exists with that ID.")
        return
    if connection.execute(
        "SELECT 1 FROM BOOK WHERE book_id = ?", (book_id,)
    ).fetchone() is None:
        print("No book exists with that ID.")
        return

    active_entry = connection.execute(
        """
        SELECT 1 FROM WAITLIST
        WHERE member_id = ? AND book_id = ?
          AND status IN ('Waiting', 'Notified')
        """,
        (member_id, book_id),
    ).fetchone()
    if active_entry is not None:
        print("This member is already on the active waitlist for that book.")
        return

    try:
        cursor = connection.execute(
            """
            INSERT INTO WAITLIST (book_id, member_id, date_added, status)
            VALUES (?, ?, ?, 'Waiting')
            """,
            (book_id, member_id, date.today().isoformat()),
        )
        connection.commit()
        print("Member added to the waitlist. Waitlist ID:", cursor.lastrowid)
    except sqlite3.IntegrityError:
        connection.rollback()
        print("The waitlist entry could not be added.")


def show_reports(connection):
    print("\n--- Most Borrowed Books ---")
    rows = connection.execute(
        """
        SELECT BOOK.title, COUNT(LOAN.loan_id) AS total_checkouts
        FROM BOOK
        LEFT JOIN BOOK_COPY ON BOOK.book_id = BOOK_COPY.book_id
        LEFT JOIN LOAN ON BOOK_COPY.copy_id = LOAN.copy_id
        GROUP BY BOOK.book_id, BOOK.title
        ORDER BY total_checkouts DESC, BOOK.title
        """
    ).fetchall()
    print_rows(rows)

    print("\n--- Current Waitlists ---")
    rows = connection.execute(
        """
        SELECT BOOK.title, COUNT(WAITLIST.waitlist_id) AS waiting_members
        FROM BOOK
        JOIN WAITLIST ON BOOK.book_id = WAITLIST.book_id
        WHERE WAITLIST.status = 'Waiting'
        GROUP BY BOOK.book_id, BOOK.title
        ORDER BY waiting_members DESC, BOOK.title
        """
    ).fetchall()
    print_rows(rows)

    print("\n--- Overdue Active Loans ---")
    rows = connection.execute(
        """
        SELECT
            CURRENT_LOANS.loan_id,
            CURRENT_LOANS.book_title,
            CURRENT_LOANS.first_name || ' ' || CURRENT_LOANS.last_name AS member,
            CURRENT_LOANS.due_date
        FROM CURRENT_LOANS
        WHERE CURRENT_LOANS.due_date < ?
        ORDER BY CURRENT_LOANS.due_date
        """,
        (date.today().isoformat(),),
    ).fetchall()
    print_rows(rows, "There are no overdue active loans.")


def display_menu():
    print("\n====================================")
    print(" Improved Library Management System")
    print("====================================")
    print("1. Search / browse book catalog")
    print("2. View a member's loan history")
    print("3. Register a new member")
    print("4. Add a book and its first copy")
    print("5. Check out a book copy")
    print("6. Return a book copy")
    print("7. Join a book waitlist")
    print("8. View library reports")
    print("0. Exit")


def main():
    if not DATABASE_FILE.exists():
        print("Database file not found:", DATABASE_FILE)
        print("Run the backend setup first (for example: bash run_queries.sh).")
        return

    try:
        connection = connect_database()
        # Fail early with a helpful message if the database has not been initialized.
        connection.execute("SELECT 1 FROM BOOK LIMIT 1")
    except sqlite3.Error:
        print("Could not open the library database or its tables are missing.")
        print("Make sure schema.sql and insert_data.sql have been run.")
        return

    operations = {
        "1": search_catalog,
        "2": view_member_loans,
        "3": register_member,
        "4": add_book_and_copy,
        "5": check_out_copy,
        "6": return_copy,
        "7": join_waitlist,
        "8": show_reports,
    }

    try:
        while True:
            display_menu()
            choice = input("Choose an option: ").strip()
            if choice == "0":
                print("Goodbye.")
                break
            operation = operations.get(choice)
            if operation is None:
                print("Invalid menu selection. Choose one of the listed options.")
                continue
            try:
                operation(connection)
            except sqlite3.Error:
                connection.rollback()
                print("A database error occurred. No incomplete changes were saved.")
            except (KeyboardInterrupt, EOFError):
                print("\nOperation cancelled.")
            pause()
    except (KeyboardInterrupt, EOFError):
        print("\nGoodbye.")
    finally:
        connection.close()


if __name__ == "__main__":
    main()
