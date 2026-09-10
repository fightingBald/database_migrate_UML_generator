CREATE TABLE "报表"."客户资料" (
    "客户编号" UUID PRIMARY KEY,
    "客户名称" VARCHAR(128),
    "shape" TEXT,
    "a.b" TEXT,
    "${reference}" TEXT,
    "path\segment" TEXT,
    "quoted""label" TEXT
);
CREATE TABLE "报表"."monthly_customer_reconciliation_details" (
    id UUID PRIMARY KEY,
    "客户编号" UUID REFERENCES "报表"."客户资料"("客户编号"),
    outstanding_amount_in_original_transaction_currency NUMERIC(18, 4),
    reconciliation_metadata JSONB,
    reconciliation_completed_at TIMESTAMPTZ,
    exception_tags TEXT[]
);
CREATE TABLE "报表"."processing_attempts" (
    id UUID PRIMARY KEY,
    "related.report" UUID REFERENCES "报表"."monthly_customer_reconciliation_details"(id),
    "previous.attempt" UUID REFERENCES "报表"."processing_attempts"(id),
    remarks TEXT
);
CREATE TABLE "报表"."empty_extension_point" ();
CREATE INDEX ix_customer_normalized_name ON "报表"."客户资料" (lower("客户名称"));
CREATE INDEX ix_unfinished_reconciliation
    ON "报表"."monthly_customer_reconciliation_details" (reconciliation_completed_at)
    WHERE reconciliation_completed_at IS NULL;
