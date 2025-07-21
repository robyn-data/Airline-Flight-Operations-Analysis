select count(*) as total_rows
from airline_ontime_2024;select * from airline_ontime_2024 limit 5;

-- 1. carriers 테이블 생성 및 데이터 삽입
CREATE TABLE carriers (
  carrier_id SERIAL PRIMARY KEY,
  carrier_code VARCHAR(10) UNIQUE
);

INSERT INTO carriers (carrier_code)
SELECT DISTINCT op_unique_carrier
FROM airline_ontime_2024;

-- 2. airports 테이블 생성 및 데이터 삽입
CREATE TABLE airports (
  airport_id SERIAL PRIMARY KEY,
  airport_code VARCHAR(10) UNIQUE,
  city_name TEXT
);

INSERT INTO airports (airport_code, city_name)
SELECT DISTINCT origin, origin_city_name FROM airline_ontime_2024
UNION
SELECT DISTINCT dest, dest_city_name FROM airline_ontime_2024;

-- 3. flights 테이블 생성 및 데이터 삽입
CREATE TABLE flights (
  flight_id SERIAL PRIMARY KEY,
  fl_date DATE,
  carrier_id INT REFERENCES carriers(carrier_id),
  origin_id INT REFERENCES airports(airport_id),
  dest_id INT REFERENCES airports(airport_id),
  flight_num INT
);

INSERT INTO flights (fl_date, carrier_id, origin_id, dest_id, flight_num)
SELECT 
  fl_date,
  (SELECT carrier_id FROM carriers WHERE carrier_code = a.op_unique_carrier),
  (SELECT airport_id FROM airports WHERE airport_code = a.origin),
  (SELECT airport_id FROM airports WHERE airport_code = a.dest),
  op_carrier_fl_num
FROM airline_ontime_2024 a;

-- 4. delays 테이블 생성 및 데이터 삽입
CREATE TABLE delays (
  flight_id INT REFERENCES flights(flight_id),
  dep_delay FLOAT,
  arr_delay FLOAT,
  carrier_delay FLOAT,
  weather_delay FLOAT,
  nas_delay FLOAT,
  security_delay FLOAT,
  late_aircraft_delay FLOAT
);

INSERT INTO delays (flight_id, dep_delay, arr_delay, carrier_delay, weather_delay, nas_delay, security_delay, late_aircraft_delay)
SELECT 
  f.flight_id,
  a.dep_delay, a.arr_delay,
  a.carrier_delay, a.weather_delay, a.nas_delay, a.security_delay, a.late_aircraft_delay
FROM airline_ontime_2024 a
JOIN flights f ON 
  f.fl_date = a.fl_date AND
  f.flight_num = a.op_carrier_fl_num AND
  f.carrier_id = (SELECT carrier_id FROM carriers WHERE carrier_code = a.op_unique_carrier)
LIMIT 100000;  -- INSERT 속도 때문에 초기에는 제한 걸기

-- 5. cancellations 테이블 생성 및 데이터 삽입
CREATE TABLE cancellations (
  flight_id INT REFERENCES flights(flight_id),
  cancelled FLOAT,
  cancellation_code TEXT,
  diverted FLOAT
);

INSERT INTO cancellations (flight_id, cancelled, cancellation_code, diverted)
SELECT 
  f.flight_id,
  a.cancelled, a.cancellation_code, a.diverted
FROM airline_ontime_2024 a
JOIN flights f ON 
  f.fl_date = a.fl_date AND
  f.flight_num = a.op_carrier_fl_num AND
  f.carrier_id = (SELECT carrier_id FROM carriers WHERE carrier_code = a.op_unique_carrier)
LIMIT 100000;

ALTER TABLE delays RENAME TO flight_delays;

-- 6. aircrafts 테이블 생성 및 데이터 삽입

CREATE TABLE aircrafts (
    tail_num VARCHAR PRIMARY KEY
);
INSERT INTO aircrafts (tail_num)
SELECT DISTINCT tail_num
FROM airline_ontime_2024
WHERE tail_num IS NOT NULL;

