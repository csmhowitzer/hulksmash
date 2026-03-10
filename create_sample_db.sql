-- Create users table with JSON metadata field
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    metadata JSON
);

-- Insert sample records with JSON data
INSERT INTO users (name, email, metadata) VALUES
    ('Alice Johnson', 'alice@example.com', '{"role": "admin", "preferences": {"theme": "dark", "notifications": true}, "last_login": "2026-01-14"}'),
    ('Bob Smith', 'bob@example.com', '{"role": "user", "preferences": {"theme": "light", "notifications": false}, "tags": ["developer", "premium"]}'),
    ('Carol Davis', 'carol@example.com', '{"role": "moderator", "preferences": {"theme": "auto", "notifications": true}, "department": "support"}'),
    ('David Wilson', 'david@example.com', '{"role": "user", "preferences": {"theme": "dark", "notifications": true}, "subscription": {"plan": "pro", "expires": "2026-12-31"}}');

-- Display the results
SELECT 'Table created with ' || COUNT(*) || ' records' as status FROM users;
SELECT * FROM users;

