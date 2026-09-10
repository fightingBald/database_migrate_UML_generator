ALTER TABLE app.orders ADD COLUMN status TEXT;
ALTER TABLE app.orders ALTER COLUMN status TYPE VARCHAR(24);
ALTER TABLE app.orders ALTER COLUMN status SET NOT NULL;
ALTER TABLE app.orders ALTER COLUMN grand_total TYPE NUMERIC(16, 2);
CREATE INDEX ix_total ON app.orders (grand_total);
ALTER INDEX app.ix_total RENAME TO ix_grand_total;
