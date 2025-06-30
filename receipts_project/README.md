# Receipt Processor API

This is a simple Flask application for uploading and managing receipts. It stores receipt metadata in a PostgreSQL database and the receipt files themselves in an AWS S3 bucket.

## Prerequisites

Before running the application, ensure you have the following:

*   Python 3.11
*   Access to a PostgreSQL database and an AWS S3 bucket.
*   The following environment variables must be set:
    *   `DB_CONNECTION_STRING`: The connection string for your PostgreSQL database (e.g., `dbname='receipts' host='localhost'`).
    *   `DB_USER`: Your database username.
    *   `DB_PASSWORD`: Your database password.
    *   `S3_BUCKET_NAME`: The name of your AWS S3 bucket.
    *   `S3_REGION`: The AWS region for your bucket (defaults to `us-east-1`).

## Running the Application

To start the Flask server, run the following command from the project's root directory:

```bash
python main.py
```

The application will be available at `http://localhost:5000` locally.

## API Endpoints

Here are the `curl` commands to interact with the API. These assume the application is running locally.

### 1. Upload a Receipt

Uploads a receipt file, parses it for vendor, total, and date, stores the file in S3, and saves the metadata to the database.

**Endpoint:** `POST /upload`

**Request Body:** A multipart form data request with a `file` part. The file should contain the vendor, total, and date on separate lines.

**Example:**

1.  Create a sample file named `receipt.txt`:

    ```
    My Favorite Store
    $123.45
    2023-10-27
    ```

2.  Run the `curl` command:

    ```bash
    curl -X POST -F "file=@receipt.txt" http://<hostname>:<port>/upload
    ```

### 2. List All Receipts

Retrieves a list of all receipts from the database, ordered by the most recently uploaded.

**Endpoint:** `GET /receipts`

```bash
curl http://localhost:5000/receipts
```

### 3. Health and Readiness Checks

These endpoints are for monitoring the application's status.

```bash
# Health check (verifies DB connection)
curl http://localhost:5000/health

# Readiness check (verifies app is running)
curl http://localhost:5000/ready
```

