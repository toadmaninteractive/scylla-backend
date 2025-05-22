-include .env
export $(shell sed 's/=.*//' .env)

DESTDIR := server
RELEASE := server
ENV 		?= prod

all: release

init: prerequisites deps
	MIX_ENV=$(ENV) mix do ecto.setup

prerequisites:
	MIX_ENV=$(ENV) mix local.prerequisites

deps:
	MIX_ENV=$(ENV) mix deps.get

clean:
	MIX_ENV=$(ENV) mix clean
	#rm -rf _build $(DESTDIR) deps .elixir_ls

release:
	MIX_ENV=$(ENV) mix release $(RELEASE) --force --overwrite

db-init:
	( cd etc/db && graphile-migrate run --rootDatabase migrations/00-init.sql && graphile-migrate reset --erase )

db-dump:
	#( cd etc/db && scripts/dump )
	( cd etc/db && graphile-migrate migrate && graphile-migrate reset --shadow --erase && graphile-migrate migrate --shadow --forceActions )

db-migrate:
	( cd etc/db && graphile-migrate migrate )

# NB: development only
db-reset:
	( cd etc/db && graphile-migrate reset --erase )

# NB: development only
db-watch:
	( cd etc/db && graphile-migrate watch )
# NB: development only
db-commit:
	( cd etc/db && graphile-migrate commit )
# NB: development only
db-uncommit:
	( cd etc/db && graphile-migrate uncommit )

api:
	postgrest

install:
	mkdir -p $(DESTDIR)
	cp -Rf _build/$(ENV)/rel/$(RELEASE)/* $(DESTDIR)/

dev: deps
	MIX_ENV=dev iex --sname '$(SYS)-$(FOLDER)' --vm-args rel/vm.args.eex -S mix

log: deps
	journalctl -f -o short-iso-precise CONTAINER_NAME=toad-db

.PHONY: all api clean deps dev init install log prerequisites release db-init db-reset db-migrate db-watch db-commit db-uncommit
.SILENT:
