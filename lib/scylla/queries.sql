--------------------------------------------------------------------------------

-- name: generic_insert
-- docs: generic_insert
select result from lib.generic_insert(to_regclass(:class), :data, :options)

-- name: generic_update
-- docs: generic_update
select result from lib.generic_update(to_regclass(:class), :data, :where, :options)

-- name: generic_delete
-- docs: generic_delete
select result from lib.generic_delete(to_regclass(:class), :where, :options)

--------------------------------------------------------------------------------

-- name: get_clickhouse_instances
-- docs: get_clickhouse_instances
select * from app.clickhouse_instance where true

-- name: get_clickhouse_instance
-- docs: get_clickhouse_instance
select * from app.clickhouse_instance where coalesce(id = :id, false) or coalesce(code = :code, false)

-- name: create_clickhouse_instance
-- docs: create_clickhouse_instance
select * from jsonb_populate_recordset(null::app.clickhouse_instance, lib.generic_insert('app.clickhouse_instance', :data, '{"return": true}'::jsonb))

-- name: update_clickhouse_instance
-- docs: update_clickhouse_instance
select * from jsonb_populate_recordset(null::app.clickhouse_instance, lib.generic_update('app.clickhouse_instance', :data, :where, '{"return": true}'::jsonb))

-- name: delete_clickhouse_instance
-- docs: delete_clickhouse_instance
select * from jsonb_populate_recordset(null::app.clickhouse_instance, lib.generic_delete('app.clickhouse_instance', :where, '{"return": true}'::jsonb))

--------------------------------------------------------------------------------

-- name: get_projects
-- docs: get_projects
select * from app.project where true

-- name: get_project
-- docs: get_project
select * from app.project where coalesce(id = :id, false) or coalesce(code = :code, false)

-- name: get_project_schema_migration_count
-- docs: get_project_schema_migration_count
select count(*) from app.project_schema_migration where project_id = :project_id

-- name: create_project
-- docs: create_project
select * from jsonb_populate_recordset(null::app.project, lib.generic_insert('app.project', :data, '{"return": true}'::jsonb))

-- name: update_project
-- docs: update_project
select * from jsonb_populate_recordset(null::app.project, lib.generic_update('app.project', :data, :where, '{"return": true}'::jsonb))

-- name: delete_project
-- docs: delete_project
select * from jsonb_populate_recordset(null::app.project, lib.generic_delete('app.project', :where, '{"return": true}'::jsonb))

--------------------------------------------------------------------------------

-- name: get_project_schema_migrations
-- docs: get_project_schema_migrations
select * from app.project_schema_migration where true

-- name: get_project_schema_migration
-- docs: get_project_schema_migration
select * from app.project_schema_migration where coalesce(id = :id, false) or coalesce(code = :code, false)

-- name: create_project_schema_migration
-- docs: create_project_schema_migration
select * from jsonb_populate_recordset(null::app.project_schema_migration, lib.generic_insert('app.project_schema_migration', :data, '{"return": true}'::jsonb))

-- name: update_project_schema_migration
-- docs: update_project_schema_migration
select * from jsonb_populate_recordset(null::app.project_schema_migration, lib.generic_update('app.project_schema_migration', :data, :where, '{"return": true}'::jsonb))

-- name: delete_project_schema_migration
-- docs: delete_project_schema_migration
select * from jsonb_populate_recordset(null::app.project_schema_migration, lib.generic_delete('app.project_schema_migration', :where, '{"return": true}'::jsonb))

--------------------------------------------------------------------------------
