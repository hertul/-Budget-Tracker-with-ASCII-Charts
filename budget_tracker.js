// budget_tracker.js
const fs = require('fs');
const readline = require('readline');

const DATA_FILE = 'budget.json';
let transactions = [];

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function ask(question) {
    return new Promise(resolve => rl.question(question, resolve));
}

function load() {
    try {
        if (fs.existsSync(DATA_FILE)) {
            const data = fs.readFileSync(DATA_FILE, 'utf8');
            transactions = JSON.parse(data);
        } else {
            transactions = [];
        }
    } catch (e) {
        transactions = [];
    }
}

function save() {
    fs.writeFileSync(DATA_FILE, JSON.stringify(transactions, null, 2));
}

function addTransaction(type, category, amount, dateStr) {
    if (!dateStr || dateStr.trim() === '') {
        dateStr = new Date().toISOString().slice(0, 10);
    } else {
        // validate date format
        if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
            console.log('Invalid date format. Use YYYY-MM-DD.');
            return false;
        }
    }
    transactions.push({
        type: type,
        category: category,
        amount: parseFloat(amount),
        date: dateStr
    });
    save();
    return true;
}

function getBalance() {
    let income = 0, expense = 0;
    for (const t of transactions) {
        if (t.type === 'income') income += t.amount;
        else if (t.type === 'expense') expense += t.amount;
    }
    return { income, expense, balance: income - expense };
}

function categoryStats(type) {
    const stats = {};
    for (const t of transactions) {
        if (t.type === type) {
            if (!stats[t.category]) stats[t.category] = 0;
            stats[t.category] += t.amount;
        }
    }
    return stats;
}

function printChart(type, width = 40) {
    const stats = categoryStats(type);
    const keys = Object.keys(stats);
    if (keys.length === 0) {
        console.log('No data to chart.');
        return;
    }
    let total = 0, maxVal = 0;
    for (const k of keys) {
        total += stats[k];
        if (stats[k] > maxVal) maxVal = stats[k];
    }
    console.log(`\n${type.charAt(0).toUpperCase() + type.slice(1)} chart (by category):`);
    for (const cat of keys.sort((a, b) => stats[b] - stats[a])) {
        const barLen = Math.round((stats[cat] / maxVal) * width);
        const bar = '█'.repeat(barLen);
        console.log(`${cat.padEnd(12)} ${bar} ${stats[cat].toFixed(2)}`);
    }
    console.log(`Total: ${total.toFixed(2)}`);
}

async function main() {
    load();
    console.log('=== Budget Tracker ===');
    while (true) {
        console.log('\n1. Add transaction');
        console.log('2. Show balance');
        console.log('3. Show category stats');
        console.log('4. Show expense chart');
        console.log('5. Save & exit');
        const choice = await ask('Choose: ');
        switch (choice.trim()) {
            case '1': {
                const type = (await ask('Type (income/expense): ')).trim().toLowerCase();
                if (!['income', 'expense'].includes(type)) {
                    console.log('Invalid type.');
                    break;
                }
                const category = (await ask('Category: ')).trim();
                const amountStr = await ask('Amount: ');
                const amount = parseFloat(amountStr);
                if (isNaN(amount) || amount < 0) {
                    console.log('Invalid amount.');
                    break;
                }
                const dateStr = (await ask('Date (YYYY-MM-DD, leave blank for today): ')).trim();
                if (addTransaction(type, category, amount, dateStr)) {
                    console.log('Transaction added.');
                }
                break;
            }
            case '2': {
                const { income, expense, balance } = getBalance();
                console.log(`\nIncome: ${income.toFixed(2)}`);
                console.log(`Expenses: ${expense.toFixed(2)}`);
                console.log(`Balance: ${balance.toFixed(2)}`);
                break;
            }
            case '3': {
                const stats = categoryStats('expense');
                const keys = Object.keys(stats);
                if (keys.length === 0) {
                    console.log('No expenses recorded.');
                } else {
                    let total = 0;
                    for (const k of keys) total += stats[k];
                    console.log('\nExpense categories:');
                    for (const cat of keys.sort((a, b) => stats[b] - stats[a])) {
                        const pct = (stats[cat] / total * 100);
                        console.log(`  ${cat.padEnd(12)} ${stats[cat].toFixed(2).padStart(10)}  (${pct.toFixed(1)}%)`);
                    }
                }
                break;
            }
            case '4':
                printChart('expense');
                break;
            case '5':
                save();
                console.log('Goodbye!');
                rl.close();
                return;
            default:
                console.log('Invalid choice.');
        }
    }
}

main().catch(console.error);
