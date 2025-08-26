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


### 🔑 OIDC-based IAM Role

* Normally, to let GitHub Actions talk to AWS, you’d have to store long-lived AWS access keys in your repo (bad practice).

* Instead, with OIDC (OpenID Connect), GitHub’s workflow identity can request a short-lived AWS IAM role at runtime.

* In AWS IAM, you create a role with a trust policy that allows GitHub’s OIDC provider (token.actions.githubusercontent.com) to assume it, but only for:

    * Your repo name

    * Specific environments/branches

* This gives temporary credentials to the workflow, scoped only to what’s needed.

✅ In your project:
You used the OIDC role to call AWS APIs directly from GitHub Actions — e.g., to fetch the EC2 public IP via the DescribeInstances API.

### 🖥️ AWS SSM (Systems Manager)

* Normally, to run commands on EC2, you’d need SSH keys and open port 22.

* With SSM Agent installed on EC2 + proper IAM role attached, you can run commands securely without opening SSH.

* You use the AWS CLI:

```bash
aws ssm send-command \
  --targets "Key=instanceIds,Values=<EC2-ID>" \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy app" \
  --parameters 'commands=["docker ps"]'
```

SSM executes the command inside the EC2 and returns the output back to you.

✅ In your project:

* OIDC gave GitHub Actions the ability to call ssm:SendCommand (no stored keys).

* SSM executed deployment/maintenance commands on EC2.

* You didn’t need SSH keys or open inbound ports, which is a big security win.

### 🔗 Putting It Together

1. GitHub Actions requests an OIDC token → exchanges it for AWS IAM Role creds.

2. Workflow uses creds to query EC2 public IP.

3. Workflow sends commands via SSM to that EC2 for deployments.

4. No long-lived credentials, no SSH, all secured through IAM + SSM.

👉 This is a modern, secure DevOps pattern — combining OIDC for short-lived access + SSM for remote execution.
If asked in an interview, you can emphasize that you eliminated:

* Hardcoded AWS keys

* Open SSH ports

* Manual access to servers

