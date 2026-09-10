ALTER TABLE app.customers ADD COLUMN metadata JSONB;
CREATE INDEX ix_customer_lower_email ON app.customers (lower(email));
CREATE INDEX ix_orders_state ON app.orders (lifecycle_state);
CREATE UNIQUE INDEX uq_active_order ON app.orders (customer_id)
    WHERE lifecycle_state = 'active';
