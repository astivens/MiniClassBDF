-- =============================================
-- Hospital Universitario del Caribe (HUC)
-- Base de datos: huc_db
-- Sistema LEGADO - Barranquilla, Colombia
-- =============================================

-- Esquema público (por defecto en PostgreSQL)
SET search_path TO public;

-- =============================================
-- TABLA: pacientes
-- Registro maestro de pacientes del HUC
-- =============================================
CREATE TABLE pacientes (
    id_paciente         SERIAL PRIMARY KEY,
    numero_documento    VARCHAR(20) NOT NULL UNIQUE,
    tipo_documento      VARCHAR(5) NOT NULL DEFAULT 'CC',
    primer_nombre       VARCHAR(50) NOT NULL,
    segundo_nombre      VARCHAR(50),
    primer_apellido     VARCHAR(50) NOT NULL,
    segundo_apellido    VARCHAR(50),
    fecha_nacimiento    DATE NOT NULL,
    sexo                CHAR(1) CHECK (sexo IN ('M', 'F')),
    telefono            VARCHAR(15),
    direccion           VARCHAR(200),
    ciudad              VARCHAR(50) DEFAULT 'Barranquilla',
    eps                 VARCHAR(100),
    grupo_sanguineo     VARCHAR(5),
    fecha_registro      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLA: consultas
-- Registro de consultas médicas en el HUC
-- =============================================
CREATE TABLE consultas (
    id_consulta         SERIAL PRIMARY KEY,
    numero_documento    VARCHAR(20) NOT NULL,
    fecha_consulta      TIMESTAMP NOT NULL,
    especialidad        VARCHAR(100) NOT NULL,
    medico_tratante     VARCHAR(150) NOT NULL,
    motivo_consulta     TEXT,
    observaciones       TEXT,
    sala                VARCHAR(20),
    FOREIGN KEY (numero_documento) REFERENCES pacientes(numero_documento)
);

-- =============================================
-- TABLA: diagnosticos
-- Diagnósticos CIE-10 asignados en consultas
-- =============================================
CREATE TABLE diagnosticos (
    id_diagnostico      SERIAL PRIMARY KEY,
    id_consulta         INTEGER NOT NULL,
    numero_documento    VARCHAR(20) NOT NULL,
    codigo_cie10        VARCHAR(10) NOT NULL,
    descripcion         VARCHAR(300) NOT NULL,
    tipo_diagnostico    VARCHAR(20) DEFAULT 'Definitivo',
    fecha_diagnostico   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_consulta) REFERENCES consultas(id_consulta),
    FOREIGN KEY (numero_documento) REFERENCES pacientes(numero_documento)
);

-- =============================================
-- DATOS DE EJEMPLO
-- =============================================

-- Pacientes del HUC
INSERT INTO pacientes (numero_documento, tipo_documento, primer_nombre, segundo_nombre, primer_apellido, segundo_apellido, fecha_nacimiento, sexo, telefono, direccion, eps, grupo_sanguineo) VALUES
('1001', 'CC', 'María', 'Elena', 'García', 'Pérez', '1985-03-15', 'F', '3001234567', 'Cra 45 #72-15, Barranquilla', 'Coomeva EPS', 'O+'),
('1002', 'CC', 'Carlos', 'Andrés', 'López', 'Mendoza', '1978-07-22', 'M', '3009876543', 'Cl 30 #15-40, Soledad', 'Sura EPS', 'A+'),
('1004', 'CC', 'Pedro', 'José', 'Rodríguez', 'Castillo', '1990-11-08', 'M', '3005551234', 'Cra 21 #55-30, Barranquilla', 'Sanitas EPS', 'B+'),
('1005', 'CC', 'Luisa', 'Fernanda', 'Fernández', 'Ruiz', '1972-05-30', 'F', '3007778899', 'Cl 76 #42-18, Barranquilla', 'Nueva EPS', 'AB+');

-- Consultas en el HUC
INSERT INTO consultas (numero_documento, fecha_consulta, especialidad, medico_tratante, motivo_consulta, observaciones, sala) VALUES
('1001', '2024-01-15 08:30:00', 'Medicina Interna', 'Dr. Roberto Villaquirán', 'Dolor abdominal recurrente', 'Paciente refiere dolor en epigastrio desde hace 2 semanas. Se solicitan exámenes.', 'S-201'),
('1001', '2024-03-20 10:00:00', 'Gastroenterología', 'Dra. Carmen Ibarra', 'Seguimiento dolor abdominal', 'Resultados de endoscopia: gastritis leve. Se inicia tratamiento con omeprazol.', 'S-305'),
('1002', '2024-02-10 14:00:00', 'Cardiología', 'Dr. Julio César Pumarejo', 'Hipertensión arterial no controlada', 'PA: 160/95. Se ajusta medicación. Control en 1 mes.', 'S-102'),
('1002', '2024-06-05 09:00:00', 'Cardiología', 'Dr. Julio César Pumarejo', 'Control de hipertensión', 'PA: 135/85. Mejoría con nueva medicación. Continuar tratamiento.', 'S-102'),
('1004', '2024-04-18 11:30:00', 'Ortopedia', 'Dr. Alejandro Montero', 'Dolor en rodilla derecha tras caída', 'RM de rodilla: leve lesión meniscal. Se recomienda fisioterapia.', 'S-410'),
('1005', '2024-05-12 07:45:00', 'Urgencias', 'Dra. Patricia Caballero', 'Dolor torácico agudo', 'ECG normal. Enzimas cardiacas negativas. Reflujo gastroesofágico probable.', 'URG-03'),
('1005', '2024-07-22 15:00:00', 'Neumología', 'Dr. Gustavo De la Rosa', 'Disnea y tos crónica', 'Rx tórax: patrón intersticial leve. Se solicita espirometría.', 'S-508');

-- Diagnósticos CIE-10
INSERT INTO diagnosticos (id_consulta, numero_documento, codigo_cie10, descripcion, tipo_diagnostico, fecha_diagnostico) VALUES
(1, '1001', 'K29.7', 'Gastritis no especificada', 'Presuntivo', '2024-01-15 09:00:00'),
(2, '1001', 'K29.0', 'Gastritis aguda con hemorragia', 'Definitivo', '2024-03-20 10:30:00'),
(3, '1002', 'I10', 'Hipertensión esencial (primaria)', 'Definitivo', '2024-02-10 14:30:00'),
(4, '1002', 'I10', 'Hipertensión esencial (primaria)', 'Definitivo', '2024-06-05 09:30:00'),
(5, '1004', 'S83.2', 'Desgarro del menisco actual', 'Definitivo', '2024-04-18 12:00:00'),
(6, '1005', 'R07.4', 'Dolor en el pecho no especificado', 'Presuntivo', '2024-05-12 08:15:00'),
(7, '1005', 'J84.1', 'Otras enfermedades pulmonares intersticiales con fibrosis', 'Presuntivo', '2024-07-22 15:30:00');
