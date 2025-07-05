import pytest
from unittest.mock import MagicMock, patch

@pytest.fixture
def patch_external_dependencies():
    with patch("boto3.client") as mock_boto_client, \
         patch("psycopg2.connect") as mock_connect:

        mock_s3 = MagicMock()
        mock_boto_client.return_value = mock_s3

        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn

        yield {
            "mock_s3": mock_s3,
            "mock_conn": mock_conn,
            "mock_cursor": mock_cursor,
        }

@pytest.fixture
def client(patch_external_dependencies):
    import receipts_project.main as main  # Delayed import ensures boto3/psycopg2 are patched
    main.app.config["TESTING"] = True
    return main.app.test_client(), patch_external_dependencies, main