from os import getenv

from dagster_dbt import DbtCliResource

resources = {
    "dbt": DbtCliResource(
        project_dir=getenv("DBT_PROJECT_DIR"),
        profiles_dir=getenv("DBT_PROFILES_DIR"),
    ),
}
