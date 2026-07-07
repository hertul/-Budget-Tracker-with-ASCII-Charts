# budget_tracker.rb
require 'json'
require 'date'

DATA_FILE = 'budget.json'

$transactions = []

def load
  if File.exist?(DATA_FILE)
    begin
      data = File.read(DATA_FILE)
      $transactions = JSON.parse(data)
    rescue
      $transactions = []
    end
  else
    $transactions = []
  end
end

def save
  File.write(DATA_FILE, JSON.pretty_generate($transactions))
end

def add_transaction(type, category, amount, date_str)
  if date_str.nil? || date_str.strip.empty?
    date_str = Date.today.iso8601
  else
    begin
      Date.parse(date_str)
    rescue ArgumentError
      puts "Invalid date format. Use YYYY-MM-DD."
      return false
    end
  end
  $transactions << {
    "type" => type,
    "category" => category,
    "amount" => amount.to_f,
    "date" => date_str
  }
  save
  true
end

def get_balance
  income = $transactions.select { |t| t["type"] == "income" }.sum { |t| t["amount"] }
  expense = $transactions.select { |t| t["type"] == "expense" }.sum { |t| t["amount"] }
  [income, expense, income - expense]
end

def category_stats(type)
  stats = Hash.new(0)
  $transactions.each do |t|
    if t["type"] == type
      stats[t["category"]] += t["amount"]
    end
  end
  stats
end

def print_chart(type, width=40)
  stats = category_stats(type)
  if stats.empty?
    puts "No data to chart."
    return
  end
  total = stats.values.sum
  max_val = stats.values.max
  puts "\n#{type.capitalize} chart (by category):"
  stats.sort_by { |_, v| -v }.each do |cat, val|
    bar_len = ((val / max_val) * width).to_i
    bar = '█' * bar_len
    puts "#{cat.ljust(12)} #{bar} #{'%.2f' % val}"
  end
  puts "Total: #{'%.2f' % total}"
end

def main
  load
  puts "=== Budget Tracker ==="
  loop do
    puts "\n1. Add transaction"
    puts "2. Show balance"
    puts "3. Show category stats"
    puts "4. Show expense chart"
    puts "5. Save & exit"
    print "Choose: "
    choice = gets.chomp.strip
    case choice
    when "1"
      print "Type (income/expense): "
      type = gets.chomp.strip.downcase
      unless ["income", "expense"].include?(type)
        puts "Invalid type."
        next
      end
      print "Category: "
      category = gets.chomp.strip
      print "Amount: "
      amount = gets.chomp.strip.to_f
      if amount <= 0
        puts "Invalid amount."
        next
      end
      print "Date (YYYY-MM-DD, leave blank for today): "
      date_str = gets.chomp.strip
      if add_transaction(type, category, amount, date_str)
        puts "Transaction added."
      end
    when "2"
      income, expense, balance = get_balance
      puts "\nIncome: #{'%.2f' % income}"
      puts "Expenses: #{'%.2f' % expense}"
      puts "Balance: #{'%.2f' % balance}"
    when "3"
      stats = category_stats("expense")
      if stats.empty?
        puts "No expenses recorded."
      else
        total = stats.values.sum
        puts "\nExpense categories:"
        stats.sort_by { |_, v| -v }.each do |cat, val|
          pct = (val / total * 100)
          puts "  #{cat.ljust(12)} #{val.to_s.rjust(10)}  (#{'%.1f' % pct}%)"
        end
      end
    when "4"
      print_chart("expense")
    when "5"
      save
      puts "Goodbye!"
      break
    else
      puts "Invalid choice."
    end
  end
end

main if __FILE__ == $0
