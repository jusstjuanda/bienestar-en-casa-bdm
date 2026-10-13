-- =====================================================================
--  Bienestar en Casa - Modelo lógico relacional (Entrega 1)
--  Asignatura: Bases de Datos Multimedia - Ingeniería Multimedia
--  Motor objetivo: MySQL 8.0.16+ (CHECK se aplican desde esa versión)
--  Nota: las reglas dinámicas (cruce de reservas, disponibilidad,
--  transiciones de estado) se implementan con triggers en la Entrega 2.
-- =====================================================================

DROP SCHEMA IF EXISTS bienestar_en_casa;
CREATE SCHEMA bienestar_en_casa
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE bienestar_en_casa;

-- ---------------------------------------------------------------------
--  Usuarios (supertipo) y subtipos cliente / proveedor
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id_usuario      INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    correo          VARCHAR(150)  NOT NULL,
    contrasena_hash VARCHAR(255)  NOT NULL COMMENT 'Hash irreversible (bcrypt/argon2); nunca texto plano',
    nombres         VARCHAR(80)   NOT NULL,
    apellidos       VARCHAR(80)   NOT NULL,
    telefono        VARCHAR(20)   NULL,
    tipo_usuario    ENUM('CLIENTE','PROVEEDOR') NOT NULL,
    fecha_registro  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_usuario),
    UNIQUE KEY uq_usuario_correo (correo)
) ENGINE=InnoDB;

CREATE TABLE cliente (
    id_usuario INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_usuario),
    CONSTRAINT fk_cliente_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE proveedor (
    id_usuario           INT UNSIGNED NOT NULL,
    nombre_profesional   VARCHAR(120) NOT NULL,
    descripcion_perfil   TEXT         NULL,
    experiencia_anios    TINYINT UNSIGNED NULL,
    PRIMARY KEY (id_usuario),
    CONSTRAINT fk_proveedor_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
--  Direcciones del cliente (una principal; otras opcionales)
-- ---------------------------------------------------------------------
CREATE TABLE direccion_cliente (
    id_direccion       INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_cliente         INT UNSIGNED NOT NULL,
    ciudad             VARCHAR(80)  NOT NULL,
    barrio_sector      VARCHAR(100) NULL,
    direccion          VARCHAR(200) NOT NULL,
    info_complementaria VARCHAR(255) NULL,
    es_principal       TINYINT(1)   NOT NULL DEFAULT 0,
    PRIMARY KEY (id_direccion),
    KEY ix_direccion_cliente (id_cliente),
    CONSTRAINT fk_direccion_cliente FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_usuario) ON DELETE CASCADE,
    CONSTRAINT ck_direccion_principal CHECK (es_principal IN (0,1))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
--  Zonas de atención (orientativas, sin cálculo de distancia)
-- ---------------------------------------------------------------------
CREATE TABLE zona_atencion (
    id_zona        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_proveedor   INT UNSIGNED NOT NULL,
    ciudad         VARCHAR(80)  NOT NULL,
    barrio_sector  VARCHAR(100) NULL COMMENT 'NULL = toda la ciudad',
    PRIMARY KEY (id_zona),
    UNIQUE KEY uq_zona (id_proveedor, ciudad, barrio_sector),
    CONSTRAINT fk_zona_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor (id_usuario) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
--  Catálogo de servicios
-- ---------------------------------------------------------------------
CREATE TABLE categoria_servicio (
    id_categoria INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre       VARCHAR(80)  NOT NULL,
    PRIMARY KEY (id_categoria),
    UNIQUE KEY uq_categoria_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE servicio (
    id_servicio   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_proveedor  INT UNSIGNED NOT NULL,
    id_categoria  INT UNSIGNED NOT NULL,
    nombre        VARCHAR(120) NOT NULL,
    descripcion   TEXT         NULL,
    duracion_min  SMALLINT UNSIGNED NOT NULL,
    precio        DECIMAL(10,2) NOT NULL,
    estado        ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
    PRIMARY KEY (id_servicio),
    KEY ix_servicio_nombre (nombre),
    KEY ix_servicio_categoria (id_categoria),
    KEY ix_servicio_proveedor (id_proveedor),
    CONSTRAINT fk_servicio_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor (id_usuario),
    CONSTRAINT fk_servicio_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria_servicio (id_categoria),
    CONSTRAINT ck_servicio_duracion CHECK (duracion_min > 0),
    CONSTRAINT ck_servicio_precio   CHECK (precio >= 0)
) ENGINE=InnoDB;

CREATE TABLE recurso_multimedia (
    id_recurso   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_servicio  INT UNSIGNED NOT NULL,
    tipo         ENUM('FOTO','VIDEO') NOT NULL,
    url          VARCHAR(500) NOT NULL,
    descripcion  VARCHAR(200) NULL,
    PRIMARY KEY (id_recurso),
    KEY ix_recurso_servicio (id_servicio),
    CONSTRAINT fk_recurso_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicio (id_servicio) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE insumo (
    id_insumo INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre    VARCHAR(120) NOT NULL,
    tipo      ENUM('PRODUCTO','INSUMO','EQUIPO') NOT NULL,
    PRIMARY KEY (id_insumo),
    UNIQUE KEY uq_insumo (nombre, tipo)
) ENGINE=InnoDB;

CREATE TABLE servicio_insumo (
    id_servicio INT UNSIGNED NOT NULL,
    id_insumo   INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_servicio, id_insumo),
    CONSTRAINT fk_si_servicio FOREIGN KEY (id_servicio)
        REFERENCES servicio (id_servicio) ON DELETE CASCADE,
    CONSTRAINT fk_si_insumo FOREIGN KEY (id_insumo)
        REFERENCES insumo (id_insumo)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
--  Disponibilidad del proveedor
-- ---------------------------------------------------------------------
CREATE TABLE horario_disponibilidad (
    id_horario    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_proveedor  INT UNSIGNED NOT NULL,
    dia_semana    TINYINT UNSIGNED NOT NULL COMMENT '1=lunes ... 7=domingo',
    hora_inicio   TIME NOT NULL,
    hora_fin      TIME NOT NULL,
    PRIMARY KEY (id_horario),
    KEY ix_horario_proveedor (id_proveedor, dia_semana),
    CONSTRAINT fk_horario_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor (id_usuario) ON DELETE CASCADE,
    CONSTRAINT ck_horario_dia  CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT ck_horario_hora CHECK (hora_fin > hora_inicio)
) ENGINE=InnoDB;

CREATE TABLE periodo_no_disponible (
    id_periodo    INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_proveedor  INT UNSIGNED NOT NULL,
    fecha_inicio  DATETIME NOT NULL,
    fecha_fin     DATETIME NOT NULL,
    motivo        VARCHAR(200) NULL,
    PRIMARY KEY (id_periodo),
    KEY ix_periodo_proveedor (id_proveedor, fecha_inicio, fecha_fin),
    CONSTRAINT fk_periodo_proveedor FOREIGN KEY (id_proveedor)
        REFERENCES proveedor (id_usuario) ON DELETE CASCADE,
    CONSTRAINT ck_periodo_fechas CHECK (fecha_fin > fecha_inicio)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
--  Solicitudes / reservas
--  El proveedor se obtiene por servicio.id_proveedor (evita redundancia).
--  nombre/precio/duración se copian al crear la solicitud (instantánea).
-- ---------------------------------------------------------------------
CREATE TABLE solicitud_reserva (
    id_solicitud            INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_cliente              INT UNSIGNED NOT NULL,
    id_servicio             INT UNSIGNED NOT NULL,
    id_direccion            INT UNSIGNED NULL COMMENT 'Dirección guardada del cliente, si se eligió una',

    -- Instantánea del servicio
    nombre_servicio         VARCHAR(120)  NOT NULL,
    precio_servicio         DECIMAL(10,2) NOT NULL,
    duracion_min            SMALLINT UNSIGNED NOT NULL,

    -- Fechas
    fecha_hora_inicio       DATETIME NOT NULL COMMENT 'Fecha/hora solicitada; pasa a ser la propuesta si el cliente la acepta',
    fecha_hora_propuesta    DATETIME NULL     COMMENT 'Horario alternativo sugerido por el proveedor',
    fecha_hora_fin          DATETIME GENERATED ALWAYS AS
                            (fecha_hora_inicio + INTERVAL duracion_min MINUTE) STORED,

    -- Lugar de la prestación (copia textual, la solicitud conserva sus datos)
    ciudad                  VARCHAR(80)  NOT NULL,
    direccion               VARCHAR(200) NOT NULL,
    barrio_sector           VARCHAR(100) NULL,
    info_complementaria     VARCHAR(255) NULL,
    observaciones           VARCHAR(500) NULL,

    -- Estado
    estado                  ENUM('PENDIENTE','SUGERIDA','ACEPTADA','RECHAZADA','CANCELADA','COMPLETADA')
                            NOT NULL DEFAULT 'PENDIENTE',
    motivo                  VARCHAR(300) NULL COMMENT 'Obligatorio si RECHAZADA o CANCELADA',
    fecha_creacion          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (id_solicitud),
    KEY ix_solicitud_cliente  (id_cliente, estado),
    KEY ix_solicitud_servicio (id_servicio, estado, fecha_hora_inicio),
    CONSTRAINT fk_solicitud_cliente   FOREIGN KEY (id_cliente)   REFERENCES cliente (id_usuario),
    CONSTRAINT fk_solicitud_servicio  FOREIGN KEY (id_servicio)  REFERENCES servicio (id_servicio),
    CONSTRAINT fk_solicitud_direccion FOREIGN KEY (id_direccion) REFERENCES direccion_cliente (id_direccion)
        ON DELETE SET NULL,
    CONSTRAINT ck_solicitud_precio   CHECK (precio_servicio >= 0),
    CONSTRAINT ck_solicitud_duracion CHECK (duracion_min > 0),
    CONSTRAINT ck_solicitud_motivo   CHECK (estado NOT IN ('RECHAZADA','CANCELADA') OR motivo IS NOT NULL),
    CONSTRAINT ck_solicitud_sugerida CHECK (estado <> 'SUGERIDA' OR fecha_hora_propuesta IS NOT NULL)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
--  Recuperación de contraseña (código de un solo uso o enlace temporal)
-- ---------------------------------------------------------------------
CREATE TABLE recuperacion_contrasena (
    id_recuperacion  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_usuario       INT UNSIGNED NOT NULL,
    tipo             ENUM('CODIGO','ENLACE') NOT NULL,
    token_hash       VARCHAR(255) NOT NULL COMMENT 'Hash del código/token; no se guarda en claro',
    fecha_creacion   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_expiracion DATETIME NOT NULL,
    fecha_uso        DATETIME NULL,
    invalidado       TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 si se usó o se generó una solicitud nueva',
    PRIMARY KEY (id_recuperacion),
    KEY ix_recuperacion_usuario (id_usuario, invalidado),
    CONSTRAINT fk_recuperacion_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE CASCADE,
    CONSTRAINT ck_recuperacion_vigencia CHECK (fecha_expiracion > fecha_creacion),
    CONSTRAINT ck_recuperacion_invalidado CHECK (invalidado IN (0,1))
) ENGINE=InnoDB;
