create extension if not exists pgtap;

select plan(4);

-- begin;
--     select ok(
--         (select count(*) from app.clickhouse_instance) = 2,
--         'we have 2 clickhouse_instance'
--     );
--     select ok(
--         (select count(*) from app.project) = 3,
--         'we have 3 project'
--     );
--     select ok(
--         (select count(*) from app.project_schema_migration) = 3,
--         'we have 2 project_schema_migration'
--     );
-- rollback;


begin;
    insert into app.clickhouse_instance (name, code, uri, username, password) values ('  tT1 ', 'Tt1 ', 'https://foo', 'uS1 ', ' Pa1 ');
    select ok(
        exists(select * from app.clickhouse_instance where name = 'tT1' and code = 'tt1' and username = 'uS1' and password = 'Pa1' and rev = 1),
        '_101_validate_changes on insert'
    );
    update app.clickhouse_instance set (name, code, uri, username, password) = ('  tT2 ', 'Tt2 ', 'https://foo', 'uS2 ', ' Pa2 ') where code = 'tt1';
    select ok(
        exists(select * from app.clickhouse_instance where name = 'tT2' and code = 'tt2' and username = 'uS2' and password = 'Pa2' and rev = 2),
        '_101_validate_changes on update'
    );
    prepare fun1 as update app.clickhouse_instance set (rev, created_at, updated_at, uuid) = row (1, now(), now(), gen_random_uuid()) where code = 'tt2';
    select throws_ok(
        'fun1',
        'PT403', 'Can not set read-only field',
        '_100_protect_readonly_columns on update'
    );
    deallocate fun1;
    prepare fun1 as update app.clickhouse_instance set (code) = row ('a and b spaced') where code = 'tt2';
    select throws_ok(
        'fun1',
        '23514', 'new row for relation "clickhouse_instance" violates check constraint "clickhouse_instance_code_check_format"',
        'code is alphanumeric'
    );
    deallocate fun1;
rollback;

-- select finish();

drop extension if exists pgtap;
