-- Exercise ALTER TABLE branches on public.users.
ALTER TABLE public.users ADD COLUMN status TEXT;
ALTER TABLE public.users ALTER COLUMN status TYPE VARCHAR(16);
ALTER TABLE public.users ALTER COLUMN status SET NOT NULL;

ALTER TABLE public.users ADD COLUMN last_login TIMESTAMPTZ;
ALTER TABLE public.users DROP COLUMN last_login;

ALTER TABLE public.users RENAME COLUMN name TO full_name;

ALTER TABLE public.users ADD CONSTRAINT users_email_unique UNIQUE (email);
ALTER TABLE public.users RENAME CONSTRAINT users_email_unique TO users_email_unq;
ALTER TABLE public.users DROP CONSTRAINT users_email_unq;
ALTER TABLE public.users ADD CONSTRAINT users_email_status_unique UNIQUE (email, status);

CREATE UNIQUE INDEX idx_users_active_email ON public.users USING btree (email, status) WHERE status <> 'inactive';

CREATE INDEX idx_users_lower_email ON public.users (LOWER(email));

