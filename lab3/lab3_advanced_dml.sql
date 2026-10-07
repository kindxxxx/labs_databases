-- Laboratory Work #3: DML Operations
-- Run with: psql -U postgres -f lab3_advanced_dml.sql

\set ON_ERROR_STOP on

-- =============================================================================
-- Part A: Database and Table Setup
-- =============================================================================

\c postgres

DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;

\c advanced_lab

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name  VARCHAR(50),
    department VARCHAR(50) DEFAULT 'General',
    salary     INTEGER DEFAULT 50000,
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50),
    budget     INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- =============================================================================
-- Part B: Advanced INSERT Operations
-- =============================================================================

-- 2. INSERT with column specification
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'Anna', 'Lee', 'IT');

-- An explicit emp_id does not advance the serial sequence.
SELECT setval(
    pg_get_serial_sequence('employees', 'emp_id'),
    (SELECT MAX(emp_id) FROM employees)
);

-- 3. INSERT with DEFAULT values
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Boris', 'Kim', 'HR', DEFAULT, DATE '2019-05-01', DEFAULT);

-- Sample rows used by the later UPDATE and DELETE tasks.
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
    ('Maya', 'Chen', 'IT', 90000, DATE '2021-06-01', 'Active'),
    ('Noah', 'Ali', 'IT', 91000, DATE '2021-06-01', 'Active'),
    ('Omar', 'Singh', 'IT', 92000, DATE '2021-07-15', 'Active'),
    ('Priya', 'Das', 'IT', 93000, DATE '2021-08-20', 'Active'),
    ('Diana', 'Cruz', 'IT', 70000, DATE '2018-04-12', 'Active'),
    ('Helen', 'Ward', 'HR', 48000, DATE '2022-07-01', 'Inactive');

-- 4. INSERT multiple rows in a single statement
INSERT INTO departments (dept_name, budget, manager_id) VALUES
    ('IT', 150000, NULL),
    ('HR', 90000, NULL),
    ('Sales', 120000, NULL);

-- Names produced by the CASE update in task 9, so later budget updates can match.
INSERT INTO departments (dept_name, budget, manager_id) VALUES
    ('Management', 200000, NULL),
    ('Senior', 80000, NULL),
    ('Junior', 40000, NULL);

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget) VALUES
    (
        'Legacy Portal',
        (SELECT dept_id FROM departments WHERE dept_name = 'IT'),
        DATE '2022-01-01',
        DATE '2022-06-01',
        10000
    ),
    (
        'Campus Analytics',
        (SELECT dept_id FROM departments WHERE dept_name = 'Management'),
        DATE '2025-01-01',
        DATE '2025-12-31',
        90000
    );

-- 5. INSERT with expressions
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Cara', 'Nguyen', 'Sales', 50000 * 1.1, CURRENT_DATE, 'Active');

-- 6. INSERT from SELECT (subquery)
CREATE TEMP TABLE temp_employees AS
SELECT *
FROM employees
WHERE false;

INSERT INTO temp_employees
SELECT *
FROM employees
WHERE department = 'IT';

-- =============================================================================
-- Part C: Complex UPDATE Operations
-- =============================================================================

-- 7. UPDATE with arithmetic expressions
UPDATE employees
SET salary = salary * 1.10;

-- 8. UPDATE with WHERE and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < DATE '2020-01-01';

-- 9. UPDATE using a CASE expression
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- 10. UPDATE with DEFAULT
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. UPDATE with a subquery.
-- Budget becomes 20% above the average salary of employees in that department.
-- Departments with no employees are left unchanged so their budget is not set to NULL.
UPDATE departments d
SET budget = (
    SELECT ROUND(AVG(e.salary) * 1.20)
    FROM employees e
    WHERE e.department = d.dept_name
)
WHERE EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.department = d.dept_name
);

-- 12. UPDATE multiple columns.
-- Task 9 already reclassified the original Sales rows, so this row restores a Sales employee.
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Ivan', 'Petrov', 'Sales', 50000, DATE '2024-03-01', 'Active');

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- =============================================================================
-- Part D: Advanced DELETE Operations
-- =============================================================================

-- 13. DELETE with a simple WHERE condition
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Tina', 'Moss', 'HR', 42000, DATE '2021-09-01', 'Terminated');

DELETE FROM employees
WHERE status = 'Terminated';

-- 14. DELETE with a complex WHERE clause
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Liam', 'Ortiz', NULL, 35000, DATE '2024-02-01', 'Active');

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > DATE '2023-01-01'
  AND department IS NULL;

-- 15. DELETE with a subquery.
-- The lab text compares dept_id to employees.department. That column stores the
-- department name, so the match is on dept_name; an integer compared with varchar
-- would not execute.
DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

-- 16. DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date < DATE '2023-01-01'
RETURNING *;

-- =============================================================================
-- Part E: Operations with NULL Values
-- =============================================================================

-- 17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Nina', 'Cole', NULL, NULL, DATE '2024-04-01', 'Active');

-- 18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- =============================================================================
-- Part F: RETURNING Clause Operations
-- =============================================================================

-- 20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Olivia', 'Grant', 'IT', 64000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. UPDATE with RETURNING.
-- RETURNING sees the new row, so the previous salary is the new value minus the raise.
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

-- 22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < DATE '2020-01-01'
RETURNING *;

-- =============================================================================
-- Part G: Advanced DML Patterns
-- =============================================================================

-- 23. Conditional INSERT (the second call inserts nothing)
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Nina', 'Patel', 'HR', 61000, DATE '2022-04-01'
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.first_name = 'Nina'
      AND e.last_name = 'Patel'
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Nina', 'Patel', 'HR', 61000, DATE '2022-04-01'
WHERE NOT EXISTS (
    SELECT 1
    FROM employees e
    WHERE e.first_name = 'Nina'
      AND e.last_name = 'Patel'
);

-- 24. UPDATE with JOIN logic expressed as a subquery
UPDATE employees e
SET salary = ROUND(
    e.salary * CASE
        WHEN (
            SELECT d.budget
            FROM departments d
            WHERE d.dept_name = e.department
        ) > 100000 THEN 1.10
        ELSE 1.05
    END
);

-- 25. Bulk operations
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status) VALUES
    ('Ben', 'Holt', 'Contract', 40000, DATE '2024-01-10', 'Active'),
    ('Cleo', 'Park', 'Contract', 41000, DATE '2024-01-10', 'Active'),
    ('Dean', 'Frost', 'Contract', 42000, DATE '2024-01-10', 'Active'),
    ('Eva', 'Stone', 'Contract', 43000, DATE '2024-01-10', 'Active'),
    ('Finn', 'Blake', 'Contract', 44000, DATE '2024-01-10', 'Active');

UPDATE employees
SET salary = salary * 1.10
WHERE department = 'Contract';

-- 26. Data migration simulation
CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

INSERT INTO employee_archive
SELECT *
FROM employees
WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

-- 27. Complex business logic.
-- Move the end date 30 days later when the project budget is above 50000 and
-- the linked department still has more than three employees.
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE p.budget > 50000
  AND (
      SELECT COUNT(*)
      FROM employees e
      JOIN departments d ON d.dept_name = e.department
      WHERE d.dept_id = p.dept_id
  ) > 3;
