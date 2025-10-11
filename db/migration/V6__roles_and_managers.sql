-- Introduce tables/columns that rely on YAML FK overrides for testing.
CREATE TABLE public.roles (
    id BIGSERIAL PRIMARY KEY,
    role_name TEXT NOT NULL UNIQUE
);

ALTER TABLE public.users
    ADD COLUMN role_id BIGINT,
    ADD COLUMN manager_id BIGINT;

-- In production these would reference roles(id) and users(id) respectively,
-- but they are intentionally left without FOREIGN KEY constraints here to
-- demonstrate YAML-driven relationships.
