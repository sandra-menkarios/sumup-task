# SumUp Analytics Engineering Task

This repository contains the task for SumUp.

It includes:
* A full **dbt project** with star schema layers.
* A **PostgreSQL database running via Docker**.
* Python scripts to ingest `.xlsx` files, convert them to `.csv`, and load them into the database with an ingestion timestamp.
* A **Makefile** to simplify common operations.

---

## Assumptions

- Source data comes from xlsx files.
- The project is entirely self-contained: setting up the virtual environment, Docker (Postgres), data loading, and dbt runs.
- For the sake of this task and this being a dev environment, I have hardcoded the password for the postgres DB in the makefile, but this should not be done on production.
- Transactions that occurred before a store was created have been excluded from the mart until they can be properly reviewed and validated.
- For the purposes of this task, I created scripts to upload the data manually. However, in a production environment, a proper extraction process would be implemented.
- I did not use seeds to upload the files as this approach will not be scalable for billions of rows and I would not have then used python in this task.

---

## Architecture & Design

### Schema Structure

This project follows the **star schema** approach with:

The first layer is called `raw`:
	- Here I extracted the data and placed it without any cleaning or transformations.

The second layer is called `stg`:
	- Here is the staging layer, where data types and cleaning are set.

The third layer is called `curated`:
	- Here I set up the star schema for the tables and created surrogate keys as primary keys for dim tables.

The fourth layer is called `intermediate`:
	- I set up here one table for the needed analysis, that joins the data from the curated layer.

The fifth layer is called `mart`:
	- I created here reporting tables that can be used for several analysis and also matches the requested queries for this task.
	- Note: I found some data with potential timestamp problem and placed them here in a view:
		- Data quality monitoring.

#### Dimension Tables (in `models/curated`)
- `dim_devices`: Info about each device.
- `dim_stores`: Info about each store.
- `dim_products`: Info about the products sold.
- `dim_dates`: Calendar table for time-based analytics.

#### Fact Table
- `fct_transactions`: Contains each transaction and links to the appropriate dimension keys.

---

## 🧱 Project Structure

```
.
├── analyses
│ ├── avg_days_to_first_5_transactions.sql
│ ├── avg_transacted_amount_by_typology_country.sql
│ ├── percentage_transaction_per_device_type.sql
│ ├── top_10_products_sold.sql
│ └── top_10_stores_by_transaction_amount.sql
├── dbt_packages
├── macros
├── models
│ ├── curated
│ │ ├── dim_dates.sql
│ │ ├── dim_dates.yml
│ │ ├── dim_devices.sql
│ │ ├── dim_devices.yml
│ │ ├── dim_products.sql
│ │ ├── dim_products.yml
│ │ ├── dim_stores.sql
│ │ ├── dim_stores.yml
│ │ ├── fct_transactions.sql
│ │ └── fct_transactions.yml
│ ├── documents
│ │ ├── doc_ingestion_timestamp.md
│ │ └── doc_transactions__status.md
│ ├── intermediate
│ │ ├── int_transactions__stores.sql
│ │ └── int_transactions__stores.yml
│ ├── mart
│ │ ├── mart_data__quality.sql
│ │ ├── mart_devices__transactions_amount.sql
│ │ ├── mart_devices__transactions_amount.yml
│ │ ├── mart_products__transactions_amount.sql
│ │ ├── mart_products__transactions_amount.yml
│ │ ├── mart_stores__transactions_amount.sql
│ │ └── mart_stores__transactions_amount.yml
│ ├── sources.yml
│ └── staging
│ │	├── stg_devices.sql
│ │	├── stg_devices.yml
│ │	├── stg_stores.sql
│ │	├── stg_stores.yml
│ │	├── stg_transactions.sql
│ │	└── stg_transactions.yml
├── package-lock.yml
├── packages.yml
├── scripts
│ └── convert_and_load.py
├── seeds
├── snapshots
├── target
├── tests
├── requirements.txt
├── dbt_project.yml
├── profiles.yml
├── docker-compose.yml
├── Makefile
└── README.md
```

---

## Run Project

### 🛠️ Getting Started

To set up the project locally, please follow these steps:

1. **Clone the repository**:

   ```bash
   git clone git@github.com:your-org/your-repo.git ~/projects/dbt_dwh

2. **Navigate into the project folder**:

   ```bash
   cd ~/projects/dbt_dwh
   ```

3. **Run the full setup with:**

   ```bash
   make all
   ```

   This will set up a virtual environment, run docker, convert the files and load them to Postgres and run all necessary DBT tasks, then launch dbt docs.

### Requirements:

- Please ensure you have Docker installed and use the Python3.9 version.

### Table Structure:

- Please note that since PostgreSQL is not designed as an analytical data warehouse, and its integration with dbt differs from other DWHs, I have chosen **not to partition** the tables in this project.

- In a typical analytical setup, I would partition at least the `transactions` table by the `ingestion_date` field and apply that partitioning downstream to related tables. For the remaining tables, the decision would depend on the volume and nature of daily ingested data — it may not justify partitioning, and clustering could be sufficient. However, I would still evaluate query performance to ensure clustering doesn’t introduce unnecessary overhead.

- Regarding the **intermediate** views, since they run outside of PostgreSQL, I would implement them as **materialized views**, which allows for indexing and improved performance.

- For the **curated**, I’ve added indexes on the unique keys to support efficient querying, as these tables are expected to be accessed frequently.

- Additionally, I have enforced the contract at the curated and mart level to prevent accidental schema changes — such as adding new columns — from causing incorrect or unexpected results in the reporting tables and with frequently queryed tables.


## Makefile Runs Explained

1. Create virtual environment with Python 3.9.6

2. Install Python dependencies in venv

3. Run Docker PostgreSQL and enabling pgcrypto to allow hashing

4. Convert xlsx and load them into Postgres

5. Run dbt models

6. Run dbt tests

7. Run the analyses queries

8. Generate and serve dbt docs

---

## 🛆 Scripts Explained

### `convert_and_load.py`

* User is asked for the folder path of the files, please provide through command line.
* Drops the `cvv` column (if exists).
* Converts these files from `.xlsx` to `.csv`.
* Saves `.csv` files with the same name in the same folder.
* Then calls the loading to postgres function.
* Loads each `.csv` file into `raw.<table_name>` in PostgreSQL.
* Adds an `ingested_at` column to each row (UTC timestamp).
* Handles schema creation and table truncation automatically.

---

## Sample Data Loaded

These tables will be created in the `raw` schema:

* `raw.devices`
* `raw.stores`
* `raw.transactions`

---

## Analyses Requested

- The 5 queries are located in the analyses folder.
- They are part of the makefile file.


enforcing contract and condition for the timestamp happened and created