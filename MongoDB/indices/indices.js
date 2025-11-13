// =============================================
// COLECCIÓN 1: sensores_iot
// Índice: Consultas híbridas por orden + tiempo
// =============================================
db.sensores_iot.createIndex(
  { id_orden: 1, timestamp: -1 },
  { name: "idx_orden_tiempo", background: true }
);
print("✓ sensores_iot: 1 índice (id_orden + timestamp)");

// =============================================
// COLECCIÓN 2: resultados_espectroscopia
// Índice: Integración con órdenes SQL
// =============================================
db.resultados_espectroscopia.createIndex(
  { id_orden: 1, fecha_analisis: -1 },
  { name: "idx_orden_fecha", background: true }
);
print("✓ resultados_espectroscopia: 1 índice (id_orden + fecha)");

// =============================================
// COLECCIÓN 3: imagenes_microscopia
// Índice: Búsquedas por orden
// =============================================
db.imagenes_microscopia.createIndex(
  { id_orden: 1, fecha_captura: -1 },
  { name: "idx_orden_captura", background: true }
);
print("✓ imagenes_microscopia: 1 índice (id_orden + fecha)");

// =============================================
// COLECCIÓN 4: logs_experimentos
// Índice: Logs por orden + timestamp
// =============================================
db.logs_experimentos.createIndex(
  { id_orden: 1, timestamp: -1 },
  { name: "idx_orden_timestamp", background: true }
);
print("✓ logs_experimentos: 1 índice (id_orden + timestamp)");

// =============================================
// COLECCIÓN 5: datos_simulacion_dft
// Índice: Simulaciones por nanomaterial
// =============================================
db.datos_simulacion_dft.createIndex(
  { id_nanomaterial: 1, fecha_simulacion: -1 },
  { name: "idx_nanomaterial_fecha", background: true }
);
print("✓ datos_simulacion_dft: 1 índice (id_nanomaterial + fecha)");

// =============================================
// COLECCIÓN 6: analisis_particulas
// Índice: Análisis por lote
// =============================================
db.analisis_particulas.createIndex(
  { id_lote: 1, fecha_analisis: -1 },
  { name: "idx_lote_fecha", background: true }
);
print("✓ analisis_particulas: 1 índice (id_lote + fecha)");

// =============================================
// COLECCIÓN 7: condiciones_ambientales
// Índice: Condiciones por orden
// =============================================
db.condiciones_ambientales.createIndex(
  { id_orden: 1, timestamp: -1 },
  { name: "idx_orden_timestamp", background: true }
);
print("✓ condiciones_ambientales: 1 índice (id_orden + timestamp)");

// =============================================
// COLECCIÓN 8: reportes_sintesis
// Índice 1: Reportes por orden
// Índice 2: Búsqueda texto (para el proyecto)
// =============================================
db.reportes_sintesis.createIndex(
  { id_orden: 1 },
  { name: "idx_orden", background: true }
);

db.reportes_sintesis.createIndex(
  { titulo: "text", resumen_ejecutivo: "text" },
  { 
    name: "idx_text_search",
    default_language: "spanish"
  }
);
print("✓ reportes_sintesis: 2 índices (id_orden + text)");

// =============================================
// COLECCIÓN 9: bibliografia_referencias
// Índice: Referencias por nanomaterial
// =============================================
db.bibliografia_referencias.createIndex(
  { id_nanomaterial: 1, año: -1 },
  { name: "idx_nanomaterial_año", background: true }
);
print("✓ bibliografia_referencias: 1 índice (id_nanomaterial + año)");
