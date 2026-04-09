-- =============================================
-- Clínica La Manga (CLM)
-- Base de datos: clm_db
-- Sistema EHR Moderno - Barranquilla, Colombia
-- =============================================

USE clm_db;

-- =============================================
-- TABLA: pacientes
-- Registro maestro de pacientes de CLM
-- =============================================
CREATE TABLE pacientes (
    id_paciente         INT AUTO_INCREMENT PRIMARY KEY,
    numero_documento    VARCHAR(20) NOT NULL UNIQUE,
    tipo_documento      VARCHAR(5) NOT NULL DEFAULT 'CC',
    nombres             VARCHAR(100) NOT NULL,
    apellidos           VARCHAR(100) NOT NULL,
    fecha_nacimiento    DATE NOT NULL,
    genero              CHAR(1) CHECK (genero IN ('M', 'F')),
    telefono_movil      VARCHAR(15),
    email               VARCHAR(100),
    direccion           VARCHAR(200),
    ciudad              VARCHAR(50) DEFAULT 'Barranquilla',
    eps                 VARCHAR(100),
    estado              ENUM('Activo', 'Inactivo') DEFAULT 'Activo',
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- TABLA: citas
-- Programación de citas médicas en CLM
-- =============================================
CREATE TABLE citas (
    id_cita             INT AUTO_INCREMENT PRIMARY KEY,
    numero_documento    VARCHAR(20) NOT NULL,
    fecha_cita          DATETIME NOT NULL,
    especialidad        VARCHAR(100) NOT NULL,
    medico              VARCHAR(150) NOT NULL,
    consultorio         VARCHAR(20),
    estado_cita         ENUM('Programada', 'Completada', 'Cancelada', 'No asistió') DEFAULT 'Programada',
    motivo              TEXT,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (numero_documento) REFERENCES pacientes(numero_documento)
);

-- =============================================
-- TABLA: prescripciones
-- Medicamentos y tratamientos recetados en CLM
-- =============================================
CREATE TABLE prescripciones (
    id_prescripcion     INT AUTO_INCREMENT PRIMARY KEY,
    id_cita             INT NOT NULL,
    numero_documento    VARCHAR(20) NOT NULL,
    medicamento         VARCHAR(200) NOT NULL,
    dosis               VARCHAR(100) NOT NULL,
    frecuencia          VARCHAR(50) NOT NULL,
    duracion_dias       INT,
    indicaciones        TEXT,
    fecha_prescripcion  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cita) REFERENCES citas(id_cita),
    FOREIGN KEY (numero_documento) REFERENCES pacientes(numero_documento)
);

-- =============================================
-- DATOS DE EJEMPLO
-- =============================================

-- Pacientes de CLM
INSERT INTO pacientes (numero_documento, tipo_documento, nombres, apellidos, fecha_nacimiento, genero, telefono_movil, email, direccion, eps, estado) VALUES
('1001', 'CC', 'María Elena', 'García Pérez', '1985-03-15', 'F', '3001234567', 'maria.garcia@email.com', 'Cra 45 #72-15, Barranquilla', 'Coomeva EPS', 'Activo'),
('1003', 'CC', 'Ana Lucía', 'Martínez Solano', '1992-09-12', 'F', '3004445566', 'ana.martinez@email.com', 'Cl 45 #30-22, Barranquilla', 'Sura EPS', 'Activo'),
('1004', 'CC', 'Pedro José', 'Rodríguez Castillo', '1990-11-08', 'M', '3005551234', 'pedro.r@email.com', 'Cra 21 #55-30, Barranquilla', 'Sanitas EPS', 'Activo');

-- Citas en CLM
INSERT INTO citas (numero_documento, fecha_cita, especialidad, medico, consultorio, estado_cita, motivo) VALUES
('1001', '2024-02-05 09:00:00', 'Gastroenterología', 'Dra. Isabel De la Cruz', 'C-101', 'Completada', 'Seguimiento gastritis - derivada del HUC'),
('1001', '2024-04-10 14:30:00', 'Medicina General', 'Dr. Fernando Suárez', 'C-205', 'Completada', 'Control general post-tratamiento'),
('1003', '2024-01-20 10:00:00', 'Ginecología', 'Dra. Marcela Henao', 'C-302', 'Completada', 'Control prenatal - primer trimestre'),
('1003', '2024-03-15 10:30:00', 'Ginecología', 'Dra. Marcela Henao', 'C-302', 'Completada', 'Control prenatal - segundo trimestre'),
('1003', '2024-05-10 10:00:00', 'Ginecología', 'Dra. Marcela Henao', 'C-302', 'Completada', 'Control prenatal - tercer trimestre'),
('1004', '2024-05-02 08:00:00', 'Fisioterapia', 'Lic. Diana Restrepo', 'F-101', 'Completada', 'Rehabilitación de rodilla derecha - sesión 1'),
('1004', '2024-05-09 08:00:00', 'Fisioterapia', 'Lic. Diana Restrepo', 'F-101', 'Completada', 'Rehabilitación de rodilla derecha - sesión 2'),
('1004', '2024-05-16 08:00:00', 'Fisioterapia', 'Lic. Diana Restrepo', 'F-101', 'Completada', 'Rehabilitación de rodilla derecha - sesión 3');

-- Prescripciones en CLM
INSERT INTO prescripciones (id_cita, numero_documento, medicamento, dosis, frecuencia, duracion_dias, indicaciones) VALUES
(1, '1001', 'Omeprazol', '20mg', 'Cada 24 horas', 30, 'Tomar en ayunas 30 minutos antes del desayuno'),
(1, '1001', 'Sucralfato', '1g', 'Cada 8 horas', 14, 'Tomar 1 hora antes de las comidas'),
(2, '1001', 'Omeprazol', '20mg', 'Cada 24 horas', 30, 'Mantenimiento - tomar en ayunas'),
(3, '1003', 'Ácido Fólico', '5mg', 'Cada 24 horas', 90, 'Suplemento prenatal'),
(3, '1003', 'Sulfato Ferroso', '325mg', 'Cada 24 horas', 90, 'Suplemento de hierro - tomar con jugo de naranja'),
(4, '1003', 'Ácido Fólico', '5mg', 'Cada 24 horas', 90, 'Continuar suplemento prenatal'),
(4, '1003', 'Carbonato de Calcio', '500mg', 'Cada 12 horas', 90, 'Suplemento de calcio'),
(6, '1004', 'Ibuprofeno', '400mg', 'Cada 8 horas', 7, 'Antiinflamatorio - tomar con alimentos'),
(6, '1004', 'Acetaminofén', '500mg', 'Cada 6 horas PRN', 7, 'Para dolor - si es necesario');
