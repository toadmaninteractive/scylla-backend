--! Previous: -
--! Hash: sha1:be0ca89c8cae1d66f540db7837ed99d7ca51018f

--! split: 10-tables.sql
/*
################################################################################
## types
################################################################################
*/

-- NB: on enums see https://blog.yo1.dog/updating-enum-values-in-postgresql-the-safe-and-easy-way/

--------------------------------------------------------------------------------

/*
################################################################################
## extensions
################################################################################
*/

--------------------------------------------------------------------------------

/*
################################################################################
## functions
################################################################################
*/

--------------------------------------------------------------------------------

/*
################################################################################
## tables
################################################################################
*/

--------------------------------------------------------------------------------
-- app.clickhouse_instance
--------------------------------------------------------------------------------

drop table if exists app.clickhouse_instance cascade;
create table if not exists app.clickhouse_instance (
    id                          bigint primary key generated always as identity,
    rev                         int not null default 1,
    created_at                  timestamptz not null default now(),
    updated_at                  timestamptz not null default now(),
    uuid                        uuid unique not null default gen_random_uuid(),
    --
    code                        text unique not null constraint clickhouse_instance_code_check_format check (lib.is_alnum(code)),
    name                        text unique not null,
    --
    uri                         text not null constraint clickhouse_instance_uri_check_format check (split_part(uri, '://', 1) in ('http', 'https')),
    username                    text not null,
    password                    text not null
);

--------------------------------------------------------------------------------

create or replace function app_priv.trigger_clickhouse_instance_validate_changes() returns trigger as $$
begin
    perform pg_advisory_xact_lock(hashtext(TG_TABLE_NAME), hash_record(new));
    --
    new.code = lower(lib.trimmed(new.code));
    new.name = lib.trimmed(new.name);
    new.uri = lib.trimmed(new.uri);
    new.username = lib.trimmed(new.username);
    new.password = lib.trimmed(new.password);
    --
    return new;
end
$$ language plpgsql;

create trigger _100_protect_readonly_columns before update of id, rev, created_at, updated_at, uuid on app.clickhouse_instance for each row execute procedure lib.trigger_protect_readonly_columns();
create trigger _110_validate_changes before insert or update on app.clickhouse_instance for each row execute procedure app_priv.trigger_clickhouse_instance_validate_changes();
create trigger _200_manage_revision before update on app.clickhouse_instance for each row when (new is distinct from old) execute procedure lib.trigger_manage_revision();

--------------------------------------------------------------------------------
-- app.project
--------------------------------------------------------------------------------

drop table if exists app.project cascade;
create table if not exists app.project (
    id                          bigint primary key generated always as identity,
    rev                         int not null default 1,
    created_at                  timestamptz not null default now(),
    updated_at                  timestamptz not null default now(),
    uuid                        uuid unique not null default gen_random_uuid(),
    --
    code                        text unique not null constraint project_code_check_format check (lib.is_alnum(code)),
    name                        text unique not null,
    description                 text,
    --
    key_su                      uuid not null default gen_random_uuid(),
    key_rw                      uuid not null default gen_random_uuid(),
    --
    clickhouse_instance_id      bigint not null references app.clickhouse_instance on delete restrict,
    clickhouse_db               text not null constraint project_clickhouse_db_check_format check (lib.is_alnum(clickhouse_db)),
    clickhouse_table            text not null default ':CLICKHOUSE_TABLE' constraint project_clickhouse_table_check_format check (lib.is_alnum(clickhouse_table)),
    -- NB: text because content formatting matters and json is not comparable
    schema                      text,
    --
    -- apply schema to ingested events
    event_validation            bool not null default true,
    -- do not drop data columns gone from schema
    preserve_db_columns         bool not null default false,
    -- backup data columns changed their type in schema
    backup_mode                 bool not null default false,
    --
    constraint project_key_su_differs_from_key_rw check (key_su != key_rw)
);

--------------------------------------------------------------------------------

create or replace function app_priv.trigger_project_validate_changes() returns trigger as $$
begin
    perform pg_advisory_xact_lock(hashtext(TG_TABLE_NAME), hash_record(new));
    --
    new.code = lower(lib.trimmed(new.code));
    new.name = lib.trimmed(new.name);
    new.description = lib.trimmed(new.description);
    new.clickhouse_db = lower(lib.trimmed(new.clickhouse_db));
    new.clickhouse_table = lower(lib.trimmed(new.clickhouse_table));
    --
    return new;
end
$$ language plpgsql;

create trigger _100_protect_readonly_columns before update of id, rev, created_at, updated_at, uuid on app.project for each row execute procedure lib.trigger_protect_readonly_columns();
create trigger _110_validate_changes before insert or update on app.project for each row execute procedure app_priv.trigger_project_validate_changes();
create trigger _200_manage_revision before update on app.project for each row when (new is distinct from old) execute procedure lib.trigger_manage_revision();

--------------------------------------------------------------------------------
-- app.project_schema_migration
--------------------------------------------------------------------------------

drop table if exists app.project_schema_migration cascade;
create table if not exists app.project_schema_migration (
    id                          bigint primary key generated always as identity,
    rev                         int not null default 1,
    created_at                  timestamptz not null default now(),
    updated_at                  timestamptz not null default now(),
    uuid                        uuid unique not null default gen_random_uuid(),
    --
    project_id                  bigint not null references app.project on delete cascade,
    previous_schema             text,
    schema                      text not null,
    schema_diff                 text not null,
    --
    constraint project_schema_migration_schema_differs_from_previous_schema check (schema != previous_schema)
);

--------------------------------------------------------------------------------

create or replace function app_priv.trigger_project_schema_migration_validate_changes() returns trigger as $$
begin
    perform pg_advisory_xact_lock(hashtext(TG_TABLE_NAME), hash_record(new));
    --
    --
    return new;
end
$$ language plpgsql;

create trigger _100_protect_readonly_columns before update of id, rev, created_at, updated_at, uuid, project_id, previous_schema, schema on app.project_schema_migration for each row execute procedure lib.trigger_protect_readonly_columns();
create trigger _110_validate_changes before insert or update on app.project_schema_migration for each row execute procedure app_priv.trigger_project_schema_migration_validate_changes();
create trigger _200_manage_revision before update on app.project_schema_migration for each row when (new is distinct from old) execute procedure lib.trigger_manage_revision();

--------------------------------------------------------------------------------

/*
################################################################################
## views
################################################################################
*/

--------------------------------------------------------------------------------

--! split: 30-data-logic.sql
--------------------------------------------------------------------------------
-- app.project
--------------------------------------------------------------------------------

create or replace function app_priv.trigger_project_schema_migration_add_migration() returns trigger as $$
begin
    perform pg_advisory_xact_lock(hashtext(TG_TABLE_NAME), hash_record(new));
    --
    insert into app.project_schema_migration (project_id, previous_schema, schema, schema_diff) values (new.id, old.schema, new.schema, 'TODO: someday!');
    --
    return new;
end
$$ language plpgsql;

create trigger _301_on_schema_changed before update of schema on app.project for each row when (new.schema is distinct from old.schema) execute procedure app_priv.trigger_project_schema_migration_add_migration();

--------------------------------------------------------------------------------

create or replace function app_priv.trigger_project_regenerate_keys() returns trigger as $$
begin
    perform pg_advisory_xact_lock(hashtext(TG_TABLE_NAME), hash_record(new));
    --
    -- NB: setting key to null regenerates it
    if new.key_su is null then new.key_su = gen_random_uuid(); end if;
    if new.key_rw is null then new.key_rw = gen_random_uuid(); end if;
    --
    return new;
end
$$ language plpgsql;

create trigger _302_on_keys_changed before update of key_su, key_rw on app.project for each row when (new.key_su is null or new.key_rw is null) execute procedure app_priv.trigger_project_regenerate_keys();

--------------------------------------------------------------------------------
