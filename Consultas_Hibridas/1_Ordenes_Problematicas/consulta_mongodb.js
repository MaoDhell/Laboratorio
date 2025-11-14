// =====================================================
// CONSULTA HÍBRIDA 1: ÓRDENES PROBLEMÁTICAS
// Parte 2: MongoDB
// =====================================================
// Objetivo: Analizar patrones de sensores IoT en órdenes
//           con bajo rendimiento detectadas en SQL Server
// =====================================================

// NOTA: Los IDs [5, 8, 12, 15] vienen de la consulta SQL
// Reemplazar con los IDs reales obtenidos de SQL Server

// Agregación 1: Estadísticas de sensores por orden problemática
db.sensores_iot.aggregate([
    {
        $match: {
            id_orden: { $in: [5, 8, 12, 15] }  // IDs de órdenes problemáticas
        }
    },
    {
        $group: {
            _id: "$id_orden",
            temperatura_promedio: { $avg: "$temperatura_celsius" },
            temperatura_maxima: { $max: "$temperatura_celsius" },
            temperatura_minima: { $min: "$temperatura_celsius" },
            presion_promedio: { $avg: "$presion_atm" },
            presion_maxima: { $max: "$presion_atm" },
            ph_promedio: { $avg: "$ph" },
            ph_desviacion: { $stdDevPop: "$ph" },
            lecturas_totales: { $sum: 1 },
            lecturas_anormales: {
                $sum: {
                    $cond: [
                        {
                            $or: [
                                { $gt: ["$temperatura_celsius", 400] },
                                { $lt: ["$temperatura_celsius", 100] },
                                { $gt: ["$presion_atm", 5] },
                                { $lt: ["$ph", 5] },
                                { $gt: ["$ph", 9] }
                            ]
                        },
                        1,
                        0
                    ]
                }
            }
        }
    },
    {
        $project: {
            _id: 1,
            temperatura_promedio: { $round: ["$temperatura_promedio", 2] },
            temperatura_maxima: 1,
            temperatura_minima: 1,
            presion_promedio: { $round: ["$presion_promedio", 3] },
            presion_maxima: 1,
            ph_promedio: { $round: ["$ph_promedio", 2] },
            ph_desviacion: { $round: ["$ph_desviacion", 3] },
            lecturas_totales: 1,
            lecturas_anormales: 1,
            porcentaje_anomalias: {
                $round: [
                    {
                        $multiply: [
                            { $divide: ["$lecturas_anormales", "$lecturas_totales"] },
                            100
                        ]
                    },
                    2
                ]
            }
        }
    },
    {
        $sort: { porcentaje_anomalias: -1 }
    }
]);

// =====================================================
// Agregación 2: Timeline de anomalías por orden
// =====================================================
db.sensores_iot.aggregate([
    {
        $match: {
            id_orden: { $in: [5, 8, 12, 15] },
            $or: [
                { temperatura_celsius: { $gt: 400 } },
                { temperatura_celsius: { $lt: 100 } },
                { presion_atm: { $gt: 5 } },
                { ph: { $lt: 5 } },
                { ph: { $gt: 9 } }
            ]
        }
    },
    {
        $project: {
            id_orden: 1,
            timestamp: 1,
            temperatura_celsius: 1,
            presion_atm: 1,
            ph: 1,
            tipo_anomalia: {
                $switch: {
                    branches: [
                        { case: { $gt: ["$temperatura_celsius", 400] }, then: "Temperatura Alta" },
                        { case: { $lt: ["$temperatura_celsius", 100] }, then: "Temperatura Baja" },
                        { case: { $gt: ["$presion_atm", 5] }, then: "Presión Alta" },
                        { case: { $lt: ["$ph", 5] }, then: "pH Ácido" },
                        { case: { $gt: ["$ph", 9] }, then: "pH Básico" }
                    ],
                    default: "Desconocida"
                }
            }
        }
    },
    {
        $sort: { id_orden: 1, timestamp: 1 }
    },
    {
        $limit: 50  // Primeras 50 anomalías
    }
]);

// =====================================================
// Agregación 3: Correlación con condiciones ambientales
// =====================================================
db.condiciones_ambientales.aggregate([
    {
        $match: {
            id_orden: { $in: [5, 8, 12, 15] }
        }
    },
    {
        $group: {
            _id: "$id_orden",
            humedad_promedio: { $avg: "$humedad_relativa" },
            temp_ambiente_promedio: { $avg: "$temperatura_ambiente" },
            presion_atmosferica_promedio: { $avg: "$presion_atmosferica" },
            condiciones_fuera_rango: {
                $sum: {
                    $cond: [
                        {
                            $or: [
                                { $gt: ["$humedad_relativa", 70] },
                                { $lt: ["$humedad_relativa", 30] }
                            ]
                        },
                        1,
                        0
                    ]
                }
            }
        }
    },
    {
        $sort: { condiciones_fuera_rango: -1 }
    }
]);

// =====================================================
// RESULTADO ESPERADO:
// - Identificación de patrones anormales en temperatura,
//   presión y pH durante órdenes con bajo rendimiento
// - Correlación entre condiciones ambientales y problemas
// - Timeline de cuándo ocurrieron las anomalías
// =====================================================
