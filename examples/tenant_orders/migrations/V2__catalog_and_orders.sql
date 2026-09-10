CREATE TABLE catalog.categories (
    tenant_id UUID NOT NULL REFERENCES accounts.tenants(id),
    id BIGINT NOT NULL,
    parent_id BIGINT,
    title TEXT,
    PRIMARY KEY (tenant_id, id),
    CONSTRAINT fk_category_parent FOREIGN KEY (tenant_id, parent_id)
        REFERENCES catalog.categories(tenant_id, id)
);

CREATE TABLE catalog.products (
    tenant_id UUID NOT NULL,
    id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    sku TEXT,
    unit_price NUMERIC(12, 2),
    archived_at TIMESTAMPTZ,
    PRIMARY KEY (tenant_id, id),
    CONSTRAINT uq_product_sku UNIQUE (tenant_id, sku),
    CONSTRAINT fk_product_category FOREIGN KEY (tenant_id, category_id)
        REFERENCES catalog.categories(tenant_id, id)
);

CREATE TABLE sales.orders (
    tenant_id UUID NOT NULL REFERENCES accounts.tenants(id),
    id BIGINT NOT NULL,
    created_by BIGINT NOT NULL,
    approved_by BIGINT,
    assigned_to BIGINT,
    status VARCHAR(24),
    total_amount NUMERIC(16, 2),
    PRIMARY KEY (tenant_id, id),
    CONSTRAINT fk_order_creator FOREIGN KEY (tenant_id, created_by)
        REFERENCES accounts.users(tenant_id, id),
    CONSTRAINT fk_order_approver FOREIGN KEY (tenant_id, approved_by)
        REFERENCES accounts.users(tenant_id, id),
    CONSTRAINT fk_order_assignee FOREIGN KEY (tenant_id, assigned_to)
        REFERENCES accounts.users(tenant_id, id)
);

CREATE TABLE sales.order_items (
    tenant_id UUID NOT NULL,
    order_id BIGINT NOT NULL,
    line_no INT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT,
    unit_price NUMERIC(12, 2),
    PRIMARY KEY (tenant_id, order_id, line_no),
    CONSTRAINT fk_item_order FOREIGN KEY (tenant_id, order_id)
        REFERENCES sales.orders(tenant_id, id),
    CONSTRAINT fk_order_product FOREIGN KEY (tenant_id, product_id)
        REFERENCES catalog.products(tenant_id, id)
);

CREATE TABLE billing.payments (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    order_id BIGINT NOT NULL,
    provider_reference TEXT UNIQUE,
    amount NUMERIC(16, 2),
    PRIMARY KEY (tenant_id, id),
    CONSTRAINT fk_payment_order FOREIGN KEY (tenant_id, order_id)
        REFERENCES sales.orders(tenant_id, id)
);

CREATE UNIQUE INDEX uq_active_product_sku ON catalog.products (tenant_id, sku)
    WHERE archived_at IS NULL;
CREATE INDEX ix_user_lower_email ON accounts.users USING btree (lower(email));
