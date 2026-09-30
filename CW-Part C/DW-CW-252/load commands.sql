\copy dim_patient FROM 'dim_patient.csv' WITH (FORMAT csv, HEADER true);
-- Output: COPY 300

\copy dim_doctor FROM 'dim_doctor.csv' WITH (FORMAT csv, HEADER true);
-- Output: COPY 21

\copy dim_clinic FROM 'dim_clinic.csv' WITH (FORMAT csv, HEADER true);
-- Output: COPY 5

\copy dim_date FROM 'dim_date.csv' WITH (FORMAT csv, HEADER true);
-- Output: COPY 365

\copy fact_appointment FROM 'fact_appointment.csv' WITH (FORMAT csv, HEADER true);
-- Output: COPY <Fact Row Count, e.g., 1477>