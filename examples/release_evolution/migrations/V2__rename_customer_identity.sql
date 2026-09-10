ALTER TABLE app.accounts RENAME TO customers;
ALTER TABLE app.customers RENAME COLUMN id TO customer_id;
ALTER TABLE app.customers RENAME COLUMN name TO display_name;
ALTER TABLE app.orders RENAME COLUMN account_id TO customer_id;
ALTER TABLE audit.events RENAME COLUMN actor_id TO customer_id;
ALTER TABLE app.customers RENAME CONSTRAINT uq_account_email TO uq_customer_email;
