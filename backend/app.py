import os
import oracledb
import urllib.request
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# ==========================================
# ALLOWED TABLES (security whitelist)
# ==========================================
ALLOWED_TABLES = {
    "SUCURSAL", "EMPLEADO", "CLIENTE", "PRODUCTO",
    "INVENTARIO", "VENTA", "DETALLE_VENTA", "PAGO",
    "DEVOLUCION", "DETALLE_DEVOLUCION", "TRASPASO",
    "DETALLE_TRASPASO", "UNIDAD_LOGISTICA"
}

# ==========================================
# DB CONNECTION (Oracle 21c — Local VM)
# ==========================================
def get_db_connection():
    try:
        # Set DB_USER, DB_PASS, DB_DSN as environment variables before running
        return oracledb.connect(
            user=os.getenv("DB_USER", "system"),
            password=os.getenv("DB_PASS", ""),
            dsn=os.getenv("DB_DSN", "localhost:1521/XE")
        )
    except Exception as e:
        print(f"Critical connection error: {e}")
        return None

# ==========================================
# API ROUTES
# ==========================================
@app.route('/api/catalogos', methods=['GET'])
def get_catalogos():
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection error"}), 500
    cursor = conn.cursor()
    data = {}
    try:
        cursor.execute("SELECT id_sucursal, nombre FROM SUCURSAL")
        data['sucursales'] = [{"id": r[0], "texto": f"{r[1]} ({r[0]})"} for r in cursor.fetchall()]

        cursor.execute("SELECT id_empleado, nombre_completo FROM EMPLEADO")
        data['empleados'] = [{"id": r[0], "texto": f"{r[1]} ({r[0]})"} for r in cursor.fetchall()]

        cursor.execute("SELECT id_cliente, nombre_completo FROM CLIENTE")
        data['clientes'] = [{"id": r[0], "texto": f"{r[1]} ({r[0]})"} for r in cursor.fetchall()]

        cursor.execute("SELECT id_producto, nombre FROM PRODUCTO")
        data['productos'] = [{"id": r[0], "texto": f"{r[1]} ({r[0]})"} for r in cursor.fetchall()]

        return jsonify(data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        if cursor: cursor.close()
        if conn: conn.close()


@app.route('/api/crud/<table_name>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def generic_crud(table_name):
    table = table_name.upper()

    # Security: only allow known tables
    if table not in ALLOWED_TABLES:
        return jsonify({"error": f"Table '{table}' is not allowed."}), 403

    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Connection error"}), 500
    cursor = conn.cursor()

    try:
        cursor.execute("ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'")
        cursor.execute("ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD\"T\"HH24:MI'")

        if request.method == 'GET':
            q = request.args.get('q', '').lower()
            cursor.execute(f"SELECT * FROM {table}")
            columns = [col[0].lower() for col in cursor.description]
            result = []
            for row in cursor.fetchall():
                row_dict = dict(zip(columns, row))
                for k, v in row_dict.items():
                    if hasattr(v, 'strftime'):
                        row_dict[k] = v.strftime('%Y-%m-%dT%H:%M') if len(str(v)) > 10 else v.strftime('%Y-%m-%d')
                if not q or any(q in str(val).lower() for val in row_dict.values()):
                    result.append(row_dict)
            return jsonify(result), 200

        # Must run before any write operation (POST, PUT, DELETE)
        cursor.execute("SET CONSTRAINTS ALL DEFERRED")

        if request.method == 'POST':
            data = {k: v for k, v in request.json.items() if v is not None and str(v).strip() != ''}
            sql = f"INSERT INTO {table} ({', '.join(data.keys())}) VALUES ({', '.join([':'+k for k in data.keys()])})"
            cursor.execute(sql, data)
            conn.commit()

            try: urllib.request.urlopen("http://192.168.1.171:5001/api/force_refresh", timeout=2)
            except: pass

            return jsonify({"message": "Record created successfully."}), 201

        elif request.method == 'PUT':
            payload = request.json.copy()
            bind_data = request.json.copy()
            pks = request.args.get('pks', '').split(',')

            for i, pk in enumerate(pks):
                bind_data[f"pk{i}"] = bind_data[pk]

            set_clauses = [f"{k} = :{k}" for k in payload.keys()]
            where_clauses = [f"{pk} = :pk{i}" for i, pk in enumerate(pks)]

            sql = f"UPDATE {table} SET {', '.join(set_clauses)} WHERE {' AND '.join(where_clauses)}"
            cursor.execute(sql, bind_data)
            conn.commit()

            try: urllib.request.urlopen("http://192.168.1.171:5001/api/force_refresh", timeout=2)
            except: pass

            return jsonify({"message": "Record updated successfully."}), 200

        elif request.method == 'DELETE':
            pks, pk_vals = request.args.get('pks', '').split(','), request.args.get('vals', '').split(',')
            bind_data = {f"pk{i}": pk_vals[i] for i in range(len(pks))}
            where_clauses = [f"{pk} = :pk{i}" for i, pk in enumerate(pks)]
            sql = f"DELETE FROM {table} WHERE {' AND '.join(where_clauses)}"
            cursor.execute(sql, bind_data)
            conn.commit()

            try: urllib.request.urlopen("http://192.168.1.171:5001/api/force_refresh", timeout=2)
            except: pass

            return jsonify({"message": "Record deleted successfully."}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 400
    finally:
        if cursor: cursor.close()
        if conn: conn.close()


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True, port=5000)
