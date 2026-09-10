CREATE TABLE public.users (
    id INT PRIMARY KEY,
    manager_id INT REFERENCES public.users(id)
);
