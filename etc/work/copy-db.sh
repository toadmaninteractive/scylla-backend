#!/bin/bash

set -e

cd $(dirname $0)

test -z "$1" && ( echo "Usage: $0 TAG" >&2 && exit 2 )

set -a
. .env
set +a

test -z "${DATABASE_URL}" && ( echo "Must export DATABASE_URL first" ; exit 2 )
DATABASE_COPY_URL="${DATABASE_URL%/${DB_NAME}}/${DB_NAME}_$1"
test "${DATABASE_URL}" == "${DATABASE_COPY_URL}" && ( echo "Must export DATABASE_COPY_URL != DATABASE_URL first" ; exit 2 )

echo "drop database if exists ${DB_NAME}_$1; create database ${DB_NAME}_$1 encoding 'utf8';" | psql -d "${DATABASE_URL}"
pg_dump -c -Fc -d "${DATABASE_URL}" | pg_restore -e -d "${DATABASE_COPY_URL}"
