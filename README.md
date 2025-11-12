# Data Warehouse - Proceso de Ventas

[![Python](https://img.shields.io/badge/Python-3.9%2B-blue)](https://www.python.org/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2019%2B-red)](https://www.microsoft.com/sql-server)
[![MariaDB](https://img.shields.io/badge/MariaDB-10.5%2B-blue)](https://mariadb.org/)
[![Power BI](https://img.shields.io/badge/Power%20BI-Latest-yellow)](https://powerbi.microsoft.com/)

## 📋 Descripción

Data Warehouse implementado con modelo dimensional (Star Schema) para el análisis integral del proceso de ventas. Incluye proceso ETL automatizado con Python, desde MariaDB hacia SQL Server, con visualización en Power BI.

## 🏗️ Arquitectura

```
MariaDB (OLTP) → Python ETL → SQL Server (OLAP) → Power BI
```

### Componentes Principales

- **Fuente de Datos**: Base de datos transaccional en MariaDB
- **Proceso ETL**: Scripts Python para extracción, transformación y carga
- **Data Warehouse**: SQL Server con modelo dimensional
- **Visualización**: Dashboards en Power BI

## 📁 Estructura del Proyecto

```
lgl-dw/
├── database/
│   ├── source/              # Scripts BD transaccional (MariaDB)
│   ├── target/              # Scripts DW (SQL Server)
│   └── queries/             # Consultas analíticas
├── etl/
│   ├── config/              # Configuraciones
│   ├── extract/             # Scripts de extracción
│   ├── transform/           # Scripts de transformación
│   ├── load/                # Scripts de carga
│   ├── utils/               # Utilidades
│   └── main_etl.py          # Orquestador principal
├── powerbi/                 # Archivos Power BI
├── logs/                    # Logs de ejecución
├── docs/                    # Documentación
└── tests/                   # Tests unitarios
```

## 🎯 Modelo Dimensional

### Dimensiones

- **dim_tiempo**: Análisis temporal (año, trimestre, mes, semana, día)
- **dim_cliente**: Información de clientes (SCD Tipo 2)
- **dim_producto**: Catálogo de productos (SCD Tipo 2)
- **dim_vendedor**: Información de vendedores (SCD Tipo 2)
- **dim_tipo_documento**: Tipos de documentos de venta
- **dim_condicion_pago**: Condiciones de pago
- **dim_estado_venta**: Estados de las ventas
- **dim_ubicacion**: Geografía (municipios y departamentos)

### Tablas de Hechos

- **fact_ventas**: Detalle de ventas a nivel de línea de producto
- **fact_ventas_diarias**: Tabla agregada para mejor performance

## 🚀 Instalación

### Prerrequisitos

- Python 3.9 o superior
- MariaDB 10.5 o superior
- SQL Server 2019 o superior
- Power BI Desktop
- ODBC Driver 17 for SQL Server

### Configuración Inicial

1. **Clonar el repositorio**
```bash
git clone <url-repositorio>
cd lgl-dw
```

2. **Crear entorno virtual**
```bash
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

3. **Instalar dependencias**
```bash
pip install -r requirements.txt
```

4. **Configurar variables de entorno**
```bash
cp .env.example .env
# Editar .env con tus credenciales
```

5. **Crear estructura del Data Warehouse**
```bash
# Ejecutar scripts en SQL Server en orden:
sqlcmd -S localhost -U sa -P password -i database/target/01_crear_dimensiones.sql
sqlcmd -S localhost -U sa -P password -i database/target/02_crear_hechos.sql
sqlcmd -S localhost -U sa -P password -i database/target/03_crear_vistas.sql
sqlcmd -S localhost -U sa -P password -i database/target/04_crear_stored_procedures.sql
```

6. **Poblar dimensión tiempo**
```sql
EXEC dbo.sp_poblar_dim_tiempo '2020-01-01', '2030-12-31';
```

## 🔧 Uso

### Carga Histórica (Primera vez)

```bash
python etl/main_etl.py --mode full --start-date 2020-01-01
```

### Carga Incremental (Diaria)

```bash
python etl/main_etl.py --mode incremental
```

### Carga de una Dimensión Específica

```bash
python etl/main_etl.py --dimension cliente
```

## 📊 Consultas Analíticas

El archivo `database/queries/consultas_analiticas.sql` contiene más de 50 consultas de ejemplo para:

- Análisis de ventas por período
- Top clientes y productos
- Análisis de rentabilidad
- Desempeño de vendedores
- Análisis geográfico
- Gestión de cartera
- KPIs ejecutivos

## 📈 Power BI

### Conectar al Data Warehouse

1. Abrir Power BI Desktop
2. Obtener datos → SQL Server
3. Servidor: `localhost` (o tu servidor)
4. Base de datos: `LGL_DW`
5. Importar tablas:
   - Todas las dimensiones (dim_*)
   - fact_ventas o fact_ventas_diarias
   - Vistas analíticas (v_*)

### Relaciones Recomendadas

```
dim_tiempo → fact_ventas (tiempo_key)
dim_cliente → fact_ventas (cliente_key)
dim_producto → fact_ventas (producto_key)
dim_vendedor → fact_ventas (vendedor_key)
...
```

## 🔍 Monitoreo

### Logs

Los logs se generan automáticamente en la carpeta `logs/`:
- `etl_YYYY-MM-DD.log`: Log diario del proceso ETL
- Nivel de detalle configurable en `config.yaml`

### Validaciones

El proceso ETL incluye validaciones automáticas:
- Conteo de registros
- Calidad de datos
- Integridad referencial

## 📚 Documentación

Documentación detallada disponible en:
- [Documentación Técnica](docs/documentacion_dw.md)
- [Guía de Instalación](docs/guia_instalacion.md)
- [Diccionario de Datos](docs/diccionario_datos.md)

## 🧪 Testing

Ejecutar tests unitarios:
```bash
pytest tests/
```

Con cobertura:
```bash
pytest --cov=etl tests/
```

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📝 Licencia

Este proyecto es privado y confidencial.

## 👥 Equipo

- **Data Engineering**: [Tu Nombre]
- **BI & Analytics**: [Nombre]
- **DBA**: [Nombre]

## 📞 Soporte

Para soporte o preguntas:
- Email: admin@empresa.com
- Slack: #data-warehouse

## 🔄 Changelog

### [1.0.0] - 2025-11-12
- ✅ Implementación inicial del modelo dimensional
- ✅ Scripts ETL en Python
- ✅ Proceso de carga histórica e incremental
- ✅ Vistas analíticas y stored procedures
- ✅ Documentación completa

---

**Nota**: Recuerda actualizar las credenciales en el archivo `.env` y mantenerlo fuera del control de versiones.
