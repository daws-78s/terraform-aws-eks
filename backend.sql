CREATE DATABASE IF NOT EXISTS transactions;
USE transactions;

CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    amount INT,
    description VARCHAR(255)
);

CREATE USER IF NOT EXISTS 'expense'@'%' IDENTIFIED BY 'ExpenseApp@1';
GRANT ALL ON transactions.* TO 'expense'@'%';
FLUSH PRIVILEGES;

