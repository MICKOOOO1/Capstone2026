CREATE DATABASE IF NOT EXISTS coop_db;
USE coop_db;

CREATE TABLE IF NOT EXISTS members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  member_id VARCHAR(50) UNIQUE NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL DEFAULT '',
  email VARCHAR(100) UNIQUE,
  phone VARCHAR(20),
  address TEXT,
  membership_type ENUM('regular', 'associate') NULL DEFAULT NULL,
  date_joined DATE,
  status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS loan_applications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  application_id VARCHAR(50) UNIQUE NOT NULL,
  member_id INT NOT NULL,
  member_name VARCHAR(200) NOT NULL,
  loan_type ENUM('Regular', 'Medical', 'Educational', 'Emergency', 'Business') NOT NULL DEFAULT 'Regular',
  amount DECIMAL(15, 2) NOT NULL,
  purpose TEXT,
  status ENUM('pending', 'under review', 'approved', 'rejected', 'released', 'completed', 'overdue') DEFAULT 'pending',
  income DECIMAL(15, 2),
  credit_score INT,
  date_submitted DATE NOT NULL,
  date_approved DATE,
  date_released DATE,
  date_completed DATE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_loan_applications_member FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS loan_payments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  loan_application_id INT NOT NULL,
  payment_amount DECIMAL(15, 2) NOT NULL,
  payment_date DATE NOT NULL,
  payment_method ENUM('cash', 'bank_transfer', 'check', 'automatic') DEFAULT 'cash',
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_loan_payments_application FOREIGN KEY (loan_application_id) REFERENCES loan_applications(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS savings_accounts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  member_id INT NOT NULL,
  account_number VARCHAR(50) UNIQUE NOT NULL,
  balance DECIMAL(15, 2) DEFAULT 0.00,
  account_type ENUM('regular', 'special', 'time_deposit') DEFAULT 'regular',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_savings_accounts_member FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE
);
