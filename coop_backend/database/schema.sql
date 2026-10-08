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

INSERT INTO members (member_id, first_name, last_name, email, phone, address) VALUES
('M-001', 'Juan', 'dela Cruz', 'juan@example.com', '09171234567', '123 Main St, Manila'),
('M-002', 'Rosa', 'Mendoza', 'rosa@example.com', '09181234567', '456 Oak Ave, Quezon City'),
('M-003', 'Carlo', 'Reyes', 'carlo@example.com', '09191234567', '789 Pine Rd, Makati'),
('M-004', 'Ana', 'Torres', 'ana@example.com', '09201234567', '321 Elm St, Pasig'),
('M-005', 'Pedro', 'Santos', 'pedro@example.com', '09211234567', '654 Maple Dr, Taguig')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;

INSERT INTO loan_applications (application_id, member_id, member_name, loan_type, amount, purpose, status, income, credit_score, date_submitted) VALUES
('LA-2025-0089', 1, 'Juan dela Cruz', 'Regular', 75000.00, 'Business expansion', 'pending', 120000, 750, '2025-07-25'),
('LA-2025-0088', 2, 'Rosa Mendoza', 'Medical', 30000.00, 'Medical emergency', 'under review', 95000, 720, '2025-07-24'),
('LA-2025-0087', 3, 'Carlo Reyes', 'Educational', 50000.00, 'Tuition fee payment', 'approved', 150000, 780, '2025-07-23'),
('LA-2025-0086', 4, 'Ana Torres', 'Emergency', 20000.00, 'Personal emergency', 'rejected', 60000, 650, '2025-07-22'),
('LA-2025-0085', 5, 'Pedro Santos', 'Regular', 80000.00, 'Home renovation', 'released', 180000, 800, '2025-07-21')
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;
