CREATE USER "usr_test"
WITH
  PASSWORD 'pass';

CREATE DATABASE "test_db"
WITH
  OWNER "usr_test" ENCODING "UTF8" TEMPLATE "template0";