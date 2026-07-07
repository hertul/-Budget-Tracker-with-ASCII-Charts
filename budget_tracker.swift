// budget_tracker.swift
import Foundation

let DATA_FILE = "budget.json"
var transactions: [[String: Any]] = []

func load() {
    if FileManager.default.fileExists(atPath: DATA_FILE) {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: DATA_FILE)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            transactions = json
            return
        }
    }
    transactions = []
}

func save() {
    do {
        let data = try JSONSerialization.data(withJSONObject: transactions, options: .prettyPrinted)
        try data.write(to: URL(fileURLWithPath: DATA_FILE))
    } catch {
        print("Error saving: \(error)")
    }
}

func addTransaction(type: String, category: String, amount: Double, dateStr: String?) -> Bool {
    var finalDate = dateStr ?? ""
    if finalDate.isEmpty {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        finalDate = formatter.string(from: Date())
    } else {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if formatter.date(from: finalDate) == nil {
            print("Invalid date format. Use YYYY-MM-DD.")
            return false
        }
    }
    let t: [String: Any] = [
        "type": type,
        "category": category,
        "amount": amount,
        "date": finalDate
    ]
    transactions.append(t)
    save()
    return true
}

func getBalance() -> (income: Double, expense: Double, balance: Double) {
    var income = 0.0, expense = 0.0
    for t in transactions {
        if let type = t["type"] as? String, let amount = t["amount"] as? Double {
            if type == "income" { income += amount }
            else if type == "expense" { expense += amount }
        }
    }
    return (income, expense, income - expense)
}

func categoryStats(type: String) -> [String: Double] {
    var stats: [String: Double] = [:]
    for t in transactions {
        if let ttype = t["type"] as? String, ttype == type,
           let cat = t["category"] as? String, let amount = t["amount"] as? Double {
            stats[cat, default: 0] += amount
        }
    }
    return stats
}

func printChart(type: String, width: Int = 40) {
    let stats = categoryStats(type: type)
    if stats.isEmpty {
        print("No data to chart.")
        return
    }
    let total = stats.values.reduce(0, +)
    let maxVal = stats.values.max() ?? 1.0
    print("\n\(type.capitalized) chart (by category):")
    for (cat, val) in stats.sorted(by: { $0.value > $1.value }) {
        let barLen = Int((val / maxVal) * Double(width))
        let bar = String(repeating: "█", count: barLen)
        print(String(format: "%-12s %@ %.2f", cat, bar, val))
    }
    print(String(format: "Total: %.2f", total))
}

func main() {
    load()
    print("=== Budget Tracker ===")
    while true {
        print("\n1. Add transaction")
        print("2. Show balance")
        print("3. Show category stats")
        print("4. Show expense chart")
        print("5. Save & exit")
        print("Choose: ", terminator: "")
        guard let choice = readLine()?.trimmingCharacters(in: .whitespaces) else { continue }
        switch choice {
        case "1":
            print("Type (income/expense): ", terminator: "")
            guard let type = readLine()?.trimmingCharacters(in: .whitespaces).lowercased(),
                  type == "income" || type == "expense" else {
                print("Invalid type.")
                continue
            }
            print("Category: ", terminator: "")
            guard let category = readLine()?.trimmingCharacters(in: .whitespaces), !category.isEmpty else {
                print("Invalid category.")
                continue
            }
            print("Amount: ", terminator: "")
            guard let amountStr = readLine(), let amount = Double(amountStr), amount >= 0 else {
                print("Invalid amount.")
                continue
            }
            print("Date (YYYY-MM-DD, leave blank for today): ", terminator: "")
            let dateStr = readLine()?.trimmingCharacters(in: .whitespaces) ?? ""
            if addTransaction(type: type, category: category, amount: amount, dateStr: dateStr) {
                print("Transaction added.")
            }
        case "2":
            let (income, expense, balance) = getBalance()
            print(String(format: "\nIncome: %.2f", income))
            print(String(format: "Expenses: %.2f", expense))
            print(String(format: "Balance: %.2f", balance))
        case "3":
            let stats = categoryStats(type: "expense")
            if stats.isEmpty {
                print("No expenses recorded.")
            } else {
                let total = stats.values.reduce(0, +)
                print("\nExpense categories:")
                for (cat, val) in stats.sorted(by: { $0.value > $1.value }) {
                    let pct = (val / total) * 100
                    print(String(format: "  %-12s %10.2f  (%5.1f%%)", cat, val, pct))
                }
            }
        case "4":
            printChart(type: "expense")
        case "5":
            save()
            print("Goodbye!")
            return
        default:
            print("Invalid choice.")
        }
    }
}

main()
