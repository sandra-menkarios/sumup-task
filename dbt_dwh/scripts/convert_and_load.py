import psycopg2
import openpyxl
import csv
import tempfile
from pathlib import Path
from datetime import datetime


def convert_all_xlsx_in_folder(folder_path):
    folder = Path(folder_path)
    csv_paths = {}

    for xlsx_file in folder.glob("*.xlsx"):
        wb = openpyxl.load_workbook(xlsx_file, data_only=True)
        ws = wb.active

        csv_file = folder / f"{xlsx_file.stem}.csv"
        with open(csv_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f, quoting=csv.QUOTE_ALL)
            rows = list(ws.iter_rows(values_only=True))
            if not rows:
                 return  # or handle empty sheet
            header = list(rows[0])
            drop_index = header.index('cvv') if 'cvv' in header else None
            if drop_index is not None:
                 header.pop(drop_index)
            writer.writerow(header)
            for row in rows[1:]:
                row = list(row)
                if drop_index is not None and drop_index < len(row):
                    row.pop(drop_index)
                writer.writerow(row)

        print(f"Converted: {xlsx_file.name} → {csv_file.name}")
        csv_paths[xlsx_file.stem.lower()] = csv_file
    return csv_paths

def load_csv_with_ingestion_ts(csv_path, table_name, conn_params):

    ingestion_time = datetime.utcnow().isoformat()
    conn = psycopg2.connect(**conn_params)
    cur = conn.cursor()

    # Ensure schema exists
    cur.execute("CREATE SCHEMA IF NOT EXISTS raw")

    # Read and extend CSV
    with open(csv_path, 'r', encoding='utf-8') as orig_file, tempfile.NamedTemporaryFile(mode='w+', newline='', delete=False, encoding='utf-8') as tmp_file:
        reader = csv.DictReader(orig_file)
        fieldnames = reader.fieldnames + ['ingested_at']

        # Recreate table with all TEXT columns
        columns_sql = ', '.join([f'"{col}" TEXT' for col in fieldnames])
        cur.execute(f'CREATE TABLE IF NOT EXISTS raw.{table_name} ({columns_sql})')
        cur.execute(f'TRUNCATE TABLE raw.{table_name}')

        # Write updated rows with ingestion timestamp
        writer = csv.DictWriter(tmp_file, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        for row in reader:
            # Defensive copy to ensure all fields match
            new_row = {col: row.get(col, '') for col in reader.fieldnames}
            new_row['ingested_at'] = ingestion_time
            writer.writerow(new_row)

        tmp_file_path = tmp_file.name

    # Now load into Postgres
    with open(tmp_file_path, 'r', encoding='utf-8') as f:
         cur.copy_expert(
			sql=f"""COPY raw.{table_name}
					FROM STDIN
					WITH (
						FORMAT CSV,
						HEADER TRUE,
						QUOTE '"'
					)""",
			file=f
    )

    conn.commit()
    cur.close()
    conn.close()
    print(f"\nLoaded {table_name} with ingested_at = {ingestion_time}")

if __name__ == "__main__":
    folder_input = Path(input("Enter the folder path containing .xlsx files: ").strip())
    folder_path = Path(folder_input)
    csv_files = convert_all_xlsx_in_folder(folder_input)

    conn_params = {
        "host": "localhost",
        "port": 5432,
        "database": "dwh",
        "user": "postgres",
        "password": "postgres"
    }
    for table, path in csv_files.items():
        print(f"Loading {table} from {path}...")
        load_csv_with_ingestion_ts(path, table, conn_params)

    print("All done.")
