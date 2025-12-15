--! Previous: sha1:be0ca89c8cae1d66f540db7837ed99d7ca51018f
--! Hash: sha1:c4230622368362a0e040b063b12b474aeee45ea2

--! split: 1-current.sql
--------------------------------------------------------------------------------
-- app.project
--------------------------------------------------------------------------------

do $$ begin create type app.project_event_validation_enum as enum ('strict', 'none', 'warn'); exception when duplicate_object then null; end $$;

alter table if exists app.project
    alter column event_validation drop default,
    alter column event_validation type text using case event_validation::text when 'true' then 'strict' else 'none' end,
    alter column event_validation set default 'strict'::app.project_event_validation_enum;

alter table if exists app.project
    alter column event_validation type app.project_event_validation_enum using event_validation::app.project_event_validation_enum;

--------------------------------------------------------------------------------
