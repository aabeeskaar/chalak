.PHONY: help run build test clean migrate-up migrate-down migrate-create docker-up docker-down

help:
	@echo "Available commands:"
	@echo "  make run           - Run the application"
	@echo "  make build         - Build the application"
	@echo "  make test          - Run tests"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make migrate-up    - Run database migrations"
	@echo "  make migrate-down  - Rollback database migrations"
	@echo "  make migrate-create NAME=<name> - Create new migration"
	@echo "  make docker-up     - Start Docker services"
	@echo "  make docker-down   - Stop Docker services"

run:
	go run cmd/api/main.go

build:
	go build -o bin/chalak-api cmd/api/main.go

test:
	go test -v -race -coverprofile=coverage.out ./...

clean:
	rm -rf bin/
	go clean

migrate-up:
	@echo "Running migrations..."
	@migrate -path migrations -database "postgres://chalak:chalak123@localhost:5432/chalak_db?sslmode=disable" up

migrate-down:
	@echo "Rolling back migrations..."
	@migrate -path migrations -database "postgres://chalak:chalak123@localhost:5432/chalak_db?sslmode=disable" down 1

migrate-create:
	@echo "Creating migration: $(NAME)"
	@migrate create -ext sql -dir migrations -seq $(NAME)

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down