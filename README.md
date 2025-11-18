# Data Warehouse - Proceso de Ventas LGL

[![Python](https://img.shields.io/badge/Python-3.12%2B-blue)](https://www.python.org/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2022-red)](https://www.microsoft.com/sql-server)
[![MariaDB](https://img.shields.io/badge/MariaDB-10.5%2B-blue)](https://mariadb.org/)

## 📋 Descripción

Data Warehouse implementado con **modelo dimensional (Star Schema)** para análisis integral del proceso de ventas. Sistema ETL en Python puro (PyMySQL + pyodbc), sin ORMs, optimizado para rendimiento y simplicidad.

## 🏗️ Arquitectura

```
MariaDB (lgldb) → Python ETL → SQL Server (LGL_DW) → Power BI
```

**Decisiones Técnicas:**
- ✅ Sin SQLAlchemy - Drivers directos para mejor performance
- ✅ SCD Type 2 para clientes, productos y vendedores
- ✅ Logging estructurado con Loguru
- ✅ Carga incremental por fechas

## 🚀 Inicio Rápido

### 1. Clonar y Configurar
```bash
git clone <url-repositorio>
cd lgl-dw
python -m venv venv
source venv/Scripts/activate  # Windows Git Bash
pip install -r requirements.txt
```

### 2. Configurar Credenciales
```bash
cp etl/config/config.yaml.example etl/config/config.yaml
# Editar config.yaml con tus credenciales
```

### 3. Verificar Setup
```bash
python verificar_setup.py
```

### 4. Crear Data Warehouse en SQL Server
```bash
sqlcmd -S localhost -E -i database/target/00_inicializar_base_datos.sql
sqlcmd -S localhost -E -i database/target/01_crear_dimensiones.sql
sqlcmd -S localhost -E -i database/target/02_crear_hechos.sql
sqlcmd -S localhost -E -i database/target/03_crear_vistas.sql
sqlcmd -S localhost -E -i database/target/04_crear_stored_procedures.sql
```

### 5. Primera Carga
```bash
python etl/load/load_dim_tiempo.py --start-year 2018 --end-year 2024
python etl/load/load_dim_static.py
python etl/load/load_dim_cliente.py --mode full
python etl/load/load_dim_producto.py --mode full
python etl/load/load_dim_vendedor.py --mode full
python etl/load/load_fact_ventas.py --truncate
```

**📊 Resultado Esperado:**
- 2,192 fechas
- 271 registros estáticos
- ~1,146 clientes
- ~594 productos  
- ~16 vendedores
- ~40,884 líneas de venta

---

## 📁 Estructura del Proyecto

```
lgl-dw/
├── venv/                          # Virtual environment (NO subir a Git)
├── database/
│   ├── source/
│   │   └── lgldb.sql             # Esquema de BD transaccional
│   └── target/                    # Scripts SQL Server
│       ├── 00_inicializar_base_datos.sql
│       ├── 01_crear_dimensiones.sql
│       ├── 02_crear_hechos.sql
│       ├── 03_crear_vistas.sql
│       └── 04_crear_stored_procedures.sql
├── etl/
│   ├── config/
│   │   ├── config.yaml           # Credenciales (NO subir)
│   │   └── config.yaml.example   # Plantilla
│   ├── load/                     # Scripts de carga
│   │   ├── load_dim_tiempo.py
│   │   ├── load_dim_static.py
│   │   ├── load_dim_cliente.py   # SCD Type 2
│   │   ├── load_dim_producto.py  # SCD Type 2
│   │   ├── load_dim_vendedor.py  # SCD Type 2
│   │   └── load_fact_ventas.py
│   └── utils/
│       ├── database.py           # Conexiones PyMySQL + pyodbc
│       ├── logger.py             # Logging con Loguru
│       └── helpers.py
├── docs/
│   ├── guia_setup_colaboradores.md  # 👈 Guía completa para nuevos devs
│   ├── analisis_base_transaccional.md
│   └── explicacion_query_ventas.md
├── logs/                         # Logs de ejecución
├── powerbi/                      # Dashboards
├── scripts/                      # 🆕 Scripts auxiliares
│   ├── setup/                    # Configuración inicial (una sola vez)
│   │   ├── ejecutar_scripts_sql.py
│   │   ├── grant_alter_permission.py
│   │   └── actualizar_fact_ventas.py
│   ├── exploracion/              # Análisis de esquemas
│   │   ├── explorar_mariadb.py
│   │   ├── ver_esquema_dimensiones.py
│   │   ├── ver_esquema_fact_ventas.py
│   │   └── ...
│   └── README.md
├── tests/                        # Scripts de prueba
│   ├── test_scd2.py             # En raíz para fácil acceso
│   ├── guia_prueba_scd2.py
│   ├── prueba_automatica_scd2.py
│   ├── test_sqlserver.py
│   └── README.md
├── requirements.txt              # Dependencias Python
├── verificar_setup.py           # 👈 Verifica configuración
├── test_scd2.py                 # 👈 Verificar SCD Type 2 (acceso rápido)
├── ver_fact_ventas.py           # 👈 Ver estadísticas DW (acceso rápido)
├── .gitignore
└── README.md                     # 👈 Estás aquí
```

## 🎯 Modelo Dimensional

### Dimensiones (8)

| Dimensión | Tipo | Registros | Descripción |
|-----------|------|-----------|-------------|
| **dim_tiempo** | Estática | 2,192 | Calendario 2020-2025 |
| **dim_tipo_documento** | Estática | 2 | Tipos de documentos |
| **dim_condicion_pago** | Estática | 4 | Condiciones de pago |
| **dim_estado_venta** | Estática | 3 | Estados de ventas |
| **dim_ubicacion** | Estática | 262 | Municipios y departamentos |
| **dim_cliente** | SCD Type 2 | ~1,146 | Clientes con historial |
| **dim_producto** | SCD Type 2 | ~594 | Productos con historial |
| **dim_vendedor** | SCD Type 2 | ~16 | Vendedores con historial |

### Tabla de Hechos

- **fact_ventas**: Detalle de ventas por línea de producto (~40,884 registros)
  - Grain: Cada línea en tabla `salidas` (detalle de venta)
  - 7 Foreign Keys a dimensiones
  - Métricas: cantidad, precio, venta_gravada, venta_exenta, IVA, venta_total
  - Flags: es_venta_credito, esta_liquidado, esta_anulado
  - Fechas: venta, liquidación, anulación

---

## 🔧 Uso Diario

### Carga Incremental

```bash
# Actualizar dimensiones (detecta cambios)
python etl/load/load_dim_cliente.py --modo incremental
python etl/load/load_dim_producto.py --modo incremental
python etl/load/load_dim_vendedor.py --modo incremental

# Cargar ventas de ayer
python etl/load/load_fact_ventas.py --fecha-inicio 2025-11-13 --fecha-fin 2025-11-13
```

### Recarga Completa

```bash
# ⚠️ Solo en caso de error o cambio estructural
python etl/load/load_dim_cliente.py --mode full
python etl/load/load_fact_ventas.py --truncate
```

---

## 🔍 Verificación

### Ver Estadísticas de Dimensiones SCD Type 2
```bash
python test_scd2.py --dimension cliente stats
python test_scd2.py --dimension producto stats
python test_scd2.py --dimension vendedor stats
```

### Ver Historial de un Cliente
```bash
python test_scd2.py --dimension cliente --id 1
```

### Ver Estadísticas de Fact Table
```bash
python ver_fact_ventas.py
```

---

## 📊 Vistas Analíticas

SQL Server incluye 4 vistas pre-construidas:

1. **v_productos_vendidos**: Top productos por período
2. **v_cartera_clientes**: Ventas a crédito pendientes
3. **v_ranking_vendedores**: Desempeño de vendedores
4. **v_ventas_geografia**: Ventas por ubicación
5. **v_kpis_ventas**: Indicadores clave mensuales

---

## 📚 Documentación

| Documento | Descripción |
|-----------|-------------|
| [guia_setup_colaboradores.md](docs/guia_setup_colaboradores.md) | **Setup completo desde cero** |
| [analisis_base_transaccional.md](docs/analisis_base_transaccional.md) | Análisis de BD origen |
| [explicacion_query_ventas.md](docs/explicacion_query_ventas.md) | Query complejo de fact_ventas |

---

## 🛠️ Stack Tecnológico

- **Python 3.12**: ETL
- **PyMySQL 1.1.0**: Conexión a MariaDB
- **pyodbc 5.0.1**: Conexión a SQL Server
- **Loguru 0.7.2**: Logging estructurado
- **MariaDB 10.5+**: BD transaccional (origen)
- **SQL Server 2022**: Data Warehouse (destino)
- **Power BI**: Visualización (pendiente)

**Sin ORMs** - Drivers directos para máximo rendimiento

---

## 🧪 Testing

### Probar SCD Type 2 (Manual)
```bash
python guia_prueba_scd2.py  # Ver instrucciones
python guia_prueba_scd2.py --list  # Ver datos de prueba
```

### Probar SCD Type 2 (Automático)
```bash
python prueba_automatica_scd2.py
```

---

## 🔄 Changelog

### [1.0.0] - 2025-11-13
- ✅ Modelo dimensional completo (8 dimensiones, 1 fact table)
- ✅ ETL Python sin SQLAlchemy (PyMySQL + pyodbc directo)
- ✅ SCD Type 2 implementado y probado
- ✅ Carga completa: 44,937 registros totales
- ✅ Logging estructurado con Loguru
- ✅ Scripts de verificación y testing
- ✅ Documentación completa para colaboradores
- ✅ Vistas analíticas pre-construidas

---

## 👥 Colaboradores

Para configurar tu entorno local, seguí la guía: **[docs/guia_setup_colaboradores.md](docs/guia_setup_colaboradores.md)**

---

## 📝 Notas Importantes

### Archivos que NO se suben a Git
- `venv/` - Virtual environment (recreable con `requirements.txt`)
- `etl/config/config.yaml` - Credenciales (usar `.example` como plantilla)
- `logs/` - Logs de ejecución
- `__pycache__/` - Caché de Python

### ¿Necesitas borrar y recrear el venv?

```bash
# 1. Desactivar si está activo
deactivate

# 2. Borrar
rm -rf venv  # Git Bash
rmdir /s venv  # CMD

# 3. Recrear
python -m venv venv
source venv/Scripts/activate
pip install -r requirements.txt
```

---

**Última actualización:** Noviembre 2025
