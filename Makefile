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
	@go run ./cmd/api \
	-db-dsn="postgres://movienite:${MOVIENITE_POSTGRES_DB_PASSWORD}@localhost/movienite?sslmode=disable" \
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
force/db/migrations/:
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


##################
# Build
##################
.PHONY: api/build
api/build:
	@echo 'Building cmd/api...'
	go build -ldflags='-s' -o=./bin/api ./cmd/api 
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o=./bin/linux_amd64/api ./cmd/api

#############
# Production
#############
production_host_ip = '144.126.208.178'
.PHONY: production/view/logs
production/view/logs:
	ssh -t movienite@${production_host_ip} "sudo journalctl -u api"

.PHONY: production/view/metrics
production/view/metrics:
	ssh -t movienite@${production_host_ip} "curl http://localhost:4000/debug/vars"

.PHONY: production/connect
production/connect:
	ssh movienite@${production_host_ip}


.PHONY: production/deploy/api
production/deploy/api:
	rsync -P ./bin/linux_amd64/api movienite@${production_host_ip}:~
	rsync -rP --delete ./migrations movienite@${production_host_ip}:~
	rsync -P ./remote/production/api.service movienite@${production_host_ip}:~
	rsync -P ./remote/production/Caddyfile movienite@${production_host_ip}:~
	ssh -t movienite@${production_host_ip} '\
		migrate -path ~/migrations -database $$MOVIENITE_DB_DSN up \
        && sudo mv ~/api.service /etc/systemd/system/ \
        && sudo systemctl enable api \
        && sudo systemctl restart api \
        && sudo mv ~/Caddyfile /etc/caddy/ \
        && sudo systemctl reload caddy \
	'