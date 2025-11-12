# Data Warehouse - Proceso de Ventas
## Documentación Técnica

---

## 📋 Tabla de Contenidos
1. [Descripción General](#descripción-general)
2. [Arquitectura del DW](#arquitectura-del-dw)
3. [Modelo Dimensional](#modelo-dimensional)
4. [Dimensiones](#dimensiones)
5. [Tabla de Hechos](#tabla-de-hechos)
6. [Proceso ETL](#proceso-etl)
7. [Casos de Uso y Consultas](#casos-de-uso-y-consultas)
8. [Mantenimiento](#mantenimiento)

---

## 📖 Descripción General

Este Data Warehouse está diseñado específicamente para el **análisis del proceso de ventas** de la organización. Utiliza un **modelo dimensional tipo estrella (Star Schema)** que facilita:

- 📊 Análisis multidimensional de ventas
- 🎯 Identificación de tendencias y patrones
- 💰 Cálculo de rentabilidad por múltiples dimensiones
- 📈 Reportes ejecutivos y dashboards
- 🔍 Análisis de cartera y cobranza

### Características Principales

- **Granularidad**: Línea de producto por venta
- **Actualización**: Carga incremental diaria
- **SCD Tipo 2**: Implementado en dimensiones clave (Cliente, Producto, Vendedor)
- **Métricas**: Ventas, márgenes, costos, saldos
- **Dimensiones**: 8 dimensiones + 1 tabla de hechos agregada

---

## 🏗️ Arquitectura del DW

### Capas del Data Warehouse

```
┌─────────────────────────────────────────┐
│    SISTEMA TRANSACCIONAL (OLTP)        │
│  (ventas, clientes, productos, etc.)    │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│        PROCESOS ETL                     │
│  - Extracción                           │
│  - Transformación                       │
│  - Carga (Incremental/Histórica)        │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│    DATA WAREHOUSE (OLAP)                │
│  - Dimensiones                          │
│  - Tabla de Hechos                      │
│  - Vistas Analíticas                    │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│    CAPA DE PRESENTACIÓN                 │
│  - Dashboards                           │
│  - Reportes                             │
│  - Herramientas BI                      │
└─────────────────────────────────────────┘
```

---

## 🎯 Modelo Dimensional

### Diagrama Estrella (Star Schema)

```
                    dim_tiempo
                         │
                         │
    dim_vendedor ────────┼──────── dim_cliente
                         │
                         │
  dim_tipo_documento ────┤
                         │
                    fact_ventas ──── dim_producto
                         │
  dim_condicion_pago ────┤
                         │
                         │
    dim_estado_venta ────┘
```

---

## 📊 Dimensiones

### 1. **dim_tiempo** (Dimensión Tiempo)

**Propósito**: Análisis temporal de las ventas

**Atributos principales**:
- `tiempo_key` (PK)
- `fecha`
- `anio`, `trimestre`, `mes`, `semana_anio`
- `dia_mes`, `dia_semana`, `dia_semana_nombre`
- `es_fin_semana`, `es_festivo`
- `periodo_fiscal`

**Consideraciones**:
- Pre-poblada con rango de fechas 2020-2030
- Permite análisis por año, trimestre, mes, semana, día
- Identifica fines de semana y festivos

---

### 2. **dim_cliente** (Dimensión Cliente)

**Propósito**: Análisis por cliente y ubicación geográfica

**Atributos principales**:
- `cliente_key` (PK - Surrogate Key)
- `cliente_id` (Natural Key)
- `nombre`, `nombre_alternativo`
- `telefono_1`, `telefono_2`, `direccion`, `correo`
- `nit`, `nrc`, `giro`
- `municipio`, `departamento`
- `retencion`

**SCD Tipo 2**:
- `fecha_inicio`, `fecha_fin`
- `version`, `es_actual`
- Mantiene histórico de cambios en datos del cliente

**Jerarquías**:
- Cliente → Municipio → Departamento

---

### 3. **dim_producto** (Dimensión Producto)

**Propósito**: Análisis por producto, categoría y tipo

**Atributos principales**:
- `producto_key` (PK - Surrogate Key)
- `producto_id` (Natural Key)
- `nombre`, `nombre_alternativo`, `codigo`
- `categoria_codigo`, `categoria_nombre`
- `tipo_producto_codigo`, `tipo_producto_nombre`
- `unidad_medida_nombre`, `unidad_medida_abreviatura`
- `producto_activo`

**SCD Tipo 2**:
- `fecha_inicio`, `fecha_fin`
- `version`, `es_actual`

**Jerarquías**:
- Producto → Categoría
- Producto → Tipo Producto

**Nota**: El `producto_key = -1` se reserva para "otras ventas" (productos no inventariados)

---

### 4. **dim_vendedor** (Dimensión Vendedor)

**Propósito**: Análisis de desempeño de vendedores

**Atributos principales**:
- `vendedor_key` (PK - Surrogate Key)
- `vendedor_id` (Natural Key)
- `nombre`, `apellido`
- `email`, `username`, `telefono`
- `rol_id`, `rol_nombre`

**SCD Tipo 2**:
- `fecha_inicio`, `fecha_fin`
- `version`, `es_actual`

---

### 5. **dim_tipo_documento** (Dimensión Tipo Documento)

**Propósito**: Clasificación de documentos de venta

**Atributos**:
- `tipo_documento_key` (PK)
- `tipo_documento_id` (Natural Key)
- `codigo`, `nombre`

**Ejemplos**: Factura, Crédito Fiscal, Nota de Débito, etc.

---

### 6. **dim_condicion_pago** (Dimensión Condición de Pago)

**Propósito**: Análisis por términos de pago

**Atributos**:
- `condicion_pago_key` (PK)
- `condicion_pago_id` (Natural Key)
- `codigo`, `nombre`

**Ejemplos**: Contado, Crédito 30 días, Crédito 60 días, etc.

---

### 7. **dim_estado_venta** (Dimensión Estado Venta)

**Propósito**: Seguimiento del estado de las ventas

**Atributos**:
- `estado_venta_key` (PK)
- `estado_venta_id` (Natural Key)
- `codigo`, `nombre`

**Ejemplos**: Activa, Liquidada, Anulada, etc.

---

### 8. **dim_ubicacion** (Dimensión Ubicación)

**Propósito**: Análisis geográfico detallado

**Atributos**:
- `ubicacion_key` (PK)
- `municipio_id`, `municipio_nombre`
- `departamento_id`, `departamento_nombre`
- `departamento_isocode`, `zonesv_id`

**Jerarquía**: Municipio → Departamento

---

## 📈 Tabla de Hechos

### **fact_ventas** (Tabla de Hechos Principal)

**Granularidad**: Una fila por cada producto vendido en cada transacción

#### Claves Foráneas (Foreign Keys)
- `tiempo_key` → dim_tiempo
- `cliente_key` → dim_cliente
- `producto_key` → dim_producto
- `vendedor_key` → dim_vendedor
- `tipo_documento_key` → dim_tipo_documento
- `condicion_pago_key` → dim_condicion_pago
- `estado_venta_key` → dim_estado_venta

#### Dimensiones Degeneradas
- `venta_id`: ID de la venta en el sistema transaccional
- `orden_pedido_id`: ID de la orden de pedido
- `numero_venta`: Número de documento de venta

#### Métricas Aditivas
- `cantidad`: Cantidad de productos vendidos
- `precio_unitario`: Precio unitario del producto
- `venta_exenta`: Monto de venta exenta de impuestos
- `venta_gravada`: Monto de venta gravada con impuestos
- `venta_total`: Total de la venta sin impuestos
- `iva`: Impuesto al valor agregado
- `venta_total_con_impuestos`: Total incluyendo IVA
- `flete`: Costo de flete
- `costo_venta`: Costo de los productos vendidos
- `margen_bruto`: Diferencia entre venta y costo

#### Métricas Semi-Aditivas
- `saldo`: Saldo pendiente por cobrar (no se suma entre períodos)

#### Métricas Derivadas
- `porcentaje_margen`: % de margen sobre venta

#### Indicadores (Flags)
- `es_venta_credito`: Indica si es venta a crédito
- `tiene_comision`: Indica si genera comisión
- `esta_liquidado`: Indica si está pagada completamente
- `esta_anulado`: Indica si fue anulada

#### Fechas Relevantes
- `fecha_venta`: Fecha de la transacción
- `fecha_liquidacion`: Fecha de pago completo
- `fecha_anulacion`: Fecha de anulación

---

### **fact_ventas_diarias** (Tabla de Hechos Agregada)

**Propósito**: Mejorar performance en consultas agregadas

**Granularidad**: Una fila por combinación de día-cliente-producto-vendedor

**Métricas Agregadas**:
- `cantidad_total`: Suma de cantidades
- `numero_transacciones`: Conteo de ventas
- `venta_exenta_total`, `venta_gravada_total`
- `venta_total`, `venta_total_con_impuestos`
- `venta_promedio`, `venta_maxima`, `venta_minima`

---

## 🔄 Proceso ETL

### Tipos de Carga

#### 1. **Carga Inicial / Histórica**
```sql
CALL sp_carga_historica_ventas();
```
- Ejecutar **una sola vez** al implementar el DW
- Carga todas las dimensiones y toda la historia de ventas
- Duración estimada: Variable según volumen de datos

#### 2. **Carga Incremental Diaria**
```sql
CALL sp_etl_diario();
```
- Ejecutar **diariamente** (recomendado programar en cron/scheduler)
- Actualiza dimensiones SCD
- Carga ventas del día anterior
- Actualiza tabla agregada

#### 3. **Carga por Rango de Fechas**
```sql
CALL sp_cargar_fact_ventas('2024-01-01', '2024-12-31');
```
- Para reprocesar períodos específicos
- Útil para correcciones o actualizaciones

#### 4. **Actualización de Venta Específica**
```sql
CALL sp_actualizar_fact_ventas(12345);
```
- Para actualizar estado/saldo de una venta individual

---

### Flujo del Proceso ETL

```
1. EXTRACCIÓN
   └─> Lee datos del sistema transaccional (OLTP)

2. TRANSFORMACIÓN
   ├─> Limpieza de datos
   ├─> Aplicación de reglas de negocio
   ├─> Cálculo de métricas derivadas
   ├─> Manejo de SCD Tipo 2
   └─> Validación de integridad

3. CARGA
   ├─> Actualización de dimensiones
   ├─> Inserción en tabla de hechos
   └─> Actualización de tablas agregadas

4. VALIDACIÓN
   └─> Verificación de totales y consistencia
```

---

### Slowly Changing Dimensions (SCD) Tipo 2

Las dimensiones `dim_cliente`, `dim_producto` y `dim_vendedor` implementan SCD Tipo 2:

**Cuando cambia un atributo**:
1. Se cierra el registro actual (`fecha_fin = NOW()`, `es_actual = FALSE`)
2. Se inserta un nuevo registro con:
   - Nueva versión (`version = version + 1`)
   - `fecha_inicio = NOW()`
   - `es_actual = TRUE`

**Ventaja**: Mantiene histórico completo de cambios

**Consultas**: Siempre filtrar por `es_actual = TRUE` para datos actuales

---

## 💡 Casos de Uso y Consultas

### Reportes Principales

#### 1. **Dashboard Ejecutivo**
- KPIs del mes actual
- Comparativas período actual vs anterior
- Top clientes y productos
- Estado de cartera

#### 2. **Análisis de Ventas**
- Ventas por período (día, semana, mes, trimestre, año)
- Tendencias y estacionalidad
- Análisis de crecimiento

#### 3. **Análisis de Clientes**
- Segmentación de clientes
- RFM (Recency, Frequency, Monetary)
- Análisis de retención
- Cartera vencida

#### 4. **Análisis de Productos**
- Productos más vendidos
- Análisis de rentabilidad
- Análisis ABC
- Categorías más rentables

#### 5. **Análisis de Vendedores**
- Ranking de desempeño
- Cumplimiento de metas
- Análisis de comisiones

#### 6. **Análisis Geográfico**
- Ventas por región
- Mapas de calor
- Oportunidades por zona

#### 7. **Análisis de Cartera**
- Aging de saldos
- Cuentas por cobrar
- Días promedio de cobro
- Riesgo de cartera

Ver ejemplos detallados en: `consultas_analiticas.sql`

---

## 🛠️ Mantenimiento

### Tareas Diarias
- ✅ Ejecutar `sp_etl_diario()` (automatizado)
- ✅ Verificar logs de ejecución
- ✅ Validar totales vs sistema transaccional

### Tareas Semanales
- ✅ Revisar performance de consultas
- ✅ Analizar índices y optimizar si necesario
- ✅ Verificar integridad referencial

### Tareas Mensuales
- ✅ Backup completo del DW
- ✅ Análisis de crecimiento de tablas
- ✅ Revisión de dimensiones SCD (versiones)
- ✅ Limpieza de logs antiguos

### Tareas Anuales
- ✅ Poblar dimensión tiempo para próximo año
- ✅ Análisis de archiving de datos antiguos
- ✅ Revisión de modelo dimensional

---

## 📝 Optimizaciones Implementadas

### Índices
- Índices en todas las claves foráneas
- Índices en campos de filtro frecuente (fecha, cliente_id, producto_id)
- Índices compuestos para queries comunes

### Tabla Agregada
- `fact_ventas_diarias` para consultas agregadas rápidas
- Reduce escaneo de millones de filas a miles

### Particionamiento (Recomendado para grandes volúmenes)
```sql
-- Ejemplo: Particionar fact_ventas por año
ALTER TABLE fact_ventas
PARTITION BY RANGE (YEAR(fecha_venta)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION pmax VALUES LESS THAN MAXVALUE
);
```

---

## 🎓 Mejores Prácticas

### Consultas
1. **Siempre filtrar por `es_actual = TRUE`** en dimensiones SCD
2. **Usar `tiempo_key`** en lugar de `fecha` para joins
3. **Filtrar por `esta_anulado = FALSE`** en análisis de ventas
4. **Usar vistas** predefinidas para consultas comunes

### ETL
1. **Ejecutar ETL en horarios de baja carga**
2. **Validar totales** después de cada carga
3. **Mantener logs** de cada ejecución
4. **Implementar alertas** en caso de fallas

### Performance
1. **Usar tabla agregada** para dashboards
2. **Limitar resultados** con TOP/LIMIT en consultas exploratorias
3. **Evitar SELECT *** en consultas de producción
4. **Analizar planes de ejecución** regularmente

---

## 📞 Información Adicional

### Archivos del Proyecto

| Archivo | Descripción |
|---------|-------------|
| `dw_ventas_schema.sql` | DDL completo del Data Warehouse |
| `etl_carga_dimensiones.sql` | Procedimientos para cargar dimensiones |
| `etl_carga_fact_ventas.sql` | Procedimientos para cargar tabla de hechos |
| `consultas_analiticas.sql` | Ejemplos de consultas y reportes |
| `documentacion_dw.md` | Este documento |

### Dependencias del Sistema Transaccional

El DW depende de las siguientes tablas OLTP:
- `ventas`
- `orden_pedidos`
- `salidas`
- `detalle_otras_ventas`
- `clientes`
- `productos`
- `users` (vendedores)
- `tipo_documentos`
- `condiciones_pago`
- `estados_ventas`
- `municipios`
- `departamentos`
- `categorias`
- `tipo_productos`
- `unidad_medidas`
- `movimientos`

---

## 🚀 Próximos Pasos

### Implementación
1. ✅ Crear esquema del DW: `mysql < dw_ventas_schema.sql`
2. ✅ Cargar dimensiones: `CALL sp_cargar_todas_dimensiones();`
3. ✅ Carga histórica: `CALL sp_carga_historica_ventas();`
4. ✅ Validar datos cargados
5. ✅ Programar ETL diario en cron

### Extensiones Futuras
- 📊 Implementar proceso de Compras
- 📦 Implementar proceso de Inventario
- 💰 Implementar proceso de Cobranza (Abonos)
- 🏭 Implementar proceso de Producción
- 🔗 Integración con herramientas BI (Power BI, Tableau, Metabase)

---

**Versión**: 1.0  
**Fecha**: Noviembre 2025  
**Autor**: Data Warehouse Team
