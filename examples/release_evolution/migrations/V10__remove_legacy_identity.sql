-- V10 must run after V2 and V3, even though its filename sorts before them.
ALTER TABLE app.orders RENAME COLUMN status TO lifecycle_state;
ALTER TABLE app.orders RENAME COLUMN grand_total TO total_amount;
-- CASCADE also removes fk_order_legacy from app.orders.
ALTER TABLE app.customers DROP COLUMN legacy_code CASCADE;
ALTER TABLE app.orders DROP COLUMN legacy_code;
DROP TABLE app.tmp_backfill;
DROP INDEX app.ix_grand_total;
