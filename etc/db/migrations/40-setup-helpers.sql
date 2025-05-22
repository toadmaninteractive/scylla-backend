--------------------------------------------------------------------------------
-- audit helpers
--------------------------------------------------------------------------------

/*
  USAGE: create trigger _100_protect_readonly_columns before update of id, rev, created_at, updated_at, uuid on app.foo for each row execute procedure lib.trigger_protect_readonly_columns();
*/

create or replace function lib.trigger_protect_readonly_columns() returns trigger as $$
begin
    raise exception 'Can not set read-only field' using errcode = 'PT403';
end
$$ language plpgsql;

--------------------------------------------------------------------------------

/*
  USAGE: create trigger _200_manage_revision before update on app.foo for each row when (new is distinct from old) execute procedure lib.trigger_manage_revision();
*/

create or replace function lib.trigger_manage_revision() returns trigger as $$
begin
    perform pg_advisory_xact_lock(hashtext(TG_TABLE_NAME), hash_record(new));
    --
    -- if new.created_at <> old.created_at then
    --     raise exception 'not allowed';
    -- end if;
    new.rev = old.rev + 1;
    new.created_at = old.created_at;
    new.updated_at = now();
    --
    return new;
end
$$ language plpgsql;

--------------------------------------------------------------------------------
-- misc helpers
--------------------------------------------------------------------------------

create or replace function lib.get_constraint_comment(schema_name text, table_name text, constraint_name text, key text) returns text as $$
    with parts as (
        select trim(unnest(string_to_array(obj_description(oid), '\\n'))) as kv from pg_constraint where conrelid = ($1 || '.' || $2)::text::regclass and conname = $3
    ),
    kv as (
        select regexp_match(kv, '^@(\w+)\s+(.+?)\s*') as kv from parts where kv != ''
    )
    select kv[2] from kv where kv[1] = $4
$$ language sql strict stable security definer;

--------------------------------------------------------------------------------

create or replace function lib.estimate_row_count(query text) returns bigint as $$
declare
    plan jsonb;
begin
    execute 'explain (format json) ' || query into plan;
    return (plan->0->'Plan'->>'Plan Rows')::bigint;
end
$$ language plpgsql;

--------------------------------------------------------------------------------
-- health helpers
--------------------------------------------------------------------------------

-- housekeeping
create or replace view lib.check_size as
    select
        relname as table_name,
        pg_size_pretty(pg_total_relation_size(relid)) as total_size,
        pg_size_pretty(pg_indexes_size(relid)) as index_size,
        pg_size_pretty(pg_relation_size(relid)) as actual_size
    from
        pg_statio_user_tables
    order by pg_total_relation_size(relid) desc;

--------------------------------------------------------------------------------
