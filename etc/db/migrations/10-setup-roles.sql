--------------------------------------------------------------------------------
-- create roles
--------------------------------------------------------------------------------

-- -- owner
-- do $$ begin create role :DATABASE_OWNER superuser replication login password ':DB_PASS'; exception when duplicate_object then null; end $$;

-- api user
do $$ begin create role :ROLE_API login password ':ROLE_API_PASS'; exception when duplicate_object then null; end $$;

-- api user roles
do $$ begin create role :ROLE_ANON; exception when duplicate_object then null; end $$; grant :ROLE_ANON to :ROLE_API;
do $$ begin create role :ROLE_USER; exception when duplicate_object then null; end $$; grant :ROLE_USER to :ROLE_API;
do $$ begin create role :ROLE_EXTERNAL; exception when duplicate_object then null; end $$; grant :ROLE_EXTERNAL to :ROLE_API;
-- NB: bypassrls for full access
do $$ begin create role :ROLE_ZEUS bypassrls; exception when duplicate_object then null; end $$; grant :ROLE_ZEUS to :ROLE_API;

--------------------------------------------------------------------------------
-- grant access
--------------------------------------------------------------------------------

grant connect on database :DATABASE_NAME to :ROLE_API;

--------------------------------------------------------------------------------
-- register extensions
--------------------------------------------------------------------------------

create extension if not exists pgcrypto;
create extension if not exists pg_trgm;
create extension if not exists btree_gin;
create extension if not exists ltree;

--------------------------------------------------------------------------------
-- revoke default access to functions
--------------------------------------------------------------------------------

-- alter default privileges revoke execute on routines from public;
alter default privileges for role :DATABASE_OWNER revoke execute on routines from public;

--------------------------------------------------------------------------------
