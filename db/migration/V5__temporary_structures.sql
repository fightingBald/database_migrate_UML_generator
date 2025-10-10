-- Create and drop supporting objects to exercise drop table/index parsing.
CREATE TABLE public.temp_audit (
    id BIGSERIAL PRIMARY KEY,
    ref_table TEXT NOT NULL,
    ref_id BIGINT NOT NULL
);

CREATE INDEX idx_temp_audit_ref ON public.temp_audit USING btree (ref_table, ref_id);
DROP INDEX idx_temp_audit_ref;

DROP TABLE public.temp_audit;
