# Guía de Instalación - Data Warehouse de Ventas

## 📋 Tabla de Contenidos

1. [Prerrequisitos](#prerrequisitos)
2. [Instalación de Software](#instalación-de-software)
3. [Configuración de Bases de Datos](#configuración-de-bases-de-datos)
4. [Configuración del Proyecto](#configuración-del-proyecto)
5. [Creación del Data Warehouse](#creación-del-data-warehouse)
6. [Configuración del ETL](#configuración-del-etl)
7. [Configuración de Power BI](#configuración-de-power-bi)
8. [Verificación](#verificación)
9. [Solución de Problemas](#solución-de-problemas)

---

## 1. Prerrequisitos

### Software Requerido

- **Python**: 3.9 o superior
- **MariaDB**: 10.5 o superior (Base de datos origen)
- **SQL Server**: 2019 o superior (Data Warehouse)
- **Power BI Desktop**: Última versión
- **ODBC Driver 17 for SQL Server**: Para conexión Python-SQL Server
- **Git**: Para control de versiones (opcional)

### Conocimientos Recomendados

- SQL (básico)
- Python (básico)
- Conceptos de Data Warehouse
- Power BI (básico)

---

## 2. Instalación de Software

### 2.1 Python

**Windows:**
1. Descargar de [python.org](https://www.python.org/downloads/)
2. Ejecutar instalador
3. ✅ Marcar "Add Python to PATH"
4. Verificar instalación:
```bash
python --version
pip --version
```

### 2.2 MariaDB (Si no está instalado)

1. Descargar de [mariadb.org](https://mariadb.org/download/)
2. Instalar con configuración predeterminada
3. Guardar contraseña de root
4. Verificar servicio activo

### 2.3 SQL Server

**Opción 1: SQL Server Express (Gratis)**
1. Descargar [SQL Server 2019 Express](https://www.microsoft.com/sql-server/sql-server-downloads)
2. Elegir instalación "Basic"
3. Instalar SQL Server Management Studio (SSMS)

**Opción 2: SQL Server Developer (Gratis para desarrollo)**
1. Descargar SQL Server Developer Edition
2. Instalar con configuración estándar

**Configuración:**
- Habilitar autenticación mixta (Windows + SQL)
- Crear usuario `sa` con contraseña segura
- Habilitar TCP/IP en configuración de red

### 2.4 ODBC Driver for SQL Server

**Windows:**
1. Descargar [ODBC Driver 17](https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server)
2. Ejecutar instalador
3. Verificar instalación:
```bash
# En PowerShell
Get-OdbcDriver | Where-Object {$_.Name -like "*SQL Server*"}
```

### 2.5 Power BI Desktop

1. Descargar de [Microsoft Store](https://www.microsoft.com/store/productId/9NTXR16HNW1T)
   O desde [powerbi.microsoft.com](https://powerbi.microsoft.com/desktop/)
2. Instalar con configuración predeterminada

---

## 3. Configuración de Bases de Datos

### 3.1 MariaDB (Base de Datos Origen)

```sql
-- Conectar a MariaDB
mysql -u root -p

-- Crear base de datos (si no existe)
CREATE DATABASE IF NOT EXISTS lgl_transaccional 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- Crear usuario para ETL
CREATE USER IF NOT EXISTS 'etl_user'@'localhost' IDENTIFIED BY 'password_seguro';

-- Otorgar permisos de solo lectura
GRANT SELECT ON lgl_transaccional.* TO 'etl_user'@'localhost';

-- Aplicar cambios
FLUSH PRIVILEGES;

-- Verificar
SHOW DATABASES;
```

### 3.2 SQL Server (Data Warehouse)

**Opción A: Con SQL Server Management Studio (SSMS)**

1. Abrir SSMS
2. Conectar al servidor (localhost o nombre del servidor)
3. Abrir archivo: `database/target/00_inicializar_base_datos.sql`
4. **IMPORTANTE**: Editar las rutas de los archivos de datos:
   ```sql
   FILENAME = N'C:\SQLData\LGL_DW_Data.mdf'  -- Ajustar según tu instalación
   ```
5. Ejecutar script (F5)

**Opción B: Con sqlcmd (Línea de comandos)**

```bash
# Ajustar usuario y contraseña
sqlcmd -S localhost -U sa -P tu_password -i database/target/00_inicializar_base_datos.sql
```

---

## 4. Configuración del Proyecto

### 4.1 Clonar/Descargar el Proyecto

```bash
# Si usas Git
git clone <url-del-repositorio>
cd lgl-dw

# O descargar ZIP y extraer
```

### 4.2 Crear Entorno Virtual de Python

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**Linux/Mac:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### 4.3 Instalar Dependencias

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**Verificar instalación:**
```bash
pip list
```

### 4.4 Configurar Variables de Entorno

1. Copiar archivo de ejemplo:
```bash
# Windows
copy .env.example .env

# Linux/Mac
cp .env.example .env
```

2. Editar `.env` con tus credenciales:
```env
# Base de datos origen (MariaDB)
SOURCE_DB_HOST=localhost
SOURCE_DB_PORT=3306
SOURCE_DB_NAME=lgl_transaccional
SOURCE_DB_USER=etl_user
SOURCE_DB_PASSWORD=password_seguro

# Base de datos destino (SQL Server)
TARGET_DB_HOST=localhost
TARGET_DB_PORT=1433
TARGET_DB_NAME=LGL_DW
TARGET_DB_USER=sa
TARGET_DB_PASSWORD=tu_password_sqlserver
```

3. **IMPORTANTE**: Verificar que `.env` esté en `.gitignore`

---

## 5. Creación del Data Warehouse

### 5.1 Ejecutar Scripts en Orden

**Opción A: Con SSMS**
1. Conectar a SQL Server
2. Seleccionar base de datos `LGL_DW`
3. Ejecutar en orden:

```
✅ 01_crear_dimensiones.sql
✅ 02_crear_hechos.sql
✅ 03_crear_vistas.sql
✅ 04_crear_stored_procedures.sql
```

**Opción B: Con sqlcmd**

```bash
cd database/target

sqlcmd -S localhost -U sa -P password -d LGL_DW -i 01_crear_dimensiones.sql
sqlcmd -S localhost -U sa -P password -d LGL_DW -i 02_crear_hechos.sql
sqlcmd -S localhost -U sa -P password -d LGL_DW -i 03_crear_vistas.sql
sqlcmd -S localhost -U sa -P password -d LGL_DW -i 04_crear_stored_procedures.sql
```

### 5.2 Poblar Dimensión Tiempo

En SSMS o sqlcmd:

```sql
USE LGL_DW;
GO

-- Poblar desde 2020 hasta 2030
EXEC dbo.sp_poblar_dim_tiempo '2020-01-01', '2030-12-31';
GO

-- Verificar
SELECT COUNT(*) AS total_dias FROM dbo.dim_tiempo;
-- Debe retornar aproximadamente 3,652 días
```

### 5.3 Verificar Estructura

```sql
-- Listar todas las tablas
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_TYPE, TABLE_NAME;

-- Verificar dimensiones vacías
SELECT 'dim_cliente' AS tabla, COUNT(*) AS registros FROM dim_cliente
UNION ALL
SELECT 'dim_producto', COUNT(*) FROM dim_producto
UNION ALL
SELECT 'dim_vendedor', COUNT(*) FROM dim_vendedor
UNION ALL
SELECT 'dim_tipo_documento', COUNT(*) FROM dim_tipo_documento
UNION ALL
SELECT 'dim_condicion_pago', COUNT(*) FROM dim_condicion_pago
UNION ALL
SELECT 'dim_estado_venta', COUNT(*) FROM dim_estado_venta
UNION ALL
SELECT 'dim_tiempo', COUNT(*) FROM dim_tiempo
UNION ALL
SELECT 'fact_ventas', COUNT(*) FROM fact_ventas;
```

---

## 6. Configuración del ETL

### 6.1 Verificar Conexiones

Crear script de prueba `test_conexiones.py`:

```python
import pymysql
import pyodbc
from dotenv import load_dotenv
import os

load_dotenv()

# Probar MariaDB
try:
    conn_maria = pymysql.connect(
        host=os.getenv('SOURCE_DB_HOST'),
        port=int(os.getenv('SOURCE_DB_PORT')),
        user=os.getenv('SOURCE_DB_USER'),
        password=os.getenv('SOURCE_DB_PASSWORD'),
        database=os.getenv('SOURCE_DB_NAME')
    )
    print("✅ Conexión a MariaDB exitosa")
    conn_maria.close()
except Exception as e:
    print(f"❌ Error en MariaDB: {e}")

# Probar SQL Server
try:
    conn_str = (
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={os.getenv('TARGET_DB_HOST')};"
        f"DATABASE={os.getenv('TARGET_DB_NAME')};"
        f"UID={os.getenv('TARGET_DB_USER')};"
        f"PWD={os.getenv('TARGET_DB_PASSWORD')}"
    )
    conn_sql = pyodbc.connect(conn_str)
    print("✅ Conexión a SQL Server exitosa")
    conn_sql.close()
except Exception as e:
    print(f"❌ Error en SQL Server: {e}")
```

Ejecutar:
```bash
python test_conexiones.py
```

### 6.2 Configurar config.yaml

Editar `etl/config/config.yaml` según tus necesidades:

```yaml
etl:
  mode: "incremental"
  batch_size: 1000
  parallel_processes: 4

logging:
  level: "INFO"
  log_to_file: true
```

---

## 7. Configuración de Power BI

### 7.1 Conectar a SQL Server

1. Abrir Power BI Desktop
2. Obtener datos → SQL Server
3. Configurar conexión:
   - **Servidor**: `localhost` (o tu servidor)
   - **Base de datos**: `LGL_DW`
   - **Modo de conectividad**: Import
4. Seleccionar tablas:
   - ✅ Todas las dimensiones (dim_*)
   - ✅ fact_ventas o fact_ventas_diarias
   - ✅ Vistas si necesitas (v_*)

### 7.2 Configurar Relaciones

En "Vista de Modelo", verificar relaciones automáticas:

```
dim_tiempo[tiempo_key] → fact_ventas[tiempo_key]
dim_cliente[cliente_key] → fact_ventas[cliente_key]
dim_producto[producto_key] → fact_ventas[producto_key]
...
```

### 7.3 Crear Medidas Básicas

```dax
Total Ventas = SUM(fact_ventas[venta_total_con_impuestos])
Margen Bruto = SUM(fact_ventas[margen_bruto])
% Margen = DIVIDE([Margen Bruto], SUM(fact_ventas[venta_total]), 0)
Número de Ventas = COUNTROWS(fact_ventas)
```

---

## 8. Verificación

### 8.1 Checklist de Instalación

- [ ] Python instalado y funcionando
- [ ] MariaDB accesible y con datos
- [ ] SQL Server instalado y corriendo
- [ ] Base de datos LGL_DW creada
- [ ] Todas las dimensiones creadas
- [ ] Tabla de hechos creada
- [ ] Dimensión tiempo poblada
- [ ] Stored procedures creados
- [ ] Variables de entorno configuradas
- [ ] Dependencias Python instaladas
- [ ] Conexiones de prueba exitosas
- [ ] Power BI conectado al DW

### 8.2 Prueba de Carga Inicial

```bash
# Activar entorno virtual
venv\Scripts\activate

# Ejecutar carga de prueba (próximo paso del proyecto)
python etl/main_etl.py --mode full --start-date 2024-01-01 --end-date 2024-01-31
```

---

## 9. Solución de Problemas

### Problema: Error de conexión a SQL Server

**Error**: `[Microsoft][ODBC Driver 17 for SQL Server][SQL Server]Login failed`

**Solución**:
1. Verificar que SQL Server esté corriendo:
   - Services.msc → SQL Server (MSSQLSERVER) → Running
2. Verificar autenticación mixta habilitada
3. Verificar usuario y contraseña en `.env`
4. Verificar TCP/IP habilitado en SQL Server Configuration Manager

### Problema: Error al instalar pymysql o pyodbc

**Error**: `error: Microsoft Visual C++ 14.0 is required`

**Solución**:
1. Descargar e instalar [Visual C++ Build Tools](https://visualstudio.microsoft.com/downloads/)
2. O instalar versiones precompiladas:
   ```bash
   pip install pymysql --no-cache-dir
   ```

### Problema: Power BI no encuentra el servidor

**Solución**:
1. Verificar que SQL Server Browser esté corriendo
2. Habilitar puerto 1433 en firewall:
   ```bash
   netsh advfirewall firewall add rule name="SQL Server" dir=in action=allow protocol=TCP localport=1433
   ```

### Problema: Permisos insuficientes en SQL Server

**Solución**:
```sql
-- Como sa
USE LGL_DW;
GO

ALTER ROLE db_datareader ADD MEMBER etl_user;
ALTER ROLE db_datawriter ADD MEMBER etl_user;
GO
```

---

## 📞 Soporte

Si encuentras problemas no documentados:

1. Revisar logs en carpeta `logs/`
2. Consultar documentación en `docs/`
3. Contactar al equipo: admin@empresa.com

---

**¡Felicitaciones! Tu Data Warehouse está listo para comenzar a cargar datos.** 🎉
