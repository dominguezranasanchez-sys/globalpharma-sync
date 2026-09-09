# GlobalPharmaSync — Interfaz de Gestión de Base de Datos

*Read this in [English](README.md).*

Sistema full-stack de gestión de base de datos construido para demostrar habilidades de diseño en Oracle 21c y desarrollo de API REST. Se eligió el dominio de una farmacia para mostrar escenarios reales complejos como inventario multi-sucursal, triggers de lógica de negocio, llaves primarias compuestas y restricciones diferidas.

> **Nota:** Este es un proyecto de portafolio. Los datos de la farmacia y el nombre de la empresa son ejemplos ficticios usados para ilustrar habilidades de arquitectura de bases de datos.

---

## Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Base de datos | Oracle 21c (XE) |
| Backend | Python 3.x · Flask · python-oracledb |
| Frontend | HTML5 · CSS3 · JavaScript Vanilla |

---

## Aspectos Destacados de la Base de Datos

- **13 tablas normalizadas** estructuradas en una jerarquía estricta de dependencias
- **Restricciones de llave foránea diferidas** para soportar inserciones transaccionales complejas
- **Llaves primarias basadas en UUID** (NVARCHAR2 36) en todas las entidades
- **Triggers de lógica de negocio:**
  * Deducción automática de inventario al vender
  * Recuperación de inventario al cancelar una venta
  * Restauración de stock en devoluciones aprobadas
  * Triggers de protección de llaves primarias inmutables
- **Llaves primarias compuestas** en tablas pivote (INVENTARIO, DETALLE_VENTA, DETALLE_TRASPASO, DETALLE_DEVOLUCION)

---

## Resumen del Esquema

```
SUCURSAL ──< EMPLEADO
         ──< CLIENTE
         ──< INVENTARIO >── PRODUCTO
         ──< TRASPASO (origen / destino)

CLIENTE ──< VENTA ──< DETALLE_VENTA >── PRODUCTO
                  ──< PAGO
                  ──< DEVOLUCION ──< DETALLE_DEVOLUCION
```

---

## Cómo Ejecutarlo

### 1. Requisitos previos

- Oracle 21c XE instalado y en ejecución
- Python 3.9+
- Instalar dependencias:

```bash
pip install flask flask-cors python-oracledb
```

### 2. Configurar variables de entorno

```bash
# Windows
set DB_USER=system
set DB_PASS=tu_contraseña
set DB_DSN=localhost:1521/XE

# macOS / Linux
export DB_USER=system
export DB_PASS=tu_contraseña
export DB_DSN=localhost:1521/XE
```

### 3. Cargar el esquema

Ejecuta `database_schema.sql` en SQL*Plus o SQL Developer contra tu instancia de Oracle XE.

### 4. Iniciar el backend

```bash
cd backend
python app.py
```

### 5. Abrir el frontend

Abre `frontend/index.html` directamente en tu navegador. La interfaz se conecta a `http://localhost:5000/api`.

---

## Estructura del Proyecto

```
GlobalPharmaSync_EN/
├── backend/
│   └── app.py              # API REST en Flask (CRUD genérico + endpoints de catálogos)
├── frontend/
│   ├── index.html          # Shell de página única
│   ├── app.js               # Motor de UI dinámico (CRUD dirigido por campos)
│   ├── styles.css           # Estilos
│   └── images/
│       └── logo.png
└── database_schema.sql     # DDL completo de Oracle: tablas, restricciones, triggers
```

---

## Endpoints de la API

| Método | Endpoint | Descripción |
|---|---|---|
| GET | `/api/catalogos` | Carga todos los datos de dropdowns de llaves foráneas |
| GET | `/api/crud/<table>` | Lista registros (soporta `?q=busqueda`) |
| POST | `/api/crud/<table>` | Inserta un nuevo registro |
| PUT | `/api/crud/<table>?pks=col` | Actualiza un registro por llave primaria |
| DELETE | `/api/crud/<table>?pks=col&vals=val` | Elimina un registro por llave primaria |

---

## Autor

**René Domínguez Sánchez**
Estudiante de Ingeniería en Sistemas Computacionales — Instituto Tecnológico de Puebla
Matrícula: 22220893
