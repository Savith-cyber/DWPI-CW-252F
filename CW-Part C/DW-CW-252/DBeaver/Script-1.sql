-- Clean up any partial tables
DROP TABLE IF EXISTS fact_appointment;
DROP TABLE IF EXISTS dim_patient;
DROP TABLE IF EXISTS dim_doctor;
DROP TABLE IF EXISTS dim_clinic;
DROP TABLE IF EXISTS dim_date;

-- 1. Create Dimension Tables
CREATE TABLE dim_patient (
    patient_sk SERIAL PRIMARY KEY,
    patient_id VARCHAR(50),
    gender VARCHAR(10),
    dob DATE,
    district VARCHAR(100)
);

CREATE TABLE dim_doctor (
    doctor_sk SERIAL PRIMARY KEY,
    doctor_id VARCHAR(50),
    doctor_name VARCHAR(100),
    specialty VARCHAR(100)
);

CREATE TABLE dim_clinic (
    clinic_sk SERIAL PRIMARY KEY,
    clinic_id VARCHAR(50),
    clinic_name VARCHAR(100),
    city VARCHAR(100),
    province VARCHAR(100)
);

-- 2. Create and Populate Date Dimension (2025)
CREATE TABLE dim_date (
    date_sk INT PRIMARY KEY,
    full_date DATE,
    year INT,
    quarter INT,
    month INT,
    day_name VARCHAR(20)
);

INSERT INTO dim_date (date_sk, full_date, year, quarter, month, day_name)
SELECT 
    TO_CHAR(datum, 'YYYYMMDD')::INT AS date_sk,
    datum AS full_date,
    EXTRACT(YEAR FROM datum) AS year,
    EXTRACT(QUARTER FROM datum) AS quarter,
    EXTRACT(MONTH FROM datum) AS month,
    TRIM(TO_CHAR(datum, 'Day')) AS day_name
FROM (
    SELECT generate_series('2025-01-01'::DATE, '2025-12-31'::DATE, '1 day'::INTERVAL) AS datum
) dates;

-- 3. Create Fact Table
CREATE TABLE fact_appointment (
    patient_sk INT REFERENCES dim_patient(patient_sk),
    doctor_sk INT REFERENCES dim_doctor(doctor_sk),
    clinic_sk INT REFERENCES dim_clinic(clinic_sk),
    date_sk INT REFERENCES dim_date(date_sk),
    wait_minutes INT,
    consultation_minutes INT,
    fee_lkr NUMERIC(10,2)
);


1. Row Count Verification Query
SELECT 'dim_patient' AS table_name, COUNT(*) AS row_count FROM dim_patient
UNION ALL
SELECT 'dim_doctor', COUNT(*) FROM dim_doctor
UNION ALL
SELECT 'dim_clinic', COUNT(*) FROM dim_clinic
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dim_date
UNION ALL
SELECT 'fact_appointment', COUNT(*) FROM fact_appointment;


2. Orphan Foreign Key Verification Query
SELECT 
    (SELECT COUNT(*) FROM fact_appointment f LEFT JOIN dim_patient p ON f.patient_sk = p.patient_sk WHERE p.patient_sk IS NULL) AS orphan_patients,
    (SELECT COUNT(*) FROM fact_appointment f LEFT JOIN dim_doctor d ON f.doctor_sk = d.doctor_sk WHERE d.doctor_sk IS NULL) AS orphan_doctors,
    (SELECT COUNT(*) FROM fact_appointment f LEFT JOIN dim_clinic c ON f.clinic_sk = c.clinic_sk WHERE c.clinic_sk IS NULL) AS orphan_clinics,
    (SELECT COUNT(*) FROM fact_appointment f LEFT JOIN dim_date dt ON f.date_sk = dt.date_sk WHERE dt.date_sk IS NULL) AS orphan_dates;





SELECT 
    c.clinic_name, 
    COUNT(f.patient_sk) AS total_appointments, 
    SUM(f.fee_lkr) AS total_revenue 
FROM fact_appointment f 
JOIN dim_clinic c ON f.clinic_sk = c.clinic_sk 
WHERE c.clinic_id = 'C01' 
GROUP BY c.clinic_name;



SELECT 
    c.province, 
    p.gender, 
    COUNT(f.patient_sk) AS total_visits, 
    SUM(f.fee_lkr) AS total_revenue 
FROM fact_appointment f 
JOIN dim_clinic c ON f.clinic_sk = c.clinic_sk 
JOIN dim_patient p ON f.patient_sk = p.patient_sk 
WHERE c.province = 'Western' AND p.gender = 'F' 
GROUP BY c.province, p.gender;



SELECT 
    d.specialty, 
    d.doctor_name, 
    SUM(f.fee_lkr) AS total_revenue 
FROM fact_appointment f 
JOIN dim_doctor d ON f.doctor_sk = d.doctor_sk 
GROUP BY ROLLUP (d.specialty, d.doctor_name) 
ORDER BY d.specialty, d.doctor_name;





SELECT 
    dt.quarter, 
    SUM(f.fee_lkr) AS total_revenue 
FROM fact_appointment f 
JOIN dim_date dt ON f.date_sk = dt.date_sk 
GROUP BY dt.quarter 
ORDER BY dt.quarter;

//SQL Query 2 (Drill down into Q1):


SELECT 
    dt.quarter, 
    dt.month, 
    SUM(f.fee_lkr) AS total_revenue 
FROM fact_appointment f 
JOIN dim_date dt ON f.date_sk = dt.date_sk 
WHERE dt.quarter = 1 
GROUP BY dt.quarter, dt.month 
ORDER BY dt.month;




SELECT 
    c.clinic_name,
    SUM(CASE WHEN dt.quarter = 1 THEN f.fee_lkr ELSE 0 END) AS Q1_Revenue,
    SUM(CASE WHEN dt.quarter = 2 THEN f.fee_lkr ELSE 0 END) AS Q2_Revenue,
    SUM(CASE WHEN dt.quarter = 3 THEN f.fee_lkr ELSE 0 END) AS Q3_Revenue,
    SUM(CASE WHEN dt.quarter = 4 THEN f.fee_lkr ELSE 0 END) AS Q4_Revenue
FROM fact_appointment f
JOIN dim_clinic c ON f.clinic_sk = c.clinic_sk
JOIN dim_date dt ON f.date_sk = dt.date_sk
GROUP BY c.clinic_name
ORDER BY c.clinic_name;