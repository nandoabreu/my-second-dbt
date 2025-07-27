.PHONY: status orchestration

ifneq (,$(wildcard .env))
  # Needs to be space-indented
  include .env
  export $(shell cut -d= -f1 .env)
endif

DB_HOST ?= "127.0.0.1"
DB_PORT ?= 5432
DB_USER ?= "postgres"
DB_PASS ?= "mysecretpassword"
DB_NAME ?= "big-star-db"


SHELL := $(shell which zsh || which bash)
PROJECT_DIR := $(shell realpath .)


status:
	@echo "Makefile shell: ${SHELL}"
	@echo "Source DB: $(shell echo "\$$DB_NAME @ \$$DB_HOST:\$$DB_PORT")"  # Test .env export
	@echo "DBT project root dir: ${DBT_PROJECT_DIR}"  # Test Makefile export
	@echo "DBT Profiles: $(shell echo "\$$DBT_PROFILES_DIR")"  # Test Makefile export
	@echo "Airflow home: $(shell poetry run echo "\$$AIRFLOW_HOME")"

env-setup:
	@poetry install --no-root --with dev,orchestrators

source-db-run:
	@podman run -d --rm --name dbt-db -p 5432:5432 \
		docker.io/lilearningproject/big-star-postgres-multi \
		-c "wal_level=logical"

db-reset-and-mess-data:
	@dump="data/dump-big-star-db.sql"; (gunzip -c "$$dump" || cat "$$dump") \
		| PGPASSWORD="${DB_PASS}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -v ON_ERROR_STOP=1


dbt-debug:  # Validate confs
	@poetry run dbt debug --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-compile:  # Jinja > SQL
	@poetry run dbt compile --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-lineage:
	@poetry run dbt ls --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-docs:
	@poetry run dbt docs generate --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"
	@poetry run dbt docs serve --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}" --host 0.0.0.0 --port 8081

dbt-load-csvs:  # dbt seed
	@poetry run dbt seed --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

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
