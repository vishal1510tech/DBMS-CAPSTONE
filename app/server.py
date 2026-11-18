#!/usr/bin/env python3
"""
============================================================================
Capstone Project: Intelligent Library and Digital Resource Management System
Component: app/server.py (Interactive Visual Schema & CRUD API Server)
============================================================================
Zero-dependency lightweight HTTP server serving the interactive web frontend
and providing REST API endpoints to explore schemas, run queries live, and
perform full Create, Read, Update, and Delete (CRUD) operations on database records.
"""

import os
import sys
import json
import sqlite3
import webbrowser
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, unquote

PORT = 5050
WORKSPACE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if WORKSPACE_DIR not in sys.path:
    sys.path.insert(0, WORKSPACE_DIR)
WEB_DIR = os.path.join(WORKSPACE_DIR, "web")
DB_PATH = os.path.join(WORKSPACE_DIR, "library_capstone.db")


def get_db_connection():
    if not os.path.exists(DB_PATH):
        # Automatically run test runner to build DB if not present
        from app.test_runner import main as build_db
        build_db()
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON;")
    return conn


class SchemaServerHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def do_GET(self):
        parsed = urlparse(self.path)

        # API: List all tables and counts
        if parsed.path == "/api/tables":
            self.handle_api_tables()
            return

        # API: Inspect individual table data & schema metadata
        if parsed.path.startswith("/api/table/"):
            table_name = unquote(parsed.path[len("/api/table/"):])
            self.handle_api_table_data(table_name)
            return

        # Default: Serve static files from web/
        super().do_GET()

    def do_POST(self):
        parsed = urlparse(self.path)

        # 1. API: Execute dynamic SQL query
        if parsed.path == "/api/query":
            data = self.read_json_body()
            if data is not None:
                self.handle_api_execute_query(data.get("query", "").strip())
            return

        # 2. API: Insert Record into Table
        if parsed.path.startswith("/api/table/") and parsed.path.endswith("/insert"):
            table_name = unquote(parsed.path[len("/api/table/"): -len("/insert")])
            data = self.read_json_body()
            if data is not None:
                self.handle_api_insert_record(table_name, data.get("data", {}))
            return

        # 3. API: Update Record in Table
        if parsed.path.startswith("/api/table/") and parsed.path.endswith("/update"):
            table_name = unquote(parsed.path[len("/api/table/"): -len("/update")])
            data = self.read_json_body()
            if data is not None:
                self.handle_api_update_record(table_name, data.get("keys", {}), data.get("data", {}))
            return

        # 4. API: Delete Record from Table
        if parsed.path.startswith("/api/table/") and parsed.path.endswith("/delete"):
            table_name = unquote(parsed.path[len("/api/table/"): -len("/delete")])
            data = self.read_json_body()
            if data is not None:
                self.handle_api_delete_record(table_name, data.get("keys", {}))
            return

        self.send_json_response({"error": "Endpoint not found"}, status=404)

    def do_PUT(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith("/api/table/"):
            table_name = unquote(parsed.path[len("/api/table/"):])
            data = self.read_json_body()
            if data is not None:
                self.handle_api_update_record(table_name, data.get("keys", {}), data.get("data", {}))
            return
        self.send_json_response({"error": "Endpoint not found"}, status=404)

    def do_DELETE(self):
        parsed = urlparse(self.path)
        if parsed.path.startswith("/api/table/"):
            table_name = unquote(parsed.path[len("/api/table/"):])
            data = self.read_json_body()
            if data is not None:
                self.handle_api_delete_record(table_name, data.get("keys", {}))
            return
        self.send_json_response({"error": "Endpoint not found"}, status=404)

    def read_json_body(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            return {}
        try:
            post_body = self.rfile.read(content_length).decode("utf-8")
            return json.loads(post_body)
        except Exception as e:
            self.send_json_response({"error": f"Invalid JSON payload: {e}"}, status=400)
            return None

    def handle_api_tables(self):
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
            tables = [row["name"] for row in cursor.fetchall()]
            result = []
            for t in tables:
                cursor.execute(f"SELECT COUNT(*) AS count FROM {t}")
                count = cursor.fetchone()["count"]
                result.append({"name": t, "count": count})
            conn.close()
            self.send_json_response(result)
        except Exception as e:
            import traceback
            traceback.print_exc()
            self.send_json_response({"error": str(e)}, status=500)

    def handle_api_table_data(self, table_name):
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            # Fetch detailed column metadata (name, type, notnull, default, pk)
            cursor.execute(f"PRAGMA table_info({table_name})")
            raw_cols = cursor.fetchall()

            columns = []
            column_metadata = []
            primary_keys = []

            for col in raw_cols:
                col_name = col["name"]
                columns.append(col_name)
                is_pk = bool(col["pk"])
                if is_pk:
                    primary_keys.append(col_name)
                column_metadata.append({
                    "name": col_name,
                    "type": col["type"],
                    "notnull": bool(col["notnull"]),
                    "default": col["dflt_value"],
                    "pk": col["pk"]
                })

            # Fetch rows
            cursor.execute(f"SELECT * FROM {table_name} LIMIT 200")
            rows = [list(row) for row in cursor.fetchall()]
            conn.close()

            self.send_json_response({
                "table": table_name,
                "columns": columns,
                "column_metadata": column_metadata,
                "primary_keys": primary_keys,
                "rows": rows
            })
        except Exception as e:
            self.send_json_response({"error": str(e)}, status=500)

    def handle_api_insert_record(self, table_name, row_dict):
        if not row_dict:
            self.send_json_response({"error": "No data provided for insertion."}, status=400)
            return

        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            # Filter out empty strings for nullable fields or convert None
            cleaned = {}
            for k, v in row_dict.items():
                if v == "" or v is None:
                    cleaned[k] = None
                else:
                    cleaned[k] = v

            cols = list(cleaned.keys())
            placeholders = ", ".join(["?"] * len(cols))
            col_names = ", ".join(cols)
            values = [cleaned[c] for c in cols]

            query = f"INSERT INTO {table_name} ({col_names}) VALUES ({placeholders})"
            cursor.execute(query, values)
            conn.commit()
            last_id = cursor.lastrowid
            conn.close()

            self.send_json_response({
                "success": True,
                "message": f"Successfully inserted record into {table_name}.",
                "inserted_id": last_id
            })
        except Exception as e:
            self.send_json_response({"error": f"Database constraint error: {str(e)}"}, status=400)

    def handle_api_update_record(self, table_name, keys_dict, data_dict):
        if not keys_dict or not data_dict:
            self.send_json_response({"error": "Missing primary keys or update data."}, status=400)
            return

        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            # Clean update values
            cleaned = {}
            for k, v in data_dict.items():
                if v == "":
                    cleaned[k] = None
                else:
                    cleaned[k] = v

            set_clause = ", ".join([f"{k} = ?" for k in cleaned.keys()])
            where_clause = " AND ".join([f"{k} = ?" for k in keys_dict.keys()])

            values = list(cleaned.values()) + list(keys_dict.values())
            query = f"UPDATE {table_name} SET {set_clause} WHERE {where_clause}"

            cursor.execute(query, values)
            conn.commit()
            rows_affected = cursor.rowcount
            conn.close()

            self.send_json_response({
                "success": True,
                "message": f"Successfully updated record in {table_name}.",
                "rows_affected": rows_affected
            })
        except Exception as e:
            self.send_json_response({"error": f"Database update error: {str(e)}"}, status=400)

    def handle_api_delete_record(self, table_name, keys_dict):
        if not keys_dict:
            self.send_json_response({"error": "Primary key required for deletion."}, status=400)
            return

        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            where_clause = " AND ".join([f"{k} = ?" for k in keys_dict.keys()])
            values = list(keys_dict.values())
            query = f"DELETE FROM {table_name} WHERE {where_clause}"

            cursor.execute(query, values)
            conn.commit()
            rows_affected = cursor.rowcount
            conn.close()

            self.send_json_response({
                "success": True,
                "message": f"Successfully deleted record from {table_name}.",
                "rows_affected": rows_affected
            })
        except Exception as e:
            self.send_json_response({"error": f"Database deletion error: {str(e)}"}, status=400)

    def handle_api_execute_query(self, query):
        if not query:
            self.send_json_response({"error": "Empty SQL query provided."}, status=400)
            return

        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            cursor.execute(query)

            # Fetch results if query returns rows (SELECT, WITH, PRAGMA)
            if cursor.description:
                columns = [desc[0] for desc in cursor.description]
                rows = [list(row) for row in cursor.fetchall()]
                conn.close()
                self.send_json_response({
                    "columns": columns,
                    "rows": rows
                })
            else:
                conn.commit()
                conn.close()
                self.send_json_response({
                    "columns": ["Status"],
                    "rows": [["Query executed successfully (no rows returned)."]]
                })
        except Exception as e:
            self.send_json_response({"error": str(e)}, status=400)

    def send_json_response(self, data, status=200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()


def run_server():
    server_address = ("127.0.0.1", PORT)
    httpd = HTTPServer(server_address, SchemaServerHandler)
    url = f"http://127.0.0.1:{PORT}/"
    print("\n" + "=" * 78)
    print("  ILDRMS INTERACTIVE VISUAL SCHEMA & CRUD EXPLORER")
    print("=" * 78)
    print(f"  [OK] Server running at: {url}")
    print(f"  [OK] Database file   : {DB_PATH}")
    print(f"  [OK] Web Directory   : {WEB_DIR}")
    print("  [OK] CRUD API Enabled: INSERT, UPDATE, DELETE, SELECT")
    print("  Press Ctrl+C to stop the server.\n")

    # Open web browser automatically
    try:
        webbrowser.open(url)
    except Exception:
        pass

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n  [OK] Server shut down gracefully.")
        httpd.server_close()


if __name__ == "__main__":
    run_server()
