# # test_main.py
# import pytest
# from unittest.mock import patch, MagicMock
# from receipts_project import get_app
# import receipts_project.main as main_module  # 👈 Explicit module
# import io


# @pytest.fixture
# def client():
#     with patch("psycopg2.connect") as mock_connect:
#         mock_conn = MagicMock()
#         mock_cursor = MagicMock()
#         mock_conn.cursor.return_value = mock_cursor
#         mock_connect.return_value = mock_conn

#         app = get_app()  # ⬅ lazy import happens *after* patch
#         app.config['TESTING'] = True

#         return app.test_client(), mock_cursor, mock_conn, app

# def test_health_ok(client):
#     client_app, mock_cursor, _, _ = client
#     mock_cursor.fetchone.return_value = (1,)
#     resp = client_app.get("/health")
#     assert resp.status_code == 200
#     assert b"OK" in resp.data


# def test_upload_success(client):
#     client_app, mock_cursor, mock_conn, main = client
#     file_content = b"Amazon\n$19.99\n2025-07-04"
#     file = (io.BytesIO(file_content), 'receipt.txt')

#     with patch.object(main.s3, 'upload_fileobj') as mock_upload:
#         resp = client_app.post("/upload", content_type='multipart/form-data', data={'file': file})

#         assert resp.status_code == 200
#         assert b"Receipt uploaded" in resp.data
#         mock_upload.assert_called_once()
        
#         # mock_cursor.execute.assert()
#         # mock_conn.commit.assert_called_once()


# def test_upload_no_file(client):
#     client_app, *_ = client
#     resp = client_app.post("/upload", content_type='multipart/form-data', data={})
#     assert resp.status_code == 400
#     assert b"No file provided" in resp.data


# def test_upload_invalid_format(client):
#     client_app, *_ = client
#     # Bad format: not a float, and invalid date
#     bad_content = b"Amazon\nNotANumber\nNotADate"
#     file = (io.BytesIO(bad_content), 'bad.txt')

#     resp = client_app.post("/upload", content_type='multipart/form-data', data={'file': file})
#     assert resp.status_code == 400
#     assert b"Failed to parse receipt" in resp.data


# def test_list_receipts(client):
#     client_app, mock_cursor, *_ = client
    
#     mock_cursor.execute.return_value = None
#     mock_cursor.fetchall.return_value = [
#         (1, "receipt1.txt", "Amazon", 19.99, "2025-07-04"),
#         (2, "receipt2.txt", "eBay", 30.5, "2025-07-01"),
#     ]

#     resp = client_app.get("/receipts")
#     assert resp.status_code == 200
#     data = resp.get_json()
#     assert data == [
#         {"id": 1, "filename": "receipt1.txt", "vendor": "Amazon", "total": "19.99", "date": "2025-07-04"},
#         {"id": 2, "filename": "receipt2.txt", "vendor": "eBay", "total": "30.5", "date": "2025-07-01"},
#     ]

#     mock_cursor.execute.assert_called_once_with(
#         "SELECT id, filename, vendor, total, purchase_date FROM receipts ORDER BY uploaded_at DESC"
#     )

