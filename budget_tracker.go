// budget_tracker.go
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

const dataFile = "budget.json"

type Transaction struct {
	Type     string  `json:"type"`
	Category string  `json:"category"`
	Amount   float64 `json:"amount"`
	Date     string  `json:"date"`
}

var transactions []Transaction

func load() {
	file, err := os.ReadFile(dataFile)
	if err != nil {
		transactions = []Transaction{}
		return
	}
	if err := json.Unmarshal(file, &transactions); err != nil {
		transactions = []Transaction{}
	}
}

func save() error {
	data, err := json.MarshalIndent(transactions, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(dataFile, data, 0644)
}

func addTransaction(ttype, category string, amount float64, dateStr string) bool {
	if dateStr == "" {
		dateStr = time.Now().Format("2006-01-02")
	} else {
		// validate format
		_, err := time.Parse("2006-01-02", dateStr)
		if err != nil {
			fmt.Println("Invalid date format. Use YYYY-MM-DD.")
			return false
		}
	}
	transactions = append(transactions, Transaction{
		Type:     ttype,
		Category: category,
		Amount:   amount,
		Date:     dateStr,
	})
	if err := save(); err != nil {
		fmt.Println("Error saving:", err)
		return false
	}
	return true
}

func getBalance() (income, expense, balance float64) {
	for _, t := range transactions {
		if t.Type == "income" {
			income += t.Amount
		} else if t.Type == "expense" {
			expense += t.Amount
		}
	}
	balance = income - expense
	return
}

func categoryStats(ttype string) map[string]float64 {
	stats := make(map[string]float64)
	for _, t := range transactions {
		if t.Type == ttype {
			stats[t.Category] += t.Amount
		}
	}
	return stats
}

func printChart(ttype string, width int) {
	stats := categoryStats(ttype)
	if len(stats) == 0 {
		fmt.Println("No data to chart.")
		return
	}
	var total float64
	maxVal := 0.0
	for _, v := range stats {
		total += v
		if v > maxVal {
			maxVal = v
		}
	}
	fmt.Printf("\n%s chart (by category):\n", strings.Title(ttype))
	for cat, val := range stats {
		barLen := int((val / maxVal) * float64(width))
		bar := strings.Repeat("█", barLen)
		fmt.Printf("%-12s %s %.2f\n", cat, bar, val)
	}
	fmt.Printf("Total: %.2f\n", total)
}

func main() {
	load()
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("=== Budget Tracker ===")
	for {
		fmt.Println("\n1. Add transaction")
		fmt.Println("2. Show balance")
		fmt.Println("3. Show category stats")
		fmt.Println("4. Show expense chart")
		fmt.Println("5. Save & exit")
		fmt.Print("Choose: ")
		scanner.Scan()
		choice := strings.TrimSpace(scanner.Text())
		switch choice {
		case "1":
			fmt.Print("Type (income/expense): ")
			scanner.Scan()
			ttype := strings.ToLower(strings.TrimSpace(scanner.Text()))
			if ttype != "income" && ttype != "expense" {
				fmt.Println("Invalid type.")
				continue
			}
			fmt.Print("Category: ")
			scanner.Scan()
			category := strings.TrimSpace(scanner.Text())
			fmt.Print("Amount: ")
			scanner.Scan()
			amount, err := strconv.ParseFloat(strings.TrimSpace(scanner.Text()), 64)
			if err != nil {
				fmt.Println("Invalid amount.")
				continue
			}
			fmt.Print("Date (YYYY-MM-DD, leave blank for today): ")
			scanner.Scan()
			dateStr := strings.TrimSpace(scanner.Text())
			if addTransaction(ttype, category, amount, dateStr) {
				fmt.Println("Transaction added.")
			}
		case "2":
			inc, exp, bal := getBalance()
			fmt.Printf("\nIncome: %.2f\n", inc)
			fmt.Printf("Expenses: %.2f\n", exp)
			fmt.Printf("Balance: %.2f\n", bal)
		case "3":
			stats := categoryStats("expense")
			if len(stats) == 0 {
				fmt.Println("No expenses recorded.")
			} else {
				var total float64
				for _, v := range stats {
					total += v
				}
				fmt.Println("\nExpense categories:")
				for cat, val := range stats {
					pct := (val / total * 100)
					fmt.Printf("  %-12s %10.2f  (%5.1f%%)\n", cat, val, pct)
				}
			}
		case "4":
			printChart("expense", 40)
		case "5":
			if err := save(); err != nil {
				fmt.Println("Error saving:", err)
			} else {
				fmt.Println("Goodbye!")
			}
			return
		default:
			fmt.Println("Invalid choice.")
		}
	}
}
