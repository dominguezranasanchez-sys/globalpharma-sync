# GlobalPharmaSync — Sistema de Gestión de Base de Datos

*Read this in [English](README.md).*

Una aplicación full-stack de tipo CRUD construida sobre un esquema relacional diseñado para una cadena de farmacias ficticia con múltiples sucursales. El objetivo principal del proyecto es demostrar buenas habilidades de **diseño de bases de datos en Oracle** y de **APIs REST**: tablas normalizadas, llaves compuestas, restricciones diferidas y lógica de negocio basada en triggers — todo conectado a una interfaz web funcional.

> **Proyecto de portafolio.** El nombre y los datos de la farmacia son ficticios, usados únicamente para ilustrar un dominio realista de inventario y ventas multi-sucursal.

---

## Índice

- [Qué demuestra este proyecto](#qué-demuestra-este-proyecto)
- [Stack Tecnológico](#stack-tecnológico)
- [Diseño de la Base de Datos](#diseño-de-la-base-de-datos)
- [Resumen del Esquema](#resumen-del-esquema)
- [Cómo Empezar](#cómo-empezar)
- [Referencia de la API](#referencia-de-la-api)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Limitaciones Conocidas](#limitaciones-conocidas)
- [Roadmap](#roadmap)
- [Autor](#autor)

---

## Qué Demuestra Este Proyecto

- **Modelado relacional**: 13 tablas normalizadas con una jerarquía de dependencias clara (sucursales → empleados/clientes/inventario → ventas/devoluciones/traspasos).
- **Integridad de datos por diseño**: llaves primarias compuestas en tablas pivote, restricciones de llave foránea diferidas para inserciones transaccionales de varios pasos, y triggers de protección de llaves primarias inmutables.
- **Lógica de negocio en la base de datos**: los triggers manejan la deducción automática de inventario en cada venta, la recuperación de inventario al cancelar una venta, y la restauración de stock en devoluciones aprobadas — en lugar de depender únicamente de la lógica en la capa de aplicación.
- **Un backend CRUD genérico**: una sola API en Flask (`/api/crud/<table>`) maneja crear/leer/actualizar/eliminar para cualquier tabla, con un frontend que genera los formularios dinámicamente a partir de metadatos de los campos, en vez de tener una página codificada por cada entidad.

---

## Stack Tecnológico

| Capa          | Tecnología                           |
| ------------- | ------------------------------------ |
| Base de datos | Oracle 21c (XE)                      |
| Backend       | Python 3.x · Flask · python-oracledb |
| Frontend      | HTML5 · CSS3 · JavaScript puro       |

---

## Diseño de la Base de Datos

- **13 tablas normalizadas** estructuradas en una jerarquía de dependencias estricta
- **Restricciones de llave foránea diferidas** para soportar inserciones transaccionales complejas
- **Llaves primarias basadas en UUID** (`NVARCHAR2(36)`) en todas las entidades
- **Triggers:**
  - Deducción automática de inventario en cada venta
  - Recuperación de inventario al cancelar una venta
  - Restauración de stock en devoluciones aprobadas
  - Protección de llaves primarias inmutables
- **Llaves primarias compuestas** en tablas pivote (`INVENTARIO`, `DETALLE_VENTA`, `DETALLE_TRASPASO`, `DETALLE_DEVOLUCION`)

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

## Cómo Empezar

### Prerrequisitos

- Oracle 21c XE instalado y corriendo
- Python 3.9+

### 1. Instalar dependencias

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

## Referencia de la API

| Método | Endpoint                             | Descripción                                  |
| ------ | ------------------------------------ | --------------------------------------------- |
| GET    | `/api/catalogos`                     | Carga los datos de todos los dropdowns de FK |
| GET    | `/api/crud/<table>`                  | Lista registros (soporta `?q=busqueda`)      |
| POST   | `/api/crud/<table>`                  | Inserta un nuevo registro                    |
| PUT    | `/api/crud/<table>?pks=col`          | Actualiza un registro por su PK              |
| DELETE | `/api/crud/<table>?pks=col&vals=val` | Elimina un registro por su PK                |

---

## Estructura del Proyecto

```
GlobalPharmaSync_EN/
├── backend/
│   └── app.py              # API REST en Flask (CRUD genérico + endpoints de catálogos)
├── frontend/
│   ├── index.html          # Shell de página única
│   ├── app.js              # Motor de UI dinámico (CRUD basado en campos)
│   ├── styles.css          # Estilos
│   └── images/
│       └── logo.png
└── database_schema.sql     # DDL completo de Oracle: tablas, restricciones, triggers
```

---

## Limitaciones Conocidas

Este es un proyecto de portafolio, no un sistema en producción. Notablemente le falta:

- Capa de autenticación / autorización en la API
- Pruebas automatizadas
- Validación/saneamiento de entradas más allá de lo que imponen las restricciones de la base de datos
- Servidor de desarrollo Flask de instancia única (sin configuración de despliegue WSGI/producción)

## Roadmap

- [ ] Agregar autenticación basada en JWT y acceso por roles (admin / empleado de sucursal)
- [ ] Agregar pruebas unitarias para los endpoints CRUD
- [ ] Contenerizar con Docker Compose (app + Oracle XE)
- [ ] Agregar validación básica de entradas en la capa de la API

---

## Autor

**René Domínguez Sánchez**
Estudiante de Ingeniería en Sistemas Computacionales — Instituto Tecnológico de Puebla
