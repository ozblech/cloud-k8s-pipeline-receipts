import io
import pytest
from unittest.mock import patch



def test_health_ok(client, patch_external_dependencies):
    client_app, mocks, main = client
    mock_cursor = mocks["mock_cursor"]
    mock_cursor.fetchone.return_value = (1,)

    resp = client_app.get("/health")
    assert resp.status_code == 200
    assert b"OK" in resp.data

def test_upload_success(client):
    client_app, mocks, main = client
    mock_cursor = mocks["mock_cursor"]
    mock_conn = mocks["mock_conn"]

    file_content = b"Amazon\n$19.99\n2025-07-04"
    file = (io.BytesIO(file_content), 'receipt.txt')

    with patch.object(main, 's3') as mock_s3, \
         patch.object(main, 'cursor', mock_cursor), \
         patch.object(main, 'conn', mock_conn):

        response = client_app.post("/upload", content_type='multipart/form-data', data={'file': file})

        assert response.status_code == 200
        assert b"Receipt uploaded" in response.data

        mock_s3.upload_fileobj.assert_called_once()
        mock_cursor.execute.assert_called_once()
        mock_conn.commit.assert_called_once()


def test_upload_no_file(client):
    client_app, mocks, main = client
    resp = client_app.post("/upload", content_type='multipart/form-data', data={})
    assert resp.status_code == 400
    assert b"No file provided" in resp.data

def test_upload_invalid_format(client):
    client_app, mocks, main = client
    bad_content = b"Amazon\nNotANumber\nNotADate"
    file = (io.BytesIO(bad_content), 'bad.txt')

    resp = client_app.post("/upload", content_type='multipart/form-data', data={'file': file})
    assert resp.status_code == 400
    assert b"Failed to parse receipt" in resp.data

def test_list_receipts(client, patch_external_dependencies):
    client_app, mocks, main = client
    mock_cursor = patch_external_dependencies["mock_cursor"]
    mock_conn = patch_external_dependencies["mock_conn"]

    mock_cursor.fetchall.return_value = [
        (1, "receipt1.txt", "Amazon", 19.99, "2025-07-04"),
        (2, "receipt2.txt", "eBay", 30.5, "2025-07-01"),
    ]

    with patch.object(main, "cursor", mock_cursor), patch.object(main, "conn", mock_conn):
        resp = client_app.get("/receipts")

    assert resp.status_code == 200
    data = resp.get_json()
    assert data == [
        {"id": 1, "filename": "receipt1.txt", "vendor": "Amazon", "total": "19.99", "date": "2025-07-04"},
        {"id": 2, "filename": "receipt2.txt", "vendor": "eBay", "total": "30.5", "date": "2025-07-01"},
    ]