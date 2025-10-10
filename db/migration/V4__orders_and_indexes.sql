-- Cover table rename, index rename/drop, and foreign-key maintenance.
ALTER TABLE public.orders RENAME TO purchase_orders;

ALTER TABLE public.purchase_orders RENAME COLUMN state TO order_state;
ALTER TABLE public.purchase_orders ADD COLUMN order_label TEXT;
ALTER TABLE public.purchase_orders DROP COLUMN order_label;

CREATE INDEX idx_purchase_orders_user ON public.purchase_orders (user_id);
ALTER INDEX idx_purchase_orders_user RENAME TO idx_purchase_orders_userid;
DROP INDEX idx_purchase_orders_userid;

ALTER TABLE public.order_items RENAME CONSTRAINT order_items_order_fk TO order_items_purchase_fk_old;
ALTER TABLE public.order_items DROP CONSTRAINT order_items_purchase_fk_old;
ALTER TABLE public.order_items
    ADD CONSTRAINT order_items_purchase_fk
    FOREIGN KEY (order_id) REFERENCES public.purchase_orders(id);

ALTER TABLE public.order_items RENAME CONSTRAINT order_items_product_fk TO order_items_product_ref;
ALTER TABLE public.order_items DROP CONSTRAINT order_items_product_ref;
CREATE UNIQUE INDEX idx_order_items_product_partial ON public.order_items (product_id) WHERE quantity > 1;
