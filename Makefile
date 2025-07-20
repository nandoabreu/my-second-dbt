.PHONY: status orchestration

ifneq (,$(wildcard .env))
  # Needs to be space-indented
  include .env
  export $(shell cut -d= -f1 .env)
endif

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
	@podman pull docker.io/lilearningproject/big-star-postgres-multi
	@podman run -d --rm --name dbt2-source -p 5432:5432 \
		docker.io/lilearningproject/big-star-postgres-multi \
		-c "wal_level=logical"


dbt-debug:  # Validate confs
	@poetry run dbt debug --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-compile:  # Jinja > SQL
	@poetry run dbt compile --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-docs:
	@poetry run dbt docs generate --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"
	@poetry run dbt docs serve --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

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
	@poetry run dagster dev --working-directory . --module-name orchestration
