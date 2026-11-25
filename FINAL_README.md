# **Improved Library Management System**

## **Project Overview**

The Improved Library Management System is a command-line application designed to help librarians manage books, physical copies, members, loans, fines, and waitlists.

The application allows users to search the book catalog, register members, check books in and out, manage waitlists, and view library reports.

## **Requirements**

* Python 3.8 or newer  
* SQLite 3  
* Python's built-in sqlite3 library (no additional packages required)

## **Files**

* schema.sql: Creates all 10 tables, primary keys, foreign keys, constraints, indexes, and the CURRENT\_LOANS view.  
* insert\_data.sql: Inserts sample data into the database.  
* queries.sql: Contains the required SQL queries and additional project queries.  
* transaction.sql: Demonstrates a database transaction.  
* run\_queries.sh: Creates the database, inserts sample data, and executes the SQL queries and transaction.  
* app.py: Contains the command-line application.  
* erd.pdf: Contains the final entity-relationship diagram.  
* README.md: Provides setup and run instructions.

## **Database Management System**

* Database Management System: SQLite  
* Database file: library.db

The database is stored locally in the project directory. No hosted database or external credentials are required.

## **Database Setup**

Place all project files in the same directory.

Run the following command from the project directory:

```
bash run_queries.sh
```

This script:

1. Removes the existing database, if one exists.  
2. Creates a new database using schema.sql.  
3. Inserts sample data using insert\_data.sql.  
4. Executes the SQL queries in queries.sql.  
5. Runs the transaction example in transaction.sql.

This creates library.db in the project directory.

**Note:** Running the script again will recreate the database and erase any changes made through the application.

## **Database Configuration**

The application automatically connects to library.db in the project directory.

Foreign-key enforcement is enabled when the application connects to the database. No additional database configuration is required.

## **Starting the Application**

Run the following command from the project directory:

```
python3 app.py
```

Follow the interactive menu to select an operation. Enter 0 to exit.

## **Required Application Operations**

The application provides the six required categories of functionality through the following menu options:

1. **Search or Browse Data (Option 1):** Search for books by title, author, or genre, or display the entire book catalog.  
2. **Display Related Data (Option 2):** View a member's loan history, including related book and copy information.  
3. **Add Data (Option 3):** Register a new library member. Option 4 also allows adding books and copies.  
4. **Update or Delete Data (Option 6):** Return a book, update its loan record, and change the copy's availability status.  
5. **Summary or Report (Option 8):** View reports showing popular books, waitlist counts, and overdue loans.  
6. **Additional Meaningful Operation (Option 5):** Check out an available book copy and create a new loan record.

### **Additional Functionality**

* Option 4: Add a new book and its first physical copy.  
* Option 7: Add a member to a book's waitlist.  
* Option 0: Exit the application.

## **Views and Indexes**

**View:**

* CURRENT\_LOANS: Joins the LOAN, BOOK\_COPY, BOOK, and MEMBER tables to display currently borrowed books and their borrowers. Returned loans are excluded.

**Indexes:**

* idx\_waitlist\_book\_status\_date: Improves searches for members on a waitlist for a particular book.  
* idx\_one\_active\_loan\_per\_copy: Ensures that a book copy cannot have multiple active loans at the same time.