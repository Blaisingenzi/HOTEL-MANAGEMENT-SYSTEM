
-- ================================
-- Hotel Management System - SQL Implementation (Phase V to VII)
-- NGENZI Blaise | ID: 27488
-- Course: Database Development with PL/SQL (INSY 8311)
-- Lecturer: Eric Maniraguha
-- Date: 27 March 2025
-- ================================

-- ========== PHASE V: Table Implementation and Data Insertion ==========

-- Create tables
CREATE TABLE guests (
    guest_id        NUMBER PRIMARY KEY,
    full_name       VARCHAR2(100) NOT NULL,
    phone_number    VARCHAR2(15) UNIQUE NOT NULL,
    email           VARCHAR2(100),
    nationality     VARCHAR2(50)
);

CREATE TABLE rooms (
    room_id         NUMBER PRIMARY KEY,
    room_type       VARCHAR2(50),
    price_per_night NUMBER CHECK (price_per_night > 0),
    status          VARCHAR2(20) CHECK (status IN ('Available', 'Booked', 'Maintenance'))
);

CREATE TABLE staff (
    staff_id        NUMBER PRIMARY KEY,
    full_name       VARCHAR2(100),
    role            VARCHAR2(50),
    phone_number    VARCHAR2(15)
);

CREATE TABLE bookings (
    booking_id      NUMBER PRIMARY KEY,
    guest_id        NUMBER REFERENCES guests(guest_id),
    room_id         NUMBER REFERENCES rooms(room_id),
    check_in_date   DATE NOT NULL,
    check_out_date  DATE NOT NULL,
    booking_date    DATE DEFAULT SYSDATE,
    status          VARCHAR2(20) DEFAULT 'Confirmed'
);

CREATE TABLE payments (
    payment_id      NUMBER PRIMARY KEY,
    booking_id      NUMBER REFERENCES bookings(booking_id),
    amount          NUMBER NOT NULL CHECK (amount >= 0),
    payment_method  VARCHAR2(30),
    payment_date    DATE DEFAULT SYSDATE
);

-- Holiday table for auditing
CREATE TABLE holidays (
    holiday_date DATE PRIMARY KEY,
    description  VARCHAR2(100)
);

-- Auditing Table
CREATE TABLE audit_logs (
    audit_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       VARCHAR2(50),
    action_time   TIMESTAMP DEFAULT SYSTIMESTAMP,
    operation     VARCHAR2(50),
    status        VARCHAR2(20)
);

-- Sample data
INSERT INTO guests VALUES (1, 'NGENZI Blaise', '0788123456', 'Blaisingenzi@gmail.com', 'Rwanda');
INSERT INTO rooms VALUES (101, 'Single', 50000, 'Available');
INSERT INTO staff VALUES (1, 'DUKUZE Alice', 'Receptionist', '0788456789');
INSERT INTO bookings VALUES (1, 1, 101, TO_DATE('2025-05-20', 'YYYY-MM-DD'), TO_DATE('2025-05-25', 'YYYY-MM-DD'), SYSDATE, 'Confirmed');
INSERT INTO payments VALUES (1, 1, 250000, 'Cash', SYSDATE);

-- ========== PHASE VI: Database Interaction and Transactions ==========
 Data Manupulation Language(DML)

 -- Update room status
UPDATE rooms SET status = 'Booked' WHERE room_id = 101;

DDL(Data Definition Language

-- Create a new table for reviews
CREATE TABLE reviews (
    review_id NUMBER PRIMARY KEY,
    guest_id NUMBER REFERENCES guests(guest_id),
    comments VARCHAR2(500),
    rating NUMBER(1)
);

-- Add a new column
ALTER TABLE staff ADD hire_date DATE;

-- Drop the reviews table
DROP TABLE reviews;
)

🧠 Simple Problem:
“Show how much each guest has paid, and also calculate the running total of all payments so far.”

📊 Solution using Window Function:
sql
Copy
Edit
SELECT 
    b.guest_id,
    p.payment_id,
    p.amount,
    SUM(p.amount) OVER (PARTITION BY b.guest_id ORDER BY p.payment_date) AS running_total
FROM payments p
JOIN bookings b ON p.booking_id = b.booking_id;
This groups data by guest_id and shows a running total of their payments — a perfect use of a window function.

# PROCEDURE

CREATE OR REPLACE PROCEDURE get_guest_info(p_guest_id IN NUMBER) IS
    v_name guests.full_name%TYPE;
    v_phone guests.phone_number%TYPE;
BEGIN
    SELECT full_name, phone_number
    INTO v_name, v_phone
    FROM guests
    WHERE guest_id = p_guest_id;

    DBMS_OUTPUT.PUT_LINE('Guest Name: ' || v_name);
    DBMS_OUTPUT.PUT_LINE('Phone Number: ' || v_phone);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No guest found with ID ' || p_guest_id);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


Procedure-call 

-- ✅ This goes in your worksheet and works
DECLARE
    v_name VARCHAR2(100);
    v_phone VARCHAR2(20);
BEGIN
    get_guest_details(1, v_name, v_phone);  -- Call procedure with OUT variables
    DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
    DBMS_OUTPUT.PUT_LINE('Phone: ' || v_phone);
END;
/


-- ========================================
-- CREATE TRIGGER: Restrict changes on weekdays and holidays
-- ========================================
CREATE OR REPLACE TRIGGER trg_restrict_weekdays
BEFORE INSERT OR UPDATE OR DELETE ON bookings
FOR EACH ROW
DECLARE
    v_day VARCHAR2(10);
    v_today DATE := SYSDATE;
BEGIN
    SELECT TO_CHAR(v_today, 'DAY') INTO v_day FROM dual;

    IF TRIM(UPPER(v_day)) IN ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Bookings cannot be modified on weekdays.');
    ELSIF EXISTS (
        SELECT 1 FROM holidays 
        WHERE TRUNC(holiday_date) = TRUNC(v_today)
    ) THEN
        RAISE_APPLICATION_ERROR(-20002, 'Today is a holiday. Booking changes are not allowed.');
    END IF;
END;
/

-- ========================================
-- CREATE TRIGGER: Audit changes to bookings
-- ========================================
CREATE OR REPLACE TRIGGER trg_audit_bookings
AFTER INSERT OR UPDATE OR DELETE ON bookings
FOR EACH ROW
DECLARE
    v_status VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_status := 'INSERT';
    ELSIF UPDATING THEN
        v_status := 'UPDATE';
    ELSIF DELETING THEN
        v_status := 'DELETE';
    END IF;

    INSERT INTO audit_logs(user_id, operation, status)
    VALUES (USER, v_status, 'Logged');
END;
/

-- ========================================
-- INSERT SAMPLE DATA INTO GUESTS AND ROOMS
-- ========================================
INSERT INTO guests (guest_id, full_name, phone_number) 
VALUES (101, 'Alice', '0788000000');

INSERT INTO rooms (room_id, room_type, price_per_night, status) 
VALUES (201, 'Single', 5000, 'Available');

-- ========================================
-- INSERT INTO BOOKINGS (WILL FAIL ON WEEKDAYS)
-- ========================================
INSERT INTO bookings (
    booking_id, guest_id, room_id, 
    check_in_date, check_out_date, 
    booking_date, status
) 
VALUES (
    2, 101, 201, 
    TO_DATE('2025-06-01', 'YYYY-MM-DD'), 
    TO_DATE('2025-06-05', 'YYYY-MM-DD'), 
    SYSDATE, 
    'CONFIRMED'
);

-- COMMIT CHANGES
COMMIT;


