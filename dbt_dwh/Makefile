# Location of virtual environment
VENV_DIR := .venv
PYTHON := $(VENV_DIR)/bin/python
PIP := $(VENV_DIR)/bin/pip
ACTIVATE := source $(VENV_DIR)/bin/activate
DBT_PROFILES_DIR := $(CURDIR)/
DB_NAME = dwh
DB_USER = postgres
DB_HOST = localhost
DB_PORT = 5432

.PHONY: all setup venv docker-up enable_pgcrypto load-data dbt-run dbt-test run-analyses dbt-docs

# 1. Full setup in order
all: venv setup docker-up enable_pgcrypto load-data dbt-run dbt-test run-analyses dbt-docs

# 2. Create virtual environment with Python 3.9.6
venv:
	@echo "Creating Python 3.9.6 virtual environment"
	python3 -m venv $(VENV_DIR)

# 3. Install Python dependencies in venv
setup: venv
	@echo "Installing dependencies into virtual env"
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

# 4. Start Docker
docker-up:
	@echo "Starting Docker"
	docker-compose up -d

enable_pgcrypto:
	@echo "Enabling pgcrypto extension"
	PGPASSWORD=postgres psql -U $(DB_USER) -h $(DB_HOST) -p $(DB_PORT) -d $(DB_NAME) -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"

# 5. Load CSVs into Postgres
load-data:
	@echo "Loading data into Postgres"
	$(PYTHON) scripts/convert_and_load.py

# 6. Run dbt models with explicit profiles directory
dbt-run:
	@echo "Running dbt models"
	DBT_PROFILES_DIR=$(DBT_PROFILES_DIR) $(VENV_DIR)/bin/dbt run

# 7. Run dbt tests with explicit profiles directory
dbt-test:
	@echo "Running dbt tests"
	DBT_PROFILES_DIR=$(DBT_PROFILES_DIR) $(VENV_DIR)/bin/dbt test

# 8. Run the analyses on postgres
run-analyses:
	@echo "Running analysis queries..."
	@for sql_file in $(shell find target/compiled/dbt_dwh/analyses -name '*.sql'); do \
		echo "Running $$sql_file..."; \
		PGPASSWORD=postgres psql -h localhost -U postgres -d dwh -f $$sql_file || exit 1; \
	done

# 9. Serve dbt docs with explicit profiles directory
dbt-docs:
	DBT_PROFILES_DIR=$(DBT_PROFILES_DIR) $(VENV_DIR)/bin/dbt docs generate
	DBT_PROFILES_DIR=$(DBT_PROFILES_DIR) $(VENV_DIR)/bin/dbt docs serve --port 8001

