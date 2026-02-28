import pandas as pd
import holidays
from supabase import create_client, Client

# Initialize Supabase Client
supabase: Client = create_client(SUPA_URL, SUPA_KEY)
TARGET_TABLE = 'dim_date'

# Initialize Philippines Holidays
ph_holidays = holidays.PH()

# Generate Date Range
dates = pd.date_range(start='2026-01-01', end='2030-01-01')
df_date = pd.DataFrame(dates, columns=['full_date'])

# Feature Engineering for Date Dimensions
df_date['date_id'] = df_date['full_date'].dt.strftime('%Y%m%d').astype(int)
df_date['day_name'] = df_date['full_date'].dt.day_name()
df_date['month_name'] = df_date['full_date'].dt.month_name()
df_date['year'] = df_date['full_date'].dt.year
df_date['quarter'] = df_date['full_date'].dt.quarter
df_date['is_weekend'] = df_date['day_name'].isin(['Saturday', 'Sunday'])
df_date['is_holiday'] = df_date['full_date'].dt.date.apply(lambda x: x in ph_holidays)

# Convert full_date to string (ISO format) for JSON serialization
df_date['full_date'] = df_date['full_date'].dt.strftime('%Y-%m-%d')

# Select final columns to match the Supabase SQL schema exactly
df_date = df_date[['date_id', 'full_date', 'day_name', 'month_name', 'year', 'quarter', 'is_weekend', 'is_holiday']]

# Push to Supabase
api_payload = df_date.to_dict(orient='records')
response = supabase.table(TARGET_TABLE).upsert(api_payload).execute()

print(f"Successfully generated and upserted date dimensions.")