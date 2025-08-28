# My Second DBT (Data Build Tool) Project

Based on the course: [End-to-End Data Engineering Project](
https://www.linkedin.com/learning/end-to-end-data-engineering-project
),\
by [LinkedIn Learning](https://www.linkedin.com/learning).

> Note: because we added invalid FKs, this repo has an [altered dump](data/dump-big-star-db.sql.gz)
of the original dataset for education purposes only. The original data and repo's licence
can be found at: https://github.com/LinkedInLearning/end-to-end-data-engineering-project-4413618


## Architecture

The current implementation follows a classic star schema–based data warehouse architecture.
We may consider migrating to a Medallion-style approach in future iterations.


## Setup

### Prerequisites
- Python Poetry
- GNU Make
- Podman or Docker
- (Optional) Any SQL client of your choice

### Environment and dependencies
```bash
make env-setup
```

### Database and data
```bash
make db-run db-reset 
```

> Note: The `db-reset` command will drop and recreate the database, so use it with caution.

### Test dbt-DB connection
```bash
make dbt-debug
```

> Note: If you encounter connection issues, ensure that the database container is running 
> and that your connection settings in `.env` are correct.


## Run DBT

### Run models
```bash
make dbt-build
```
