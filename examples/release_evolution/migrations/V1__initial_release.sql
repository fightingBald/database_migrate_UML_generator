CREATE TABLE app.accounts (
    id BIGINT,
    email TEXT,
    name TEXT,
    legacy_code TEXT,
    CONSTRAINT pk_accounts PRIMARY KEY (id),
    CONSTRAINT uq_account_email UNIQUE (email),
    CONSTRAINT uq_legacy_code UNIQUE (legacy_code)
);
CREATE TABLE app.orders (
    id BIGINT PRIMARY KEY,
    account_id BIGINT REFERENCES app.accounts(id),
    legacy_code TEXT,
    grand_total NUMERIC(12, 2),
    CONSTRAINT fk_order_legacy FOREIGN KEY (legacy_code) REFERENCES app.accounts(legacy_code)
);
CREATE TABLE app.order_lines (
    id BIGINT PRIMARY KEY,
    order_id BIGINT REFERENCES app.orders(id),
    quantity INT,
    unit_price NUMERIC(12, 2)
);
CREATE TABLE audit.events (
    id BIGINT PRIMARY KEY,
    actor_id BIGINT REFERENCES app.accounts(id),
    event_type TEXT
);
CREATE TABLE app.tmp_backfill (
    id BIGINT PRIMARY KEY,
    account_id BIGINT REFERENCES app.accounts(id)
);
