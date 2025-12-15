#!/bin/bash

set -e

cd $(dirname $0)

set -a
. .env
set +a

PSQL=psql
PG_DUMP=pg_dump

TS=`date +%Y-%m-%d_%H-%M-%S`
HEAD=`git ls-remote -qh "$BACKEND_REPO" $BACKEND_BRANCH 2>/dev/null | awk '{print substr($1, 1, 10); nextfile}'`
BUILD=_builds/build-$HEAD

mkdir -p $BUILD

_backup_db() {
    $PG_DUMP -c -Fc "${DATABASE_URL}" > build/db-${DB_NAME}-${TS}.dump
    (
        echo "SET session_replication_role = 'replica';"
        $PG_DUMP \
            --no-sync \
            --data-only \
            --inserts \
            --rows-per-insert=1000000 \
            --column-inserts \
            --on-conflict-do-nothing \
            --no-owner \
            --no-unlogged-table-data \
            --exclude-schema=graphile_migrate \
            --exclude-schema=graphile_worker \
            --exclude-schema=public \
            --file=- "${DATABASE_URL}"
        echo "SET session_replication_role = 'origin';"
    ) > build/db-${DB_NAME}-${TS}-data.sql
}

_restore_db() {
    test $# -lt 1 && echo "Specify database dump file to restrore from" >&2 && exit 2
    $PSQL -1 -d "${DATABASE_URL}" <"$1"
}

_reset_db() {
    make db-reset -C $BUILD/src
}

_migrate_db() {
    make db-migrate -C $BUILD/src
}

_pull() {
    rm -rf $BUILD/src
    git clone --depth 1 --single-branch --branch $BACKEND_BRANCH "$BACKEND_REPO" $BUILD/src
}

_set_env() {
    if test -s "$HOME/.kiex/scripts/kiex"; then
        test -f /usr/local/erlang/$ERLANG_OTP_VERSION/activate && . /usr/local/erlang/$ERLANG_OTP_VERSION/activate
        . $HOME/.kiex/scripts/kiex
        . $HOME/.kiex/elixirs/elixir-$ELIXIR_VERSION.env
    fi
}

_build_new() {
    _set_env
    make deps release install ENV=prod DESTDIR=../server -C $BUILD/src
}

_switch_build() {
    rm -f build
    ln -sf $BUILD build
}

init() {
    _pull
    _set_env
    make init deps all install ENV=prod DESTDIR=../server -C $BUILD/src
    _reset_db
}

rebuild() {
    _pull
    _build_new
    _backup_db
    stop
#CURR=`( cd build/src && ( git rev-parse HEAD | awk '{print substr($1, 1, 10); nextfile}' ) || echo 'HEAD' )`
#if ( cd $BUILD/src && git diff --name-only HEAD $CURR | grep -q etc/db ); then
#echo 'NB: SQL migration needed!'
#_reset_db
#ls -1 build/db-${DB_NAME}-*-data.sql | tail -1
#_restore_db $(ls -1 build/db-${DB_NAME}-*-data.sql | tail -1)
#fi
    _switch_build
    _migrate_db
    start
    _backup_db
}

rebuild_nopull() {
    _build_new
    _backup_db
    stop
    _switch_build
    _migrate_db
    start
    _backup_db
}

stop() {
    sudo systemctl stop ${SYS}@${FOLDER}
}

start() {
    sudo systemctl start ${SYS}@${FOLDER}
}

restart() {
    sudo systemctl restart ${SYS}@${FOLDER}
}

_usage() {
    echo "Usage: $0 {init|rebuild|rebuild_nopull|start|stop|restart}" >&2 && exit 2
}

test $# -lt 1 && _usage
case "$1" in
    init|rebuild|rebuild_nopull|start|stop|restart) $1 ;;
    migrate) _migrate_db ;;
    reset) _reset_db ;;
    backup_db) _backup_db ;;
    restore_db) shift ; _restore_db $@ ;;
    *) _usage ;;
esac
