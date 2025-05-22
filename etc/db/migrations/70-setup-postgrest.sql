--------------------------------------------------------------------------------
-- postgrest helpers
--------------------------------------------------------------------------------

alter role :DATABASE_OWNER in database :DATABASE_NAME set pgrst.jwt_aud = ':JWT_AUD';
alter role :DATABASE_OWNER in database :DATABASE_NAME set pgrst.jwt_secret = ':JWT_SECRET';
alter role :ROLE_API in database :DATABASE_NAME set pgrst.jwt_aud = ':JWT_AUD';
alter role :ROLE_API in database :DATABASE_NAME set pgrst.jwt_secret = ':JWT_SECRET';

create or replace function app_priv.pgrst_watch() returns event_trigger as $$
begin
    notify pgrst, 'reload schema';
    -- perform pg_notify('pgrst', tg_tag);
end
$$ language plpgsql;

create event trigger _900_notify_postgrest_on_schema_changed on ddl_command_end execute function app_priv.pgrst_watch();

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.jwt_token
--------------------------------------------------------------------------------

drop type if exists api.jwt_token cascade;
create type api.jwt_token as (
    uid bigint,
    sid bigint,
    role text
);

--------------------------------------------------------------------------------
-- app.authenticate
--------------------------------------------------------------------------------

create or replace function app.authenticate() returns void as $$
declare
    access_token text = current_setting('request.cookies', true)::json->>'access_token';
    claims jsonb;
begin
    if not (current_setting('request.headers', true)::jsonb ? 'authorization') and access_token is not null then
        select payload into claims from lib.jwt_verify(access_token, current_setting('pgrst.jwt_secret'), 'HS256') where valid;
        if found and claims->>'aud' = current_setting('pgrst.jwt_aud', true) then
            perform set_config('request.jwt.claims', (claims - array['aud', 'exp', 'nbf'])::text, true);
            perform set_config('role', claims->>'role', true);
        end if;
    end if;
end
$$ language plpgsql;

--------------------------------------------------------------------------------
-- app_priv.make_token
--------------------------------------------------------------------------------

create or replace function app.make_token(claims jsonb, ttl int = 100000000) returns text as $$
    select lib.jwt_sign(claims || jsonb_build_object(
        'aud', current_setting('pgrst.jwt_aud', true),
        'nbf', extract(epoch from now())::int - 10,
        'exp', extract(epoch from now())::int + ttl
    ), current_setting('pgrst.jwt_secret'), 'HS256')
$$ language sql strict stable;

--------------------------------------------------------------------------------
-- app.make_user_token
--------------------------------------------------------------------------------

create or replace function app.make_user_token(p_uid api.jwt_token.uid%type, p_sid api.jwt_token.sid%type) returns text as $$
    select app.make_token(jsonb_build_object(
        'role', ':ROLE_USER',
        'uid', p_uid,
        'sid', p_sid
    ))
$$ language sql strict;

--------------------------------------------------------------------------------
-- app.make_external_token
--------------------------------------------------------------------------------

create or replace function app.make_external_token() returns text as $$
    select app.make_token(jsonb_build_object(
        'role', ':ROLE_EXTERNAL',
        'key', current_setting('pgrst.api_key_external')
    ))
$$ language sql strict;

--------------------------------------------------------------------------------
-- app.make_zeus_token
--------------------------------------------------------------------------------

create or replace function app.make_zeus_token() returns text as $$
    select app.make_token(jsonb_build_object(
        'role', ':ROLE_ZEUS',
        'key', current_setting('pgrst.api_key_zeus')
    ))
$$ language sql strict;

--------------------------------------------------------------------------------
-- app_priv.login
--------------------------------------------------------------------------------

create or replace function app_priv.login(p_token text) returns text as $$
begin
    -- issue cookie
    if current_setting('request.headers', true) is not null then
        perform set_config('response.headers', format('[{"set-cookie":"access_token=%s; max-age: %s; httponly; path=/; samesite=strict"}]', p_token, 100000000), true);
    end if;
    --
    perform set_config('response.status', '201', true);
    --
    return p_token;
end
$$ language plpgsql immutable;

--------------------------------------------------------------------------------
-- app_priv.logout
--------------------------------------------------------------------------------

create or replace function app_priv.logout() returns void as $$
begin
    -- delete cookie
    if current_setting('request.headers', true) is not null then
        perform set_config('response.headers', format('[{"set-cookie":"access_token=; max-age: -1; httponly; path=/; samesite=strict"}]'), true);
    end if;
    --
    perform set_config('response.status', '204', true);
end
$$ language plpgsql strict immutable;

--------------------------------------------------------------------------------
