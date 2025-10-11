-- Cover table rename and index maintenance (foreign keys handled via FK comments in the table definition).
ALTER TABLE public.orders RENAME TO purchase_orders;

ALTER TABLE public.purchase_orders RENAME COLUMN state TO order_state;
ALTER TABLE public.purchase_orders ADD COLUMN order_label TEXT;
ALTER TABLE public.purchase_orders DROP COLUMN order_label;

CREATE INDEX idx_purchase_orders_user ON public.purchase_orders (user_id);
ALTER INDEX idx_purchase_orders_user RENAME TO idx_purchase_orders_userid;
DROP INDEX idx_purchase_orders_userid;

CREATE UNIQUE INDEX idx_order_items_product_partial ON public.order_items (product_id) WHERE quantity > 1;
