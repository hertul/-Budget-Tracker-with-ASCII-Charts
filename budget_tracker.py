
---

# 💻 Code Implementations

## 1. Python (`budget_tracker.py`)

```python
# budget_tracker.py
import json
import os
from datetime import datetime, date
from collections import defaultdict

DATA_FILE = "budget.json"

class BudgetTracker:
    def __init__(self):
        self.transactions = []
        self.load()

    def load(self):
        if os.path.exists(DATA_FILE):
            with open(DATA_FILE, 'r') as f:
                try:
                    self.transactions = json.load(f)
                except:
                    self.transactions = []
        else:
            self.transactions = []

    def save(self):
        with open(DATA_FILE, 'w') as f:
            json.dump(self.transactions, f, indent=2)

    def add_transaction(self, ttype, category, amount, date_str=None):
        if date_str is None or date_str.strip() == "":
            date_str = date.today().isoformat()
        else:
            # validate format
            try:
                datetime.strptime(date_str, "%Y-%m-%d")
            except ValueError:
                print("Invalid date format. Use YYYY-MM-DD.")
                return False
        self.transactions.append({
            "type": ttype,
            "category": category,
            "amount": float(amount),
            "date": date_str
        })
        self.save()
        return True

    def get_balance(self):
        total_income = sum(t['amount'] for t in self.transactions if t['type'] == 'income')
        total_expense = sum(t['amount'] for t in self.transactions if t['type'] == 'expense')
        return total_income, total_expense, total_income - total_expense

    def category_stats(self, ttype='expense'):
        stats = defaultdict(float)
        for t in self.transactions:
            if t['type'] == ttype:
                stats[t['category']] += t['amount']
        return dict(stats)

    def print_chart(self, ttype='expense', width=40):
        stats = self.category_stats(ttype)
        if not stats:
            print("No data to chart.")
            return
        total = sum(stats.values())
        max_val = max(stats.values()) if stats else 1
        sorted_items = sorted(stats.items(), key=lambda x: x[1], reverse=True)
        print(f"\n{ttype.capitalize()} chart (by category):")
        for cat, val in sorted_items:
            bar_len = int((val / max_val) * width)
            bar = '█' * bar_len
            print(f"{cat:12} {bar} {val:.2f}")
        print(f"Total: {total:.2f}")

def main():
    tracker = BudgetTracker()
    print("=== Budget Tracker ===")
    while True:
        print("\n1. Add transaction")
        print("2. Show balance")
        print("3. Show category stats")
        print("4. Show expense chart")
        print("5. Save & exit")
        choice = input("Choose: ").strip()
        if choice == '1':
            ttype = input("Type (income/expense): ").strip().lower()
            if ttype not in ('income', 'expense'):
                print("Invalid type.")
                continue
            category = input("Category: ").strip()
            try:
                amount = float(input("Amount: "))
            except ValueError:
                print("Invalid amount.")
                continue
            date_str = input("Date (YYYY-MM-DD, leave blank for today): ").strip()
            if tracker.add_transaction(ttype, category, amount, date_str):
                print("Transaction added.")
        elif choice == '2':
            inc, exp, bal = tracker.get_balance()
            print(f"\nIncome: {inc:.2f}")
            print(f"Expenses: {exp:.2f}")
            print(f"Balance: {bal:.2f}")
        elif choice == '3':
            stats = tracker.category_stats('expense')
            if not stats:
                print("No expenses recorded.")
            else:
                total = sum(stats.values())
                print("\nExpense categories:")
                for cat, val in sorted(stats.items(), key=lambda x: x[1], reverse=True):
                    pct = (val / total * 100) if total else 0
                    print(f"  {cat:12} {val:10.2f}  ({pct:5.1f}%)")
        elif choice == '4':
            tracker.print_chart('expense')
        elif choice == '5':
            tracker.save()
            print("Goodbye!")
            break
        else:
            print("Invalid choice.")

if __name__ == "__main__":
    main()
