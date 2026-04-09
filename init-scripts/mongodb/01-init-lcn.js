// =============================================
// Laboratorio Clínico del Norte (LCN)
// Base de datos: lcn_db
// MongoDB - Barranquilla, Colombia
// =============================================

db = db.getSiblingDB('lcn_db');

// =============================================
// Colección: pacientes
// Pacientes registrados en el laboratorio
// =============================================
db.createCollection('pacientes');

db.pacientes.insertMany([
  {
    "_id": "PAC-1001",
    "numero_documento": "1001",
    "tipo_documento": "CC",
    "nombre_completo": "María Elena García Pérez",
    "fecha_nacimiento": ISODate("1985-03-15"),
    "sexo": "F",
    "telefono": "3001234567",
    "email": "maria.garcia@email.com",
    "eps": "Coomeva EPS",
    "clinica_referencia": "Hospital Universitario del Caribe",
    "fecha_registro": ISODate("2024-01-18"),
    "activo": true
  },
  {
    "_id": "PAC-1002",
    "numero_documento": "1002",
    "tipo_documento": "CC",
    "nombre_completo": "Carlos Andrés López Mendoza",
    "fecha_nacimiento": ISODate("1978-07-22"),
    "sexo": "M",
    "telefono": "3009876543",
    "email": "carlos.lopez@email.com",
    "eps": "Sura EPS",
    "clinica_referencia": "Hospital Universitario del Caribe",
    "fecha_registro": ISODate("2024-02-12"),
    "activo": true
  },
  {
    "_id": "PAC-1003",
    "numero_documento": "1003",
    "tipo_documento": "CC",
    "nombre_completo": "Ana Lucía Martínez Solano",
    "fecha_nacimiento": ISODate("1992-09-12"),
    "sexo": "F",
    "telefono": "3004445566",
    "email": "ana.martinez@email.com",
    "eps": "Sura EPS",
    "clinica_referencia": "Clínica La Manga",
    "fecha_registro": ISODate("2024-01-22"),
    "activo": true
  }
]);

// =============================================
// Colección: resultados_laboratorio
// Resultados de exámenes de laboratorio
// =============================================
db.createCollection('resultados_laboratorio');

db.resultados_laboratorio.insertMany([
  // María Elena García - Exámenes gastro
  {
    "_id": "LAB-001",
    "numero_documento": "1001",
    "fecha_toma_muestra": ISODate("2024-01-18"),
    "fecha_resultado": ISODate("2024-01-19"),
    "tipo_examen": "Hemograma completo",
    "medico_solicitante": "Dr. Roberto Villaquirán - HUC",
    "resultados": [
      { "parametro": "Hemoglobina", "valor": "12.5", "unidad": "g/dL", "referencia": "12.0 - 16.0", "estado": "Normal" },
      { "parametro": "Hematocrito", "valor": "37.2", "unidad": "%", "referencia": "36.0 - 46.0", "estado": "Normal" },
      { "parametro": "Leucocitos", "valor": "7800", "unidad": "/mm3", "referencia": "4500 - 11000", "estado": "Normal" },
      { "parametro": "Plaquetas", "valor": "245000", "unidad": "/mm3", "referencia": "150000 - 400000", "estado": "Normal" }
    ],
    "observaciones": "Hemograma dentro de parámetros normales"
  },
  {
    "_id": "LAB-002",
    "numero_documento": "1001",
    "fecha_toma_muestra": ISODate("2024-01-18"),
    "fecha_resultado": ISODate("2024-01-20"),
    "tipo_examen": "Perfil hepático",
    "medico_solicitante": "Dr. Roberto Villaquirán - HUC",
    "resultados": [
      { "parametro": "TGO (AST)", "valor": "28", "unidad": "U/L", "referencia": "10 - 40", "estado": "Normal" },
      { "parametro": "TGP (ALT)", "valor": "35", "unidad": "U/L", "referencia": "7 - 56", "estado": "Normal" },
      { "parametro": "Bilirrubina total", "valor": "0.8", "unidad": "mg/dL", "referencia": "0.1 - 1.2", "estado": "Normal" },
      { "parametro": "Fosfatasa alcalina", "valor": "72", "unidad": "U/L", "referencia": "44 - 147", "estado": "Normal" }
    ],
    "observaciones": "Función hepática normal"
  },
  {
    "_id": "LAB-003",
    "numero_documento": "1001",
    "fecha_toma_muestra": ISODate("2024-03-18"),
    "fecha_resultado": ISODate("2024-03-20"),
    "tipo_examen": "Helicobacter pylori (antígeno en heces)",
    "medico_solicitante": "Dra. Carmen Ibarra - HUC",
    "resultados": [
      { "parametro": "Helicobacter pylori", "valor": "Positivo", "unidad": "Cualitativo", "referencia": "Negativo", "estado": "Alterado" }
    ],
    "observaciones": "Resultado positivo para H. pylori. Se recomienda tratamiento erradicador."
  },

  // Carlos Andrés López - Exámenes cardiológicos
  {
    "_id": "LAB-004",
    "numero_documento": "1002",
    "fecha_toma_muestra": ISODate("2024-02-12"),
    "fecha_resultado": ISODate("2024-02-13"),
    "tipo_examen": "Perfil lipídico",
    "medico_solicitante": "Dr. Julio César Pumarejo - HUC",
    "resultados": [
      { "parametro": "Colesterol total", "valor": "245", "unidad": "mg/dL", "referencia": "< 200", "estado": "Alterado" },
      { "parametro": "LDL Colesterol", "valor": "168", "unidad": "mg/dL", "referencia": "< 130", "estado": "Alterado" },
      { "parametro": "HDL Colesterol", "valor": "38", "unidad": "mg/dL", "referencia": "> 40", "estado": "Alterado" },
      { "parametro": "Triglicéridos", "valor": "210", "unidad": "mg/dL", "referencia": "< 150", "estado": "Alterado" }
    ],
    "observaciones": "Dislipidemia severa. Riesgo cardiovascular alto. Se recomienda cambio de dieta y medicación."
  },
  {
    "_id": "LAB-005",
    "numero_documento": "1002",
    "fecha_toma_muestra": ISODate("2024-06-03"),
    "fecha_resultado": ISODate("2024-06-04"),
    "tipo_examen": "Perfil lipídico (control)",
    "medico_solicitante": "Dr. Julio César Pumarejo - HUC",
    "resultados": [
      { "parametro": "Colesterol total", "valor": "210", "unidad": "mg/dL", "referencia": "< 200", "estado": "Alterado" },
      { "parametro": "LDL Colesterol", "valor": "132", "unidad": "mg/dL", "referencia": "< 130", "estado": "Alterado" },
      { "parametro": "HDL Colesterol", "valor": "44", "unidad": "mg/dL", "referencia": "> 40", "estado": "Normal" },
      { "parametro": "Triglicéridos", "valor": "168", "unidad": "mg/dL", "referencia": "< 150", "estado": "Alterado" }
    ],
    "observaciones": "Mejoría parcial con tratamiento. Continuar dieta y medicación."
  },

  // Ana Lucía Martínez - Exámenes prenatales
  {
    "_id": "LAB-006",
    "numero_documento": "1003",
    "fecha_toma_muestra": ISODate("2024-01-22"),
    "fecha_resultado": ISODate("2024-01-23"),
    "tipo_examen": "Perfil prenatal - primer trimestre",
    "medico_solicitante": "Dra. Marcela Henao - CLM",
    "resultados": [
      { "parametro": "Hemoglobina", "valor": "11.8", "unidad": "g/dL", "referencia": "11.0 - 14.0", "estado": "Normal" },
      { "parametro": "Glucosa en ayunas", "valor": "88", "unidad": "mg/dL", "referencia": "70 - 100", "estado": "Normal" },
      { "parametro": "TSH", "valor": "2.1", "unidad": "mUI/L", "referencia": "0.4 - 4.0", "estado": "Normal" },
      { "parametro": "Grupo sanguíneo", "valor": "A+", "unidad": "", "referencia": "", "estado": "Normal" },
      { "parametro": "VDRL", "valor": "No reactivo", "unidad": "Cualitativo", "referencia": "No reactivo", "estado": "Normal" },
      { "parametro": "VIH", "valor": "No reactivo", "unidad": "Cualitativo", "referencia": "No reactivo", "estado": "Normal" }
    ],
    "observaciones": "Perfil prenatal dentro de parámetros normales. Embarazo de bajo riesgo."
  },
  {
    "_id": "LAB-007",
    "numero_documento": "1003",
    "fecha_toma_muestra": ISODate("2024-03-14"),
    "fecha_resultado": ISODate("2024-03-15"),
    "tipo_examen": "Curva de tolerancia a la glucosa",
    "medico_solicitante": "Dra. Marcela Henao - CLM",
    "resultados": [
      { "parametro": "Glucosa basal", "valor": "92", "unidad": "mg/dL", "referencia": "< 92", "estado": "Normal" },
      { "parametro": "Glucosa 1 hora", "valor": "178", "unidad": "mg/dL", "referencia": "< 180", "estado": "Normal" },
      { "parametro": "Glucosa 2 horas", "valor": "152", "unidad": "mg/dL", "referencia": "< 153", "estado": "Normal" }
    ],
    "observaciones": "Tolerancia a la glucosa normal. No se evidencia diabetes gestacional."
  },
  {
    "_id": "LAB-008",
    "numero_documento": "1003",
    "fecha_toma_muestra": ISODate("2024-05-08"),
    "fecha_resultado": ISODate("2024-05-09"),
    "tipo_examen": "Hemograma + Coagulación (pre-parto)",
    "medico_solicitante": "Dra. Marcela Henao - CLM",
    "resultados": [
      { "parametro": "Hemoglobina", "valor": "10.9", "unidad": "g/dL", "referencia": "11.0 - 14.0", "estado": "Alterado" },
      { "parametro": "Hematocrito", "valor": "32.5", "unidad": "%", "referencia": "33.0 - 42.0", "estado": "Alterado" },
      { "parametro": "Plaquetas", "valor": "198000", "unidad": "/mm3", "referencia": "150000 - 400000", "estado": "Normal" },
      { "parametro": "TP", "valor": "12.5", "unidad": "seg", "referencia": "11.0 - 13.5", "estado": "Normal" },
      { "parametro": "TPT", "valor": "30.2", "unidad": "seg", "referencia": "25.0 - 35.0", "estado": "Normal" }
    ],
    "observaciones": "Anemia leve del tercer trimestre. Refuerzo con suplementos de hierro."
  }
]);

// Crear índices para optimizar las consultas federadas
db.pacientes.createIndex({ "numero_documento": 1 });
db.resultados_laboratorio.createIndex({ "numero_documento": 1 });
db.resultados_laboratorio.createIndex({ "tipo_examen": 1 });
db.resultados_laboratorio.createIndex({ "fecha_toma_muestra": 1 });

print("LCN - Base de datos inicializada correctamente con datos de ejemplo");
