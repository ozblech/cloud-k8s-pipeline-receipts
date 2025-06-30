import os
import boto3
import psycopg2
from flask import Flask, request, jsonify
from datetime import datetime
from werkzeug.utils import secure_filename

app = Flask(__name__)

# Environment variables
DB_CONN = os.getenv("DB_CONNECTION_STRING")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
S3_BUCKET = os.getenv("S3_BUCKET_NAME")
S3_REGION = os.getenv("S3_REGION", "us-east-1")

# DB Connection
conn = psycopg2.connect(DB_CONN, user=DB_USER, password=DB_PASSWORD)
cursor = conn.cursor()

# S3 client
s3 = boto3.client(
    "s3",
    region_name=S3_REGION,
)

@app.route("/upload", methods=["POST"])
def upload_receipt():
    file = request.files.get("file")
    if not file:
        return "No file provided", 400

    filename = secure_filename(file.filename)
    lines = file.read().decode().splitlines()

    try:
        vendor = lines[0].strip()
        total = float(lines[1].strip().replace("$", ""))
        date = datetime.strptime(lines[2].strip(), "%Y-%m-%d")
    except Exception as e:
        return f"Failed to parse receipt: {e}", 400

    # Upload file to S3
    file.seek(0)
    s3.upload_fileobj(file, S3_BUCKET, filename)

    # Insert into DB
    cursor.execute(
        """
        INSERT INTO receipts (filename, vendor, total, purchase_date)
        VALUES (%s, %s, %s, %s)
        """,
        (filename, vendor, total, date),
    )
    conn.commit()

    return "Receipt uploaded", 200

@app.route("/receipts", methods=["GET"])
def list_receipts():
    cursor.execute("SELECT id, filename, vendor, total, purchase_date FROM receipts ORDER BY uploaded_at DESC")
    rows = cursor.fetchall()
    return jsonify([
        {"id": r[0], "filename": r[1], "vendor": r[2], "total": str(r[3]), "date": str(r[4])}
        for r in rows
    ])

@app.route("/health", methods=["GET"])
def health():
    # test connection to db
    try:
        cursor.execute("SELECT 1")
        result = cursor.fetchone()
    except Exception as e:
        return f"Failed to connect to DB: {e}", 500

@app.route("/ready", methods=["GET"])
def ready():
    return "Ready", 200
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
