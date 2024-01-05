MAKEFLAGS += --silent

APP ?= app

all: up test
	echo ""
	$(MAKE) status
	echo ""
	echo "* Frontend: http://localhost:8080"
	echo ""

up:
	docker-compose up --remove-orphans -d
	sleep 1

%:
	DOCKER_BUILDKIT=1 docker-compose up --build --force-recreate --no-color $@ -d

psql:
	docker exec -it db psql -h localhost -U postgres -d example

status:
	docker-compose ps -a

healthcheck:
	docker inspect $(APP) --format "{{ (index (.State.Health.Log) 0).Output }}"

test:
	[ -f ./tests/test.sh ] && ./tests/test.sh || true

clean:
	docker-compose down --remove-orphans -v --rmi local
