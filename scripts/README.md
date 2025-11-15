# Scripts de Utilidades

Scripts auxiliares para desarrollo, exploración y mantenimiento del Data Warehouse.

## 📂 Estructura

### `setup/`
Scripts ejecutados **una sola vez** durante la configuración inicial:

- `ejecutar_scripts_sql.py` - Helper para ejecutar scripts DDL en SQL Server
- `grant_alter_permission.py` - Otorga permisos ALTER al usuario ETL
- `actualizar_fact_ventas.py` - Actualiza estructura de fact_ventas (elimina columnas de costo/margen)

**Nota:** Estos scripts ya se ejecutaron. Solo necesarios si se recrea el DW desde cero.

---

### `exploracion/`
Scripts para **explorar y analizar** las bases de datos:

#### Exploración de MariaDB
- `explorar_mariadb.py` - Lista todas las tablas de la BD transaccional
- `listar_tablas_sqlserver.py` - Lista tablas en SQL Server

#### Análisis de Esquemas
- `ver_esquema_dimensiones.py` - Muestra estructura de dimensiones
- `ver_esquema_scd2.py` - Muestra estructura de dimensiones SCD Type 2
- `ver_esquema_fact_ventas.py` - Muestra estructura de fact_ventas y tablas origen
- `ver_columnas_dim_ubicacion.py` - Análisis específico de ubicación

#### Diagnóstico
- `diagnostico_sqlserver.py` - Verifica estado de SQL Server

**Uso:** Ejecutar cuando necesites investigar la estructura de datos.

---

## 🚫 No Modificar

Estos scripts son históricos del proceso de desarrollo. **No los modifiques** a menos que necesites recrear el DW.

---

## 📝 Referencia Rápida

```bash
# Ver tablas de MariaDB
python scripts/exploracion/explorar_mariadb.py

# Ver estructura de dimensiones
python scripts/exploracion/ver_esquema_dimensiones.py

# Ver estructura de fact_ventas
python scripts/exploracion/ver_esquema_fact_ventas.py
```
