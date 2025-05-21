CREATE DATABASE worship_db;
USE worship_db;

-- Kullanıcılar tablosu
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    password VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Kaçırılan namazlar tablosu
CREATE TABLE IF NOT EXISTS missed_prayers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255),
    prayer_name VARCHAR(50),
    date DATE,
    completed BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Oruç (fasting) tablosu
CREATE TABLE IF NOT EXISTS fasting (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255),
    date DATE,
    completed BOOLEAN DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Kuran okuma tablosu
CREATE TABLE IF NOT EXISTS quran_reading (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    pages_read INT DEFAULT 0,
    daily_goal INT DEFAULT 1,
    UNIQUE KEY unique_reading (email, date)
);

-- Kuran günlük hedef tablosu
DROP TABLE IF EXISTS quran_goal;
CREATE TABLE IF NOT EXISTS quran_goal (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    daily_goal INT DEFAULT 1,
    UNIQUE KEY unique_goal (email, date)
);

SELECT * FROM users;
SELECT * FROM missed_prayers;
SELECT * FROM fasting;
SELECT * FROM quran_reading;
SELECT * FROM quran_goal;
