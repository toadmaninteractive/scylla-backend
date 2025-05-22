--
-- initially taken from https://github.com/michelp/pgjwt/
--

create or replace function lib.try_cast_double(inp text) returns double precision as $$
begin
    return inp::double precision;
exception
    when others then return null;
end
$$ language plpgsql strict immutable;

create or replace function lib.try_decode_base64(data text) returns bytea as $$
begin
    return decode(data, 'base64');
exception
    when others then return null;
end
$$ language plpgsql strict immutable;

create or replace function lib.url_encode(data bytea) returns text as $$
    select translate(encode(data, 'base64'), e'+/=\n', '-_');
$$ language sql strict immutable;

create or replace function lib.url_decode(data text) returns bytea as $$
    with
    t as (select translate(data, '-_', '+/') as trans),
    rem as (select length(t.trans) % 4 as remainder from t) -- compute padding size
    select lib.try_decode_base64(t.trans || case when rem.remainder > 0 then repeat('=', (4 - rem.remainder)) else '' end) from t, rem
$$ language sql strict immutable;

create or replace function lib.algorithm_sign(signables text, secret text, algorithm text) returns text as $$
    with
    alg as (select case
        when algorithm = 'HS256' then 'sha256'
        when algorithm = 'HS384' then 'sha384'
        when algorithm = 'HS512' then 'sha512'
        else '' end
    as id) -- hmac throws error
    select lib.url_encode(hmac(signables, secret, alg.id)) from alg
$$ language sql strict immutable;

create or replace function lib.jwt_sign(payload jsonb, secret text, algorithm text default 'HS256') returns text as $$
    with
    header as (
        select lib.url_encode(convert_to(jsonb_build_object('alg', algorithm, 'typ', 'JWT')::text, 'utf8')) as data
    ),
    payload as (
        select lib.url_encode(convert_to(payload::text, 'utf8')) as data
    ),
    signables as (
        select header.data || '.' || payload.data as data from header, payload
    )
    select
        signables.data || '.' ||
        lib.algorithm_sign(signables.data, secret, algorithm)
    from signables;
$$ language sql strict immutable;

create or replace function lib.jwt_verify(token text, secret text, algorithm text default 'HS256') returns table(header jsonb, payload jsonb, valid boolean) as $$
    select
        jwt.header as header,
        jwt.payload as payload,
        jwt.signature_ok and tstzrange(
            to_timestamp(lib.try_cast_double(jwt.payload->>'nbf')),
            to_timestamp(lib.try_cast_double(jwt.payload->>'exp'))
        ) @> current_timestamp as valid
    from (
        select
            convert_from(lib.url_decode(r[1]), 'utf8')::jsonb as header,
            convert_from(lib.url_decode(r[2]), 'utf8')::jsonb as payload,
            r[3] = lib.algorithm_sign(r[1] || '.' || r[2], secret, algorithm) as signature_ok
        from regexp_split_to_array(token, '\.') r
    ) jwt
$$ language sql stable;
