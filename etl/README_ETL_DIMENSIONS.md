# Scripts Python del ETL para Dimensiones

## 📁 Estructura de Archivos Creados

```
etl/
├── utils/
│   ├── __init__.py
│   ├── database.py          # Conexiones a MariaDB y SQL Server
│   ├── logger.py            # Sistema de logging con loguru
│   └── helpers.py           # Funciones auxiliares de transformación
├── load/
│   ├── __init__.py
│   ├── load_dim_tiempo.py      # ETL para dimensión tiempo
│   ├── load_dim_static.py      # ETL para dimensiones estáticas
│   ├── load_dim_cliente.py     # ETL para dim_cliente (SCD Type 2)
│   ├── load_dim_producto.py    # ETL para dim_producto (SCD Type 2)
│   └── load_dim_vendedor.py    # ETL para dim_vendedor (SCD Type 2)
└── main_load_dimensions.py     # Orquestador principal
```

## 🚀 Cómo Ejecutar

### 1. Preparación
Primero asegúrate de tener las credenciales correctas en `.env`:
- `SOURCE_DB_*`: Configuración de MariaDB
- `TARGET_DB_*`: Configuración de SQL Server

### 2. Probar Conexiones
```bash
# Probar conexión a ambas bases de datos
python etl/utils/database.py
```

### 3. Ejecutar ETL Individual

#### Dimensión Tiempo
```bash
python etl/load/load_dim_tiempo.py --start-year 2020 --end-year 2030
```

#### Dimensiones Estáticas (todas)
```bash
python etl/load/load_dim_static.py --dimension all
```

#### Dimensiones Estáticas (individual)
```bash
python etl/load/load_dim_static.py --dimension tipo_documento
python etl/load/load_dim_static.py --dimension condicion_pago
python etl/load/load_dim_static.py --dimension estado_venta
python etl/load/load_dim_static.py --dimension ubicacion
```

#### Dimensiones SCD Type 2

**Modo FULL (carga completa inicial):**
```bash
python etl/load/load_dim_cliente.py --modo full
python etl/load/load_dim_producto.py --modo full
python etl/load/load_dim_vendedor.py --modo full
```

**Modo INCREMENTAL (solo cambios):**
```bash
python etl/load/load_dim_cliente.py --modo incremental
python etl/load/load_dim_producto.py --modo incremental
python etl/load/load_dim_vendedor.py --modo incremental
```

### 4. Ejecutar Todas las Dimensiones

**Primera vez (carga completa):**
```bash
python etl/main_load_dimensions.py --modo full
```

**Ejecuciones subsecuentes (incremental):**
```bash
python etl/main_load_dimensions.py --modo incremental --skip-tiempo
```

## 📊 Características de los Scripts

### Módulo de Conexión (database.py)
- ✅ Clase `SourceDatabase` para MariaDB
- ✅ Clase `TargetDatabase` para SQL Server
- ✅ Context managers para manejo automático de conexiones
- ✅ Soporte para autenticación de Windows en SQL Server
- ✅ Función `test_connections()` para verificar conectividad

### Módulo de Logging (logger.py)
- ✅ Logging a consola con colores
- ✅ Archivos de log rotativos (diarios)
- ✅ Archivo separado para errores
- ✅ Compresión automática de logs antiguos
- ✅ Funciones auxiliares: `log_etl_start()`, `log_step()`, `log_success()`, `log_error()`

### Módulo de Helpers (helpers.py)
- ✅ Limpieza y normalización de strings
- ✅ Conversión segura de tipos (float, int, date, bool)
- ✅ Normalización de DataFrames
- ✅ Eliminación de duplicados
- ✅ Comparación de DataFrames para detectar cambios
- ✅ División en lotes (batching)

### ETL Dimensiones Estáticas
- ✅ Extracción desde MariaDB
- ✅ Transformación con limpieza de datos
- ✅ Carga completa (TRUNCATE + INSERT)
- ✅ Logging detallado de cada paso

### ETL Dimensiones SCD Type 2
- ✅ **Modo FULL**: Cierra registros actuales e inserta todos como nuevos
- ✅ **Modo INCREMENTAL**: Detecta nuevos y modificados
- ✅ Implementación correcta de SCD Type 2:
  - Cierra versión anterior (`es_actual = 0`, `fecha_fin = hoy`)
  - Inserta nueva versión (`es_actual = 1`, `fecha_fin = 9999-12-31`)
- ✅ Maneja columnas de auditoría automáticamente

### Orquestador Principal
- ✅ Ejecuta dimensiones en orden correcto
- ✅ Resumen de resultados al finalizar
- ✅ Tiempo de ejecución
- ✅ Manejo de errores por dimensión
- ✅ Exit code apropiado para automatización

## 📝 Logs Generados

Los logs se guardan en `./logs/` con el formato:
- `etl_YYYYMMDD.log` - Log general
- `etl_errors_YYYYMMDD.log` - Solo errores
- `dim_tiempo_YYYYMMDD.log` - Log específico por dimensión
- `dim_cliente_YYYYMMDD.log`
- etc.

## ⚙️ Próximos Pasos

Una vez que pruebes la carga de dimensiones, podremos continuar con:
1. Verificar los datos cargados en SQL Server
2. Crear el ETL para la tabla de hechos `fact_ventas`
3. Implementar proceso de actualización de flags (`esta_liquidado`, `esta_anulado`)
4. Automatizar ejecución con tareas programadas
