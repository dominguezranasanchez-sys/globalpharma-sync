# GlobalPharmaSync — Database Management UI

*Leer esto en [Español](README.es.md).*

A full-stack CRUD application built on top of a relational schema designed for a fictional multi-branch pharmacy chain. The project's main goal is to demonstrate solid **Oracle database design** and **REST API** skills: normalized tables, composite keys, deferred constraints, and trigger-based business logic — wired up to a working web UI.

> **Portfolio project.** The pharmacy name and data are fictional, used purely to illustrate a realistic multi-branch inventory/sales domain.

---

## Table of Contents

- [What this demonstrates](#what-this-demonstrates)
- [Tech Stack](#tech-stack)
- [Database Design](#database-design)
- [Schema Overview](#schema-overview)
- [Getting Started](#getting-started)
- [API Reference](#api-reference)
- [Project Structure](#project-structure)
- [Known Limitations](#known-limitations)
- [Roadmap](#roadmap)
- [Author](#author)

---

## What This Demonstrates

- **Relational modeling**: 13 normalized tables with a clear dependency hierarchy (branches → employees/clients/inventory → sales/returns/transfers).
- **Data integrity by design**: composite primary keys on pivot tables, deferred foreign key constraints for multi-step transactional inserts, and immutable-PK protection triggers.
- **Business logic in the database**: triggers handle inventory deduction on sale, inventory recovery on cancellation, and stock restoration on approved returns — instead of relying solely on application-layer logic.
- **A generic CRUD backend**: a single Flask API (`/api/crud/<table>`) drives create/read/update/delete for any table, with a frontend that renders forms dynamically based on field metadata rather than hardcoding a page per entity.

---

## Tech Stack

| Layer    | Technology                           |
| -------- | ------------------------------------ |
| Database | Oracle 21c (XE)                      |
| Backend  | Python 3.x · Flask · python-oracledb |
| Frontend | HTML5 · CSS3 · Vanilla JavaScript    |

---

## Database Design

- **13 normalized tables** structured in a strict dependency hierarchy
- **Deferred foreign key constraints** to support complex transactional inserts
- **UUID-based primary keys** (`NVARCHAR2(36)`) across all entities
- **Triggers:**
  - Inventory auto-deduction on sale
  - Inventory recovery on sale cancellation
  - Stock restoration on approved returns
  - Immutable PK protection
- **Composite PKs** on pivot tables (`INVENTARIO`, `DETALLE_VENTA`, `DETALLE_TRASPASO`, `DETALLE_DEVOLUCION`)

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

## Getting Started

### Prerequisites

- Oracle 21c XE installed and running
- Python 3.9+

### 1. Install dependencies

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

## API Reference

| Method | Endpoint                             | Description                         |
| ------ | ------------------------------------ | ------------------------------------ |
| GET    | `/api/catalogos`                     | Load all FK dropdown data           |
| GET    | `/api/crud/<table>`                  | List records (supports `?q=search`) |
| POST   | `/api/crud/<table>`                  | Insert a new record                 |
| PUT    | `/api/crud/<table>?pks=col`          | Update a record by PK               |
| DELETE | `/api/crud/<table>?pks=col&vals=val` | Delete a record by PK               |

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

## Known Limitations

This is a portfolio piece, not a production system. Notably missing:

- No authentication / authorization layer on the API
- No automated tests
- No input validation/sanitization beyond what the DB constraints enforce
- Single-instance Flask dev server (no WSGI/production deployment config)

## Roadmap

- [ ] Add JWT-based auth and role-based access (admin / branch employee)
- [ ] Add unit tests for CRUD endpoints
- [ ] Containerize with Docker Compose (app + Oracle XE)
- [ ] Add basic input validation on the API layer

---

## Author

**René Domínguez Sánchez**
Systems Engineering Student — Instituto Tecnológico de Puebla
