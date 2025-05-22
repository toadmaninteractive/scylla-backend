--------------------------------------------------------------------------------
-- schemas
--------------------------------------------------------------------------------

-- standard library code
create schema if not exists lib;
grant usage on schema lib to public;
alter default privileges in schema lib grant execute on routines to public;

-- application: private logic
create schema if not exists app_priv;

-- application: public logic
create schema if not exists app;
grant usage on schema app to :ROLE_ANON, :ROLE_USER, :ROLE_ZEUS, :ROLE_EXTERNAL;
alter default privileges in schema app grant execute on routines to :ROLE_ANON, :ROLE_USER, :ROLE_ZEUS, :ROLE_EXTERNAL;

-- application: exposed api
create schema if not exists api;
grant usage on schema api to :ROLE_ANON, :ROLE_USER, :ROLE_ZEUS, :ROLE_EXTERNAL;

--------------------------------------------------------------------------------
