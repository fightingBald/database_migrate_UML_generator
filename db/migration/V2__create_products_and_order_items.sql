
CREATE TABLE public.products (
                                 id            BIGSERIAL PRIMARY KEY,
                                 product_name  TEXT NOT NULL,
                                 price         NUMERIC(12,2) NOT NULL
);

CREATE TABLE public.order_items (
                                    order_id       BIGINT NOT NULL, -- FK public.orders(id)
                                    product_id     BIGINT NOT NULL, -- FK public.products(id)
                                    quantity       INTEGER NOT NULL DEFAULT 1,
                                    price_per_unit NUMERIC(12,2) NOT NULL,
                                    PRIMARY KEY (order_id, product_id)
);
