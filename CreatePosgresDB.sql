CREATE USER "abcoctobot88" WITH PASSWORD 'ChangeToALongPassword';
CREATE DATABASE "abcoctobot88-paperclip" OWNER "abcoctobot88";
GRANT ALL PRIVILEGES ON DATABASE "abcoctobot88-paperclip" TO "abcoctobot88";
SELECT datname FROM pg_database ORDER BY datname;