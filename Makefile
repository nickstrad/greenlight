include .env

## help: print this help message
.PHONY: help
help:
	@echo "Usage:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^//'

.PHONY: helper/confirm
helper/confirm:
	@echo -n "Are you sure? [y/N]" && read ans && [ $${ans:-N} = y ]

## api/run: run the cmd/api app
.PHONY: api/run
api/run:
	@go run ./cmd/api \
	-db-dsn="postgres://movienite:pa55word@localhost/movienite?sslmode=disable" \
	-smtp-port=${MOVIENITE_SMTP_PORT} \
	-smtp-host=${MOVIENITE_SMTP_HOST} \
	-smtp-username=${MOVIENITE_SMTP_USERNAME} \
	-smtp-password=${MOVIENITE_SMTP_PASSWORD} \
	-smtp-sender='${MOVIENITE_SMTP_SENDER}'

## db/run: run the database
.PHONY: db/run
db/run:
	@/opt/homebrew/opt/postgresql@14/bin/postgres -D /opt/homebrew/var/postgresql@14

## db/run: login to the database
.PHONY: db/login/psql
db/login/psql:
	psql ${MOVIENITE_DB_DSN}

## db/migrations/new: create a new set of migration files
.PHONY: db/migrations/new
db/migrations/new:
	@echo "Creating migration files for ${name}..."
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migrations/up: Migrate database up to latest migration files
.PHONY: db/migrations/up
db/migrations/up: helper/confirm
	@echo "Running db up migrations..."
	migrate -path ./migrations -database ${MOVIENITE_DB_DSN} up

## db/migrations/up: Migrate database down through all migrations
.PHONY: db/migrations/down
db/migrations/down: helper/confirm
	@echo "Running db down migrations..."
	migrate -path ./migrations -database ${MOVIENITE_DB_DSN} down