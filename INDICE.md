# 📚 Índice Rápido - LGL Data Warehouse

Guía rápida de navegación del proyecto.

---

## 🚀 Para Empezar

| Acción | Archivo |
|--------|---------|
| **Setup inicial** | [`docs/guia_setup_colaboradores.md`](docs/guia_setup_colaboradores.md) |
| **Verificar entorno** | `python verificar_setup.py` |
| **Información general** | [`README.md`](README.md) |

---

## 📊 Scripts Principales (en raíz)

| Script | Propósito | Uso |
|--------|-----------|-----|
| `verificar_setup.py` | Validar configuración | `python verificar_setup.py` |
| `test_scd2.py` | Verificar SCD Type 2 | `python test_scd2.py --dimension cliente stats` |
| `ver_fact_ventas.py` | Ver estadísticas del DW | `python ver_fact_ventas.py` |

---

## 🔄 ETL - Carga de Datos

### Carpeta: `etl/load/`

| Script | Descripción | Modo | Comando |
|--------|-------------|------|---------|
| `load_dim_tiempo.py` | Dimensión tiempo | Full | `python etl/load/load_dim_tiempo.py --anio-inicio 2020 --anio-fin 2025` |
| `load_dim_static.py` | Dimensiones estáticas | Full | `python etl/load/load_dim_static.py` |
| `load_dim_cliente.py` | Clientes (SCD2) | Full/Incremental | `python etl/load/load_dim_cliente.py --modo full` |
| `load_dim_producto.py` | Productos (SCD2) | Full/Incremental | `python etl/load/load_dim_producto.py --modo full` |
| `load_dim_vendedor.py` | Vendedores (SCD2) | Full/Incremental | `python etl/load/load_dim_vendedor.py --modo full` |
| `load_fact_ventas.py` | Tabla de hechos | Full/Fechas | `python etl/load/load_fact_ventas.py --truncate` |

---

## 🗄️ Base de Datos

### Carpeta: `database/target/`

| Script SQL | Propósito |
|------------|-----------|
| `00_inicializar_base_datos.sql` | Crear BD, schemas, usuarios |
| `01_crear_dimensiones.sql` | Crear 8 dimensiones |
| `02_crear_hechos.sql` | Crear fact_ventas |
| `03_crear_vistas.sql` | Crear 4 vistas analíticas |
| `04_crear_stored_procedures.sql` | Crear sp_poblar_dim_tiempo |

---

## 📖 Documentación

### Carpeta: `docs/`

| Documento | Contenido |
|-----------|-----------|
| [`guia_setup_colaboradores.md`](docs/guia_setup_colaboradores.md) | Setup completo para nuevos devs |
| [`analisis_base_transaccional.md`](docs/analisis_base_transaccional.md) | Análisis de BD origen |
| [`explicacion_query_ventas.md`](docs/explicacion_query_ventas.md) | Query complejo de fact_ventas |

---

## 🧪 Testing

### Carpeta: `tests/`

| Script | Propósito |
|--------|-----------|
| `test_scd2.py` | Verificar historiales SCD Type 2 |
| `guia_prueba_scd2.py` | Guía para pruebas manuales |
| `prueba_automatica_scd2.py` | Test automatizado completo |
| `test_sqlserver.py` | Test de conexión |

Ver más: [`tests/README.md`](tests/README.md)

---

## 🔧 Scripts Auxiliares

### Carpeta: `scripts/`

#### Setup (una sola vez)
- `scripts/setup/ejecutar_scripts_sql.py`
- `scripts/setup/grant_alter_permission.py`
- `scripts/setup/actualizar_fact_ventas.py`

#### Exploración
- `scripts/exploracion/explorar_mariadb.py`
- `scripts/exploracion/ver_esquema_dimensiones.py`
- `scripts/exploracion/ver_esquema_fact_ventas.py`

Ver más: [`scripts/README.md`](scripts/README.md)

---

## ⚙️ Configuración

| Archivo | Propósito |
|---------|-----------|
| `etl/config/config.yaml` | Credenciales (NO subir a Git) |
| `etl/config/config.yaml.example` | Plantilla de configuración |
| `requirements.txt` | Dependencias Python |
| `.gitignore` | Archivos excluidos de Git |
| `.env` | Variables de entorno (si existe) |

---

## 🎯 Flujos Comunes

### Primera Carga Completa
```bash
# 1. Verificar setup
python verificar_setup.py

# 2. Cargar dimensiones
python etl/load/load_dim_tiempo.py --anio-inicio 2020 --anio-fin 2025
python etl/load/load_dim_static.py
python etl/load/load_dim_cliente.py --modo full
python etl/load/load_dim_producto.py --modo full
python etl/load/load_dim_vendedor.py --modo full

# 3. Cargar hechos
python etl/load/load_fact_ventas.py --truncate

# 4. Verificar
python ver_fact_ventas.py
python test_scd2.py --dimension cliente stats
```

### Carga Incremental Diaria
```bash
# 1. Actualizar dimensiones SCD2
python etl/load/load_dim_cliente.py --modo incremental
python etl/load/load_dim_producto.py --modo incremental
python etl/load/load_dim_vendedor.py --modo incremental

# 2. Cargar ventas de ayer
python etl/load/load_fact_ventas.py --fecha-inicio 2025-11-14 --fecha-fin 2025-11-14

# 3. Verificar
python ver_fact_ventas.py
```

---

## 📞 Ayuda

- **Setup:** Ver `docs/guia_setup_colaboradores.md`
- **Testing:** Ver `tests/README.md`
- **Scripts:** Ver `scripts/README.md`
- **General:** Ver `README.md`

---

**Última actualización:** Noviembre 2025
