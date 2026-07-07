// BudgetTracker.cs
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;

class Transaction
{
    public string Type { get; set; }
    public string Category { get; set; }
    public double Amount { get; set; }
    public string Date { get; set; }
}

class BudgetTracker
{
    private const string DataFile = "budget.json";
    private static List<Transaction> transactions = new List<Transaction>();

    static void Main()
    {
        Load();
        Console.WriteLine("=== Budget Tracker ===");
        while (true)
        {
            Console.WriteLine("\n1. Add transaction");
            Console.WriteLine("2. Show balance");
            Console.WriteLine("3. Show category stats");
            Console.WriteLine("4. Show expense chart");
            Console.WriteLine("5. Save & exit");
            Console.Write("Choose: ");
            string choice = Console.ReadLine()?.Trim() ?? "";
            switch (choice)
            {
                case "1":
                    AddTransaction();
                    break;
                case "2":
                    ShowBalance();
                    break;
                case "3":
                    ShowCategoryStats();
                    break;
                case "4":
                    PrintChart("expense", 40);
                    break;
                case "5":
                    Save();
                    Console.WriteLine("Goodbye!");
                    return;
                default:
                    Console.WriteLine("Invalid choice.");
                    break;
            }
        }
    }

    static void Load()
    {
        if (File.Exists(DataFile))
        {
            string json = File.ReadAllText(DataFile);
            transactions = JsonSerializer.Deserialize<List<Transaction>>(json) ?? new List<Transaction>();
        }
        else
        {
            transactions = new List<Transaction>();
        }
    }

    static void Save()
    {
        string json = JsonSerializer.Serialize(transactions, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(DataFile, json);
    }

    static void AddTransaction()
    {
        Console.Write("Type (income/expense): ");
        string type = Console.ReadLine()?.Trim().ToLower() ?? "";
        if (type != "income" && type != "expense")
        {
            Console.WriteLine("Invalid type.");
            return;
        }
        Console.Write("Category: ");
        string category = Console.ReadLine()?.Trim() ?? "";
        Console.Write("Amount: ");
        if (!double.TryParse(Console.ReadLine(), out double amount) || amount < 0)
        {
            Console.WriteLine("Invalid amount.");
            return;
        }
        Console.Write("Date (YYYY-MM-DD, leave blank for today): ");
        string dateStr = Console.ReadLine()?.Trim() ?? "";
        if (string.IsNullOrEmpty(dateStr))
            dateStr = DateTime.Today.ToString("yyyy-MM-dd");
        else
        {
            if (!DateTime.TryParseExact(dateStr, "yyyy-MM-dd", null, System.Globalization.DateTimeStyles.None, out _))
            {
                Console.WriteLine("Invalid date format. Use YYYY-MM-DD.");
                return;
            }
        }
        transactions.Add(new Transaction { Type = type, Category = category, Amount = amount, Date = dateStr });
        Save();
        Console.WriteLine("Transaction added.");
    }

    static void ShowBalance()
    {
        double income = 0, expense = 0;
        foreach (var t in transactions)
        {
            if (t.Type == "income") income += t.Amount;
            else if (t.Type == "expense") expense += t.Amount;
        }
        Console.WriteLine($"\nIncome: {income:F2}");
        Console.WriteLine($"Expenses: {expense:F2}");
        Console.WriteLine($"Balance: {(income - expense):F2}");
    }

    static Dictionary<string, double> CategoryStats(string type)
    {
        var stats = new Dictionary<string, double>();
        foreach (var t in transactions)
        {
            if (t.Type == type)
            {
                if (!stats.ContainsKey(t.Category))
                    stats[t.Category] = 0;
                stats[t.Category] += t.Amount;
            }
        }
        return stats;
    }

    static void ShowCategoryStats()
    {
        var stats = CategoryStats("expense");
        if (stats.Count == 0)
        {
            Console.WriteLine("No expenses recorded.");
            return;
        }
        double total = stats.Values.Sum();
        Console.WriteLine("\nExpense categories:");
        foreach (var kv in stats.OrderByDescending(x => x.Value))
        {
            double pct = (kv.Value / total) * 100;
            Console.WriteLine($"  {kv.Key,-12} {kv.Value,10:F2}  ({pct,5:F1}%)");
        }
    }

    static void PrintChart(string type, int width)
    {
        var stats = CategoryStats(type);
        if (stats.Count == 0)
        {
            Console.WriteLine("No data to chart.");
            return;
        }
        double total = stats.Values.Sum();
        double maxVal = stats.Values.Max();
        Console.WriteLine($"\n{char.ToUpper(type[0]) + type.Substring(1)} chart (by category):");
        foreach (var kv in stats.OrderByDescending(x => x.Value))
        {
            int barLen = (int)((kv.Value / maxVal) * width);
            string bar = new string('█', barLen);
            Console.WriteLine($"{kv.Key,-12} {bar} {kv.Value:F2}");
        }
        Console.WriteLine($"Total: {total:F2}");
    }
}
