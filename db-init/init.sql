-- Créer le tableau Users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    email VARCHAR(80) NOT NULL
);

-- Créer des enregistrements dans Users
INSERT INTO users (name, email) VALUES
('Ada Lovelace', 'alovelace@example.com'),
('Adele Goldberg', 'agoldberg@example.com'),
('Alan Turing', 'aturing@example.com');

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    brand VARCHAR(20) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- Créer des enregistrements dans Products
INSERT INTO products (name, brand, price) VALUES
('iPhone 15', 'Apple', 999.99),
('Galaxy S24', 'Samsung', 899.99),
('MacBook Pro', 'Apple', 1999.99),
('ThinkPad X1', 'Lenovo', 1299.99),
('AirPods Pro', 'Apple', 249.99),
('Surface Pro', 'Microsoft', 1099.99),
('iPad Air', 'Apple', 599.99),
('Pixel 8', 'Google', 699.99);
