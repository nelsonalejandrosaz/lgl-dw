# Guía de Setup - Data Warehouse LGL

## 📋 Requisitos Previos

### Software Instalado
- ✅ Python 3.12+ ([python.org](https://www.python.org/downloads/))
- ✅ MariaDB 10.5+ (base transaccional)
- ✅ SQL Server 2022 (Data Warehouse)
- ✅ ODBC Driver 17 for SQL Server
- ✅ Git (para clonar el repositorio)

---

## 🚀 Setup Paso a Paso

### 1. Clonar el Repositorio

```bash
git clone https://github.com/nelsonalejandrosaz/lgl-dw.git
cd lgl-dw
```

---

### 2. Crear Virtual Environment

**¿Qué es venv?** Un entorno Python aislado para este proyecto.

```bash
# Crear el virtual environment
python -m venv venv

# Activar (Windows - Git Bash)
source venv/Scripts/activate

# Activar (Windows - CMD)
venv\Scripts\activate.bat

# Activar (Windows - PowerShell)
venv\Scripts\Activate.ps1

# Activar (Linux/Mac)
source venv/bin/activate
```

**✅ Sabrás que está activo cuando veas `(venv)` al inicio de tu prompt:**
```bash
(venv) user@computer ~/proyectos/lgl-dw $
```

---

### 3. Instalar Dependencias

```bash
# Con el venv activo
pip install -r requirements.txt
```

**Paquetes que se instalarán:**
- `pymysql==1.1.0` - Conexión a MariaDB
- `pyodbc==5.0.1` - Conexión a SQL Server
- `pandas==2.1.3` - Manipulación de datos
- `loguru==0.7.2` - Sistema de logging
- `pyyaml==6.0.1` - Configuración

---

### 4. Configurar Credenciales

Edita `etl/config/config.yaml`:

```yaml
source_db:
  host: localhost
  port: 3306
  database: lgldb
  user: root
  password: TU_PASSWORD_MARIADB

target_db:
  server: localhost
  port: 1433
  database: LGL_DW
  user: etl_dw_user
  password: TU_PASSWORD_SQLSERVER
  driver: "ODBC Driver 17 for SQL Server"
  trusted_connection: false
  trust_server_certificate: true
```

---

### 5. Crear Base de Datos en SQL Server

**Opción A: Con Windows Authentication**
```bash
# Ejecutar scripts DDL
sqlcmd -S localhost -E -i database/target/00_inicializar_base_datos.sql
sqlcmd -S localhost -E -i database/target/01_crear_dimensiones.sql
sqlcmd -S localhost -E -i database/target/02_crear_hechos.sql
sqlcmd -S localhost -E -i database/target/03_crear_vistas.sql
sqlcmd -S localhost -E -i database/target/04_crear_stored_procedures.sql
```

**Opción B: Con SQL Authentication**
```bash
sqlcmd -S localhost -U sa -P TU_PASSWORD -i database/target/00_inicializar_base_datos.sql
# ... repetir para los demás scripts
```

---

### 6. Verificar Conexiones

```bash
# Probar conexión a MariaDB
python -c "from etl.utils.database import SourceDatabase; db = SourceDatabase(); print('MariaDB:', db.test_connection())"

# Probar conexión a SQL Server
python -c "from etl.utils.database import TargetDatabase; db = TargetDatabase(); print('SQL Server:', db.test_connection())"
```

**Salida esperada:**
```
MariaDB: True
SQL Server: True
```

---

## 📊 Primera Carga de Datos

### Paso 1: Dimensión Tiempo
```bash
python etl/load/load_dim_tiempo.py --start-year 2018 --end-year 2024
```
**Resultado esperado:** 3,652 registros (fechas desde 2018-01-01 hasta 2024-12-31)

### Paso 2: Dimensiones Estáticas
```bash
python etl/load/load_dim_static.py
```
**Resultado esperado:** 271 registros (tipo_documento: 2, condicion_pago: 4, estado_venta: 3, ubicacion: 262)

### Paso 3: Dimensión Cliente (SCD Type 2)
```bash
python etl/load/load_dim_cliente.py --mode full
```
**Resultado esperado:** ~1,146 clientes

### Paso 4: Dimensión Producto (SCD Type 2)
```bash
python etl/load/load_dim_producto.py --mode full
```
**Resultado esperado:** ~594 productos

### Paso 5: Dimensión Vendedor (SCD Type 2)
```bash
python etl/load/load_dim_vendedor.py --mode full
```
**Resultado esperado:** ~16 vendedores

### Paso 6: Tabla de Hechos
```bash
python etl/load/load_fact_ventas.py --truncate
```
**Resultado esperado:** ~40,884 líneas de venta

---

## 🔄 Cargas Incrementales

### Actualizar Dimensiones SCD Type 2
```bash
# Detecta cambios en clientes/productos/vendedores
python etl/load/load_dim_cliente.py --modo incremental
python etl/load/load_dim_producto.py --modo incremental
python etl/load/load_dim_vendedor.py --modo incremental
```

### Cargar Ventas por Fecha
```bash
# Carga solo ventas de ayer
python etl/load/load_fact_ventas.py --fecha-inicio 2025-11-13 --fecha-fin 2025-11-13

# Carga un rango de fechas
python etl/load/load_fact_ventas.py --fecha-inicio 2025-11-01 --fecha-fin 2025-11-30
```

---

## 🛠️ Comandos Útiles

### Gestión del Virtual Environment

```bash
# Activar
source venv/Scripts/activate  # Git Bash

# Desactivar
deactivate

# Ver paquetes instalados
pip list

# Actualizar un paquete
pip install --upgrade nombre_paquete

# Recrear requirements.txt
pip freeze > requirements.txt
```

### Verificar Datos Cargados

```bash
# Ver estadísticas de fact_ventas
python ver_fact_ventas.py

# Ver dimensiones SCD Type 2
python test_scd2.py --dimension cliente stats
python test_scd2.py --dimension producto stats
python test_scd2.py --dimension vendedor stats

# Ver historial de un cliente específico
python test_scd2.py --dimension cliente --id 1
```

---

## 🧹 Recrear Virtual Environment

Si necesitas recrear el venv desde cero:

```bash
# 1. Desactivar venv (si está activo)
deactivate

# 2. Borrar carpeta venv
rm -rf venv  # Git Bash / Linux / Mac
# o en CMD: rmdir /s venv

# 3. Recrear
python -m venv venv

# 4. Activar
source venv/Scripts/activate

# 5. Reinstalar dependencias
pip install -r requirements.txt
```

**⚠️ Importante:** El archivo `requirements.txt` contiene la lista exacta de paquetes. **NO borres este archivo**.

---

## 📁 Estructura del Proyecto

```
lgl-dw/
├── venv/                          # Virtual environment (NO subir a Git)
├── database/                      # Scripts SQL
│   ├── source/                   # Base transaccional
│   └── target/                   # Data Warehouse
│       ├── 00_inicializar_base_datos.sql
│       ├── 01_crear_dimensiones.sql
│       ├── 02_crear_hechos.sql
│       ├── 03_crear_vistas.sql
│       └── 04_crear_stored_procedures.sql
├── etl/                          # Scripts ETL Python
│   ├── config/
│   │   └── config.yaml          # Configuración (NO subir a Git)
│   ├── load/                    # Scripts de carga
│   │   ├── load_dim_tiempo.py
│   │   ├── load_dim_static.py
│   │   ├── load_dim_cliente.py
│   │   ├── load_dim_producto.py
│   │   ├── load_dim_vendedor.py
│   │   └── load_fact_ventas.py
│   └── utils/                   # Utilidades
│       ├── database.py
│       ├── logger.py
│       └── helpers.py
├── docs/                         # Documentación
│   ├── guia_setup_colaboradores.md  ← Estás aquí
│   ├── analisis_base_transaccional.md
│   └── explicacion_query_ventas.md
├── logs/                         # Logs de ejecución
├── tests/                        # Scripts de prueba
├── requirements.txt              # Dependencias Python
└── README.md                     # Documentación principal
```

---

## ❓ Preguntas Frecuentes

### ¿Por qué usar venv?
- **Aislamiento:** Cada proyecto tiene sus propias versiones de paquetes
- **Reproducibilidad:** Otros pueden recrear el entorno exacto con `requirements.txt`
- **No contamina:** No afecta el Python del sistema

### ¿Puedo usar otro nombre para el venv?
Sí, pero **mantén `venv`** porque ya está en `.gitignore`. Si usas otro nombre, agrégalo a `.gitignore`.

### ¿Qué archivos NO debo subir a Git?
```
venv/                    # Virtual environment
etl/config/config.yaml  # Credenciales
logs/                    # Logs de ejecución
__pycache__/            # Caché de Python
*.pyc                    # Bytecode compilado
```

### ¿Cómo actualizo el proyecto si hay cambios?
```bash
git pull origin main
pip install -r requirements.txt  # Por si hay nuevas dependencias
```

### ¿Cuánto espacio ocupa el venv?
Aproximadamente 100-200 MB. Es recreable en cualquier momento con `requirements.txt`.

---

## 🆘 Solución de Problemas

### Error: "python: command not found"
Asegúrate de tener Python instalado y en el PATH del sistema.

### Error: "pip: command not found"
```bash
python -m pip install --upgrade pip
```

### Error de conexión a SQL Server
Verifica:
1. SQL Server está corriendo
2. Puerto 1433 está abierto
3. Usuario `etl_dw_user` existe con permisos correctos
4. ODBC Driver 17 está instalado

### Error de conexión a MariaDB
Verifica:
1. MariaDB está corriendo
2. Puerto 3306 está abierto
3. Usuario tiene permisos en la base `lgldb`

---

## 📞 Contacto

Para dudas o problemas, contactar al equipo de desarrollo.

---

**Última actualización:** Noviembre 2025
