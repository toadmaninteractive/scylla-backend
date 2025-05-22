--------------------------------------------------------------------------------
-- debug helpers
--------------------------------------------------------------------------------

create or replace function lib.mark(s text) returns text as $$
begin
    raise warning 'MARK: %', s;
    return s;
end
$$ language plpgsql strict immutable;

create or replace function lib.raise(msg text, errcode text = 'PT500', hint text = null) returns void as $$
begin
    raise exception '%', msg using errcode = errcode, hint = hint;
end
$$ language plpgsql strict immutable;

--------------------------------------------------------------------------------
-- misc helpers
--------------------------------------------------------------------------------

create or replace function lib.crc16(s text) returns int as $$
    select ('x' || substr(md5(s), 1, 8))::bit(32)::int
$$ language sql strict;

create or replace function lib.hex_to_bigint(hexval text) returns bigint as $$
declare
    result bigint;
begin
    if starts_with(hexval, '0x') then
        execute 'select x' || quote_literal(substr(hexval, 3)) || '::bigint' into result;
    else
        result = hexval::bigint;
    end if;
    return result;
end;
$$ language plpgsql strict immutable;

--------------------------------------------------------------------------------

create or replace function lib.trimmed_non_empty(s text) returns bool as $$
    select length(btrim(s)) > 0
$$ language sql strict immutable;

create or replace function lib.trimmed(s text) returns text as $$
    select nullif(btrim(s), '')
$$ language sql strict immutable;

create or replace function lib.is_alnum(s text) returns bool as $$
    select s ~ '^[a-z0-9_]+$'
$$ language sql strict immutable;

--------------------------------------------------------------------------------
