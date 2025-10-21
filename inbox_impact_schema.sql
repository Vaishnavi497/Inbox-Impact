-- 1️⃣ Create and use database
DROP DATABASE IF EXISTS inbox_impact;
CREATE DATABASE inbox_impact;
USE inbox_impact;

-- ======================================================
-- 2️⃣ USERS TABLE
-- ======================================================
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(150),
    role ENUM('USER','ADMIN') DEFAULT 'USER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ======================================================
-- 3️⃣ EMAIL DATA TABLE
-- ======================================================
CREATE TABLE email_data (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    email_count INT NOT NULL,
    avg_size_mb DOUBLE NOT NULL,
    total_size_mb DOUBLE NOT NULL,
    co2_grams DOUBLE NOT NULL,
    record_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ======================================================
-- 4️⃣ TIPS TABLE
-- ======================================================
CREATE TABLE tips (
    tip_id INT AUTO_INCREMENT PRIMARY KEY,
    tip_text VARCHAR(500) NOT NULL,
    active BOOLEAN DEFAULT TRUE
);

-- ======================================================
-- 5️⃣ SAMPLE DATA
-- ======================================================
INSERT INTO users (username, password, full_name, role) VALUES
('admin', 'admin123', 'System Admin', 'ADMIN'),
('vaishnavi', 'v1234', 'Vaishnavi S', 'USER');

INSERT INTO tips (tip_text, active) VALUES
('Compress attachments before sending.', TRUE),
('Delete old emails and large attachments regularly.', TRUE),
('Use links instead of attachments for large files.', TRUE),
('Unsubscribe from unwanted newsletters.', TRUE);

-- ======================================================
-- 6️⃣ STORED PROCEDURE: Add email record
-- ======================================================
DELIMITER $$
CREATE PROCEDURE add_email_record(
    IN p_user_id INT,
    IN p_email_count INT,
    IN p_avg_size_mb DOUBLE,
    IN p_record_date DATE
)
BEGIN
    DECLARE v_total_mb DOUBLE;
    DECLARE v_co2 DOUBLE;

    SET v_total_mb = p_email_count * p_avg_size_mb;
    SET v_co2 = v_total_mb * 4.0; -- 4g CO2 per MB

    INSERT INTO email_data (user_id, email_count, avg_size_mb, total_size_mb, co2_grams, record_date)
    VALUES (p_user_id, p_email_count, p_avg_size_mb, v_total_mb, v_co2, p_record_date);

    SELECT LAST_INSERT_ID() AS inserted_id, v_total_mb AS total_size_mb, v_co2 AS co2_grams;
END $$
DELIMITER ;

-- ======================================================
-- 7️⃣ VIEWS
-- ======================================================

-- Daily emission per user
CREATE OR REPLACE VIEW vw_daily_emission AS
SELECT 
    user_id, 
    record_date, 
    SUM(co2_grams) AS daily_co2_grams
FROM email_data
GROUP BY user_id, record_date;

-- Monthly emission per user (safe alias)
CREATE OR REPLACE VIEW vw_monthly_emission AS
SELECT 
    user_id,
    DATE_FORMAT(record_date, '%Y-%m') AS formatted_month,
    SUM(co2_grams) AS monthly_co2_grams
FROM email_data
GROUP BY 
    user_id,
    DATE_FORMAT(record_date, '%Y-%m');

-- ======================================================
-- 8️⃣ CREATE FRONTEND APP USER (for Java or GUI)
-- ======================================================
CREATE USER IF NOT EXISTS 'appuser'@'localhost' IDENTIFIED BY 'app_pass';
GRANT SELECT, INSERT, UPDATE, DELETE ON inbox_impact.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;

-- ======================================================
-- ✅ 9️⃣ TEST SECTION (optional, safe to run)
-- ======================================================
-- Call the procedure for testing
CALL add_email_record(2, 30, 1.0, CURDATE());

-- Check results
SELECT * FROM email_data;
SELECT * FROM vw_daily_emission;
SELECT * FROM vw_monthly_emission;
SELECT * FROM tips;
