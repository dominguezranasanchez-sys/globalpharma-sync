# GlobalPharmaSync — Database Management UI

A full-stack database management system built to demonstrate Oracle 21c database design and REST API skills. The pharmacy domain was chosen to showcase complex real-world scenarios such as multi-branch inventory, business logic triggers, composite primary keys, and deferred constraints.

> **Note:** This is a portfolio project. The pharmacy data and company name are fictional examples used to illustrate database architecture skills.

---

## Tech Stack

| Layer    | Technology                        |
|----------|-----------------------------------|
| Database | Oracle 21c (XE)                   |
| Backend  | Python 3.x · Flask · python-oracledb |
| Frontend | HTML5 · CSS3 · Vanilla JavaScript |

---

## Database Highlights

- **13 normalized tables** structured in strict dependency hierarchy
- **Deferred foreign key constraints** to support complex transactional inserts
- **UUID-based primary keys** (NVARCHAR2 36) across all entities
- **Business logic triggers:**
  - Inventory auto-deduction on sale
  - Inventory recovery on sale cancellation
  - Stock restoration on approved returns
  - Immutable PK protection triggers
- **Composite PKs** on pivot tables (INVENTARIO, DETALLE_VENTA, DETALLE_TRASPASO, DETALLE_DEVOLUCION)

---

## Schema Overview

```
SUCURSAL ──< EMPLEADO
         ──< CLIENTE
         ──< INVENTARIO >── PRODUCTO
         ──< TRASPASO (origin / destination)

CLIENTE ──< VENTA ──< DETALLE_VENTA >── PRODUCTO
                  ──< PAGO
                  ──< DEVOLUCION ──< DETALLE_DEVOLUCION
```

---

## How to Run

### 1. Prerequisites

- Oracle 21c XE installed and running
- Python 3.9+
- Install dependencies:

```bash
pip install flask flask-cors python-oracledb
```

### 2. Set environment variables

```bash
# Windows
set DB_USER=system
set DB_PASS=your_password
set DB_DSN=localhost:1521/XE

# macOS / Linux
export DB_USER=system
export DB_PASS=your_password
export DB_DSN=localhost:1521/XE
```

### 3. Load the schema

Run `database_schema.sql` in SQL*Plus or SQL Developer against your Oracle XE instance.

### 4. Start the backend

```bash
cd backend
python app.py
```

### 5. Open the frontend

Open `frontend/index.html` directly in your browser. The UI connects to `http://localhost:5000/api`.

---

## Project Structure

```
GlobalPharmaSync_EN/
├── backend/
│   └── app.py              # Flask REST API (generic CRUD + catalog endpoints)
├── frontend/
│   ├── index.html          # Single-page shell
│   ├── app.js              # Dynamic UI engine (field-driven CRUD)
│   ├── styles.css          # Styles
│   └── images/
│       └── logo.png
└── database_schema.sql     # Full Oracle DDL: tables, constraints, triggers
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/catalogos` | Load all FK dropdown data |
| GET | `/api/crud/<table>` | List records (supports `?q=search`) |
| POST | `/api/crud/<table>` | Insert a new record |
| PUT | `/api/crud/<table>?pks=col` | Update a record by PK |
| DELETE | `/api/crud/<table>?pks=col&vals=val` | Delete a record by PK |

---

## Author

**René Domínguez Sánchez**  
Systems Engineering Student — Instituto Tecnológico de Puebla  
ID: 22220893
