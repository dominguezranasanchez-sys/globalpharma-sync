
-- ==========================================================
-- PHASE 0: CLEANUP
-- ==========================================================

DROP TABLE DETALLE_TRASPASO;
DROP TABLE DETALLE_DEVOLUCION;
DROP TABLE DEVOLUCION;
DROP TABLE PAGO;
DROP TABLE DETALLE_VENTA ;
DROP TABLE TRASPASO ;
DROP TABLE VENTA ;
DROP TABLE INVENTARIO ;
DROP TABLE CLIENTE;
DROP TABLE EMPLEADO ;
DROP TABLE PRODUCTO ;
DROP TABLE UNIDAD_LOGISTICA ;
DROP TABLE SUCURSAL ;

-- ==========================================================
-- PHASE 1: TABLE CREATION (WITH INTEGRATED FOREIGN KEYS)
-- Strictly ordered by hierarchy to avoid FK errors
-- ==========================================================

-- Level 1: Root Catalogs (No dependencies)
CREATE TABLE SUCURSAL (
    id_sucursal NVARCHAR2(36) NOT NULL PRIMARY KEY,
    nombre VARCHAR2(100) NOT NULL,
    direccion VARCHAR2(200),
    region VARCHAR2(100) NOT NULL,
    pais VARCHAR2(50) NOT NULL,
    tipo VARCHAR2(20) CHECK (tipo IN ('FARMACIA', 'ALMACEN_CENTRAL'))
);

CREATE TABLE UNIDAD_LOGISTICA (
    id_unidad NVARCHAR2(36) NOT NULL PRIMARY KEY,
    matricula VARCHAR2(20) UNIQUE NOT NULL,
    capacidad_kg NUMBER(10,2)
);

CREATE TABLE PRODUCTO (
    id_producto NVARCHAR2(36) NOT NULL PRIMARY KEY,
    sku VARCHAR2(50) UNIQUE NOT NULL,
    nombre VARCHAR2(100) NOT NULL,
    descripcion VARCHAR2(255),
    precio_base NUMBER(10,2) NOT NULL,
    requiere_receta CHAR(1) DEFAULT 'N' CHECK (requiere_receta IN ('S','N'))
);

-- Level 2: Branch-dependent tables
CREATE TABLE EMPLEADO (
    id_empleado NVARCHAR2(36) NOT NULL PRIMARY KEY,
    nombre_completo VARCHAR2(150) NOT NULL,
    puesto VARCHAR2(50),
    id_sucursal NVARCHAR2(36) NOT NULL,
    activo CHAR(1) DEFAULT 'S' CHECK (activo IN ('S','N')),
    CONSTRAINT fk_emp_suc1 FOREIGN KEY (id_sucursal) REFERENCES SUCURSAL(id_sucursal) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE CLIENTE (
    id_cliente NVARCHAR2(36) NOT NULL PRIMARY KEY,
    nombre_completo VARCHAR2(150) NOT NULL,
    curp VARCHAR2(18) UNIQUE,
    fecha_nacimiento DATE,
    email VARCHAR2(100),
    id_sucursal_registro NVARCHAR2(36) NOT NULL,
    CONSTRAINT fk_cli_suc FOREIGN KEY (id_sucursal_registro) REFERENCES SUCURSAL(id_sucursal) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

-- Level 3: Transactional and pivot tables
CREATE TABLE INVENTARIO (
    id_sucursal NVARCHAR2(36) NOT NULL,
    id_producto NVARCHAR2(36) NOT NULL,
    cantidad NUMBER(10) DEFAULT 0,
    stock_minimo NUMBER(10) DEFAULT 5,
    CONSTRAINT pk_inv1 PRIMARY KEY (id_sucursal, id_producto),
    CONSTRAINT fk_inv_suc1 FOREIGN KEY (id_sucursal) REFERENCES SUCURSAL(id_sucursal) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_inv_prod FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE VENTA (
    id_venta NVARCHAR2(36) NOT NULL PRIMARY KEY,
    id_cliente NVARCHAR2(36) NOT NULL,
    id_empleado NVARCHAR2(36) NOT NULL,
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estatus VARCHAR2(20) CHECK (estatus IN ('PENDIENTE','PAGADA','ENTREGADA','CANCELADA')),
    monto_total NUMBER(12,2) DEFAULT 0,
    CONSTRAINT fk_ven_cli1 FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_ven_emp1 FOREIGN KEY (id_empleado) REFERENCES EMPLEADO(id_empleado) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE TRASPASO (
    id_traspaso NVARCHAR2(36) NOT NULL PRIMARY KEY,
    id_sucursal_origen NVARCHAR2(36) NOT NULL,
    id_sucursal_destino NVARCHAR2(36) NOT NULL,
    id_unidad NVARCHAR2(36), 
    id_empleado_responsable NVARCHAR2(36),
    fecha_salida TIMESTAMP,
    fecha_recepcion TIMESTAMP,
    estatus VARCHAR2(20) CHECK (estatus IN ('PREPARACION','TRANSITO','RECIBIDO','INCIDENCIA')),
    CONSTRAINT fk_tra_org1 FOREIGN KEY (id_sucursal_origen) REFERENCES SUCURSAL(id_sucursal) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_tra_des1 FOREIGN KEY (id_sucursal_destino) REFERENCES SUCURSAL(id_sucursal) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_tra_uni1 FOREIGN KEY (id_unidad) REFERENCES UNIDAD_LOGISTICA(id_unidad) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_tra_emp1 FOREIGN KEY (id_empleado_responsable) REFERENCES EMPLEADO(id_empleado) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

-- Nivel 4: Detalles y tablas dependientes de transacciones
CREATE TABLE DETALLE_VENTA (
    id_venta NVARCHAR2(36) NOT NULL,
    id_producto NVARCHAR2(36) NOT NULL,
    cantidad NUMBER(10) NOT NULL,
    precio_unitario NUMBER(10,2) NOT NULL,
    subtotal NUMBER(12,2) NOT NULL,
    CONSTRAINT pk_det_ven2 PRIMARY KEY (id_venta, id_producto),
    CONSTRAINT fk_dven_head2 FOREIGN KEY (id_venta) REFERENCES VENTA(id_venta) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_dven_prod2 FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE PAGO (
    id_pago NVARCHAR2(36) NOT NULL PRIMARY KEY,
    id_venta NVARCHAR2(36) NOT NULL,
    fecha_pago TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    monto NUMBER(12,2) NOT NULL,
    metodo_pago VARCHAR2(50),
    CONSTRAINT fk_pag_ven3 FOREIGN KEY (id_venta) REFERENCES VENTA(id_venta) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE DEVOLUCION (
    id_devolucion NVARCHAR2(36) NOT NULL PRIMARY KEY,
    id_venta NVARCHAR2(36) NOT NULL,
    id_empleado_autoriza NVARCHAR2(36) NOT NULL,
    fecha_devolucion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    motivo VARCHAR2(255),
    estatus VARCHAR2(20) DEFAULT 'SOLICITADA' CHECK (estatus IN ('SOLICITADA','APROBADA','RECHAZADA')),
    CONSTRAINT fk_dev_ven5 FOREIGN KEY (id_venta) REFERENCES VENTA(id_venta) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_dev_emp5 FOREIGN KEY (id_empleado_autoriza) REFERENCES EMPLEADO(id_empleado) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE DETALLE_DEVOLUCION (
    id_devolucion NVARCHAR2(36) NOT NULL,
    id_producto NVARCHAR2(36) NOT NULL,
    cantidad NUMBER(10) NOT NULL,
    CONSTRAINT pk_det_dev6 PRIMARY KEY (id_devolucion, id_producto),
    CONSTRAINT fk_ddev_head6 FOREIGN KEY (id_devolucion) REFERENCES DEVOLUCION(id_devolucion) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_ddev_prod6 FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE DETALLE_TRASPASO (
    id_traspaso NVARCHAR2(36) NOT NULL,
    id_producto NVARCHAR2(36) NOT NULL,
    cantidad_enviada NUMBER(10) NOT NULL,
    cantidad_recibida NUMBER(10) DEFAULT 0,
    CONSTRAINT pk_det_tra7 PRIMARY KEY (id_traspaso, id_producto),
    CONSTRAINT fk_dtra_head7 FOREIGN KEY (id_traspaso) REFERENCES TRASPASO(id_traspaso) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
    CONSTRAINT fk_dtra_prod7 FOREIGN KEY (id_producto) REFERENCES PRODUCTO(id_producto) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
);

-- ==========================================================
-- FASE 2: INSERCIÓN DE DATOS CORREGIDA
-- ==========================================================

-- 1. SUCURSALES (Respetando los CHECK: FARMACIA o ALMACEN_CENTRAL)
INSERT INTO SUCURSAL VALUES ('SUC-001M', 'Farmacia Central', 'Av. Reforma 100', 'Centro', 'Mexico', 'ALMACEN_CENTRAL');
INSERT INTO SUCURSAL VALUES ('SUC-002M', 'Farmacia Sur', 'Blvd. Sur 45', 'Sur', 'Mexico', 'FARMACIA');
INSERT INTO SUCURSAL VALUES ('SUC-003M', 'Farmacia Oeste', 'Camino Real 88', 'Oeste', 'Mexico', 'FARMACIA');
INSERT INTO SUCURSAL VALUES ('SUC-004M', 'Farmacia Norte', 'Av. Norte 200', 'Norte', 'Mexico', 'FARMACIA');
INSERT INTO SUCURSAL VALUES ('SUC-005M', 'Farmacia Centro Plus', 'Calle 5 de Mayo 10', 'Centro', 'Mexico', 'FARMACIA');

INSERT INTO SUCURSAL VALUES ('SUC-001C', 'North Pharmacy', '5 North Street', 'North District', 'Canada', 'FARMACIA');
INSERT INTO SUCURSAL VALUES ('SUC-002C', 'East Pharmacy', '10 East Avenue', 'East Side', 'Canada', 'FARMACIA');
INSERT INTO SUCURSAL VALUES ('SUC-003C', 'West End Drugs', '77 West Blvd', 'West End', 'Canada', 'FARMACIA');
INSERT INTO SUCURSAL VALUES ('SUC-004C', 'South Pharmacy', '22 South Street', 'South District', 'Canada', 'FARMACIA');
INSERT INTO SUCURSAL VALUES ('SUC-005C', 'Central Health Drugs', '100 Main Ave', 'Downtown', 'Canada', 'ALMACEN_CENTRAL');

-- 2. UNIDADES LOGÍSTICAS
INSERT INTO UNIDAD_LOGISTICA VALUES ('UNI-001', 'ABC-1234', 1500.00);
INSERT INTO UNIDAD_LOGISTICA VALUES ('UNI-002', 'XYZ-9876', 3000.50);
INSERT INTO UNIDAD_LOGISTICA VALUES ('UNI-003', 'LMN-4567', 1000.00);
INSERT INTO UNIDAD_LOGISTICA VALUES ('UNI-004', 'QWE-1122', 5000.00);

-- 3. PRODUCTOS (Respetando CHECK de requiere_receta: S o N)
INSERT INTO PRODUCTO VALUES ('PROD-001', 'SKU-PAR500', 'Paracetamol 500mg', 'Caja con 20 tabletas', 45.50, 'N');
INSERT INTO PRODUCTO VALUES ('PROD-002', 'SKU-AMO500', 'Amoxicilina 500mg', 'Caja con 12 cápsulas', 120.00, 'S');
INSERT INTO PRODUCTO VALUES ('PROD-003', 'SKU-IBU400', 'Ibuprofeno 400mg', 'Caja con 10 tabletas', 55.00, 'N');
INSERT INTO PRODUCTO VALUES ('PROD-004', 'SKU-LOR10', 'Loratadina 10mg', 'Caja con 10 tabletas', 35.00, 'N');
INSERT INTO PRODUCTO VALUES ('PROD-005', 'SKU-NAP250', 'Naproxeno 250mg', 'Caja con 30 tabletas', 85.00, 'N');
INSERT INTO PRODUCTO VALUES ('PROD-006', 'SKU-ASP100', 'Aspirina 100mg', 'Caja con 20 tabletas', 30.00, 'N');
INSERT INTO PRODUCTO VALUES ('PROD-007', 'SKU-VITC', 'Vitamina C', 'Frasco con 60 tabletas', 90.00, 'N');
INSERT INTO PRODUCTO VALUES ('PROD-008', 'SKU-OMEP20', 'Omeprazol 20mg', 'Caja con 14 cápsulas', 75.00, 'S');
INSERT INTO PRODUCTO VALUES ('PROD-009', 'SKU-DEXT', 'Dextromethorphan Syrup', 'Bottle 120ml', 65.00, 'N');
INSERT INTO PRODUCTO VALUES ('PROD-010', 'SKU-INSU', 'Insulin', 'Injectable vial', 350.00, 'S');

-- 4. EMPLEADOS (Asegurando que id_sucursal exista arriba)
INSERT INTO EMPLEADO VALUES ('EMP-001M', 'Juan Pérez', 'Gerente', 'SUC-001M', 'S');
INSERT INTO EMPLEADO VALUES ('EMP-002M', 'María García', 'Cajero', 'SUC-002M', 'S');
INSERT INTO EMPLEADO VALUES ('EMP-003M', 'Carlos López', 'Almacenista', 'SUC-001M', 'S');
INSERT INTO EMPLEADO VALUES ('EMP-004M', 'Luis Torres', 'Cajero', 'SUC-004M', 'S');
INSERT INTO EMPLEADO VALUES ('EMP-005M', 'Ana Martínez', 'Farmacéutica', 'SUC-005M', 'S');

INSERT INTO EMPLEADO VALUES ('EMP-001C', 'John Cook', 'General Manager', 'SUC-001C', 'S');
INSERT INTO EMPLEADO VALUES ('EMP-002C', 'Jane Smith', 'Senior Cashier', 'SUC-002C', 'S');
INSERT INTO EMPLEADO VALUES ('EMP-003C', 'Michael Brown', 'Stock Clerk', 'SUC-003C', 'S');
INSERT INTO EMPLEADO VALUES ('EMP-004C', 'Emily Davis', 'Pharmacist', 'SUC-004C', 'S');
INSERT INTO EMPLEADO VALUES ('EMP-005C', 'Chris Johnson', 'Warehouse Manager', 'SUC-005C', 'S');

-- 5. CLIENTES
INSERT INTO CLIENTE VALUES ('CLI-001M', 'Pedro Gómez', 'GOMP800101H1', TO_DATE('1980-01-01','YYYY-MM-DD'), 'pedro@email.com', 'SUC-001M');
INSERT INTO CLIENTE VALUES ('CLI-002M', 'Laura Sánchez', 'SANL850202H2', TO_DATE('1985-02-02','YYYY-MM-DD'), 'laura@email.com', 'SUC-002M');
INSERT INTO CLIENTE VALUES ('CLI-001C', 'Robert Wilson', 'WILR900303C1', TO_DATE('1990-03-03','YYYY-MM-DD'), 'robert@email.ca', 'SUC-001C');
INSERT INTO CLIENTE VALUES ('CLI-002C', 'Alice Brown', 'BROA950404C2', TO_DATE('1995-04-04','YYYY-MM-DD'), 'alice@email.ca', 'SUC-002C');

-- 6. INVENTARIO
INSERT INTO INVENTARIO VALUES ('SUC-001M', 'PROD-001', 1000, 100);
INSERT INTO INVENTARIO VALUES ('SUC-001M', 'PROD-002', 500, 50);
INSERT INTO INVENTARIO VALUES ('SUC-001C', 'PROD-003', 250, 25);
INSERT INTO INVENTARIO VALUES ('SUC-002C', 'PROD-004', 150, 15);
INSERT INTO INVENTARIO VALUES ('SUC-003C', 'PROD-001', 200, 20);

-- 7. VENTAS (El error ORA-02291 venía de aquí, ya están sincronizados los IDs)
INSERT INTO VENTA VALUES ('VEN-001M', 'CLI-001M', 'EMP-001M', CURRENT_TIMESTAMP, 'PAGADA', 91.00);
INSERT INTO VENTA VALUES ('VEN-002M', 'CLI-002M', 'EMP-002M', CURRENT_TIMESTAMP, 'PAGADA', 120.00);
INSERT INTO VENTA VALUES ('VEN-001C', 'CLI-001C', 'EMP-001C', CURRENT_TIMESTAMP, 'PAGADA', 110.00);
INSERT INTO VENTA VALUES ('VEN-002C', 'CLI-002C', 'EMP-002C', CURRENT_TIMESTAMP, 'PAGADA', 35.00);

-- 8. DETALLE VENTA (Asegurando que id_venta e id_producto existan)
INSERT INTO DETALLE_VENTA VALUES ('VEN-001M', 'PROD-001', 2, 45.50, 91.00);
INSERT INTO DETALLE_VENTA VALUES ('VEN-002M', 'PROD-002', 1, 120.00, 120.00);
INSERT INTO DETALLE_VENTA VALUES ('VEN-001C', 'PROD-003', 2, 55.00, 110.00);
INSERT INTO DETALLE_VENTA VALUES ('VEN-002C', 'PROD-004', 1, 35.00, 35.00);

-- 9. PAGOS
INSERT INTO PAGO VALUES ('PAG-001M', 'VEN-001M', CURRENT_TIMESTAMP, 91.00, 'EFECTIVO');
INSERT INTO PAGO VALUES ('PAG-002M', 'VEN-002M', CURRENT_TIMESTAMP, 120.00, 'TARJETA');
INSERT INTO PAGO VALUES ('PAG-001C', 'VEN-001C', CURRENT_TIMESTAMP, 110.00, 'CASH');
INSERT INTO PAGO VALUES ('PAG-002C', 'VEN-002C', CURRENT_TIMESTAMP, 35.00, 'CREDIT_CARD');

-- 10. TRASPASOS
INSERT INTO TRASPASO VALUES ('TRA-001M', 'SUC-001M', 'SUC-001C', 'UNI-001', 'EMP-001M', CURRENT_TIMESTAMP, NULL, 'TRANSITO');
INSERT INTO TRASPASO VALUES ('TRA-001C', 'SUC-001C', 'SUC-002C', 'UNI-002', 'EMP-001C', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'RECIBIDO');

-- 11. DETALLE TRASPASO
INSERT INTO DETALLE_TRASPASO VALUES ('TRA-001M', 'PROD-001', 100, 0);
INSERT INTO DETALLE_TRASPASO VALUES ('TRA-001C', 'PROD-003', 50, 50);

COMMIT;


-- =============================================================
--  TRIGGERS DE CASCADA - GlobalPharma Sync
--  Oracle 21c XE
--  Cubre: UPDATE en cascada de PKs + DELETE en cascada
--  NOTA: El DELETE CASCADE ya está definido en las FKs (ON DELETE CASCADE),
--        por lo que SOLO se necesitan triggers para UPDATE de PKs.
-- =============================================================


-- ─────────────────────────────────────────────────────────────
-- 1. SUCURSAL.id_sucursal → propaga a EMPLEADO, CLIENTE,
--    INVENTARIO, VENTA (via EMPLEADO/CLIENTE), TRASPASO
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_upd_sucursal_pk
AFTER UPDATE OF id_sucursal ON SUCURSAL
FOR EACH ROW
BEGIN
    IF :OLD.id_sucursal <> :NEW.id_sucursal THEN

        -- Empleados que pertenecen a esta sucursal
        UPDATE EMPLEADO
           SET id_sucursal = :NEW.id_sucursal
         WHERE id_sucursal = :OLD.id_sucursal;

        -- Clientes registrados en esta sucursal
        UPDATE CLIENTE
           SET id_sucursal_registro = :NEW.id_sucursal
         WHERE id_sucursal_registro = :OLD.id_sucursal;

        -- Inventario de la sucursal
        UPDATE INVENTARIO
           SET id_sucursal = :NEW.id_sucursal
         WHERE id_sucursal = :OLD.id_sucursal;

        -- Traspasos donde es origen
        UPDATE TRASPASO
           SET id_sucursal_origen = :NEW.id_sucursal
         WHERE id_sucursal_origen = :OLD.id_sucursal;

        -- Traspasos donde es destino
        UPDATE TRASPASO
           SET id_sucursal_destino = :NEW.id_sucursal
         WHERE id_sucursal_destino = :OLD.id_sucursal;

    END IF;
END;
/


-- ─────────────────────────────────────────────────────────────
-- 2. UNIDAD_LOGISTICA.id_unidad → propaga a TRASPASO
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_upd_unidad_pk
AFTER UPDATE OF id_unidad ON UNIDAD_LOGISTICA
FOR EACH ROW
BEGIN
    IF :OLD.id_unidad <> :NEW.id_unidad THEN

        UPDATE TRASPASO
           SET id_unidad = :NEW.id_unidad
         WHERE id_unidad = :OLD.id_unidad;

    END IF;
END;
/


-- ─────────────────────────────────────────────────────────────
-- 3. PRODUCTO.id_producto → propaga a INVENTARIO,
--    DETALLE_VENTA, DETALLE_DEVOLUCION, DETALLE_TRASPASO
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_upd_producto_pk
AFTER UPDATE OF id_producto ON PRODUCTO
FOR EACH ROW
BEGIN
    IF :OLD.id_producto <> :NEW.id_producto THEN

        UPDATE INVENTARIO
           SET id_producto = :NEW.id_producto
         WHERE id_producto = :OLD.id_producto;

        UPDATE DETALLE_VENTA
           SET id_producto = :NEW.id_producto
         WHERE id_producto = :OLD.id_producto;

        UPDATE DETALLE_DEVOLUCION
           SET id_producto = :NEW.id_producto
         WHERE id_producto = :OLD.id_producto;

        UPDATE DETALLE_TRASPASO
           SET id_producto = :NEW.id_producto
         WHERE id_producto = :OLD.id_producto;

    END IF;
END;
/


-- ─────────────────────────────────────────────────────────────
-- 4. EMPLEADO.id_empleado → propaga a VENTA, TRASPASO,
--    DEVOLUCION
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_upd_empleado_pk
AFTER UPDATE OF id_empleado ON EMPLEADO
FOR EACH ROW
BEGIN
    IF :OLD.id_empleado <> :NEW.id_empleado THEN

        UPDATE VENTA
           SET id_empleado = :NEW.id_empleado
         WHERE id_empleado = :OLD.id_empleado;

        UPDATE TRASPASO
           SET id_empleado_responsable = :NEW.id_empleado
         WHERE id_empleado_responsable = :OLD.id_empleado;

        UPDATE DEVOLUCION
           SET id_empleado_autoriza = :NEW.id_empleado
         WHERE id_empleado_autoriza = :OLD.id_empleado;

    END IF;
END;
/


-- ─────────────────────────────────────────────────────────────
-- 5. CLIENTE.id_cliente → propaga a VENTA
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_upd_cliente_pk
AFTER UPDATE OF id_cliente ON CLIENTE
FOR EACH ROW
BEGIN
    IF :OLD.id_cliente <> :NEW.id_cliente THEN

        UPDATE VENTA
           SET id_cliente = :NEW.id_cliente
         WHERE id_cliente = :OLD.id_cliente;

    END IF;
END;
/


-- ─────────────────────────────────────────────────────────────
-- 6. VENTA.id_venta → propaga a DETALLE_VENTA, PAGO,
--    DEVOLUCION
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_upd_venta_pk
AFTER UPDATE OF id_venta ON VENTA
FOR EACH ROW
BEGIN
    IF :OLD.id_venta <> :NEW.id_venta THEN

        UPDATE DETALLE_VENTA
           SET id_venta = :NEW.id_venta
         WHERE id_venta = :OLD.id_venta;

        UPDATE PAGO
           SET id_venta = :NEW.id_venta
         WHERE id_venta = :OLD.id_venta;

        UPDATE DEVOLUCION
           SET id_venta = :NEW.id_venta
         WHERE id_venta = :OLD.id_venta;

    END IF;
END;
/


-- ─────────────────────────────────────────────────────────────
-- 7. TRASPASO.id_traspaso → propaga a DETALLE_TRASPASO
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_upd_traspaso_pk
AFTER UPDATE OF id_traspaso ON TRASPASO
FOR EACH ROW
BEGIN
    IF :OLD.id_traspaso <> :NEW.id_traspaso THEN

        UPDATE DETALLE_TRASPASO
           SET id_traspaso = :NEW.id_traspaso
         WHERE id_traspaso = :OLD.id_traspaso;

    END IF;
END;
/


-- ─────────────────────────────────────────────────────────────
-- 8. DEVOLUCION.id_devolucion → propaga a DETALLE_DEVOLUCION
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_upd_devolucion_pk
AFTER UPDATE OF id_devolucion ON DEVOLUCION
FOR EACH ROW
BEGIN
    IF :OLD.id_devolucion <> :NEW.id_devolucion THEN

        UPDATE DETALLE_DEVOLUCION
           SET id_devolucion = :NEW.id_devolucion
         WHERE id_devolucion = :OLD.id_devolucion;

    END IF;
END;
/


-- =============================================================
--  VERIFICACIÓN: consulta los triggers creados
-- =============================================================
SELECT trigger_name, trigger_type, triggering_event, table_name, status
FROM   user_triggers
WHERE  trigger_name LIKE 'TRG_UPD_%'
ORDER  BY table_name;

-- =============================================================
--  TRIGGERS DE NEGOCIO - GlobalPharma Sync
--  Oracle 21c XE
--
--  1. Al insertar DETALLE_VENTA → descuenta inventario
--     (lanza error si no hay stock suficiente)
--  2. Al eliminar DETALLE_VENTA → regresa stock
--     (por si se cancela una venta)
--  3. Al insertar DETALLE_DEVOLUCION → regresa stock
--  4. Al insertar DEVOLUCION con estatus APROBADA directamente
--     (salvaguarda extra a nivel cabecera)
--  5. Al actualizar estatus de DEVOLUCION a APROBADA → regresa stock
--     (flujo real: primero se crea SOLICITADA, luego se aprueba)
-- =============================================================


-- ─────────────────────────────────────────────────────────────
-- TRIGGER 1: Descontar inventario al registrar un detalle de venta
--            Valida stock ANTES de permitir la venta
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_venta_descuenta_inv
BEFORE INSERT ON DETALLE_VENTA
FOR EACH ROW
DECLARE
    v_sucursal   NVARCHAR2(36);
    v_stock_act  NUMBER(10);
BEGIN
    -- Obtener la sucursal del empleado que realizó la venta
    SELECT e.id_sucursal
      INTO v_sucursal
      FROM VENTA v
      JOIN EMPLEADO e ON e.id_empleado = v.id_empleado
     WHERE v.id_venta = :NEW.id_venta;

    -- Verificar si existe el producto en inventario de esa sucursal
    BEGIN
        SELECT cantidad
          INTO v_stock_act
          FROM INVENTARIO
         WHERE id_sucursal = v_sucursal
           AND id_producto  = :NEW.id_producto
           FOR UPDATE;  -- bloquea la fila para evitar race conditions
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001,
                'STOCK INSUFICIENTE: El producto ' || :NEW.id_producto ||
                ' no existe en el inventario de la sucursal ' || v_sucursal || '.');
    END;

    -- Verificar que haya suficiente cantidad
    IF v_stock_act < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20002,
            'STOCK INSUFICIENTE: Se requieren ' || :NEW.cantidad ||
            ' unidades de ' || :NEW.id_producto ||
            ' pero solo hay ' || v_stock_act ||
            ' en la sucursal ' || v_sucursal || '.');
    END IF;

    -- Descontar del inventario
    UPDATE INVENTARIO
       SET cantidad = cantidad - :NEW.cantidad
     WHERE id_sucursal = v_sucursal
       AND id_producto  = :NEW.id_producto;

END;
/


-- ─────────────────────────────────────────────────────────────
-- TRIGGER 2: Regresar inventario si se elimina un detalle de venta
--            (caso de cancelación de venta)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_venta_cancela_inv
BEFORE DELETE ON DETALLE_VENTA
FOR EACH ROW
DECLARE
    v_sucursal NVARCHAR2(36);
BEGIN
    -- Obtener la sucursal asociada a la venta
    SELECT e.id_sucursal
      INTO v_sucursal
      FROM VENTA v
      JOIN EMPLEADO e ON e.id_empleado = v.id_empleado
     WHERE v.id_venta = :OLD.id_venta;

    -- Regresar las unidades al inventario
    UPDATE INVENTARIO
       SET cantidad = cantidad + :OLD.cantidad
     WHERE id_sucursal = v_sucursal
       AND id_producto  = :OLD.id_producto;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Si ya no existe la venta o el inventario, no hacemos nada
        NULL;
END;
/


-- ─────────────────────────────────────────────────────────────
-- TRIGGER 3: Regresar inventario al insertar un detalle de devolución
--            Solo aplica si la DEVOLUCION ya está en estatus APROBADA
--            (flujo rápido donde se aprueba en el mismo INSERT)
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_devolucion_regresa_inv
BEFORE INSERT ON DETALLE_DEVOLUCION
FOR EACH ROW
DECLARE
    v_sucursal      NVARCHAR2(36);
    v_estatus_dev   VARCHAR2(20);
    v_id_venta      NVARCHAR2(36);
BEGIN
    -- Obtener estatus de la devolución y la venta asociada
    SELECT d.estatus, d.id_venta
      INTO v_estatus_dev, v_id_venta
      FROM DEVOLUCION d
     WHERE d.id_devolucion = :NEW.id_devolucion;

    -- Solo regresar stock si la devolución está APROBADA
    IF v_estatus_dev = 'APROBADA' THEN

        SELECT e.id_sucursal
          INTO v_sucursal
          FROM VENTA v
          JOIN EMPLEADO e ON e.id_empleado = v.id_empleado
         WHERE v.id_venta = v_id_venta;

        -- Reingresar al inventario
        UPDATE INVENTARIO
           SET cantidad = cantidad + :NEW.cantidad
         WHERE id_sucursal = v_sucursal
           AND id_producto  = :NEW.id_producto;

        -- Si el producto fue dado de baja del inventario, lo reinserta
        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO INVENTARIO (id_sucursal, id_producto, cantidad, stock_minimo)
            VALUES (v_sucursal, :NEW.id_producto, :NEW.cantidad, 5);
        END IF;

    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003,
            'No se encontró la devolución o la venta asociada para el producto ' ||
            :NEW.id_producto || '.');
END;
/


-- ─────────────────────────────────────────────────────────────
-- TRIGGER 4: Regresar inventario cuando se APRUEBA una devolución
--            Flujo normal: devolución inicia como SOLICITADA
--            y luego el empleado la cambia a APROBADA
-- ─────────────────────────────────────────────────────────────
CREATE OR REPLACE TRIGGER trg_devolucion_aprobada_inv
AFTER UPDATE OF estatus ON DEVOLUCION
FOR EACH ROW
DECLARE
    v_sucursal NVARCHAR2(36);
BEGIN
    -- Solo actuar cuando el cambio es hacia APROBADA
    IF :OLD.estatus <> 'APROBADA' AND :NEW.estatus = 'APROBADA' THEN

        -- Obtener la sucursal de la venta original
        SELECT e.id_sucursal
          INTO v_sucursal
          FROM VENTA v
          JOIN EMPLEADO e ON e.id_empleado = v.id_empleado
         WHERE v.id_venta = :NEW.id_venta;

        -- Regresar cada producto del detalle de devolución al inventario
        FOR rec IN (
            SELECT id_producto, cantidad
              FROM DETALLE_DEVOLUCION
             WHERE id_devolucion = :NEW.id_devolucion
        ) LOOP

            UPDATE INVENTARIO
               SET cantidad = cantidad + rec.cantidad
             WHERE id_sucursal = v_sucursal
               AND id_producto  = rec.id_producto;

            -- Si el producto no existe en inventario, lo crea
            IF SQL%ROWCOUNT = 0 THEN
                INSERT INTO INVENTARIO (id_sucursal, id_producto, cantidad, stock_minimo)
                VALUES (v_sucursal, rec.id_producto, rec.cantidad, 5);
            END IF;

        END LOOP;

    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20004,
            'No se encontró la sucursal asociada a la devolución ' ||
            :NEW.id_devolucion || '.');
END;
/


-- =============================================================
--  VERIFICACIÓN
-- =============================================================
SELECT trigger_name, triggering_event, table_name, status
FROM   user_triggers
WHERE  trigger_name IN (
    'TRG_VENTA_DESCUENTA_INV',
    'TRG_VENTA_CANCELA_INV',
    'TRG_DEVOLUCION_REGRESA_INV',
    'TRG_DEVOLUCION_APROBADA_INV'
)
ORDER BY table_name;