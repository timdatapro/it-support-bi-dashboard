"""
Load translated support tickets into PostgreSQL.
Run after executing create_schema.sql in DBeaver.

Requirements:
    pip install pandas openpyxl psycopg2-binary
"""

import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

# -- Connection ------------------------------------------------
DB_CONFIG = {
    "host":     "localhost",
    "port":     5432,
    "dbname":   "edtech_support",
    "user":     "postgres",
    "password": "password",
}

XLSX_PATH = r"C:\Temp\support_tickets_en.xlsx"

# -- Load Excel ------------------------------------------------
print("Reading Excel...")
df = pd.read_excel(XLSX_PATH, sheet_name="tickets")
print(f"  Rows loaded: {len(df)}")

# -- Fix boolean columns ---------------------------------------
# Handles: True/False, TRUE/FALSE, 1.0/0.0, 1/0, NaN
def to_bool_nullable(val):
    if pd.isna(val):
        return None
    if isinstance(val, bool):
        return val
    if isinstance(val, (int, float)):
        return bool(int(val))
    s = str(val).strip().upper()
    if s == "TRUE" or s == "1":
        return True
    if s == "FALSE" or s == "0":
        return False
    return None

def to_bool_notnull(val):
    result = to_bool_nullable(val)
    return result if result is not None else False

df["is_sla_breached"] = df["is_sla_breached"].apply(to_bool_nullable)
df["is_first_contact_resolution"] = df["is_first_contact_resolution"].apply(to_bool_notnull)

# -- Fix NOT NULL string columns -------------------------------
for col in ["employee_name", "employee_department", "agent_name",
            "category_name", "priority_id", "project_name"]:
    df[col] = df[col].fillna("Unknown")

# -- Fix timestamp columns -------------------------------------
for col in ["created_at", "resolved_at", "closed_at"]:
    df[col] = pd.to_datetime(df[col], errors="coerce")

# -- Replace remaining NaN/NaT with None -----------------------
def clean_val(x):
    if x is None:
        return None
    if isinstance(x, float) and pd.isna(x):
        return None
    try:
        if pd.isnull(x):
            return None
    except (TypeError, ValueError):
        pass
    return x

# -- Validate before insert ------------------------------------
print("\nPre-insert validation:")
print(f"  Null ticket_id:       {df['ticket_id'].isna().sum()}")
print(f"  Null status:          {df['status'].isna().sum()}")
print(f"  Null priority_id:     {df['priority_id'].isna().sum()}")
print(f"  Null project_name:    {df['project_name'].isna().sum()}")
print(f"  Null is_fcr:          {df['is_first_contact_resolution'].isna().sum()}")
print(f"  Null is_sla_breached: {df['is_sla_breached'].isna().sum()}")
print(f"\n  is_sla_breached distribution:")
print(df.groupby(['status', 'is_sla_breached'], dropna=False).size().to_string())

# -- Build records ---------------------------------------------
cols = [
    "ticket_id", "created_at", "resolved_at", "closed_at", "hours",
    "status", "employee_name", "employee_department", "agent_name",
    "category_name", "priority_id", "sla_target_hours",
    "is_sla_breached", "is_first_contact_resolution",
    "original_ticket_id", "project_name"
]

records = [
    tuple(clean_val(v) for v in row)
    for row in df[cols].itertuples(index=False, name=None)
]

insert_sql = f"""
    INSERT INTO public.support_tickets ({', '.join(cols)})
    VALUES %s
    ON CONFLICT (ticket_id) DO NOTHING
"""

# -- Insert ----------------------------------------------------
print("\nConnecting to PostgreSQL...")
conn = psycopg2.connect(**DB_CONFIG)
cur  = conn.cursor()

print("Inserting rows...")
execute_values(cur, insert_sql, records, page_size=500)
conn.commit()

cur.execute("SELECT COUNT(*) FROM public.support_tickets")
count = cur.fetchone()[0]
print(f"\n  Rows in table: {count}")
print(f"  Expected:      2672")
print(f"  Match:         {'YES' if count == 2672 else 'NO - check for errors'}")

# -- Verify is_sla_breached in DB ------------------------------
cur.execute("""
    SELECT status, is_sla_breached, COUNT(*) as cnt
    FROM public.support_tickets
    GROUP BY status, is_sla_breached
    ORDER BY status, is_sla_breached
""")
print("\n  is_sla_breached in DB:")
for row in cur.fetchall():
    print(f"    {row[0]:25} | {str(row[1]):5} | {row[2]}")

cur.close()
conn.close()
print("\nDone.")
