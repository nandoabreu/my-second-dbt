.PHONY: status orchestration

ifneq (,$(wildcard .env))
  # Needs to be space-indented
  include .env
  export $(shell cut -d= -f1 .env)
endif

DB_HOST ?= "127.0.0.1"
DB_PORT ?= 3306
DB_USER ?= "dbt_user"
DB_PASS ?= "dbt_pass"
DB_SCHEMA_SRC ?= "src"
DBT_MODE ?= "prod"


SHELL := $(shell command -v bash 2>/dev/null || command -v zsh)
CONTAINER_ENGINE := $(shell command -v podman 2>/dev/null || command -v docker)
VIRTUAL_ENV ?= $(shell poetry env info -p 2>/dev/null || find . -type d -name '*venv' -exec realpath {} \;)
PROJECT_DIR := $(shell realpath .)
DBT_CMD_EXTRA_PARAMS := "--project-dir \"${DBT_PROJECT_DIR}\" --profiles-dir \"${DBT_PROFILES_DIR}\""

REFRESH :=
ifeq ($(DBT_MODE),dev)
  # Needs to be space-indented
  REFRESH := "--full-refresh"
endif

status:
	@echo "Makefile shell: ${SHELL}"
	@echo "Source DB: $(shell echo "\$$DB_SCHEMA_SRC @ \$$DB_HOST:\$$DB_PORT")"  # Test .env export
	@echo "Container engine: ${CONTAINER_ENGINE}"
	@echo "DBT project root dir: ${DBT_PROJECT_DIR}"  # Test Makefile export
	@echo "DBT Profiles: $(shell echo "\$$DBT_PROFILES_DIR")"  # Test Makefile export
	@echo "DBT refresh mode: ${DBT_MODE} (${REFRESH})"
	@echo "Project's virtual env: ${VIRTUAL_ENV}"
	@echo "Airflow home: $(shell poetry run echo "\$$AIRFLOW_HOME")"

env-setup:
	@poetry install --no-root

db-run:
	@${CONTAINER_ENGINE} stop dbt-mysql >/dev/null 2>&1 && sleep 3 || true
	@${CONTAINER_ENGINE} run -d --rm --name dbt-mysql -p "${DB_PORT}:3306" \
		-e MYSQL_ROOT_PASSWORD="${MYSQL_ADM_PASS}" \
		docker.io/library/mysql:5.7 \
		--explicit_defaults_for_timestamp=1 --secure-file-priv= \
		&& sleep 9  # Wait for MySQL to start

db-reset:
	@${CONTAINER_ENGINE} exec -t dbt-mysql bash -c "MYSQL_PWD=${MYSQL_ADM_PASS} mysql -e \" \
		SET GLOBAL sql_mode = 'NO_AUTO_CREATE_USER'; \
		SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER'; \
		DROP DATABASE IF EXISTS ${DB_SCHEMA_SRC}; CREATE DATABASE ${DB_SCHEMA_SRC}; \
		DROP DATABASE IF EXISTS ${DB_SCHEMA_STG}; CREATE DATABASE ${DB_SCHEMA_STG}; \
		DROP DATABASE IF EXISTS ${DB_SCHEMA_MART}; CREATE DATABASE ${DB_SCHEMA_MART}; \
		DROP DATABASE IF EXISTS delayed_data; CREATE DATABASE delayed_data; \
		CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}'; \
		GRANT ALL PRIVILEGES ON ${DB_SCHEMA_SRC}.* TO '${DB_USER}'@'%'; \
		GRANT ALL PRIVILEGES ON ${DB_SCHEMA_STG}.* TO '${DB_USER}'@'%'; \
		GRANT ALL PRIVILEGES ON ${DB_SCHEMA_MART}.* TO '${DB_USER}'@'%'; \
		GRANT ALL PRIVILEGES ON delayed_data.* TO '${DB_USER}'@'%'; \
		GRANT FILE ON *.* TO '${DB_USER}'@'%'; \
		FLUSH PRIVILEGES; \
	\""
	@${CONTAINER_ENGINE} exec -t dbt-mysql rm -rf "/data"; \
		${CONTAINER_ENGINE} exec -t dbt-mysql mkdir "/data"; \
		${CONTAINER_ENGINE} cp data dbt-mysql:/
	@${CONTAINER_ENGINE} exec -t -w /data dbt-mysql bash -c "gunzip *gz"
	@echo "$(shell date +%T) Load data (may take ~55 seconds)"
	@${CONTAINER_ENGINE} exec -t -w /data dbt-mysql bash -c "cat *sql | MYSQL_PWD="${MYSQL_ADM_PASS}" mysql ${DB_SCHEMA_SRC}"

dbt-debug:  # Validate DB conn
	@eval poetry run dbt debug ${DBT_CMD_EXTRA_PARAMS}

dbt-compile:  # Jinja > SQL
	@poetry run dbt compile --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-lineage:
	@eval poetry run dbt ls ${DBT_CMD_EXTRA_PARAMS}

dbt-docs:
	@eval poetry run dbt docs generate ${DBT_CMD_EXTRA_PARAMS}
	@eval poetry run dbt docs serve ${DBT_CMD_EXTRA_PARAMS} --port 8080  # --debug

dbt-load-csvs:  # dbt seed
	@eval poetry run dbt seed ${DBT_CMD_EXTRA_PARAMS} ${REFRESH}

dbt-run-only-stg:
	@eval poetry run dbt run ${DBT_CMD_EXTRA_PARAMS} --select tag:stg ${REFRESH}

dbt-run:
	@poetry run dbt run --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-test:  # Test models after build/run
	@poetry run dbt test --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-build:  # Full prod pipeline: run (update) > seed > snapshot > test
	@poetry run dbt build --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-source-freshness:
	@poetry run dbt source freshness --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-clean:
	@poetry run dbt clean --project-dir "${DBT_PROJECT_DIR}"


airflow-migrate:
	@poetry run airflow db migrate
	@poetry run airflow users create --role Admin \
		--username ${AIRFLOW_ROOT_USER} --password ${AIRFLOW_ROOT_PASS} \
		--firstname "Airflow" --lastname "Admin" --email none

airflow-ui:
	@poetry run airflow webserver

orchestration:
#	@poetry run dagster dev --working-directory . --module-name orchestration
	@#poetry run astro dev start  # Astronomer > Airflow
