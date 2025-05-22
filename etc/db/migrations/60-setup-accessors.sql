/*
################################################################################
## functions
################################################################################
*/

create or replace function lib.generic_insert(p_class regclass, p_data jsonb, p_options jsonb = '{}'::jsonb, out result jsonb) as $$
declare
    qry text;
    class_keys varchar[];
    field_keys text;
    i int;
    s text;
begin
    -- fetch keys relevant to the class
    select array_agg(a.attname) into class_keys from pg_attribute a where a.attrelid = p_class and a.attnum > 0 and not a.attisdropped;
    -- ensure data is array of objects
    if jsonb_typeof(p_data) != 'array' then p_data = jsonb_build_array(p_data); end if;
    -- collect relevant data keys
    with keys as (select distinct key from jsonb_array_elements(p_data) a, jsonb_object_keys(a) key)
        select string_agg(format('%I', key), ', ') into field_keys from keys where key = any(class_keys);
    -- bail out if no relevant data keys provided
    if field_keys is null then raise exception 'Data must provide at least one relevant field' using errcode = 'PT400', hint = 'argument_error'; end if;
    -- compose query text
    qry = format('insert into %s (%s)%s (select %s from jsonb_populate_recordset(null::%s, $1))',
        p_class,
        field_keys,
        case p_options->'override' when 'true' then ' overriding system value' else '' end,
        field_keys,
        p_class
    );
    -- raise notice '%', qry;
    -- run the query
    if p_options->'return' = 'true' then
        qry = format('with result as (%s returning *) select jsonb_strip_nulls(jsonb_agg(result)) from result', qry);
        execute qry using p_data into result;
    elseif p_options->'return' = '"pkey"' then
        -- https://wiki.postgresql.org/wiki/Retrieve_primary_key_columns
        select coalesce(string_agg(a.attname, ', '), 'id') into s from pg_index i inner join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any(i.indkey) where i.indrelid = p_class and indisprimary;
        qry = format('with result as (%s returning %s) select jsonb_agg(result) from result', qry, s);
        execute qry using p_data into result;
    else
        execute qry using p_data;
        get diagnostics i = row_count;
        result = to_jsonb(i);
    end if;
exception
    -- catch common data exception
    when not_null_violation or unique_violation or check_violation or foreign_key_violation or invalid_text_representation or insufficient_privilege then
        declare
            schema_name text;
            table_name text;
            column_name text;
            constraint_name text;
            detail text;
            stack text;
            entity_title text;
        begin
            get stacked diagnostics schema_name = SCHEMA_NAME, table_name = TABLE_NAME, column_name = COLUMN_NAME, constraint_name = CONSTRAINT_NAME, detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
            entity_title = initcap(regexp_replace(table_name, '_+', ' ', 'g'));
            if SQLSTATE = '23502' then -- not_null_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = format('invalid_%s', column_name), detail = stack;
            elseif SQLSTATE = '23505' then -- unique_violation
                raise exception 'Clashing %', entity_title using errcode = 'PT409', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^(?:' || table_name || '_(\w+)_key|(' || table_name || ')_pkey)$', '\1\2_already_exists')), detail = stack;
            elseif SQLSTATE = '23514' then -- check_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_check(?:_\w+)?$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '23503' then -- foreign_key_violation
                select initcap(regexp_replace(relname, '_+', ' ', 'g')) into entity_title from pg_class where oid = (select confrelid from pg_constraint where conname = constraint_name and contype = 'f' order by 1 limit 1);
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_fkey$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '22P02' then -- invalid_text_representation
                -- TODO: extract from SQLERRM == invalid input value for enum api.customer_transaction_currency_enum: "a"
                raise exception 'Invalid data' using errcode = 'PT400', hint = 'invalid_data', detail = stack;
            elseif SQLSTATE = '42501' then -- insufficient_privilege
                raise exception 'Access to % denied. You are not authorized to perform this action', entity_title using errcode = 'PT403', hint = 'forbidden', detail = stack;
            end if;
        end;
    -- -- catch generic exception
    -- when others then
    --     declare
    --         detail text;
    --         stack text;
    --     begin
    --         get stacked diagnostics detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
    --         raise exception '%', SQLERRM using errcode = 'PT500', hint = detail, detail = stack;
    --     end;
end
$$ language plpgsql strict;

/*
-- https://stackoverflow.com/questions/11740256/refactor-a-pl-pgsql-function-to-return-the-output-of-various-select-queries/11751557#11751557
create or replace function lib.generic_insert(p_class anyelement, p_data jsonb, p_options jsonb = '{}'::jsonb) returns setof anyelement as $$
declare
    qry text;
    class regclass = to_regclass(pg_typeof(p_class)::text);
    class_keys varchar[];
    field_keys text;
    i int;
    s text;
begin
    -- fetch keys relevant to the class
    select array_agg(a.attname) into class_keys from pg_attribute a where a.attrelid = class and a.attnum > 0 and not a.attisdropped;
    -- raise notice 'CLS: %', class_keys;
    -- ensure data is array of objects
    if jsonb_typeof(p_data) != 'array' then p_data = jsonb_build_array(p_data); end if;
    -- collect relevant data keys
    with keys as (select distinct key from jsonb_array_elements(p_data) a, jsonb_object_keys(a) key)
        select string_agg(format('%I', key), ', ') into field_keys from keys where key = any(class_keys);
    -- bail out if no relevant data keys provided
    if field_keys is null then raise exception 'Data must provide at least one relevant field' using errcode = 'PT400', hint = 'argument_error'; end if;
    -- compose query text
    qry = format('insert into %s (%s)%s (select %s from jsonb_populate_recordset(null::%s, $1))',
        class,
        field_keys,
        case p_options->'override' when 'true' then ' overriding system value' else '' end,
        field_keys,
        class
    );
    -- raise notice 'QRY: %', qry;
    -- run the query
    qry = format('%s returning *', qry);
    return query execute qry using p_data;
exception
    -- catch common data exception
    when not_null_violation or unique_violation or check_violation or foreign_key_violation or invalid_text_representation or insufficient_privilege then
        declare
            schema_name text;
            table_name text;
            column_name text;
            constraint_name text;
            detail text;
            stack text;
            entity_title text;
        begin
            get stacked diagnostics schema_name = SCHEMA_NAME, table_name = TABLE_NAME, column_name = COLUMN_NAME, constraint_name = CONSTRAINT_NAME, detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
            entity_title = initcap(regexp_replace(table_name, '_+', ' ', 'g'));
            if SQLSTATE = '23502' then -- not_null_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = format('invalid_%s', column_name), detail = stack;
            elseif SQLSTATE = '23505' then -- unique_violation
                raise exception 'Clashing %', entity_title using errcode = 'PT409', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^(?:' || table_name || '_(\w+)_key|(' || table_name || ')_pkey)$', '\1\2_already_exists')), detail = stack;
            elseif SQLSTATE = '23514' then -- check_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_check(?:_\w+)?$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '23503' then -- foreign_key_violation
                select initcap(regexp_replace(relname, '_+', ' ', 'g')) into entity_title from pg_class where oid = (select confrelid from pg_constraint where conname = constraint_name and contype = 'f' order by 1 limit 1);
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_fkey$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '22P02' then -- invalid_text_representation
                -- TODO: extract from SQLERRM == invalid input value for enum api.customer_transaction_currency_enum: "a"
                raise exception 'Invalid data' using errcode = 'PT400', hint = 'invalid_data', detail = stack;
            elseif SQLSTATE = '42501' then -- insufficient_privilege
                raise exception 'Access to % denied. You are not authorized to perform this action', entity_title using errcode = 'PT403', hint = 'forbidden', detail = stack;
            end if;
        end;
    -- -- catch generic exception
    -- when others then
    --     declare
    --         detail text;
    --         stack text;
    --     begin
    --         get stacked diagnostics detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
    --         raise exception '%', SQLERRM using errcode = 'PT500', hint = detail, detail = stack;
    --     end;
end
$$ language plpgsql;
*/

--------------------------------------------------------------------------------

-- TODO: limit/offset, order
create or replace function lib.generic_select(p_class regclass, p_where jsonb = '[]'::jsonb, p_options jsonb = '{}'::jsonb, out result jsonb) as $$
declare
    qry text;
    class_keys varchar[];
    where_keys text;
begin
    -- fetch keys relevant to the class
    select array_agg(a.attname) into class_keys from pg_attribute a where a.attrelid = p_class and a.attnum > 0 and not a.attisdropped;
    -- ensure filter criteria is array of objects
    if jsonb_typeof(p_where) != 'array' then p_where = jsonb_build_array(p_where); end if;
    -- collect relevant filter criteria keys
    with keys as (select distinct key from jsonb_array_elements(jsonb_strip_nulls(p_where)) a, jsonb_object_keys(a) key)
        select string_agg(format('%I', key), ', ') into where_keys from keys where key = any(class_keys);
    -- coalesce empty filter criteria
    where_keys = case when where_keys is null then 'true' else format('(%s) = any(select %s from jsonb_populate_recordset(null::%s, $1))', where_keys, where_keys, p_class) end;
    -- compose query text
    qry = format('select * from %s where %s',
        p_class,
        where_keys
    );
    qry = format('with result as (%s) select jsonb_strip_nulls(jsonb_agg(result)) from result', qry);
    -- raise notice '%', qry;
    -- run the query
    execute qry using p_where into result;
exception
    -- catch common data exception
    when not_null_violation or unique_violation or check_violation or foreign_key_violation or invalid_text_representation or insufficient_privilege then
        declare
            schema_name text;
            table_name text;
            column_name text;
            constraint_name text;
            detail text;
            stack text;
            entity_title text;
        begin
            get stacked diagnostics schema_name = SCHEMA_NAME, table_name = TABLE_NAME, column_name = COLUMN_NAME, constraint_name = CONSTRAINT_NAME, detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
            entity_title = initcap(regexp_replace(table_name, '_+', ' ', 'g'));
            if SQLSTATE = '23502' then -- not_null_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = format('invalid_%s', column_name), detail = stack;
            elseif SQLSTATE = '23505' then -- unique_violation
                raise exception 'Clashing %', entity_title using errcode = 'PT409', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^(?:' || table_name || '_(\w+)_key|(' || table_name || ')_pkey)$', '\1\2_already_exists')), detail = stack;
            elseif SQLSTATE = '23514' then -- check_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_check(?:_\w+)?$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '23503' then -- foreign_key_violation
                select initcap(regexp_replace(relname, '_+', ' ', 'g')) into entity_title from pg_class where oid = (select confrelid from pg_constraint where conname = constraint_name and contype = 'f' order by 1 limit 1);
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_fkey$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '22P02' then -- invalid_text_representation
                -- TODO: extract from SQLERRM == invalid input value for enum api.customer_transaction_currency_enum: "a"
                raise exception 'Invalid data' using errcode = 'PT400', hint = 'invalid_data', detail = stack;
            elseif SQLSTATE = '42501' then -- insufficient_privilege
                raise exception 'Access to % denied. You are not authorized to perform this action', entity_title using errcode = 'PT403', hint = 'forbidden', detail = stack;
            end if;
        end;
    -- -- catch generic exception
    -- when others then
    --     declare
    --         detail text;
    --         stack text;
    --     begin
    --         get stacked diagnostics detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
    --         raise exception '%', SQLERRM using errcode = 'PT500', hint = detail, detail = stack;
    --     end;
end
$$ language plpgsql strict stable;

--------------------------------------------------------------------------------

create or replace function lib.generic_update(p_class regclass, p_patch jsonb, p_where jsonb, p_options jsonb = '{}'::jsonb, out result jsonb) as $$
declare
    qry text;
    class_keys varchar[];
    where_keys text;
    patch_keys text;
    i int;
    s text;
begin
    -- fetch keys relevant to the class
    select array_agg(a.attname) into class_keys from pg_attribute a where a.attrelid = p_class and a.attnum > 0 and not a.attisdropped;
    -- ensure filter criteria is array of objects
    if jsonb_typeof(p_where) != 'array' then p_where = jsonb_build_array(p_where); end if;
    -- collect relevant filter criteria keys
    with keys as (select distinct key from jsonb_array_elements(jsonb_strip_nulls(p_where)) a, jsonb_object_keys(a) key)
        select string_agg(format('%I', key), ', ') into where_keys from keys where key = any(class_keys);
    -- collect relevant data keys
    if jsonb_typeof(p_patch) != 'object' then raise exception 'Data must be an object' using errcode = 'PT400', hint = 'argument_error'; end if;
    select string_agg(format('%I', key), ', ') into patch_keys from jsonb_object_keys(p_patch) key where key = any(class_keys);
    -- bail out if no relevant filter criteria provided
    if where_keys is null then raise exception 'Criteria must provide at least one relevant filter' using errcode = 'PT400', hint = 'argument_error'; end if;
    -- bail out if no relevant data keys provided
    if patch_keys is null then raise exception 'Data must provide at least one relevant field' using errcode = 'PT400', hint = 'argument_error'; end if;
    -- compose query text
    qry = format('update %s set (%s) = (select %s from jsonb_populate_record(null::%s, $1)) where (%s) = any(select %s from jsonb_populate_recordset(null::%s, $2))',
        p_class,
        patch_keys,
        patch_keys,
        p_class,
        where_keys,
        where_keys,
        p_class
    );
    -- raise notice '%', qry;
    -- run the query
    if p_options->'return' = 'true' then
        qry = format('with result as (%s returning *) select jsonb_strip_nulls(jsonb_agg(result)) from result', qry);
        execute qry using p_patch, p_where into result;
    elseif p_options->'return' = '"pkey"' then
        -- https://wiki.postgresql.org/wiki/Retrieve_primary_key_columns
        select coalesce(string_agg(a.attname, ', '), 'id') into s from pg_index i inner join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any(i.indkey) where i.indrelid = p_class and indisprimary;
        qry = format('with result as (%s returning %s) select jsonb_agg(result) from result', qry, s);
        execute qry using p_patch, p_where into result;
    else
        execute qry using p_patch, p_where;
        get diagnostics i = row_count;
        result = to_jsonb(i);
    end if;
exception
    -- catch common data exception
    when not_null_violation or unique_violation or check_violation or foreign_key_violation or invalid_text_representation or insufficient_privilege then
        declare
            schema_name text;
            table_name text;
            column_name text;
            constraint_name text;
            detail text;
            stack text;
            entity_title text;
        begin
            get stacked diagnostics schema_name = SCHEMA_NAME, table_name = TABLE_NAME, column_name = COLUMN_NAME, constraint_name = CONSTRAINT_NAME, detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
            entity_title = initcap(regexp_replace(table_name, '_+', ' ', 'g'));
            if SQLSTATE = '23502' then -- not_null_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = format('invalid_%s', column_name), detail = stack;
            elseif SQLSTATE = '23505' then -- unique_violation
                raise exception 'Clashing %', entity_title using errcode = 'PT409', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^(?:' || table_name || '_(\w+)_key|(' || table_name || ')_pkey)$', '\1\2_already_exists')), detail = stack;
            elseif SQLSTATE = '23514' then -- check_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_check(?:_\w+)?$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '23503' then -- foreign_key_violation
                select initcap(regexp_replace(relname, '_+', ' ', 'g')) into entity_title from pg_class where oid = (select confrelid from pg_constraint where conname = constraint_name and contype = 'f' order by 1 limit 1);
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_fkey$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '22P02' then -- invalid_text_representation
                -- TODO: extract from SQLERRM == invalid input value for enum api.customer_transaction_currency_enum: "a"
                raise exception 'Invalid data' using errcode = 'PT400', hint = 'invalid_data', detail = stack;
            elseif SQLSTATE = '42501' then -- insufficient_privilege
                raise exception 'Access to % denied. You are not authorized to perform this action', entity_title using errcode = 'PT403', hint = 'forbidden', detail = stack;
            end if;
        end;
    -- -- catch generic exception
    -- when others then
    --     declare
    --         detail text;
    --         stack text;
    --     begin
    --         get stacked diagnostics detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
    --         raise exception '%', SQLERRM using errcode = 'PT500', hint = detail, detail = stack;
    --     end;
end
$$ language plpgsql strict;

--------------------------------------------------------------------------------

create or replace function lib.generic_delete(p_class regclass, p_where jsonb, p_options jsonb = '{}'::jsonb, out result jsonb) as $$
declare
    qry text;
    class_keys varchar[];
    where_keys text;
    i int;
    s text;
begin
    -- fetch keys relevant to the class
    select array_agg(a.attname) into class_keys from pg_attribute a where a.attrelid = p_class and a.attnum > 0 and not a.attisdropped;
    -- ensure filter criteria is array of objects
    if jsonb_typeof(p_where) != 'array' then p_where = jsonb_build_array(p_where); end if;
    -- collect relevant filter criteria keys
    with keys as (select distinct key from jsonb_array_elements(jsonb_strip_nulls(p_where)) a, jsonb_object_keys(a) key)
        select string_agg(format('%I', key), ', ') into where_keys from keys where key = any(class_keys);
    -- bail out if no relevant filter criteria provided
    if where_keys is null then raise exception 'Criteria must provide at least one relevant filter' using errcode = 'PT400', hint = 'argument_error'; end if;
    -- compose query text
    qry = format('delete from %s where (%s) = any(select %s from jsonb_populate_recordset(null::%s, $1))',
        p_class,
        where_keys,
        where_keys,
        p_class
    );
    -- raise notice '%', qry;
    -- run the query
    if p_options->'return' = 'true' then
        qry = format('with result as (%s returning *) select jsonb_strip_nulls(jsonb_agg(result)) from result', qry);
        execute qry using p_where into result;
    elseif p_options->'return' = '"pkey"' then
        -- https://wiki.postgresql.org/wiki/Retrieve_primary_key_columns
        select coalesce(string_agg(a.attname, ', '), 'id') into s from pg_index i inner join pg_attribute a on a.attrelid = i.indrelid and a.attnum = any(i.indkey) where i.indrelid = p_class and indisprimary;
        qry = format('with result as (%s returning %s) select jsonb_agg(result) from result', qry, s);
        execute qry using p_where into result;
    else
        execute qry using p_where;
        get diagnostics i = row_count;
        result = to_jsonb(i);
    end if;
exception
    -- catch common data exception
    when not_null_violation or unique_violation or check_violation or foreign_key_violation or invalid_text_representation or insufficient_privilege then
        declare
            schema_name text;
            table_name text;
            column_name text;
            constraint_name text;
            detail text;
            stack text;
            entity_title text;
        begin
            get stacked diagnostics schema_name = SCHEMA_NAME, table_name = TABLE_NAME, column_name = COLUMN_NAME, constraint_name = CONSTRAINT_NAME, detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
            entity_title = initcap(regexp_replace(table_name, '_+', ' ', 'g'));
            if SQLSTATE = '23502' then -- not_null_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = format('invalid_%s', column_name), detail = stack;
            elseif SQLSTATE = '23505' then -- unique_violation
                raise exception 'Clashing %', entity_title using errcode = 'PT409', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^(?:' || table_name || '_(\w+)_key|(' || table_name || ')_pkey)$', '\1\2_already_exists')), detail = stack;
            elseif SQLSTATE = '23514' then -- check_violation
                raise exception 'Invalid %', entity_title using errcode = 'PT400', hint = coalesce(lib.get_constraint_comment(schema_name, table_name, constraint_name, 'error'), regexp_replace(constraint_name, '^' || table_name || '_(\w+)_check(?:_\w+)?$', 'invalid_\1')), detail = stack;
            elseif SQLSTATE = '23503' then -- foreign_key_violation
                select initcap(regexp_replace(relname, '_+', ' ', 'g')) into entity_title from pg_class where oid = (select confrelid from pg_constraint where conname = constraint_name and contype = 'f' order by 1 limit 1);
                -- NB: cascade restrict acted
                raise exception 'This % is in use', entity_title using errcode = 'PT403', hint = 'forbidden', detail = stack;
            elseif SQLSTATE = '22P02' then -- invalid_text_representation
                -- TODO: extract from SQLERRM == invalid input value for enum api.customer_transaction_currency_enum: "a"
                raise exception 'Invalid data' using errcode = 'PT400', hint = 'invalid_data', detail = stack;
            elseif SQLSTATE = '42501' then -- insufficient_privilege
                raise exception 'Insufficient privilege for %', entity_title using errcode = 'PT403', hint = 'forbidden', detail = stack;
            end if;
        end;
    -- -- catch generic exception
    -- when others then
    --     declare
    --         detail text;
    --         stack text;
    --     begin
    --         get stacked diagnostics detail = PG_EXCEPTION_DETAIL, stack = PG_EXCEPTION_CONTEXT;
    --         raise exception '%', SQLERRM using errcode = 'PT500', hint = detail, detail = stack;
    --     end;
end
$$ language plpgsql strict;

--------------------------------------------------------------------------------
