-- Create test drivers with different locations for testing
-- Run these one by one to create multiple drivers

-- Driver 1: New York
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES ('John Driver', 'john.driver@test.com', '+1234567890', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 40.7128, -74.0060, NOW(), NOW());

-- Driver 2: London
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES ('Sarah Driver', 'sarah.driver@test.com', '+1234567891', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 51.5074, -0.1278, NOW(), NOW());

-- Driver 3: Tokyo
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES ('Mike Driver', 'mike.driver@test.com', '+1234567892', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 35.6762, 139.6503, NOW(), NOW());

-- Driver 4: Sydney
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES ('Lisa Driver', 'lisa.driver@test.com', '+1234567893', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', -33.8688, 151.2093, NOW(), NOW());

-- Driver 5: Dubai
INSERT INTO users (name, email, phone, password, role, latitude, longitude, created_at, updated_at) 
VALUES ('Ahmed Driver', 'ahmed.driver@test.com', '+1234567894', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'driver', 25.2048, 55.2708, NOW(), NOW());

-- Note: All drivers use password: 'password'
-- You can login with any of these emails and password: 'password' 