
#!/bin/bash

DB="library.db"

echo "Recreating database..."

rm -f "$DB"

sqlite3 "$DB" < schema.sql
sqlite3 "$DB" < insert_data.sql

echo
echo "Running queries..."

sqlite3 -header -column "$DB" < queries.sql

echo
echo "Running transaction..."

sqlite3 -bail "$DB" < transaction.sql
status=$?

if [ "$status" -eq 0 ]; then
    echo "Transaction completed successfully."

    LOAN_COUNT=$(sqlite3 -batch -noheader -list "$DB" "SELECT COUNT(*) FROM LOAN;")
    COPY_STATUS=$(sqlite3 -batch -noheader -list "$DB" "SELECT availability_status FROM BOOK_COPY WHERE copy_id = 2;")

    if [ "$LOAN_COUNT" = "8" ] && [ "$COPY_STATUS" = "Available" ]; then
        echo "[PASS] Transaction rolled back successfully."
    else
        echo "[FAIL] Transaction did not restore the original data."
    fi
else
    echo "Transaction failed."
    echo "Uncommitted changes were rolled back."
fi

echo
echo "Done."

