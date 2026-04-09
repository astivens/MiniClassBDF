<div align="center">

<h1>Bases de Datos Federadas con Trino</h1>

<p><strong>Red de Salud — Clínicas del Caribe · Barranquilla, Colombia</strong></p>

<p><em>Tres instituciones. Tres motores de base de datos. Un solo punto de consulta.</em></p>

<br/>

<img src="https://img.shields.io/badge/Trino-Latest-DD00A1?style=for-the-badge&logo=trino&logoColor=white" alt="Trino"/>
<img src="https://img.shields.io/badge/PostgreSQL-16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
<img src="https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL"/>
<img src="https://img.shields.io/badge/MongoDB-7-47A248?style=for-the-badge&logo=mongodb&logoColor=white" alt="MongoDB"/>
<img src="https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/>
<img src="https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge" alt="License"/>

</div>

---

## Tabla de contenidos

1. [El problema que resuelve este proyecto](#1-el-problema-que-resuelve-este-proyecto)
2. [Concepto: Bases de datos federadas](#2-concepto-bases-de-datos-federadas)
3. [Trino: el motor de consulta federada](#3-trino-el-motor-de-consulta-federada)
4. [Arquitectura del sistema](#4-arquitectura-del-sistema)
5. [Requisitos previos](#5-requisitos-previos)
6. [Instalación y puesta en marcha](#6-instalación-y-puesta-en-marcha)
7. [Configuración de catálogos](#7-configuración-de-catálogos)
8. [Guía de uso: consultas federadas](#8-guía-de-uso-consultas-federadas)
9. [Estructura del proyecto](#9-estructura-del-proyecto)
10. [Ventajas y limitaciones](#10-ventajas-y-limitaciones)
11. [Cuándo usar federación](#11-cuándo-usar-federación)

---

## 1. El problema que resuelve este proyecto

Imagina que eres médico en Barranquilla. Tu paciente, **María Elena García**, llega a urgencias.
Necesitas saber de inmediato:

- ► ¿Qué diagnósticos tiene registrados?
- ► ¿Qué exámenes de laboratorio le han realizado?
- ► ¿Qué medicamentos le han prescrito?

El problema es que sus datos están repartidos en **tres instituciones distintas**, cada una con su propio
sistema de información y motor de base de datos independiente:

| Institución | Motor | Puerto | Datos almacenados |
|---|---|:---:|---|
| **Hospital Universitario del Caribe (HUC)** | PostgreSQL 16 | `5433` | Pacientes, consultas, diagnósticos |
| **Clínica La Manga (CLM)** | MySQL 8.0 | `3306` | Citas, prescripciones, médicos |
| **Laboratorio Clínico del Norte (LCN)** | MongoDB 7 | `27017` | Resultados de laboratorio |

> **◆ Sin federación**
> Llamadas telefónicas entre instituciones → envío de PDFs por correo → horas de espera → información incompleta o desactualizada.

> **◆ Con federación**
> Una sola consulta SQL devuelve el historial clínico completo del paciente en tiempo real, cruzando las tres instituciones simultáneamente.

---

## 2. Concepto: Bases de datos federadas

### 2.1 Definición

Una **base de datos federada** (también llamada *federated database system*, FDBS) es una arquitectura de sistemas de información que expone múltiples bases de datos autónomas y heterogéneas como si fueran **una única fuente de datos unificada**, sin mover ni centralizar los datos.

El término "federada" hace referencia al mismo principio político de una federación: unidades independientes que cooperan bajo una autoridad común sin perder su autonomía interna.

> **Principio fundamental**
> Los datos **no se mueven ni se duplican**. Cada base de datos conserva su propiedad y administración. La capa federada **traduce, enruta y orquesta** las consultas en tiempo real contra cada fuente.

### 2.2 Modelo de arquitectura

Un sistema federado se compone de tres capas:

```
  ┌──────────────────────────────────────────┐
  │           CAPA DE PRESENTACIÓN           │
  │   Cliente SQL (CLI, app, BI tool…)        │
  │   Escribe SQL estándar, ignora el origen  │
  └─────────────────┬────────────────────────┘
                    │
                    ▼
  ┌──────────────────────────────────────────┐
  │            CAPA FEDERADA                 │
  │   Motor de federación (Trino)            │
  │   ◆ Resuelve catálogos                   │
  │   ◆ Planifica la ejecución distribuida   │
  │   ◆ Aplica pushdown de predicados        │
  │   ◆ Ensambla el resultado final          │
  └────────┬──────────────┬──────────────────┘
           │              │              │
           ▼              ▼              ▼
  ┌──────────────┐ ┌──────────┐ ┌─────────────┐
  │  PostgreSQL  │ │  MySQL   │ │   MongoDB   │
  │  (HUC)       │ │  (CLM)   │ │   (LCN)     │
  │  Relacional  │ │Relacional│ │  Documental │
  └──────────────┘ └──────────┘ └─────────────┘
```

### 2.3 Propiedades de un sistema federado

Un FDBS formal debe satisfacer cinco propiedades definidas por Sheth & Larson (1990):

| Propiedad | Descripción |
|---|---|
| **Heterogeneidad** | Integra fuentes con distintos modelos, lenguajes y sistemas operativos |
| **Autonomía de diseño** | Cada BD conserva su propio esquema, sin adaptarse a los demás |
| **Autonomía de ejecución** | Cada BD procesa sus operaciones de forma independiente |
| **Autonomía de comunicación** | Cada BD decide cuándo y cómo participa en la federación |
| **Transparencia** | El cliente percibe una sola BD, sin conocer la distribución interna |

### 2.4 Federación vs. otras arquitecturas de integración

Es importante distinguir la federación de aproximaciones relacionadas:

| Arquitectura | Mueve datos | Latencia de consulta | Mantenimiento | Caso de uso |
|---|:---:|:---:|:---:|---|
| **Federación (Trino)** | No | Media-alta | Bajo | Reportes ad-hoc, visibilidad unificada |
| **Data Warehouse** | Si (ETL) | Baja | Alto | Analítica histórica a gran escala |
| **Data Lake** | Si (ELT) | Variable | Medio | Big data, ML, datos semiestructurados |
| **Replicación** | Si (CDC) | Baja | Alto | Alta disponibilidad, failover |
| **API Gateway** | No | Media | Medio | Servicios heterogéneos REST/GraphQL |

> **Cuándo la federación es la respuesta correcta**
> Cuando los datos pertenecen a distintos propietarios o sistemas que no se pueden (o no se deben) consolidar, pero se necesita una vista unificada para consultas de lectura o análisis.

### 2.5 El reto de la heterogeneidad semántica

Uno de los desafíos más reales de la federación es que diferentes sistemas modelan la misma entidad de forma distinta. En este proyecto, el nombre del paciente se almacena de tres maneras:

| Institución | Columna(s) | Ejemplo |
|---|---|---|
| HUC (PostgreSQL) | `primer_nombre`, `primer_apellido` | `'María'`, `'García'` |
| CLM (MySQL) | `nombres`, `apellidos` | `'María Elena'`, `'García López'` |
| LCN (MongoDB) | `nombre_completo` | `'María Elena García López'` |

Trino no resuelve estas inconsistencias automáticamente. La normalización semántica es **responsabilidad de la query**, usando concatenaciones, aliases y lógica de negocio explícita.

---

## 3. Trino: el motor de consulta federada

### 3.1 Qué es Trino

**Trino** (antes PrestoSQL, creado en Meta en 2012) es un motor de consulta SQL distribuido, de código abierto, diseñado con un objetivo específico: **consultar datos donde residen**, sin importar el origen, el modelo o el protocolo de cada fuente.

A diferencia de un motor de base de datos tradicional, Trino **no almacena datos**. Es un motor de cómputo puro: recibe una query SQL, la fragmenta, la delega a los conectores correspondientes, recibe los resultados parciales y los ensambla en una respuesta unificada.

### 3.2 Pipeline de ejecución

Cuando Trino recibe una consulta federada, ejecuta el siguiente pipeline de forma determinista:

```mermaid
flowchart LR
    A["PARSE\nAnaliza el SQL\ny genera el AST"]
    B["PLAN\nCrea el plan\nde ejecución lógico"]
    C["PUSH DOWN\nDelega filtros y\npredicados al origen"]
    D["EXECUTE\nEjecuta fragmentos\nen paralelo"]
    E["JOIN / MERGE\nEnsambla resultados\nen el coordinador"]
    F["RETURN\nEntrega resultado\nfinal al cliente"]

    A --> B --> C --> D --> E --> F

    style A fill:#1e3a5f,color:#fff,stroke:#4169E1
    style B fill:#1e3a5f,color:#fff,stroke:#4169E1
    style C fill:#1a4a2e,color:#fff,stroke:#2E8B57
    style D fill:#1a4a2e,color:#fff,stroke:#2E8B57
    style E fill:#4a1e1e,color:#fff,stroke:#B22222
    style F fill:#4a1e1e,color:#fff,stroke:#B22222
```

#### Detalle de cada fase

| Fase | Responsabilidad |
|---|---|
| **PARSE** | Tokeniza el SQL y construye el AST (Abstract Syntax Tree). Detecta errores de sintaxis. |
| **PLAN** | El Analyzer resuelve nombres de catálogos, esquemas y tablas. El Planner genera un plan lógico distribuido. |
| **PUSH DOWN** | El Optimizer intenta delegar filtros (`WHERE`), proyecciones (`SELECT`) y límites (`LIMIT`) directamente al motor de origen para reducir el volumen de datos transferidos. |
| **EXECUTE** | El Scheduler asigna fragmentos del plan a los workers disponibles. Cada conector ejecuta su fragmento contra el motor de origen usando su protocolo nativo. |
| **JOIN / MERGE** | El coordinador recibe los resultados parciales de todos los workers y aplica los `JOIN`, `ORDER BY`, `GROUP BY` y agregaciones que no pudieron delegarse. |
| **RETURN** | El resultado final se serializa y devuelve al cliente como un único conjunto de filas. |

### 3.3 Connector API

Trino no usa SQL genérico para comunicarse con cada motor. Cada fuente tiene su propio **conector** que implementa el protocolo nativo del motor de destino:

| Conector | Protocolo | Fuente en este proyecto |
|---|---|---|
| `postgresql` | JDBC + PostgreSQL Wire Protocol | `postgres-huc` |
| `mysql` | JDBC + MySQL Protocol | `mysql-clm` |
| `mongodb` | MongoDB Wire Protocol | `mongodb-lcn` |

> **Sobre el pushdown**
> No todos los conectores soportan el mismo nivel de pushdown. El conector de PostgreSQL puede delegar filtros complejos, funciones de ventana y expresiones regulares. El conector de MongoDB delega filtros básicos como comparaciones de igualdad y rangos. Cuando un predicado no puede delegarse, Trino lo evalúa en el coordinador sobre los datos ya transferidos.

---

## 4. Arquitectura del sistema

Todo el entorno corre en contenedores Docker bajo la red privada `clinicas-caribe`.
El coordinador de Trino es el **único punto de contacto** para el cliente; las tres bases de datos no se exponen directamente al exterior.

### 4.1 Diagrama de componentes

```mermaid
graph TD
    Client(["Cliente SQL\nTrino CLI / Aplicación / BI"])

    subgraph Docker["Red: clinicas-caribe"]
        Trino["Trino Coordinator\n:8080"]

        subgraph HUC["Hospital Universitario del Caribe"]
            PG["PostgreSQL 16\n:5433\nhuc_db"]
        end

        subgraph CLM["Clínica La Manga"]
            MY["MySQL 8.0\n:3306\nclm_db"]
        end

        subgraph LCN["Laboratorio Clínico del Norte"]
            MG["MongoDB 7\n:27017\nlcn_db"]
        end
    end

    Client -->|"SQL estándar"| Trino
    Trino -->|"JDBC"| PG
    Trino -->|"JDBC"| MY
    Trino -->|"Wire Protocol"| MG
```

### 4.2 Flujo de ejecución de una consulta federada

```mermaid
sequenceDiagram
    participant C  as Cliente
    participant T  as Trino Coordinator
    participant PG as PostgreSQL (HUC)
    participant MG as MongoDB (LCN)

    C->>T: SELECT ... FROM postgresql.public.diagnosticos<br/>UNION ALL<br/>SELECT ... FROM mongodb.lcn_db.resultados_laboratorio

    T->>T: PARSE  → genera AST
    T->>T: PLAN   → plan lógico distribuido
    T->>T: OPTIMIZE → pushdown de WHERE, ORDER BY

    par Ejecución paralela
        T->>PG: Fragment 1: SELECT ... WHERE numero_documento = '1001'
        T->>MG: Fragment 2: SELECT ... WHERE numero_documento = '1001'
    end

    PG-->>T: Resultados parciales (diagnósticos)
    MG-->>T: Resultados parciales (lab results)

    T->>T: MERGE + ORDER BY fecha

    T-->>C: Resultado unificado (línea de tiempo completa)
```

---

## 5. Requisitos previos

| Dependencia | Versión mínima | Notas |
|---|:---:|---|
| [Docker Engine](https://docs.docker.com/get-docker/) | 24 | Incluye BuildKit |
| [Docker Compose](https://docs.docker.com/compose/) | 2.20 | Plugin integrado en Docker Desktop |
| RAM disponible | 4 GB | Recomendado 6 GB para ejecución estable |
| Puertos libres | — | `8080`, `5433`, `3306`, `27017` |

---

## 6. Instalación y puesta en marcha

### 6.1 Clonar el repositorio

```bash
git clone https://github.com/astivens/MiniClassBDF.git
cd MiniClassBDF
```

### 6.2 Levantar todos los servicios

```bash
docker compose up -d
```

Docker Compose inicia los servicios en orden controlado: las bases de datos arrancan primero y deben superar sus `healthchecks` antes de que Trino se inicialice. El proceso completo tarda aproximadamente 30–60 segundos.

| Servicio | Imagen | Puerto | Estado esperado |
|---|---|:---:|---|
| `trino-coordinator` | `trinodb/trino:latest` | `8080` | `Up` |
| `postgres-huc` | `postgres:16` | `5433` | `healthy` |
| `mysql-clm` | `mysql:8.0` | `3306` | `healthy` |
| `mongodb-lcn` | `mongo:7` | `27017` | `Up` |

### 6.3 Verificar el estado

```bash
docker compose ps
```

### 6.4 Acceder a Trino

**▶ CLI interactiva:**

```bash
docker exec -it trino-coordinator trino
```

**▶ Interfaz web (Web UI):**

Abre [`http://localhost:8080`](http://localhost:8080) para ver el panel de métricas: consultas activas, workers, throughput y uso de memoria.

### 6.5 Detener el entorno

```bash
# Detener contenedores (datos persisten en volúmenes)
docker compose down

# Detener y eliminar todos los datos
docker compose down -v
```

---

## 7. Configuración de catálogos

Cada archivo `.properties` en `trino/catalog/` registra una fuente como un **catálogo** de Trino.
Una vez registrado, el catálogo es accesible con la notación: `catalogo.esquema.tabla`.

**► PostgreSQL — Hospital Universitario del Caribe (HUC)**

```properties
# trino/catalog/postgresql.properties
connector.name=postgresql
connection-url=jdbc:postgresql://postgres-huc:5432/huc_db
connection-user=huc_admin
connection-password=huc_pass_2024
```

**► MySQL — Clínica La Manga (CLM)**

```properties
# trino/catalog/mysql.properties
connector.name=mysql
connection-url=jdbc:mysql://mysql-clm:3306
connection-user=clm_admin
connection-password=clm_pass_2024
```

**► MongoDB — Laboratorio Clínico del Norte (LCN)**

```properties
# trino/catalog/mongodb.properties
connector.name=mongodb
mongodb.connection-url=mongodb://lcn_admin:lcn_pass_2024@mongodb-lcn:27017/
mongodb.schema-collection=_schema
```

> **Nota sobre MongoDB y `_schema`**
> A diferencia de los motores relacionales, MongoDB no tiene un esquema fijo. Para que Trino pueda inferir tipos y columnas, los metadatos de cada colección deben estar declarados en la colección especial `_schema`. El script `init-scripts/mongodb/01-init-lcn.js` crea y puebla esta colección automáticamente al iniciar el contenedor.

---

## 8. Guía de uso: consultas federadas

Todos los ejemplos siguientes se ejecutan dentro de la CLI de Trino:

```bash
docker exec -it trino-coordinator trino
```

El archivo `queries-ejemplo.sql` contiene todas las consultas organizadas para ejecución secuencial.

---

### 8.1 Verificar catálogos y tablas disponibles

```sql
-- Catálogos registrados en Trino
SHOW CATALOGS;
-- Resultado esperado: mongodb, mysql, postgresql, system

-- Tablas visibles por catálogo
SHOW TABLES FROM postgresql.public;
SHOW TABLES FROM mysql.clm_db;
SHOW SCHEMAS FROM mongodb;
```

Trino ve las tres clínicas como si fueran esquemas del mismo sistema.

---

### 8.2 Consultas individuales por fuente (warmup)

Antes de federar, conviene confirmar que cada fuente responde de forma independiente:

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

> **Heterogeneidad semántica**
> El nombre del paciente se almacena de forma diferente en cada sistema:
>
> ○ HUC → `primer_nombre || ' ' || primer_apellido`
> ○ CLM → `nombres || ' ' || apellidos`
> ○ LCN → `nombre_completo`
>
> Trino no normaliza esto automáticamente. La unificación es responsabilidad de la query.

---

### 8.3 Historial completo del paciente (UNION federado)

**Caso:** Historial de María Elena García (CC: `1001`) — diagnósticos del HUC + resultados del LCN en una sola consulta.

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
4. Trino une los resultados y aplica el `ORDER BY fecha` en el coordinador
5. El cliente recibe una sola tabla con la línea de tiempo clínica completa

---

### 8.4 Perfil completo: tres clínicas en una sola fila

```sql
SELECT
    p_huc.numero_documento                               AS cedula,
    p_huc.primer_nombre || ' ' || p_huc.primer_apellido  AS nombre_completo,
    p_huc.fecha_nacimiento,
    p_huc.eps,
    p_huc.grupo_sanguineo,
    (SELECT COUNT(*)
     FROM postgresql.public.consultas c
     WHERE c.numero_documento = p_huc.numero_documento)  AS consultas_huc,
    (SELECT COUNT(*)
     FROM mysql.clm_db.citas ct
     WHERE ct.numero_documento = p_huc.numero_documento) AS citas_clm,
    (SELECT COUNT(*)
     FROM mongodb.lcn_db.resultados_laboratorio rl
     WHERE rl.numero_documento = p_huc.numero_documento) AS examenes_lcn
FROM postgresql.public.pacientes p_huc
WHERE p_huc.numero_documento = '1001';
```

> Tres subqueries correlacionadas, tres motores distintos, un solo `SELECT`. Sin federación, este resultado requeriría tres conexiones independientes y código de aplicación para unir los resultados.

---

### 8.5 JOIN cruzado entre PostgreSQL y MongoDB

```sql
SELECT
    p.numero_documento,
    p.primer_nombre || ' ' || p.primer_apellido  AS paciente,
    p.eps,
    d.codigo_cie10,
    d.descripcion                                AS diagnostico,
    d.fecha_diagnostico,
    rl.tipo_examen,
    rl.fecha_resultado,
    rl.observaciones                             AS resultado_lab
FROM postgresql.public.pacientes p
JOIN postgresql.public.diagnosticos d
    ON p.numero_documento = d.numero_documento
JOIN mongodb.lcn_db.resultados_laboratorio rl
    ON p.numero_documento = rl.numero_documento
WHERE rl.fecha_resultado >= d.fecha_diagnostico - INTERVAL '30' DAY
ORDER BY p.numero_documento, d.fecha_diagnostico;
```

> Ninguno de los dos motores puede ejecutar este `JOIN` por sí solo. Trino actúa como intermediario: extrae los datos de cada fuente con sus predicados delegados y realiza el join en el coordinador.

---

### 8.6 Resumen ejecutivo de la federación

```sql
SELECT 'Pacientes únicos en federación'  AS metrica,
       CAST(COUNT(DISTINCT numero_documento) AS VARCHAR) AS valor
FROM (
    SELECT numero_documento FROM postgresql.public.pacientes
    UNION
    SELECT numero_documento FROM mysql.clm_db.pacientes
    UNION
    SELECT numero_documento FROM mongodb.lcn_db.pacientes
)

UNION ALL
SELECT 'Consultas en HUC (PostgreSQL)',
       CAST(COUNT(*) AS VARCHAR)
FROM postgresql.public.consultas

UNION ALL
SELECT 'Citas en CLM (MySQL)',
       CAST(COUNT(*) AS VARCHAR)
FROM mysql.clm_db.citas

UNION ALL
SELECT 'Examenes en LCN (MongoDB)',
       CAST(COUNT(*) AS VARCHAR)
FROM mongodb.lcn_db.resultados_laboratorio;
```

Cuatro tablas, tres motores distintos, una sola ejecución.

---

## 9. Estructura del proyecto

```
MiniClassBDF/
│
├── docker-compose.yml                   ← Orquestación de los cuatro servicios
├── queries-ejemplo.sql                  ← Colección de consultas de demostración
├── README.md
├── .gitignore
│
├── trino/
│   └── catalog/
│       ├── postgresql.properties        ← Catálogo HUC (PostgreSQL)
│       ├── mysql.properties             ← Catálogo CLM (MySQL)
│       └── mongodb.properties           ← Catálogo LCN (MongoDB)
│
└── init-scripts/
    ├── postgresql/
    │   └── 01-init-huc.sql              ← Esquema + datos de ejemplo (HUC)
    ├── mysql/
    │   └── 01-init-clm.sql              ← Esquema + datos de ejemplo (CLM)
    └── mongodb/
        └── 01-init-lcn.js               ← Esquema (_schema) + datos de ejemplo (LCN)
```

---

## 10. Ventajas y limitaciones

### Ventajas

| Ventaja | Descripción |
|---|---|
| **Sin migración de datos** | Los datos permanecen en sus sistemas de origen. No hay ETL. |
| **Sin duplicación** | No existe una copia secundaria que mantener sincronizada. |
| **SQL estándar** | El cliente escribe SQL ANSI; no aprende APIs ni SDKs de cada motor. |
| **Heterogeneidad real** | Relacional y documental en la misma query con `JOIN` y `UNION`. |
| **Escalabilidad horizontal** | Se agregan nuevos catálogos sin modificar el cliente ni los sistemas existentes. |
| **Autonomía preservada** | Cada institución sigue administrando su BD con su propio equipo y reglas. |

### Limitaciones

| Limitación | Descripción |
|---|---|
| **Latencia de red** | Los datos viajan por red en tiempo de consulta. No apto para queries de alta frecuencia. |
| **Sin transacciones distribuidas** | No existe ACID entre fuentes. Las operaciones de escritura no son atómicas entre motores. |
| **Pushdown parcial** | No todos los predicados se delegan al origen; algunos se evalúan en el coordinador sobre datos ya transferidos. |
| **Optimizador ciego** | Trino no conoce las estadísticas internas de cada fuente, lo que puede generar planes subóptimos. |
| **MongoDB requiere `_schema`** | Las colecciones de MongoDB deben tener sus tipos declarados explícitamente para que Trino las pueda consultar. |

---

## 11. Cuándo usar federación

**Úsala cuando...**

- ► Los datos no pueden o no deben moverse (regulaciones, distintos propietarios, contratos)
- ► Se necesita visibilidad unificada sin modificar los sistemas existentes
- ► Las consultas son de análisis o reporting, no transaccionales de alta frecuencia
- ► Se quiere evitar el mantenimiento de una copia replicada (Data Warehouse)
- ► Las instituciones son autónomas y no existe un equipo de datos centralizado

**No la uses cuando...**

- ► Se necesitan joins muy frecuentes a gran escala entre fuentes remotas → considerar DW o Data Lake
- ► Se requieren transacciones distribuidas con garantías ACID entre sistemas
- ► La latencia de red de la fuente remota es inaceptable para el caso de uso
- ► Los datos deben procesarse con transformaciones complejas de forma recurrente → considerar ETL + DW

---

<div align="center">

<sub>Bases de Datos Federadas · Caso de estudio: Red de Salud Clínicas del Caribe · Barranquilla, Colombia · 2026</sub>

</div>
