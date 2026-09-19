CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    stock INT NOT NULL
);

INSERT INTO products (name, price, stock) VALUES
('Kubernetes & Docker El Kitabi', 350.00, 100),
('DevOps Pipeline Mimarisi', 450.00, 50),
('Linux Sistem Yonetimi', 280.00, 75)
ON CONFLICT DO NOTHING;
