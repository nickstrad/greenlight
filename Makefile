include .env

###########
# Helpers
###########
## help: print this help message
.PHONY: help
help:
	@echo "Usage:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^//'

.PHONY: helper/confirm
helper/confirm:
	@echo -n "Are you sure? [y/N]" && read ans && [ $${ans:-N} = y ]

###########
# Dev
###########
## api/run: run the cmd/api app
.PHONY: api/run
api/run:
	go run ./cmd/api \
	-db-dsn="postgres://movienite:secret_pwd@localhost/movienite?sslmode=disable" \
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
.PHONY: db/login
db/login:
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


.PHONY: db/migrations/force
db/migrations/force:
	@echo "Forcing db version for ${version}..."
	migrate -path migrations/ -database ${MOVIENITE_DB_DSN} force ${version}

##################
# Quality Control
##################

## audit: tidy dependencies and format, vet, and test all code
.PHONY: audit
audit: vendor
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

.PHONY: vendor
vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo "Vendoring dependencies..."
	go mod vendor