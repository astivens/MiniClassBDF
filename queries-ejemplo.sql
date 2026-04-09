-- =============================================
-- QUERIES DE DEMOSTRACIÓN - Federación con Trino
-- Caso: Clínicas del Caribe - Barranquilla, Colombia
-- =============================================
-- Ejecutar desde: Trino CLI (docker exec -it trino-coordinator trino)
-- o desde Trino Web UI: http://localhost:8080
-- =============================================


-- =============================================
-- 1. VERIFICAR CATÁLOGOS CONECTADOS
-- =============================================
-- Confirma que Trino ve las tres clínicas

SHOW CATALOGS;
-- Deberías ver: postgresql, mysql, mongodb, system


-- =============================================
-- 2. EXPLORAR ESQUEMAS DE CADA CLÍNICA
-- =============================================

-- Esquemas del HUC (PostgreSQL)
SHOW SCHEMAS FROM postgresql;
-- Resultado: public, information_schema

-- Tablas del HUC
SHOW TABLES FROM postgresql.public;

-- Tablas de CLM (MySQL)
SHOW TABLES FROM mysql.clm_db;

-- Esquemas de LCN (MongoDB)
SHOW SCHEMAS FROM mongodb;


-- =============================================
-- 3. CONSULTAS INDIVIDUALES POR CLÍNICA
-- =============================================

-- Pacientes del HUC (PostgreSQL)
SELECT numero_documento, primer_nombre, primer_apellido, eps, grupo_sanguineo
FROM postgresql.public.pacientes
ORDER BY numero_documento;

-- Citas de CLM (MySQL)
SELECT numero_documento, nombres, apellidos, fecha_cita, especialidad, medico, estado_cita
FROM mysql.clm_db.citas
ORDER BY fecha_cita;

-- Resultados de laboratorio de LCN (MongoDB)
SELECT numero_documento, nombre_completo, eps
FROM mongodb.lcn_db.pacientes
ORDER BY numero_documento;


-- =============================================
-- 4. QUERY FEDERADA: HISTORIAL COMPLETO
--    María Elena García (CC 1001)
--    Atendida en HUC + CLM + LCN
-- =============================================
-- Este es el caso de uso principal:
-- Un médico necesita TODO el historial de un paciente
-- que pasó por las tres instituciones.
-- SIN federación: llamada telefónica + PDF + horas de espera.
-- CON federación: UNA SOLA QUERY.
-- =============================================

-- 4a. Diagnósticos del HUC + Resultados de laboratorio del LCN
SELECT
    'HUC' AS institucion,
    d.fecha_diagnostico AS fecha,
    d.codigo_cie10 AS codigo,
    d.descripcion AS detalle,
    d.tipo_diagnostico AS tipo
FROM postgresql.public.diagnosticos d
WHERE d.numero_documento = '1001'

UNION ALL

SELECT
    'LCN' AS institucion,
    r.fecha_resultado AS fecha,
    r.tipo_examen AS codigo,
    r.observaciones AS detalle,
    'Laboratorio' AS tipo
FROM mongodb.lcn_db.resultados_laboratorio r
WHERE r.numero_documento = '1001'

ORDER BY fecha;


-- =============================================
-- 5. QUERY FEDERADA: PERFIL COMPLETO DEL PACIENTE
--    María Elena García - Cruzando las 3 clínicas
-- =============================================

SELECT
    p_huc.numero_documento AS cedula,
    p_huc.primer_nombre || ' ' || p_huc.primer_apellido AS nombre_completo,
    p_huc.fecha_nacimiento,
    p_huc.eps,
    p_huc.grupo_sanguineo,
    -- Datos del HUC
    (SELECT COUNT(*) FROM postgresql.public.consultas c WHERE c.numero_documento = p_huc.numero_documento) AS consultas_huc,
    -- Datos de CLM
    (SELECT COUNT(*) FROM mysql.clm_db.citas ct WHERE ct.numero_documento = p_huc.numero_documento) AS citas_clm,
    -- Datos de LCN
    (SELECT COUNT(*) FROM mongodb.lcn_db.resultados_laboratorio rl WHERE rl.numero_documento = p_huc.numero_documento) AS examenes_lcn
FROM postgresql.public.pacientes p_huc
WHERE p_huc.numero_documento = '1001';


-- =============================================
-- 6. QUERY FEDERADA: JOIN ENTRE HUC Y LCN
--    Diagnósticos + Exámenes de laboratorio juntos
-- =============================================
-- Caso: El médico del HUC diagnosticó "Gastritis"
-- y el laboratorio confirmó H. pylori.
-- ¿Cuántos pacientes tienen diagnósticos del HUC
-- y exámenes de laboratorio del LCN?
-- =============================================

SELECT
    p.numero_documento,
    p.primer_nombre || ' ' || p.primer_apellido AS paciente,
    p.eps,
    d.codigo_cie10,
    d.descripcion AS diagnostico,
    d.fecha_diagnostico,
    rl.tipo_examen,
    rl.fecha_resultado,
    rl.observaciones AS resultado_lab
FROM postgresql.public.pacientes p
JOIN postgresql.public.diagnosticos d
    ON p.numero_documento = d.numero_documento
JOIN mongodb.lcn_db.resultados_laboratorio rl
    ON p.numero_documento = rl.numero_documento
WHERE rl.fecha_resultado >= d.fecha_diagnostico - INTERVAL '30' DAY
ORDER BY p.numero_documento, d.fecha_diagnostico;


-- =============================================
-- 7. QUERY FEDERADA: PACIENTES ATENDIDOS EN
--    MÁS DE UNA CLÍNICA
-- =============================================
-- ¿Qué pacientes aparecen en múltiples clínicas?
-- Esto NO se puede resolver sin federación.
-- =============================================

SELECT
    p.numero_documento AS cedula,
    MAX(p.nombre) AS nombre,
    MAX(p.eps) AS eps,
    MAX(p.en_huc) AS atendido_en_huc,
    MAX(p.en_clm) AS atendido_en_clm,
    MAX(p.en_lcn) AS atendido_en_lcn,
    SUM(p.total_atenciones) AS total_atenciones
FROM (
    -- Pacientes del HUC
    SELECT
        huc.numero_documento,
        huc.primer_nombre || ' ' || huc.primer_apellido AS nombre,
        huc.eps,
        1 AS en_huc, 0 AS en_clm, 0 AS en_lcn,
        (SELECT COUNT(*) FROM postgresql.public.consultas c WHERE c.numero_documento = huc.numero_documento) AS total_atenciones
    FROM postgresql.public.pacientes huc

    UNION ALL

    -- Pacientes de CLM
    SELECT
        clm.numero_documento,
        clm.nombres || ' ' || clm.apellidos AS nombre,
        clm.eps,
        0 AS en_huc, 1 AS en_clm, 0 AS en_lcn,
        (SELECT COUNT(*) FROM mysql.clm_db.citas ct WHERE ct.numero_documento = clm.numero_documento) AS total_atenciones
    FROM mysql.clm_db.pacientes clm

    UNION ALL

    -- Pacientes de LCN
    SELECT
        lcn.numero_documento,
        lcn.nombre_completo AS nombre,
        lcn.eps,
        0 AS en_huc, 0 AS en_clm, 1 AS en_lcn,
        (SELECT COUNT(*) FROM mongodb.lcn_db.resultados_laboratorio rl WHERE rl.numero_documento = lcn.numero_documento) AS total_atenciones
    FROM mongodb.lcn_db.pacientes lcn
) p
GROUP BY p.numero_documento
HAVING COUNT(DISTINCT p.en_huc + p.en_clm + p.en_lcn) > 0
   AND SUM(p.en_huc) + SUM(p.en_clm) + SUM(p.en_lcn) > 1
ORDER BY SUM(p.en_huc) + SUM(p.en_clm) + SUM(p.en_lcn) DESC;


-- =============================================
-- 8. QUERY FEDERADA: MEDICAMENTOS + DIAGNÓSTICOS
--    ¿Qué medicamentos toman los pacientes
--    según sus diagnósticos del HUC?
-- =============================================

SELECT
    p.nombres || ' ' || p.apellidos AS paciente,
    d.descripcion AS diagnostico,
    d.codigo_cie10,
    pr.medicamento,
    pr.dosis,
    pr.frecuencia,
    pr.duracion_dias
FROM mysql.clm_db.pacientes p
JOIN mysql.clm_db.prescripciones pr
    ON p.numero_documento = pr.numero_documento
JOIN postgresql.public.diagnosticos d
    ON p.numero_documento = d.numero_documento
WHERE d.tipo_diagnostico = 'Definitivo'
ORDER BY p.numero_documento, pr.fecha_prescripcion;


-- =============================================
-- 9. QUERY FEDERADA: RESUMEN EJECUTIVO
--    Vista general de la federación
-- =============================================

SELECT
    'Pacientes únicos en federación' AS metrica,
    CAST(COUNT(DISTINCT numero_documento) AS VARCHAR) AS valor
FROM (
    SELECT numero_documento FROM postgresql.public.pacientes
    UNION
    SELECT numero_documento FROM mysql.clm_db.pacientes
    UNION
    SELECT numero_documento FROM mongodb.lcn_db.pacientes
)

UNION ALL

SELECT
    'Consultas en HUC (PostgreSQL)',
    CAST(COUNT(*) AS VARCHAR)
FROM postgresql.public.consultas

UNION ALL

SELECT
    'Citas en CLM (MySQL)',
    CAST(COUNT(*) AS VARCHAR)
FROM mysql.clm_db.citas

UNION ALL

SELECT
    'Exámenes en LCN (MongoDB)',
    CAST(COUNT(*) AS VARCHAR)
FROM mongodb.lcn_db.resultados_laboratorio

UNION ALL

SELECT
    'Diagnósticos registrados (HUC)',
    CAST(COUNT(*) AS VARCHAR)
FROM postgresql.public.diagnosticos

UNION ALL

SELECT
    'Prescripciones (CLM)',
    CAST(COUNT(*) AS VARCHAR)
FROM mysql.clm_db.prescripciones;
