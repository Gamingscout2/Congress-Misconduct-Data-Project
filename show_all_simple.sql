--A simple SQL script to DESC out the misconduct table and then show
--Every entry without all the extra data
--An example of using the database

USE usCongress;
SHOW TABLES;
DESC misconduct;
SELECT id, name, allegation, description FROM misconduct;
