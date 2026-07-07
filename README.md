# 📊 Budget Tracker with ASCII Charts

A cross‑platform, multi‑language **budget tracking tool** that stores your transactions locally and displays beautiful **text‑based bar charts** for spending analysis.  
Perfect for learning or comparing programming languages — all implementations share the same feature set.

## ✨ Features
- **Add transactions** – income or expense, with category, amount, and optional date (defaults to today).
- **View balance** – total income, total expenses, and net balance.
- **Category statistics** – breakdown by category with sums and percentages.
- **Visual chart** – horizontal bar chart of spending categories (scaled to fit the terminal).
- **Persistent storage** – automatically saved to `budget.json` in the working directory.
- **Interactive menu** – simple CLI with numbered options.

## 🗂 Languages & Files
| Language          | File                  |
|-------------------|-----------------------|
| Python            | `budget_tracker.py`   |
| Go                | `budget_tracker.go`   |
| JavaScript (Node) | `budget_tracker.js`   |
| C#                | `BudgetTracker.cs`    |
| Java              | `BudgetTracker.java`  |
| Ruby              | `budget_tracker.rb`   |
| Swift             | `budget_tracker.swift`|

## 🚀 How to Run
Each file is standalone – just run with the corresponding interpreter/compiler:

| Language | Command |
|----------|---------|
| Python   | `python budget_tracker.py` |
| Go       | `go run budget_tracker.go` |
| JavaScript | `node budget_tracker.js` |
| C#       | `dotnet run` (or `csc BudgetTracker.cs`) |
| Java     | `javac BudgetTracker.java && java BudgetTracker` |
| Ruby     | `ruby budget_tracker.rb` |
| Swift    | `swift budget_tracker.swift` |

## 📊 Example Session
=== Budget Tracker ===

Add transaction

Show balance

Show category stats

Show expense chart

Save & exit
Choose: 1
Type (income/expense): expense
Category: Food
Amount: 25.50
Date (YYYY-MM-DD, leave blank for today):
Transaction added.

Choose: 4
Expense chart (by category):
Food ████████████████████ 25.50
Transport ████████ 10.00
Total: 35.50

text

## 💾 Data Format
All transactions are stored in `budget.json` as an array of objects:
```json
[
  {"type":"expense","category":"Food","amount":25.50,"date":"2025-01-15"},
  ...
]
🤝 Contributing
Feel free to add more languages, improve the chart scaling, or add data export – PRs are welcome!

📜 License
MIT – use anywhere.
