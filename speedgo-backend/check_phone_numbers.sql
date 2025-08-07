-- Check existing phone numbers in the database
SELECT id, name, phone, role FROM users ORDER BY role, id;

-- Check if 81338640 already exists
SELECT id, name, phone, role FROM users WHERE phone = '81338640'; 