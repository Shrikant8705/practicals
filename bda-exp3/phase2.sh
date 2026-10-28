#!/usr/bin/env bash
set -e

echo "== Checking services =="
jps | grep -q NameNode || { start-dfs.sh; start-yarn.sh; }
sudo service mysql status >/dev/null 2>&1 || sudo service mysql start

echo "== Creating source data =="
sudo mysql <<'SQL'
DROP DATABASE IF EXISTS sqoop_demo;
CREATE DATABASE sqoop_demo;
USE sqoop_demo;
CREATE TABLE employee (emp_id INT PRIMARY KEY, emp_name VARCHAR(50), department VARCHAR(30), salary INT);
INSERT INTO employee VALUES
(1,'Aarav','CSE',45000),(2,'Diya','IT',55000),(3,'Kabir','AI',62000),
(4,'Meera','CSE',48000),(5,'Rohan','Data Science',70000);
GRANT ALL PRIVILEGES ON sqoop_demo.* TO 'sqoopuser'@'localhost';
FLUSH PRIVILEGES;
SQL

CONN="jdbc:mysql://localhost:3306/sqoop_demo?useSSL=false"

echo "== Full import =="
hdfs dfs -rm -r -f /sqoop/employee_data
sqoop import --connect "$CONN" --username sqoopuser --password Sqoop123 \
  --table employee --target-dir /sqoop/employee_data --num-mappers 1
hdfs dfs -cat /sqoop/employee_data/part-m-00000

echo "== Filtered import =="
hdfs dfs -rm -r -f /sqoop/high_salary
sqoop import --connect "$CONN" --username sqoopuser --password Sqoop123 \
  --table employee --where "salary > 50000" \
  --target-dir /sqoop/high_salary --num-mappers 1
hdfs dfs -cat /sqoop/high_salary/part-m-00000