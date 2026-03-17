import pandas as pd
import sqlite3
import os

df = pd.read_csv('data/Sample - Superstore.csv', encoding='latin-1')

df.columns = [c.lower().replace(' ', '_').replace('-', '_') for c in df.columns]

print("Columns:", df.columns.tolist())
print("Shape:", df.shape)

os.makedirs('database', exist_ok=True)
conn = sqlite3.connect('database/sales.db')
df.to_sql('orders', conn, if_exists='replace', index=False)
conn.close()

print("✓ Loaded successfully into database/sales.db")