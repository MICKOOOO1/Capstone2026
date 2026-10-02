-- CSUCC Cooperative Database Schema
-- Created for coop_frontend and coop_frontend_admin

USE coop_db;

-- Users/Members Table
CREATE TABLE IF NOT EXISTS members (
    id INT AUTO_INCREMENT PRIMARY KEY,
    member_id VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birthdate DATE,
    mobile VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    department VARCHAR(100),
    address TEXT,
    membership_status ENUM('active', 'inactive', 'pending') DEFAULT 'pending',
    pin_hash VARCHAR(255),
    biometric_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Cooperative Equity Table
CREATE TABLE IF NOT EXISTS cooperative_equity (
    id INT AUTO_INCREMENT PRIMARY KEY,
    member_id VARCHAR(50) NOT NULL,
    share_capital DECIMAL(15, 2) DEFAULT 0.00,
    locked_investment DECIMAL(15, 2) DEFAULT 0.00,
    savings_balance DECIMAL(15, 2) DEFAULT 0.00,
    withdrawable DECIMAL(15, 2) DEFAULT 0.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Loan Types Table
CREATE TABLE IF NOT EXISTS loan_types (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    interest_rate DECIMAL(5, 2) NOT NULL,
    max_amount DECIMAL(15, 2),
    min_amount DECIMAL(15, 2),
    max_tenure_months INT,
    min_tenure_months INT,
    requirements TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Loan Applications Table
CREATE TABLE IF NOT EXISTS loan_applications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    member_id VARCHAR(50) NOT NULL,
    loan_type_id INT NOT NULL,
    application_number VARCHAR(50) UNIQUE NOT NULL,
    principal_amount DECIMAL(15, 2) NOT NULL,
    tenure_months INT NOT NULL,
    monthly_payment DECIMAL(15, 2) NOT NULL,
    purpose TEXT,
    status ENUM('pending', 'approved', 'rejected', 'disbursed') DEFAULT 'pending',
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    reviewed_by INT NULL,
    rejection_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (loan_type_id) REFERENCES loan_types(id)
);

-- Loans Table
CREATE TABLE IF NOT EXISTS loans (
    id INT AUTO_INCREMENT PRIMARY KEY,
    loan_application_id INT NOT NULL,
    member_id VARCHAR(50) NOT NULL,
    loan_number VARCHAR(50) UNIQUE NOT NULL,
    loan_type VARCHAR(100) NOT NULL,
    principal_amount DECIMAL(15, 2) NOT NULL,
    outstanding_balance DECIMAL(15, 2) NOT NULL,
    monthly_payment DECIMAL(15, 2) NOT NULL,
    tenure_months INT NOT NULL,
    months_paid INT DEFAULT 0,
    next_due_date DATE,
    status ENUM('active', 'fully_paid', 'defaulted') DEFAULT 'active',
    disbursed_at TIMESTAMP NULL,
    fully_paid_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_application_id) REFERENCES loan_applications(id),
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Loan Payments Table
CREATE TABLE IF NOT EXISTS loan_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT NOT NULL,
    member_id VARCHAR(50) NOT NULL,
    payment_amount DECIMAL(15, 2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(50),
    reference_number VARCHAR(100),
    months_covered INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Transaction History Table
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    member_id VARCHAR(50) NOT NULL,
    transaction_type ENUM('loan_payment', 'loan_disbursement', 'deposit', 'withdrawal', 'contribution') NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    description TEXT,
    reference_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Documents Table
CREATE TABLE IF NOT EXISTS documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    member_id VARCHAR(50) NOT NULL,
    loan_application_id INT NULL,
    document_type VARCHAR(100) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size INT,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (loan_application_id) REFERENCES loan_applications(id) ON DELETE SET NULL
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    member_id VARCHAR(50) NOT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('info', 'success', 'warning', 'error') DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- Announcements Table
CREATE TABLE IF NOT EXISTS announcements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    author_id INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Audit Logs Table
CREATE TABLE IF NOT EXISTS audit_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INT NOT NULL,
    old_values JSON NULL,
    new_values JSON NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin Users Table
CREATE TABLE IF NOT EXISTS admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role ENUM('super_admin', 'admin', 'staff') DEFAULT 'staff',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Settings Table
CREATE TABLE IF NOT EXISTS settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    key_name VARCHAR(100) UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default settings
INSERT INTO settings (key_name, value, description) VALUES
('coop_name', 'CSUCC Multipurpose Cooperative', 'Cooperative name'),
('coop_address', 'Caraga State University - Cabadbaran Campus', 'Cooperative address'),
('coop_contact', '+63 917 456 7890', 'Cooperative contact number'),
('coop_email', 'info@csucc.edu.ph', 'Cooperative email address'),
('interest_rate_default', '12.00', 'Default interest rate for loans'),
('max_loan_amount', '500000.00', 'Maximum loan amount'),
('min_share_capital', '1000.00', 'Minimum share capital requirement')
ON DUPLICATE KEY UPDATE value = VALUES(value);

-- Insert default loan types
INSERT INTO loan_types (name, description, interest_rate, max_amount, min_amount, max_tenure_months, min_tenure_months) VALUES
('Regular Loan', 'Standard loan for various purposes', 12.00, 500000.00, 5000.00, 36, 3),
('Emergency Loan', 'For emergency situations', 10.00, 100000.00, 1000.00, 12, 1),
('Educational Loan', 'For educational expenses', 8.00, 200000.00, 5000.00, 24, 6),
('Quick Loan', 'Fast approval for small amounts', 15.00, 50000.00, 1000.00, 6, 1),
('ASSME Loan', 'ASSME-backed program loan', 6.00, 300000.00, 10000.00, 24, 6)
ON DUPLICATE KEY UPDATE updated_at = CURRENT_TIMESTAMP;
