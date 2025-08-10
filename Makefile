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
DB_NAME ?= "src"


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

db-run:
	@podman stop dbt-mysql >/dev/null 2>&1 && sleep 3 || true
	@podman run -d --rm --name dbt-mysql -p "${DB_PORT}:3306" \
		-e MYSQL_ROOT_PASSWORD="${MYSQL_ADM_PASS}" \
		docker.io/library/mysql:5.7 \
		--explicit_defaults_for_timestamp=1 --secure-file-priv= \
		&& sleep 9

db-reset:
	@podman exec -t dbt-mysql rm -rf "/data"; \
		podman exec -t dbt-mysql mkdir "/data"; \
		podman cp data dbt-mysql:/
	@podman exec -t dbt-mysql bash -c "MYSQL_PWD=${MYSQL_ADM_PASS} mysql -e \" \
		SET GLOBAL sql_mode = 'NO_AUTO_CREATE_USER'; \
		SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER'; \
		DROP DATABASE IF EXISTS src; CREATE DATABASE src; \
		DROP DATABASE IF EXISTS stg; CREATE DATABASE stg; \
		DROP DATABASE IF EXISTS marts; CREATE DATABASE marts; \
		CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}'; \
		GRANT ALL PRIVILEGES ON src.* TO '${DB_USER}'@'%'; \
		GRANT ALL PRIVILEGES ON stg.* TO '${DB_USER}'@'%'; \
		GRANT ALL PRIVILEGES ON marts.* TO '${DB_USER}'@'%'; \
		GRANT FILE ON *.* TO '${DB_USER}'@'%'; \
		FLUSH PRIVILEGES; \
	\""
	@podman exec -t -w /data dbt-mysql bash -c "\
		gunzip *gz; \
		cat *sql | MYSQL_PWD="${MYSQL_ADM_PASS}" mysql -h 127.0.0.1 -u root src \
	"


dbt-debug:  # Validate confs
	@poetry run dbt debug --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-compile:  # Jinja > SQL
	@poetry run dbt compile --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-lineage:
	@poetry run dbt ls --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"

dbt-docs:
	@poetry run dbt docs generate --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}"
	@poetry run dbt docs serve --project-dir "${DBT_PROJECT_DIR}" --profiles-dir "${DBT_PROFILES_DIR}" # --port 8080 --debug

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
