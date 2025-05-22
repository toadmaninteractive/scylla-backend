--------------------------------------------------------------------------------
-- create roles
--------------------------------------------------------------------------------

-- owner
do $$ begin create role :DATABASE_OWNER superuser replication login password ':DB_PASS'; exception when duplicate_object then null; end $$;

--------------------------------------------------------------------------------
