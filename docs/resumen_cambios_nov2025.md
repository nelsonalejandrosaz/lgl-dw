# Resumen: Actualización del Data Warehouse

**Fecha:** 18 de noviembre de 2025  
**Cambios aplicados:** 2 mejoras al esquema dimensional

---

## ✅ Cambios Implementados

### 1. Campo `antiguedad_cliente` en `dim_cliente`

**Descripción:** Nuevo campo que calcula la antigüedad del cliente en años desde su primera venta.

**Detalles técnicos:**
- Tipo de dato: `INT NULL`
- Cálculo: `YEAR(CURDATE()) - YEAR(MIN(v.fecha))`
- Ubicación: `dim_cliente.antiguedad_cliente`

**Datos poblados:**
- ✅ 971 clientes con antigüedad calculada
- Rango: 2 a 7 años
- Promedio: 5.5 años

**Uso en análisis:**
- Segmentación de clientes (nuevos, leales, veteranos)
- Análisis de retención de clientes
- Comparación de ticket promedio vs antigüedad
- Identificación de clientes VIP por longevidad

---

### 2. Relación `fact_ventas → dim_ubicacion`

**Descripción:** Nueva Foreign Key que conecta cada venta con su ubicación geográfica normalizada.

**Detalles técnicos:**
- Nuevo campo: `fact_ventas.ubicacion_key INT NULL`
- FK: `fact_ventas.ubicacion_key → dim_ubicacion.ubicacion_key`
- Índice: `idx_fact_ventas_ubicacion` (optimización de consultas)

**Datos poblados:**
- ✅ 40,837 ventas con ubicación (99.9% de cobertura)
- 83 ubicaciones diferentes (municipios)
- 262 registros en `dim_ubicacion` (todos los municipios de El Salvador)

**Ventajas:**
- Análisis geográfico preciso y normalizado
- Mapas de calor por departamento/municipio
- Campos adicionales: `departamento_isocode`, `zonesv_id`
- Consistencia en nombres de ubicaciones

---

## 🔄 Componentes Actualizados

### Scripts DDL
- ✅ `database/target/01_crear_dimensiones.sql` - Agregado campo `antiguedad_cliente`
- ✅ `database/target/02_crear_hechos.sql` - Agregado campo `ubicacion_key` con FK

### Scripts ETL
- ✅ `etl/load/load_dim_cliente.py` - Calcula antigüedad automáticamente
- ✅ `etl/load/load_fact_ventas.py` - Obtiene `ubicacion_key` desde cliente

### Vistas Analíticas
- ✅ `v_analisis_ventas` - Incluye `antiguedad_cliente` y campos de ubicación
- ✅ `v_cartera_clientes` - Incluye `antiguedad_cliente`
- ✅ `v_ventas_geografia` - Usa `dim_ubicacion` como fuente principal

### Documentación
- ✅ `docs/guia_powerbi.md` - Actualizada con nuevos campos y relaciones
- ✅ `docs/actualizacion_esquema.md` - Guía completa de cambios
- ✅ `scripts/setup/actualizar_esquema_dw.py` - Script de actualización

---

## 📊 Impacto en Power BI

### Nuevas Relaciones a Configurar

```
fact_ventas.ubicacion_key → dim_ubicacion.ubicacion_key
    Cardinalidad: Muchos a Uno (*:1)
    Dirección: Única
```

### Nuevas Visualizaciones Recomendadas

1. **Segmentación por Antigüedad:**
   - Gráfico de barras: Ventas por segmento (0-1 años, 2-5 años, 5+ años)
   - Ticket promedio vs antigüedad
   - Tabla de clientes VIP (antigüedad + monto)

2. **Análisis Geográfico Mejorado:**
   - Mapa de coropletas: Departamentos con mayor facturación
   - Tabla: Top municipios por ventas
   - Treemap: Distribución geográfica de ventas

3. **Análisis Combinado:**
   - Antigüedad de clientes por departamento
   - Evolución de ventas por ubicación en el tiempo
   - Ranking de municipios con clientes más leales

---

## 🎯 Próximos Pasos

### Paso 1: Conectar en Power BI
```
1. Abrir Power BI Desktop
2. Obtener datos → SQL Server
3. Servidor: localhost, Base de datos: LGL_DW
4. Seleccionar tablas:
   ✓ fact_ventas (actualizar)
   ✓ dim_cliente (actualizar)
   ✓ dim_ubicacion (importar)
5. Cargar
```

### Paso 2: Verificar Relaciones
```
Vista de Modelo → Verificar:
✓ fact_ventas → dim_ubicacion (debe estar activa)
✓ Todas las demás relaciones intactas
```

### Paso 3: Crear Medidas DAX

**Segmentación por Antigüedad:**
```dax
Segmento Antigüedad = 
    SWITCH(
        TRUE(),
        ISBLANK(dim_cliente[antiguedad_cliente]), "Sin datos",
        dim_cliente[antiguedad_cliente] <= 1, "Nuevos (0-1 años)",
        dim_cliente[antiguedad_cliente] <= 3, "Establecidos (2-3 años)",
        dim_cliente[antiguedad_cliente] <= 5, "Leales (4-5 años)",
        "Veteranos (5+ años)"
    )
```

**Cobertura Geográfica:**
```dax
Municipios con Ventas = 
    CALCULATE(
        DISTINCTCOUNT(fact_ventas[ubicacion_key]),
        fact_ventas[esta_anulado] = 0
    )
```

---

## 📈 Ejemplos de Consultas SQL

### Clientes más antiguos con mayor facturación
```sql
SELECT TOP 10
    dc.nombre,
    dc.departamento,
    dc.antiguedad_cliente,
    COUNT(DISTINCT fv.venta_id) as total_ventas,
    SUM(fv.venta_total_con_impuestos) as total_vendido
FROM dim_cliente dc
INNER JOIN fact_ventas fv ON dc.cliente_key = fv.cliente_key
WHERE dc.es_actual = 1 
    AND dc.antiguedad_cliente IS NOT NULL
    AND fv.esta_anulado = 0
GROUP BY dc.nombre, dc.departamento, dc.antiguedad_cliente
ORDER BY total_vendido DESC;
```

### Top municipios por ventas (usando dim_ubicacion)
```sql
SELECT TOP 10
    du.departamento_nombre,
    du.municipio_nombre,
    COUNT(DISTINCT fv.venta_id) as num_ventas,
    COUNT(DISTINCT fv.cliente_key) as num_clientes,
    SUM(fv.venta_total_con_impuestos) as total
FROM fact_ventas fv
INNER JOIN dim_ubicacion du ON fv.ubicacion_key = du.ubicacion_key
WHERE fv.esta_anulado = 0
GROUP BY du.departamento_nombre, du.municipio_nombre
ORDER BY total DESC;
```

### Análisis de antigüedad vs ticket promedio
```sql
SELECT 
    CASE 
        WHEN dc.antiguedad_cliente IS NULL THEN 'Sin datos'
        WHEN dc.antiguedad_cliente <= 1 THEN 'Nuevos (0-1 años)'
        WHEN dc.antiguedad_cliente <= 3 THEN 'Establecidos (2-3 años)'
        WHEN dc.antiguedad_cliente <= 5 THEN 'Leales (4-5 años)'
        ELSE 'Veteranos (5+ años)'
    END as segmento,
    COUNT(DISTINCT dc.cliente_id) as num_clientes,
    COUNT(DISTINCT fv.venta_id) as num_ventas,
    AVG(fv.venta_total_con_impuestos) as ticket_promedio,
    SUM(fv.venta_total_con_impuestos) as total_vendido
FROM dim_cliente dc
INNER JOIN fact_ventas fv ON dc.cliente_key = fv.cliente_key
WHERE dc.es_actual = 1 AND fv.esta_anulado = 0
GROUP BY 
    CASE 
        WHEN dc.antiguedad_cliente IS NULL THEN 'Sin datos'
        WHEN dc.antiguedad_cliente <= 1 THEN 'Nuevos (0-1 años)'
        WHEN dc.antiguedad_cliente <= 3 THEN 'Establecidos (2-3 años)'
        WHEN dc.antiguedad_cliente <= 5 THEN 'Leales (4-5 años)'
        ELSE 'Veteranos (5+ años)'
    END
ORDER BY segmento;
```

---

## ✨ Beneficios del Cambio

### Para el Negocio:
- ✅ Mejor comprensión de la lealtad de clientes
- ✅ Identificación de patrones de compra según antigüedad
- ✅ Análisis geográfico preciso para planificación de rutas/territorios
- ✅ Datos listos para estrategias de retención de clientes

### Para Análisis:
- ✅ Nuevas dimensiones de segmentación
- ✅ Consistencia en datos geográficos
- ✅ Campos calculados automáticamente en ETL
- ✅ Vistas analíticas ya incluyen los nuevos campos

### Para el DW:
- ✅ Sin pérdida de datos históricos
- ✅ Compatibilidad total con ETL existente
- ✅ Optimización de consultas (índices creados)
- ✅ Documentación completa actualizada

---

## 🔍 Validación Realizada

✅ Todas las validaciones pasaron exitosamente:

- Campo `antiguedad_cliente` poblado para 971 clientes activos
- Campo `ubicacion_key` poblado para 40,837 ventas (99.9%)
- FK `fk_fact_ventas_ubicacion` creada y activa
- Índice `idx_fact_ventas_ubicacion` creado
- 6 vistas analíticas actualizadas
- Scripts ETL modificados y probados
- Documentación actualizada

---

## 📝 Notas Importantes

1. **Antigüedad de cliente:** Se recalcula automáticamente en cada carga ETL incremental
2. **Ubicación:** Se obtiene del municipio del cliente en el momento de la venta
3. **Sin datos perdidos:** La actualización se aplicó sin borrar información existente
4. **Compatibilidad:** Los reportes de Power BI existentes siguen funcionando
5. **Nuevas cargas ETL:** Ya incluirán automáticamente estos campos

---

## 📞 Soporte

Si necesitas ayuda:
- Ver guía completa: `docs/actualizacion_esquema.md`
- Ver guía Power BI: `docs/guia_powerbi.md`
- Script de actualización: `scripts/setup/actualizar_esquema_dw.py`

---

**Actualización completada exitosamente** ✅
