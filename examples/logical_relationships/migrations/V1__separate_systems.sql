-- auth.users and crm.users are different entities with the same short name.
CREATE TABLE auth.users (
    id BIGINT PRIMARY KEY,
    email TEXT UNIQUE
);
CREATE TABLE crm.users (
    id BIGINT PRIMARY KEY,
    account_ref UUID,
    external_auth_id BIGINT,
    nickname TEXT
);
CREATE TABLE crm.accounts (
    id UUID PRIMARY KEY,
    owner_id BIGINT, -- FK crm.users(id)
    parent_id UUID REFERENCES crm.accounts(id),
    display_name TEXT
);
CREATE TABLE support.tickets (
    id BIGINT PRIMARY KEY,
    reporter_id BIGINT, -- FK crm.users(id)
    assignee_id BIGINT,
    account_id UUID REFERENCES crm.accounts(id),
    subject TEXT
);
CREATE TABLE integration.sync_jobs (
    id UUID PRIMARY KEY,
    ticket_id BIGINT, -- FK support.tickets(id)
    triggered_by BIGINT,
    previous_job_id UUID REFERENCES integration.sync_jobs(id),
    last_error TEXT
);
-- Disconnected tables must remain visible. A JSON payload is not a declared FK.
CREATE TABLE ops.outbox (
    id UUID PRIMARY KEY,
    event_type TEXT,
    payload JSONB
);
