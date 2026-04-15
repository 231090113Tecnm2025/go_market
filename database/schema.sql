-- Extensión para UUID (opcional)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================
-- SEGURIDAD Y ACCESIBILIDAD
-- ========================
CREATE TABLE rol (
    id_rol SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT
);

CREATE TABLE permiso (
    id_permiso SERIAL PRIMARY KEY,
    nombre_permiso VARCHAR(100) NOT NULL UNIQUE,
    recurso VARCHAR(200),
    acciones VARCHAR(200)
);

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    idioma_preferido VARCHAR(10) DEFAULT 'es',
    tema VARCHAR(20) DEFAULT 'claro',
    tamano_letra INT DEFAULT 16,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_acceso TIMESTAMP
);

CREATE TABLE usuario_rol (
    id_usuario INT REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    id_rol INT REFERENCES rol(id_rol) ON DELETE CASCADE,
    PRIMARY KEY (id_usuario, id_rol)
);

CREATE TABLE rol_permiso (
    id_rol INT REFERENCES rol(id_rol) ON DELETE CASCADE,
    id_permiso INT REFERENCES permiso(id_permiso) ON DELETE CASCADE,
    PRIMARY KEY (id_rol, id_permiso)
);

CREATE TABLE preferencia_accesibilidad (
    id_preferencia SERIAL PRIMARY KEY,
    id_usuario INT UNIQUE REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    lsm_activo BOOLEAN DEFAULT FALSE,
    alto_contraste BOOLEAN DEFAULT FALSE,
    fuente VARCHAR(50) DEFAULT 'Inter',
    tamano_fuente INT DEFAULT 16
);

-- ========================
-- PRODUCTOS Y CATEGORÍAS
-- ========================
CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    id_categoria_padre INT REFERENCES categoria(id_categoria) ON DELETE SET NULL
);

CREATE TABLE producto (
    id_producto SERIAL PRIMARY KEY,
    codigo_barras VARCHAR(50) UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    precio_venta DECIMAL(10,2) NOT NULL,
    precio_compra DECIMAL(10,2) NOT NULL,
    stock_minimo INT DEFAULT 0,
    stock_maximo INT,
    unidad_medida VARCHAR(20),
    imagen_url TEXT,
    activo BOOLEAN DEFAULT TRUE,
    id_categoria INT REFERENCES categoria(id_categoria) ON DELETE SET NULL
);

-- ========================
-- PROVEEDORES Y SCM
-- ========================
CREATE TABLE proveedor (
    id_proveedor SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    contacto VARCHAR(100),
    telefono VARCHAR(20),
    email VARCHAR(150),
    direccion TEXT
);

CREATE TABLE producto_proveedor (
    id_producto INT REFERENCES producto(id_producto) ON DELETE CASCADE,
    id_proveedor INT REFERENCES proveedor(id_proveedor) ON DELETE CASCADE,
    precio_compra_habitual DECIMAL(10,2),
    tiempo_entrega_dias INT,
    PRIMARY KEY (id_producto, id_proveedor)
);

-- ========================
-- LOGÍSTICA E INVENTARIO
-- ========================
CREATE TABLE almacen (
    id_almacen SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT,
    tipo VARCHAR(50)
);

CREATE TABLE ubicacion (
    id_ubicacion SERIAL PRIMARY KEY,
    id_almacen INT REFERENCES almacen(id_almacen) ON DELETE CASCADE,
    pasillo VARCHAR(20),
    estante VARCHAR(20),
    nivel VARCHAR(20),
    codigo_ubicacion VARCHAR(50) UNIQUE
);

CREATE TABLE inventario (
    id_inventario SERIAL PRIMARY KEY,
    id_producto INT REFERENCES producto(id_producto) ON DELETE CASCADE,
    id_ubicacion INT REFERENCES ubicacion(id_ubicacion) ON DELETE CASCADE,
    cantidad INT NOT NULL DEFAULT 0,
    lote VARCHAR(50),
    fecha_vencimiento DATE,
    UNIQUE (id_producto, id_ubicacion)
);

CREATE TABLE movimiento_stock (
    id_movimiento SERIAL PRIMARY KEY,
    id_producto INT REFERENCES producto(id_producto) ON DELETE CASCADE,
    tipo VARCHAR(20) NOT NULL,
    cantidad INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    motivo TEXT,
    id_usuario INT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    id_ubicacion INT REFERENCES ubicacion(id_ubicacion) ON DELETE SET NULL,
    referencia VARCHAR(100)
);

-- ========================
-- CRM (CLIENTES)
-- ========================
CREATE TABLE cliente (
    id_cliente SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    email VARCHAR(150) UNIQUE,
    telefono VARCHAR(20),
    direccion TEXT,
    fecha_registro DATE DEFAULT CURRENT_DATE,
    puntos_lealtad INT DEFAULT 0
);

CREATE TABLE punto_lealtad (
    id_punto SERIAL PRIMARY KEY,
    id_cliente INT REFERENCES cliente(id_cliente) ON DELETE CASCADE,
    puntos INT NOT NULL,
    fecha DATE DEFAULT CURRENT_DATE,
    concepto VARCHAR(200),
    caducidad DATE,
    id_venta INT  -- FK se agregará después
);

-- ========================
-- COMPRAS
-- ========================
CREATE TABLE orden_compra (
    id_orden SERIAL PRIMARY KEY,
    id_proveedor INT REFERENCES proveedor(id_proveedor) ON DELETE SET NULL,
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_esperada DATE,
    estado VARCHAR(20) DEFAULT 'pendiente',
    id_usuario_solicita INT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    id_usuario_aprueba INT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    total DECIMAL(12,2) DEFAULT 0,
    observaciones TEXT
);

CREATE TABLE detalle_orden_compra (
    id_detalle SERIAL PRIMARY KEY,
    id_orden INT REFERENCES orden_compra(id_orden) ON DELETE CASCADE,
    id_producto INT REFERENCES producto(id_producto) ON DELETE CASCADE,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED
);

CREATE TABLE recepcion_mercancia (
    id_recepcion SERIAL PRIMARY KEY,
    id_orden INT REFERENCES orden_compra(id_orden) ON DELETE SET NULL,
    fecha_recepcion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_usuario INT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    estado VARCHAR(20) DEFAULT 'en_proceso'
);

CREATE TABLE detalle_recepcion (
    id_detalle_recepcion SERIAL PRIMARY KEY,
    id_recepcion INT REFERENCES recepcion_mercancia(id_recepcion) ON DELETE CASCADE,
    id_producto INT REFERENCES producto(id_producto) ON DELETE CASCADE,
    cantidad_recibida INT NOT NULL,
    cantidad_aceptada INT,
    lote VARCHAR(50),
    fecha_vencimiento DATE,
    motivo_rechazo TEXT,
    id_ubicacion INT REFERENCES ubicacion(id_ubicacion) ON DELETE SET NULL
);

-- ========================
-- VENTAS
-- ========================
CREATE TABLE venta (
    id_venta SERIAL PRIMARY KEY,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_cliente INT REFERENCES cliente(id_cliente) ON DELETE SET NULL,
    id_vendedor INT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    total DECIMAL(12,2) NOT NULL,
    iva DECIMAL(10,2) DEFAULT 0,
    metodo_pago VARCHAR(50),
    estado VARCHAR(20) DEFAULT 'completada'
);

-- Agregar FK de punto_lealtad después de crear venta
ALTER TABLE punto_lealtad ADD CONSTRAINT fk_punto_venta FOREIGN KEY (id_venta) REFERENCES venta(id_venta) ON DELETE SET NULL;

CREATE TABLE detalle_venta (
    id_detalle_venta SERIAL PRIMARY KEY,
    id_venta INT REFERENCES venta(id_venta) ON DELETE CASCADE,
    id_producto INT REFERENCES producto(id_producto) ON DELETE CASCADE,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0,
    subtotal DECIMAL(12,2) GENERATED ALWAYS AS ((cantidad * precio_unitario) - descuento) STORED
);

CREATE TABLE devolucion (
    id_devolucion SERIAL PRIMARY KEY,
    id_venta INT REFERENCES venta(id_venta) ON DELETE CASCADE,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    motivo TEXT,
    monto_reembolso DECIMAL(10,2),
    id_usuario INT REFERENCES usuario(id_usuario) ON DELETE SET NULL,
    estado VARCHAR(20) DEFAULT 'procesada'
);

-- ========================
-- FINANZAS
-- ========================
CREATE TABLE factura (
    id_factura SERIAL PRIMARY KEY,
    tipo VARCHAR(20),
    id_venta INT REFERENCES venta(id_venta) ON DELETE SET NULL,
    id_orden INT REFERENCES orden_compra(id_orden) ON DELETE SET NULL,
    numero_factura VARCHAR(50) UNIQUE,
    fecha_emision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12,2),
    impuestos DECIMAL(12,2),
    total DECIMAL(12,2),
    pdf_url TEXT,
    estado VARCHAR(20)
);

CREATE TABLE pago (
    id_pago SERIAL PRIMARY KEY,
    id_factura INT REFERENCES factura(id_factura) ON DELETE CASCADE,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    monto DECIMAL(12,2) NOT NULL,
    metodo VARCHAR(50),
    referencia VARCHAR(100),
    id_usuario INT REFERENCES usuario(id_usuario) ON DELETE SET NULL
);

-- ========================
-- CAPACITACIÓN
-- ========================
CREATE TABLE curso (
    id_curso SERIAL PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT,
    duracion_horas INT,
    material_url TEXT,
    activo BOOLEAN DEFAULT TRUE,
    id_instructor INT REFERENCES usuario(id_usuario) ON DELETE SET NULL
);

CREATE TABLE inscripcion (
    id_inscripcion SERIAL PRIMARY KEY,
    id_curso INT REFERENCES curso(id_curso) ON DELETE CASCADE,
    id_empleado INT REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    fecha_inscripcion DATE DEFAULT CURRENT_DATE,
    progreso INT DEFAULT 0,
    completado BOOLEAN DEFAULT FALSE,
    fecha_completado DATE
);

CREATE TABLE evaluacion (
    id_evaluacion SERIAL PRIMARY KEY,
    id_inscripcion INT UNIQUE REFERENCES inscripcion(id_inscripcion) ON DELETE CASCADE,
    nota DECIMAL(5,2),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    comentarios TEXT
);

-- ========================
-- REPORTES
-- ========================
CREATE TABLE reporte (
    id_reporte SERIAL PRIMARY KEY,
    nombre VARCHAR(200),
    tipo VARCHAR(50),
    parametros JSONB,
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    archivo_url TEXT,
    id_usuario INT REFERENCES usuario(id_usuario) ON DELETE SET NULL
);

-- ========================
-- DATOS INICIALES
-- ========================
INSERT INTO rol (nombre_rol, descripcion) VALUES 
('admin', 'Administrador del sistema'),
('gerente', 'Gerente de tienda'),
('vendedor', 'Vendedor o cajero'),
('almacenista', 'Encargado de inventario'),
('cliente', 'Cliente registrado');

INSERT INTO permiso (nombre_permiso, recurso, acciones) VALUES
('gestion_usuarios', '/usuarios', 'CRUD'),
('ver_reportes', '/reportes', 'READ'),
('gestion_productos', '/productos', 'CRUD'),
('gestion_ventas', '/ventas', 'CRUD');

-- Usuario admin (contraseña en texto plano: "admin123" - luego se hashea con bcrypt)
-- El hash que ves es un ejemplo, en desarrollo se puede poner uno real.
INSERT INTO usuario (nombre, email, password_hash, activo) VALUES 
('Admin', 'admin@marketonline.com', '$2a$10$dummyhashquenofunciona', TRUE);

-- Asignar rol admin (suponiendo id_usuario=1, id_rol=1)
INSERT INTO usuario_rol (id_usuario, id_rol) VALUES (1, 1);
