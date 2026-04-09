<div align="center">

# 🏥 Bases de Datos Federadas con Trino

### Red de Salud — Clínicas del Caribe · Barranquilla, Colombia

*Tres instituciones. Tres motores de base de datos. Un solo punto de consulta.*

---

![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Trino](https://img.shields.io/badge/Trino-Query_Engine-DD00A1?logo=trino&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-7-47A248?logo=mongodb&logoColor=white)

</div>

---

## Tabla de contenidos

1. [El problema que resuelve este proyecto](#1-el-problema-que-resuelve-este-proyecto)
2. [¿Qué es una base de datos federada?](#2-qué-es-una-base-de-datos-federada)
3. [Arquitectura del sistema](#3-arquitectura-del-sistema)
4. [Requisitos previos](#4-requisitos-previos)
5. [Instalación y puesta en marcha](#5-instalación-y-puesta-en-marcha)
6. [Cómo funciona Trino internamente](#6-cómo-funciona-trino-internamente)
7. [Configuración de catálogos](#7-configuración-de-catálogos)
8. [Guía de uso: consultas federadas](#8-guía-de-uso-consultas-federadas)
9. [Estructura del proyecto](#9-estructura-del-proyecto)
10. [Ventajas y limitaciones](#10-ventajas-y-limitaciones)
11. [¿Cuándo usar federación?](#11-cuándo-usar-federación)

---

## 1. El problema que resuelve este proyecto

Imagina que eres médico en Barranquilla. Tu paciente, **María Elena García**, llega a urgencias. Necesitas saber de inmediato:

- ¿Qué diagnósticos tiene registrados?
- ¿Qué exámenes de laboratorio le han realizado?
- ¿Qué medicamentos le han prescrito?

El problema es que sus datos están repartidos en **tres instituciones distintas**, cada una con su propio sistema de información y motor de base de datos:

| Institución | Motor de BD | Puerto | ¿Qué guarda? |
|---|---|---|---|
| **Hospital Universitario del Caribe (HUC)** | PostgreSQL 16 | 5433 | Pacientes, consultas, diagnósticos |
| **Clínica La Manga (CLM)** | MySQL 8.0 | 3306 | Citas, prescripciones, médicos |
| **Laboratorio Clínico del Norte (LCN)** | MongoDB 7 | 27017 | Resultados de laboratorio |

> **Sin federación:** Llamadas telefónicas entre instituciones → envío de PDFs → horas de espera → información incompleta.
>
> **Con federación:** Una sola consulta SQL devuelve el historial completo del paciente en tiempo real.

---

## 2. ¿Qué es una base de datos federada?

Una **base de datos federada** es un sistema que permite consultar múltiples fuentes de datos heterogéneas —diferentes motores, diferentes servidores, incluso diferentes modelos de datos— como si fueran **una sola base de datos unificada**.

> **Principio fundamental:** No mueve ni duplica los datos. Los datos siguen viviendo en sus sistemas de origen. La capa federada **traduce y orquesta** las consultas en tiempo real.

```
                    ┌─────────────────────┐
   Cliente SQL ──►  │   CAPA FEDERADA     │
                    │      (Trino)        │
                    └──────┬──────┬───────┘
                           │      │      │
                    ┌──────▼─┐ ┌──▼──┐ ┌─▼──────┐
                    │PostgreS│ │MySQL│ │MongoDB │
                    │  (HUC) │ │(CLM)│ │ (LCN)  │
                    └────────┘ └─────┘ └────────┘
```

### Características clave

| Característica | Descripción |
|---|---|
| **Heterogeneidad** | Conecta distintos motores (relacional, documental, columnar, etc.) |
| **Autonomía** | Cada base de datos sigue administrándose de forma independiente |
| **Transparencia** | El cliente escribe SQL estándar; no sabe qué hay debajo |
| **Sin ETL** | No hay transformación ni carga previa de datos |

---

## 3. Arquitectura del sistema

Todo el entorno corre en contenedores Docker bajo la red privada `clinicas-caribe`. El coordinador de Trino es el **único punto de contacto** para el cliente; las tres bases de datos nunca se exponen directamente.

```
┌──────────────────────────────────────────────────────────────┐
│                  CLIENTE (Trino CLI / App)                    │
│   SELECT ... FROM postgresql.public.pacientes p              │
│   JOIN mongodb.lcn_db.resultados_laboratorio rl ...          │
└───────────────────────────┬──────────────────────────────────┘
                            │ SQL
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    TRINO COORDINATOR                          │
│   1. Parser    →  AST (árbol sintáctico)                     │
│   2. Analyzer  →  Resuelve catálogos y esquemas              │
│   3. Planner   →  Plan lógico distribuido                    │
│   4. Optimizer →  Pushdown de predicados, reordenamiento     │
│   5. Scheduler →  Asigna fragmentos a workers                │
└───────────┬────────────────────────┬─────────────────────────┘
            │ Fragment 1             │ Fragment 2
            ▼                        ▼
  ┌─────────────────┐      ┌──────────────────────┐
  │  Conector PG    │      │   Conector MongoDB   │
  │  postgresql     │      │   mongodb            │
  │  postgres-huc   │      │   mongodb-lcn        │
  └────────┬────────┘      └──────────┬───────────┘
           │ JDBC                     │ MongoDB Wire Protocol
           ▼                          ▼
  ┌────────────────┐        ┌──────────────────┐
  │  PostgreSQL    │        │     MongoDB      │
  │  HUC           │        │     LCN          │
  └────────────────┘        └──────────────────┘
           │                          │
           └────────────┬─────────────┘
                        ▼
               Resultado unificado
                   al cliente
```

---

## 4. Requisitos previos

- [Docker](https://docs.docker.com/get-docker/) >= 24
- [Docker Compose](https://docs.docker.com/compose/) >= 2.20
- Al menos **4 GB de RAM** disponibles para los contenedores
- Puerto `8080`, `5433`, `3306` y `27017` libres en tu máquina

---

## 5. Instalación y puesta en marcha

### 5.1 Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd BDF
```

### 5.2 Levantar todos los servicios

```bash
docker compose up -d
```

Este comando inicia los cuatro servicios en orden (las bases de datos primero, gracias a los `healthchecks`, y luego Trino):

| Servicio | Descripción |
|---|---|
| `trino-coordinator` | Motor de consulta federada — puerto `8080` |
| `postgres-huc` | PostgreSQL del Hospital Universitario del Caribe — puerto `5433` |
| `mysql-clm` | MySQL de Clínica La Manga — puerto `3306` |
| `mongodb-lcn` | MongoDB del Laboratorio Clínico del Norte — puerto `27017` |

### 5.3 Verificar que todo esté corriendo

```bash
docker compose ps
```

Todos los servicios deben aparecer con estado `Up` (o `healthy`).

### 5.4 Acceder a Trino

**CLI interactiva:**

```bash
docker exec -it trino-coordinator trino
```

**Interfaz web (Web UI):**

Abre [`http://localhost:8080`](http://localhost:8080) en tu navegador para ver el panel de métricas de Trino: consultas activas, workers, uso de memoria, etc.

### 5.5 Detener el entorno

```bash
# Solo detener (los datos persisten en volúmenes Docker)
docker compose down

# Detener y eliminar todos los datos
docker compose down -v
```

---

## 6. Cómo funciona Trino internamente

**Trino** (antes conocido como PrestoSQL) es un motor de consulta SQL distribuido y de código abierto, diseñado para consultar datos donde residen, sin importar su origen.

Cuando Trino recibe una consulta federada, ejecuta el siguiente pipeline:

```
1. PARSE       →  Analiza el SQL del cliente y genera un AST
2. PLAN        →  Genera un plan de ejecución distribuido
3. PUSH DOWN   →  Delega predicados y filtros a cada fuente (si es posible)
4. EXECUTE     →  Ejecuta fragmentos en paralelo contra cada conector
5. JOIN/MERGE  →  Une los resultados en el coordinador
6. RETURN      →  Devuelve el resultado al cliente como un único conjunto de filas
```

> **Connector API:** Trino no usa SQL genérico para hablar con cada motor. Cada fuente tiene su propio **conector** que "habla el idioma nativo" del motor (`JDBC` para relacionales, `Wire Protocol` para MongoDB, etc.).

---

## 7. Configuración de catálogos

Cada archivo `.properties` en `trino/catalog/` registra una fuente como un **catálogo**. Desde ese momento es posible consultarla con la notación `catalogo.esquema.tabla`.

**PostgreSQL (HUC):**

```properties
# trino/catalog/postgresql.properties
connector.name=postgresql
connection-url=jdbc:postgresql://postgres-huc:5432/huc_db
connection-user=huc_admin
connection-password=huc_pass_2024
```

**MySQL (CLM):**

```properties
# trino/catalog/mysql.properties
connector.name=mysql
connection-url=jdbc:mysql://mysql-clm:3306
connection-user=clm_admin
connection-password=clm_pass_2024
```

**MongoDB (LCN):**

```properties
# trino/catalog/mongodb.properties
connector.name=mongodb
mongodb.connection-url=mongodb://lcn_admin:lcn_pass_2024@mongodb-lcn:27017/
mongodb.schema-collection=_schema
```

> **Nota sobre MongoDB:** A diferencia de los motores relacionales, MongoDB requiere que los tipos de cada colección estén declarados en la colección especial `_schema`. El script `init-scripts/mongodb/01-init-lcn.js` se encarga de ello automáticamente.

---

## 8. Guía de uso: consultas federadas

Todos los ejemplos asumen que estás dentro de la **CLI de Trino** (`docker exec -it trino-coordinator trino`). También puedes ejecutar el archivo `queries-ejemplo.sql` como referencia.

### 8.1 Verificar catálogos y tablas disponibles

```sql
-- Ver los catálogos registrados
SHOW CATALOGS;
-- Resultado esperado: mongodb, mysql, postgresql, system

-- Ver tablas de cada fuente
SHOW TABLES FROM postgresql.public;
SHOW TABLES FROM mysql.clm_db;
SHOW SCHEMAS FROM mongodb;
```

Trino ve las tres clínicas como si fueran esquemas del mismo sistema.

---

### 8.2 Consultas individuales por fuente

Antes de federar, conviene verificar que cada fuente responde de forma independiente:

```sql
-- HUC — PostgreSQL: listar pacientes
SELECT numero_documento, primer_nombre, primer_apellido, eps, grupo_sanguineo
FROM postgresql.public.pacientes
ORDER BY numero_documento;

-- CLM — MySQL: listar citas
SELECT numero_documento, nombres, apellidos, fecha_cita, especialidad, estado_cita
FROM mysql.clm_db.citas
ORDER BY fecha_cita;

-- LCN — MongoDB: listar pacientes del laboratorio
SELECT numero_documento, nombre_completo, eps
FROM mongodb.lcn_db.pacientes
ORDER BY numero_documento;
```

> **Esquemas heterogéneos:** El nombre del paciente se guarda de forma diferente en cada clínica:
> - HUC → `primer_nombre + primer_apellido`
> - CLM → `nombres + apellidos`
> - LCN → `nombre_completo`
>
> Trino **no normaliza esto automáticamente**. Es responsabilidad de la query unificar los campos.

---

### 8.3 La consulta que justifica todo

**Historial completo de María Elena García (CC: 1001):** diagnósticos del HUC + resultados de laboratorio del LCN en una sola consulta.

```sql
SELECT
    'HUC'                  AS institucion,
    d.fecha_diagnostico    AS fecha,
    d.codigo_cie10         AS codigo,
    d.descripcion          AS detalle,
    d.tipo_diagnostico     AS tipo
FROM postgresql.public.diagnosticos d
WHERE d.numero_documento = '1001'

UNION ALL

SELECT
    'LCN'                  AS institucion,
    r.fecha_resultado      AS fecha,
    r.tipo_examen          AS codigo,
    r.observaciones        AS detalle,
    'Laboratorio'          AS tipo
FROM mongodb.lcn_db.resultados_laboratorio r
WHERE r.numero_documento = '1001'

ORDER BY fecha;
```

**Lo que ocurre internamente:**

1. Trino detecta dos fuentes: `postgresql` y `mongodb`
2. Divide la query en dos fragmentos y los ejecuta **en paralelo**
3. Cada conector aplica el `WHERE` **en el motor de origen** (pushdown)
4. Trino une los resultados y los ordena por fecha
5. El cliente recibe una sola tabla con la línea de tiempo completa

---

### 8.4 Perfil completo: tres clínicas en una sola fila

```sql
SELECT
    p_huc.numero_documento                              AS cedula,
    p_huc.primer_nombre || ' ' || p_huc.primer_apellido AS nombre_completo,
    p_huc.fecha_nacimiento,
    p_huc.eps,
    p_huc.grupo_sanguineo,
    (SELECT COUNT(*) FROM postgresql.public.consultas c
     WHERE c.numero_documento = p_huc.numero_documento) AS consultas_huc,
    (SELECT COUNT(*) FROM mysql.clm_db.citas ct
     WHERE ct.numero_documento = p_huc.numero_documento) AS citas_clm,
    (SELECT COUNT(*) FROM mongodb.lcn_db.resultados_laboratorio rl
     WHERE rl.numero_documento = p_huc.numero_documento) AS examenes_lcn
FROM postgresql.public.pacientes p_huc
WHERE p_huc.numero_documento = '1001';
```

> Tres subqueries, tres motores distintos, un solo `SELECT`. Sin federación, esto requeriría tres conexiones independientes y código de aplicación para unir los resultados.

---

### 8.5 JOIN cruzado: PostgreSQL ↔ MongoDB

```sql
SELECT
    p.numero_documento,
    p.primer_nombre || ' ' || p.primer_apellido AS paciente,
    p.eps,
    d.codigo_cie10,
    d.descripcion       AS diagnostico,
    d.fecha_diagnostico,
    rl.tipo_examen,
    rl.fecha_resultado,
    rl.observaciones    AS resultado_lab
FROM postgresql.public.pacientes p
JOIN postgresql.public.diagnosticos d
    ON p.numero_documento = d.numero_documento
JOIN mongodb.lcn_db.resultados_laboratorio rl
    ON p.numero_documento = rl.numero_documento
WHERE rl.fecha_resultado >= d.fecha_diagnostico - INTERVAL '30' DAY
ORDER BY p.numero_documento, d.fecha_diagnostico;
```

> Ninguno de los dos motores puede hacer este JOIN por sí solo. Trino actúa como intermediario que une los datos de ambos sistemas en tiempo de ejecución.

---

### 8.6 Resumen ejecutivo de la federación

```sql
SELECT 'Pacientes únicos en federación'   AS metrica,
       CAST(COUNT(DISTINCT numero_documento) AS VARCHAR) AS valor
FROM (
    SELECT numero_documento FROM postgresql.public.pacientes
    UNION
    SELECT numero_documento FROM mysql.clm_db.pacientes
    UNION
    SELECT numero_documento FROM mongodb.lcn_db.pacientes
)
UNION ALL
SELECT 'Consultas en HUC (PostgreSQL)',   CAST(COUNT(*) AS VARCHAR) FROM postgresql.public.consultas
UNION ALL
SELECT 'Citas en CLM (MySQL)',            CAST(COUNT(*) AS VARCHAR) FROM mysql.clm_db.citas
UNION ALL
SELECT 'Exámenes en LCN (MongoDB)',       CAST(COUNT(*) AS VARCHAR) FROM mongodb.lcn_db.resultados_laboratorio;
```

Cuatro tablas, tres motores distintos, una sola ejecución.

---

## 9. Estructura del proyecto

```
BDF/
├── docker-compose.yml              # Orquestación de los cuatro servicios
├── queries-ejemplo.sql             # Colección de consultas de demostración
├── EXPOSICION.md                   # Documentación de la presentación
│
├── trino/
│   └── catalog/
│       ├── postgresql.properties   # Catálogo HUC (PostgreSQL)
│       ├── mysql.properties        # Catálogo CLM (MySQL)
│       └── mongodb.properties      # Catálogo LCN (MongoDB)
│
└── init-scripts/
    ├── postgresql/
    │   └── 01-init-huc.sql         # Esquema y datos del HUC
    ├── mysql/
    │   └── 01-init-clm.sql         # Esquema y datos del CLM
    └── mongodb/
        └── 01-init-lcn.js          # Esquema y datos del LCN
```

---

## 10. Ventajas y limitaciones

### ✅ Ventajas

| Ventaja | Descripción |
|---|---|
| **Sin migración** | Los datos permanecen en sus sistemas de origen |
| **Sin duplicación** | No hay ETL ni sincronización que mantener |
| **SQL estándar** | El cliente no aprende APIs nuevas |
| **Heterogeneidad real** | Relacional + documental en la misma query |
| **Escalabilidad** | Se agregan catálogos sin cambiar el cliente |

### ⚠️ Limitaciones

| Limitación | Descripción |
|---|---|
| **Latencia de red** | Los datos viajan por red en tiempo de consulta |
| **Sin transacciones** | No hay ACID cruzado entre fuentes |
| **Pushdown limitado** | No todos los predicados se delegan al origen |
| **Optimización compleja** | El optimizador no conoce estadísticas internas de cada fuente |
| **MongoDB requiere schema** | Los tipos deben estar declarados en `_schema` |

---

## 11. ¿Cuándo usar federación?

**Úsala cuando…**

- Los datos **no pueden o no deben moverse** (regulaciones, propietarios distintos)
- Se necesita **visibilidad unificada** sin modificar los sistemas existentes
- Las consultas son de **análisis o reporting**, no transaccionales de alta frecuencia
- Se quiere evitar el mantenimiento de una copia replicada (Data Warehouse)

**No la uses cuando…**

- Se necesitan **joins muy frecuentes a gran escala** entre fuentes remotas → usar DW o Data Lake
- Se requieren **transacciones distribuidas** (ACID entre sistemas)
- La **latencia** de la fuente remota es inaceptable para el caso de uso

---

<div align="center">

*Bases de Datos Federadas · Caso de estudio: Red de Salud Clínicas del Caribe · 2026*

</div>
# MiniClassBDF
