# Guía de Actualización del DW - Nuevos Campos

## Cambios Realizados

### 1. Campo `antiguedad_cliente` en `dim_cliente`
- **Descripción**: Antigüedad del cliente en años desde su primera venta
- **Tipo**: `INT NULL`
- **Cálculo**: `YEAR(CURDATE()) - YEAR(MIN(v.fecha))`
- **Uso**: Segmentar clientes por antigüedad, análisis de retención

### 2. Campo `ubicacion_key` en `fact_ventas`
- **Descripción**: Foreign Key a `dim_ubicacion`
- **Tipo**: `INT NULL`
- **Relación**: `fact_ventas.ubicacion_key → dim_ubicacion.ubicacion_key`
- **Uso**: Análisis geográfico preciso con datos de ubicación normalizados

---

## Pasos para Aplicar los Cambios

### Opción 1: Actualizar DW Existente (Recomendado - Sin Perder Datos)

```bash
# 1. Ejecutar script de actualización del esquema
python scripts/setup/actualizar_esquema_dw.py
```

Este script hace:
- ✅ Agrega campo `antiguedad_cliente` a `dim_cliente`
- ✅ Calcula antigüedad para clientes existentes
- ✅ Agrega campo `ubicacion_key` a `fact_ventas`
- ✅ Puebla `ubicacion_key` desde `dim_cliente.municipio`
- ✅ Crea FK constraint y índice
- ✅ NO borra datos existentes

### Opción 2: Recrear DW Completo (Solo si hay problemas)

```bash
# 1. Recrear tablas con nuevos campos
python scripts/setup/ejecutar_scripts_sql.py

# 2. Recargar dimensiones
python etl/main_load_dimensions.py --mode full

# 3. Recargar fact_ventas
python etl/load/load_fact_ventas.py --truncate
```

---

## Verificación

```bash
# Ver clientes con antigüedad
python -c "
import pyodbc
conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=LGL_DW;Trusted_Connection=yes;')
cursor = conn.cursor()
cursor.execute('SELECT TOP 10 nombre, municipio, departamento, antiguedad_cliente FROM dim_cliente WHERE es_actual=1 AND antiguedad_cliente IS NOT NULL ORDER BY antiguedad_cliente DESC')
for row in cursor: print(f'{row[0][:30]:<30} {row[1]:<15} {row[2]:<15} {row[3]:>3} años')
"

# Ver ventas con ubicación
python -c "
import pyodbc
conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=LGL_DW;Trusted_Connection=yes;')
cursor = conn.cursor()
cursor.execute('''
    SELECT TOP 10 fv.venta_id, du.municipio_nombre, du.departamento_nombre, fv.venta_total_con_impuestos
    FROM fact_ventas fv
    LEFT JOIN dim_ubicacion du ON fv.ubicacion_key = du.ubicacion_key
    ORDER BY fv.venta_key DESC
''')
for row in cursor: print(f'Venta {row[0]}: {row[1]} / {row[2]} - ${row[3]:.2f}')
"
```

---

## Uso en Power BI

### Nuevas Visualizaciones Posibles

#### 1. Análisis por Antigüedad de Cliente
```
Gráfico de Barras:
- Eje X: antiguedad_cliente (agrupado: 0-1 años, 2-5 años, 5+ años)
- Eje Y: SUM(monto_venta)
- Leyenda: departamento
```

#### 2. Mapa de Ventas por Ubicación
```
Mapa:
- Ubicación: dim_ubicacion.departamento_nombre
- Tamaño: SUM(venta_total_con_impuestos)
- Color: COUNT(DISTINCT venta_id)
```

#### 3. Tabla de Clientes VIP
```
Tabla:
- Columnas: cliente_nombre, antiguedad_cliente, departamento, SUM(venta_total)
- Filtro: antiguedad_cliente >= 3
- Ordenar: SUM(venta_total) DESC
```

### Relaciones en Power BI

Después de actualizar, verifica estas relaciones:

```
fact_ventas.ubicacion_key → dim_ubicacion.ubicacion_key
    Cardinalidad: Muchos a Uno (*:1)
    Dirección: Única
```

---

## Consultas SQL Útiles

### Top clientes por antigüedad
```sql
SELECT TOP 10
    dc.nombre,
    dc.departamento,
    dc.antiguedad_cliente,
    COUNT(DISTINCT fv.venta_id) as total_ventas,
    SUM(fv.venta_total_con_impuestos) as total_vendido
FROM dim_cliente dc
INNER JOIN fact_ventas fv ON dc.cliente_key = fv.cliente_key
WHERE dc.es_actual = 1 AND dc.antiguedad_cliente IS NOT NULL
GROUP BY dc.nombre, dc.departamento, dc.antiguedad_cliente
ORDER BY dc.antiguedad_cliente DESC, total_vendido DESC;
```

### Ventas por ubicación (usando dim_ubicacion)
```sql
SELECT 
    du.departamento_nombre,
    du.municipio_nombre,
    COUNT(DISTINCT fv.venta_id) as num_ventas,
    SUM(fv.venta_total_con_impuestos) as total
FROM fact_ventas fv
INNER JOIN dim_ubicacion du ON fv.ubicacion_key = du.ubicacion_key
WHERE fv.esta_anulado = 0
GROUP BY du.departamento_nombre, du.municipio_nombre
ORDER BY total DESC;
```

### Comparar antigüedad vs ticket promedio
```sql
SELECT 
    CASE 
        WHEN dc.antiguedad_cliente IS NULL THEN 'Sin datos'
        WHEN dc.antiguedad_cliente = 0 THEN 'Nuevo (0 años)'
        WHEN dc.antiguedad_cliente BETWEEN 1 AND 2 THEN '1-2 años'
        WHEN dc.antiguedad_cliente BETWEEN 3 AND 5 THEN '3-5 años'
        ELSE '5+ años'
    END as segmento_antiguedad,
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
        WHEN dc.antiguedad_cliente = 0 THEN 'Nuevo (0 años)'
        WHEN dc.antiguedad_cliente BETWEEN 1 AND 2 THEN '1-2 años'
        WHEN dc.antiguedad_cliente BETWEEN 3 AND 5 THEN '3-5 años'
        ELSE '5+ años'
    END
ORDER BY segmento_antiguedad;
```

---

## Vistas Actualizadas

Las siguientes vistas ya incluyen los nuevos campos:

- ✅ `v_analisis_ventas`: Incluye `antiguedad_cliente` y campos de `dim_ubicacion`
- ✅ `v_cartera_clientes`: Incluye `antiguedad_cliente`
- ✅ `v_ventas_geografia`: Ahora usa `dim_ubicacion` en lugar de `dim_cliente`

---

## Próximas Cargas ETL

Los scripts ETL ya están actualizados:

- `etl/load/load_dim_cliente.py`: 
  - Calcula `antiguedad_cliente` automáticamente
  - Incluido en cargas full e incremental
  
- `etl/load/load_fact_ventas.py`:
  - Obtiene `ubicacion_key` desde `clientes.municipio_id`
  - Mapea a `dim_ubicacion.ubicacion_key`
  
Las próximas ejecuciones ya usarán los nuevos campos.

---

## ¿Necesitas Ayuda?

Si encuentras problemas:

1. Verifica que `dim_ubicacion` tenga datos:
   ```sql
   SELECT COUNT(*) FROM dim_ubicacion;  -- Debe tener 262 registros
   ```

2. Verifica que los municipios coincidan:
   ```sql
   SELECT DISTINCT dc.municipio 
   FROM dim_cliente dc
   WHERE dc.municipio NOT IN (SELECT municipio_nombre FROM dim_ubicacion)
   AND dc.es_actual = 1;
   ```

3. Si hay inconsistencias, ejecuta:
   ```bash
   python scripts/setup/actualizar_esquema_dw.py
   ```
