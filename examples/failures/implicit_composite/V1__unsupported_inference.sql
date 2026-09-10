CREATE TABLE parent (
    tenant_id UUID,
    id BIGINT,
    PRIMARY KEY (tenant_id, id)
);
CREATE TABLE child (
    tenant_id UUID,
    parent_id BIGINT,
    FOREIGN KEY (tenant_id, parent_id) REFERENCES parent
);
