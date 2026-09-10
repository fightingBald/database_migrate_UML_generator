-- Fictional SaaS commerce. Schemas are namespaces; these files are parsed offline.
CREATE TABLE accounts.tenants (
    id UUID PRIMARY KEY,
    slug TEXT UNIQUE,
    display_name TEXT
);

CREATE TABLE accounts.users (
    tenant_id UUID NOT NULL REFERENCES accounts.tenants(id),
    id BIGINT NOT NULL,
    email TEXT NOT NULL,
    manager_id BIGINT,
    CONSTRAINT pk_users PRIMARY KEY (tenant_id, id),
    CONSTRAINT uq_tenant_email UNIQUE (tenant_id, email),
    CONSTRAINT fk_user_manager FOREIGN KEY (tenant_id, manager_id)
        REFERENCES accounts.users(tenant_id, id)
);

CREATE TABLE accounts.roles (
    tenant_id UUID NOT NULL REFERENCES accounts.tenants(id),
    id BIGINT NOT NULL,
    role_name TEXT,
    PRIMARY KEY (tenant_id, id)
);

CREATE TABLE accounts.user_roles (
    tenant_id UUID NOT NULL,
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    granted_at TIMESTAMPTZ,
    PRIMARY KEY (tenant_id, user_id, role_id),
    CONSTRAINT fk_grant_user FOREIGN KEY (tenant_id, user_id)
        REFERENCES accounts.users(tenant_id, id),
    CONSTRAINT fk_grant_role FOREIGN KEY (tenant_id, role_id)
        REFERENCES accounts.roles(tenant_id, id)
);
