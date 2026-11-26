#!/bin/bash

# ============================================================
#  Upload GroupLedger.csv / whole repo to GitHub
#  Order: pull -> copy -> add -> commit -> push
# ============================================================

# ===== Config =====
SRC_FILE="/c/xampp/htdocs/service-system-v2/storage/uploads/exports/GroupLedger.csv"
DEST_REL="GroupLedger.csv"                # فایل مستقیم در ریشه مخزن
DEST_FILE="$(pwd)/GroupLedger.csv"

# ============================================================
#  Functions
# ============================================================

# --- Pull latest from GitHub (safe against local changes) ---
do_pull() {
    echo "[1/3] Pulling latest changes from GitHub..."

    # اگر فایل مقصد تغییر لوکال دارد، قبل از pull آن را دور بریز
    if [ -f "$DEST_FILE" ] && ! git diff --quiet -- "$DEST_REL" 2>/dev/null; then
        echo "      [!] Local changes detected on $DEST_REL - discarding before pull."
        git checkout -- "$DEST_REL" 2>/dev/null || true
    fi

    git pull origin main --allow-unrelated-histories --no-edit
    if [ $? -ne 0 ]; then
        echo "[X] git pull failed!"
        return 1
    fi
    echo "      [OK] Pull done."
    return 0
}

# --- Copy GroupLedger.csv from XAMPP to repo root ---
copy_ledger() {
    echo "[2/3] Copying GroupLedger.csv from XAMPP to repo root..."

    if [ ! -f "$SRC_FILE" ]; then
        echo "[X] Source file not found:"
        echo "    $SRC_FILE"
        return 1
    fi

    cp -f "$SRC_FILE" "$DEST_FILE"
    if [ $? -ne 0 ]; then
        echo "[X] Copy failed!"
        return 1
    fi
    echo "      [OK] Copy done: $DEST_REL"

    # --- فایل فشرده + فایل نسخه (هش) برای بروزرسانی خودکار برنامه ---
    gzip -9 -c "$DEST_FILE" > "$(pwd)/GroupLedger.csv.gz"
    if [ $? -ne 0 ]; then
        echo "[X] gzip failed!"
        return 1
    fi
    SHA=$(tr -d '\r' < "$DEST_FILE" | sha256sum | cut -d' ' -f1)
    SIZE=$(wc -c < "$DEST_FILE" | tr -d ' ')
    REC=$(( $(wc -l < "$DEST_FILE") - 1 ))
    printf 'sha256=%s\nsize=%s\nrecords=%s\nupdated=%s\n' "$SHA" "$SIZE" "$REC" "$(date '+%Y-%m-%d %H:%M:%S')" > "$(pwd)/GroupLedger.meta"

    # جلوگیری از تغییر پایان خط فایل‌ها توسط گیت (حیاتی برای هش)
    if [ ! -f "$(pwd)/.gitattributes" ]; then
        printf 'GroupLedger.csv -text\nGroupLedger.csv.gz -text\nGroupLedger.meta text eol=lf\n' > "$(pwd)/.gitattributes"
    fi
    echo "      [OK] Created GroupLedger.csv.gz + GroupLedger.meta (records: $REC)"
    return 0
}

# فایل‌هایی که برای بروزرسانی دیتابیس باید آپلود شوند
LEDGER_FILES="GroupLedger.csv GroupLedger.csv.gz GroupLedger.meta .gitattributes"

# --- Commit & push ---
do_commit_push() {
    echo "[3/3] Committing and pushing..."

    if git diff --cached --quiet; then
        echo "      [!] No new changes to commit."
    else
        git commit -m "Update GroupLedger.csv ($(date '+%Y-%m-%d %H:%M:%S'))"
        if [ $? -ne 0 ]; then
            echo "[X] Commit failed!"
            return 1
        fi
        echo "      [OK] Commit done."
    fi

    git push origin main
    if [ $? -ne 0 ]; then
        echo "[X] Push failed! Check the error above."
        return 1
    fi
    echo "      [OK] Push done."
    return 0
}

# ============================================================
#  Menu
# ============================================================
echo "========================================"
echo "        Upload to GitHub - Menu"
echo "========================================"
echo
echo "  1) Upload only GroupLedger.csv (to repo root)"
echo "  2) Upload entire repository content"
echo "  3) Upload both"
echo "  4) Exit"
echo
read -p "Choose an option [1-4]: " CHOICE
echo

case "$CHOICE" in
    # --------------------------------------------------------
    1)
        echo ">>> Option 1: Only GroupLedger.csv (root)"
        echo
        do_pull     || { read -p "Press Enter to exit..."; exit 1; }
        echo
        copy_ledger || { read -p "Press Enter to exit..."; exit 1; }
        echo
        git add $LEDGER_FILES
        if [ $? -ne 0 ]; then
            echo "[X] git add failed!"
            read -p "Press Enter to exit..."
            exit 1
        fi
        echo
        do_commit_push || { read -p "Press Enter to exit..."; exit 1; }
        ;;

    # --------------------------------------------------------
    2)
        echo ">>> Option 2: Entire repository"
        echo
        do_pull || { read -p "Press Enter to exit..."; exit 1; }
        echo
        git add -A
        if [ $? -ne 0 ]; then
            echo "[X] git add failed!"
            read -p "Press Enter to exit..."
            exit 1
        fi
        echo
        do_commit_push || { read -p "Press Enter to exit..."; exit 1; }
        ;;

    # --------------------------------------------------------
    3)
        echo ">>> Option 3: GroupLedger.csv (root) + entire repository"
        echo
        do_pull     || { read -p "Press Enter to exit..."; exit 1; }
        echo
        copy_ledger || { read -p "Press Enter to exit..."; exit 1; }
        echo
        git add -A
        if [ $? -ne 0 ]; then
            echo "[X] git add failed!"
            read -p "Press Enter to exit..."
            exit 1
        fi
        echo
        do_commit_push || { read -p "Press Enter to exit..."; exit 1; }
        ;;

    # --------------------------------------------------------
    4)
        echo "Exit."
        exit 0
        ;;

    # --------------------------------------------------------
    *)
        echo "[X] Invalid choice: $CHOICE"
        read -p "Press Enter to exit..."
        exit 1
        ;;
esac

echo
echo "========================================"
echo "  [OK] Operation completed successfully."
echo "========================================"
echo
read -p "Press Enter to close..."