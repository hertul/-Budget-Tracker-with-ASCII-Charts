// BudgetTracker.java
import java.io.*;
import java.nio.file.*;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.*;
import java.util.stream.Collectors;

class Transaction {
    public String type;
    public String category;
    public double amount;
    public String date;

    public Transaction(String type, String category, double amount, String date) {
        this.type = type;
        this.category = category;
        this.amount = amount;
        this.date = date;
    }
}

public class BudgetTracker {
    private static final String DATA_FILE = "budget.json";
    private static List<Transaction> transactions = new ArrayList<>();
    private static Scanner scanner = new Scanner(System.in);

    public static void main(String[] args) {
        load();
        System.out.println("=== Budget Tracker ===");
        while (true) {
            System.out.println("\n1. Add transaction");
            System.out.println("2. Show balance");
            System.out.println("3. Show category stats");
            System.out.println("4. Show expense chart");
            System.out.println("5. Save & exit");
            System.out.print("Choose: ");
            String choice = scanner.nextLine().trim();
            switch (choice) {
                case "1":
                    addTransaction();
                    break;
                case "2":
                    showBalance();
                    break;
                case "3":
                    showCategoryStats();
                    break;
                case "4":
                    printChart("expense", 40);
                    break;
                case "5":
                    save();
                    System.out.println("Goodbye!");
                    return;
                default:
                    System.out.println("Invalid choice.");
            }
        }
    }

    @SuppressWarnings("unchecked")
    private static void load() {
        Path path = Paths.get(DATA_FILE);
        if (Files.exists(path)) {
            try {
                String json = new String(Files.readAllBytes(path));
                // manual simple JSON parsing for demonstration; in production use a library.
                // We'll use a simplistic approach: expect array of objects.
                // For brevity, we'll just use a simple parser here.
                // Alternative: use Jackson, but to keep it dependency-free, we parse manually.
                // We'll implement a tiny parser just for this demo.
                transactions = parseTransactions(json);
            } catch (IOException e) {
                transactions = new ArrayList<>();
            }
        } else {
            transactions = new ArrayList<>();
        }
    }

    // Very naive JSON parser – just for demo.
    private static List<Transaction> parseTransactions(String json) {
        List<Transaction> list = new ArrayList<>();
        // remove outer brackets and split by "},{"
        json = json.trim();
        if (json.startsWith("[")) json = json.substring(1);
        if (json.endsWith("]")) json = json.substring(0, json.length()-1);
        if (json.isEmpty()) return list;
        String[] parts = json.split("\\},\\{");
        for (String part : parts) {
            // clean braces
            part = part.replace("{", "").replace("}", "");
            String[] fields = part.split(",");
            String type = "", category = "", date = "";
            double amount = 0;
            for (String field : fields) {
                String[] kv = field.split(":");
                if (kv.length != 2) continue;
                String key = kv[0].trim().replaceAll("\"", "");
                String value = kv[1].trim().replaceAll("\"", "");
                switch (key) {
                    case "type": type = value; break;
                    case "category": category = value; break;
                    case "amount": amount = Double.parseDouble(value); break;
                    case "date": date = value; break;
                }
            }
            if (!type.isEmpty() && !category.isEmpty() && !date.isEmpty()) {
                list.add(new Transaction(type, category, amount, date));
            }
        }
        return list;
    }

    private static void save() {
        try {
            String json = toJson(transactions);
            Files.write(Paths.get(DATA_FILE), json.getBytes());
        } catch (IOException e) {
            System.out.println("Error saving: " + e.getMessage());
        }
    }

    private static String toJson(List<Transaction> list) {
        StringBuilder sb = new StringBuilder();
        sb.append("[\n");
        for (int i = 0; i < list.size(); i++) {
            Transaction t = list.get(i);
            sb.append("  {");
            sb.append("\"type\":\"").append(t.type).append("\",");
            sb.append("\"category\":\"").append(t.category).append("\",");
            sb.append("\"amount\":").append(t.amount).append(",");
            sb.append("\"date\":\"").append(t.date).append("\"");
            sb.append("}");
            if (i < list.size() - 1) sb.append(",");
            sb.append("\n");
        }
        sb.append("]");
        return sb.toString();
    }

    private static void addTransaction() {
        System.out.print("Type (income/expense): ");
        String type = scanner.nextLine().trim().toLowerCase();
        if (!type.equals("income") && !type.equals("expense")) {
            System.out.println("Invalid type.");
            return;
        }
        System.out.print("Category: ");
        String category = scanner.nextLine().trim();
        System.out.print("Amount: ");
        double amount;
        try {
            amount = Double.parseDouble(scanner.nextLine().trim());
        } catch (NumberFormatException e) {
            System.out.println("Invalid amount.");
            return;
        }
        System.out.print("Date (YYYY-MM-DD, leave blank for today): ");
        String dateStr = scanner.nextLine().trim();
        if (dateStr.isEmpty()) {
            dateStr = LocalDate.now().toString();
        } else {
            try {
                LocalDate.parse(dateStr);
            } catch (DateTimeParseException e) {
                System.out.println("Invalid date format. Use YYYY-MM-DD.");
                return;
            }
        }
        transactions.add(new Transaction(type, category, amount, dateStr));
        save();
        System.out.println("Transaction added.");
    }

    private static void showBalance() {
        double income = 0, expense = 0;
        for (Transaction t : transactions) {
            if (t.type.equals("income")) income += t.amount;
            else if (t.type.equals("expense")) expense += t.amount;
        }
        System.out.printf("\nIncome: %.2f\n", income);
        System.out.printf("Expenses: %.2f\n", expense);
        System.out.printf("Balance: %.2f\n", income - expense);
    }

    private static Map<String, Double> categoryStats(String type) {
        Map<String, Double> stats = new HashMap<>();
        for (Transaction t : transactions) {
            if (t.type.equals(type)) {
                stats.put(t.category, stats.getOrDefault(t.category, 0.0) + t.amount);
            }
        }
        return stats;
    }

    private static void showCategoryStats() {
        Map<String, Double> stats = categoryStats("expense");
        if (stats.isEmpty()) {
            System.out.println("No expenses recorded.");
            return;
        }
        double total = stats.values().stream().mapToDouble(Double::doubleValue).sum();
        System.out.println("\nExpense categories:");
        stats.entrySet().stream()
            .sorted(Map.Entry.<String, Double>comparingByValue().reversed())
            .forEach(e -> {
                double pct = (e.getValue() / total) * 100;
                System.out.printf("  %-12s %10.2f  (%5.1f%%)\n", e.getKey(), e.getValue(), pct);
            });
    }

    private static void printChart(String type, int width) {
        Map<String, Double> stats = categoryStats(type);
        if (stats.isEmpty()) {
            System.out.println("No data to chart.");
            return;
        }
        double total = stats.values().stream().mapToDouble(Double::doubleValue).sum();
        double maxVal = stats.values().stream().max(Double::compare).orElse(1.0);
        System.out.printf("\n%s chart (by category):\n", type.substring(0,1).toUpperCase() + type.substring(1));
        stats.entrySet().stream()
            .sorted(Map.Entry.<String, Double>comparingByValue().reversed())
            .forEach(e -> {
                int barLen = (int)((e.getValue() / maxVal) * width);
                String bar = "█".repeat(Math.max(0, barLen));
                System.out.printf("%-12s %s %.2f\n", e.getKey(), bar, e.getValue());
            });
        System.out.printf("Total: %.2f\n", total);
    }
}
