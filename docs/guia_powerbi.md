# Guía de Conexión Power BI Desktop con Data Warehouse

## 📋 Requisitos Previos

1. **Power BI Desktop instalado** (descarga gratuita desde https://powerbi.microsoft.com/desktop)
2. **SQL Server con base de datos LGL_DW** funcionando en localhost
3. **Credenciales de acceso**: Windows Authentication o usuario SQL Server

---

## 🚀 Paso 1: Abrir Power BI Desktop

1. Inicia **Power BI Desktop**
2. Si es la primera vez, puede pedir que inicies sesión (puedes omitir este paso)
3. Verás una pantalla inicial con opciones

---

## 🔌 Paso 2: Conectar a SQL Server

### Opción A: Desde la pantalla inicial

1. Clic en **"Obtener datos"** o **"Get Data"**
2. En el cuadro de búsqueda, escribe: `SQL Server`
3. Selecciona **"SQL Server database"**
4. Clic en **"Conectar"** o **"Connect"**

### Opción B: Desde la cinta de opciones

1. En la barra superior, pestaña **"Inicio"**
2. Clic en **"Obtener datos"** → **"Más..."**
3. Busca y selecciona **"SQL Server database"**
4. Clic en **"Conectar"**

---

## ⚙️ Paso 3: Configurar la Conexión

Aparecerá un diálogo con campos para conectar:

### Configuración:

```
Servidor (Server):          localhost
o también puede ser:        localhost\SQLEXPRESS

Base de datos (Database):   LGL_DW

Modo de conectividad de datos:
   ☑ Importar (recomendado para tu DW)
   ☐ DirectQuery
```

### Opciones avanzadas (Expandir):

Si quieres filtrar desde la conexión, puedes agregar una consulta SQL:

```sql
-- Ejemplo: solo ventas de 2023 en adelante
SELECT * 
FROM fact_ventas fv
WHERE fv.tiempo_key IN (
    SELECT tiempo_key 
    FROM dim_tiempo 
    WHERE anio >= 2023
)
```

**Nota**: Por ahora, déjalo en blanco para importar todo.

---

## 🔐 Paso 4: Autenticación

Selecciona el método de autenticación:

### Opción 1: Windows Authentication (recomendado)
- Selecciona **"Windows"** en el panel izquierdo
- Power BI usará tu usuario de Windows actual
- Clic en **"Conectar"**

### Opción 2: Credenciales SQL Server
- Selecciona **"Base de datos"** o **"Database"**
- Ingresa:
  - **Usuario**: `etl_dw_user` (u otro usuario con permisos de lectura)
  - **Contraseña**: (la contraseña del usuario)
- Clic en **"Conectar"**

---

## 📊 Paso 5: Seleccionar Tablas

Aparecerá el **Navegador** con todas las tablas disponibles:

### Tablas a seleccionar (marca las casillas):

#### ✅ Tabla de Hechos:
- `fact_ventas`

#### ✅ Dimensiones:
- `dim_tiempo`
- `dim_cliente`
- `dim_producto`
- `dim_vendedor`
- `dim_ubicacion`
- `dim_tipo_documento`
- `dim_condicion_pago`
- `dim_estado_venta`

#### ✅ Vistas Analíticas (opcional, pero recomendado):
- `v_ventas_completas`
- `v_productos_vendidos`
- `v_cartera_clientes`
- `v_ranking_vendedores`

### Vista previa:
- Puedes hacer clic en cada tabla para ver una vista previa de los datos
- Verifica que las tablas tengan datos

### Cargar datos:
1. Después de seleccionar todas las tablas necesarias
2. Clic en **"Cargar"** o **"Load"** (botón en la parte inferior)
3. Power BI comenzará a importar los datos (puede tardar 1-2 minutos)

---

## 🔗 Paso 6: Crear Relaciones (Modelo de Datos)

Power BI puede detectar automáticamente algunas relaciones, pero es mejor verificarlas:

### 6.1 Ir a la Vista de Modelo:
- En el panel izquierdo, clic en el ícono de **"Modelo"** (parece un diagrama)
- Verás todas las tablas como cajas conectadas

### 6.2 Crear/Verificar Relaciones:

#### Relaciones de fact_ventas con dimensiones:

| Tabla Origen    | Campo             | Tabla Destino         | Campo               | Cardinalidad | Dirección |
|-----------------|-------------------|-----------------------|---------------------|--------------|-----------|
| fact_ventas     | tiempo_key        | dim_tiempo            | tiempo_key          | Muchos a Uno | Única     |
| fact_ventas     | cliente_key       | dim_cliente           | cliente_key         | Muchos a Uno | Única     |
| fact_ventas     | producto_key      | dim_producto          | producto_key        | Muchos a Uno | Única     |
| fact_ventas     | vendedor_key      | dim_vendedor          | vendedor_key        | Muchos a Uno | Única     |
| fact_ventas     | ubicacion_key     | dim_ubicacion         | ubicacion_key       | Muchos a Uno | Única     |
| fact_ventas     | tipo_documento_key| dim_tipo_documento    | tipo_documento_key  | Muchos a Uno | Única     |
| fact_ventas     | condicion_pago_key| dim_condicion_pago    | condicion_pago_key  | Muchos a Uno | Única     |
| fact_ventas     | estado_venta_key  | dim_estado_venta      | estado_venta_key    | Muchos a Uno | Única     |

### 6.3 Crear una Relación Manualmente:

Si falta alguna relación:

1. **Arrastra** el campo `tiempo_key` de `fact_ventas`
2. **Suelta** sobre el campo `tiempo_key` en `dim_tiempo`
3. En el diálogo que aparece, configura:
   - **Cardinalidad**: `Muchos a uno (*:1)`
   - **Dirección de filtro cruzado**: `Única` (de dimensión → hecho)
4. Clic en **"Aceptar"**
5. Repite para cada dimensión

### 6.4 Verificar Relaciones Activas:

- Las líneas entre tablas deben ser **sólidas** (no punteadas)
- Si están punteadas, haz clic derecho → **"Activar relación"**

---

## 📈 Paso 7: Crear tu Primera Visualización

Vamos a crear un reporte simple de ventas:

### 7.1 Ir a Vista de Informe:
- Clic en el ícono **"Informe"** o **"Report"** (primer ícono en panel izquierdo)

### 7.2 Crear una Tabla de Ventas por Año:

1. En el panel derecho, en **"Campos"**, expande `fact_ventas`
2. Marca la casilla de: `☑ monto_venta`
3. Expande `dim_tiempo` y marca: `☑ anio`
4. Power BI creará automáticamente una visualización

5. En **"Visualizaciones"** (panel derecho arriba), cambia a:
   - **Gráfico de columnas agrupadas** o
   - **Gráfico de barras**

### 7.3 Crear KPI de Total de Ventas:

1. Clic en un área en blanco del lienzo
2. En **"Visualizaciones"**, selecciona **"Tarjeta"** (Card)
3. Arrastra `monto_venta` de `fact_ventas` al área de la tarjeta
4. Verás el total de ventas: **$1,471,206.11**

### 7.4 Crear Tabla de Top Productos:

1. Clic en área en blanco
2. En **"Visualizaciones"**, selecciona **"Tabla"**
3. Arrastra estos campos:
   - `dim_producto` → `nombre`
   - `fact_ventas` → `cantidad`
   - `fact_ventas` → `monto_venta`
4. Ordena por `monto_venta` descendente (clic en encabezado)

---

## 🎯 Paso 8: Usar Vistas Analíticas (Más Fácil)

Si cargaste las vistas, puedes usarlas directamente sin unir tablas:

### Ejemplo con `v_ventas_completas`:

1. Clic en área en blanco
2. En **"Campos"**, expande `v_ventas_completas`
3. Ya contiene todos los campos unidos (cliente, producto, fecha, etc.)
4. Arrastra:
   - `departamento` (de cliente)
   - `monto_venta`
5. Crea un **mapa** o **gráfico de barras** por departamento

### Ventaja de las vistas:
- No necesitas crear relaciones
- Todos los datos ya están combinados
- Ideal para principiantes en Power BI

---

## 🔄 Paso 9: Actualizar Datos

Cuando cargues nuevos datos en el DW:

### Opción 1: Actualización Manual
1. En Power BI Desktop, cinta **"Inicio"**
2. Clic en **"Actualizar"** o **"Refresh"**
3. Power BI volverá a importar los datos desde SQL Server

### Opción 2: Actualización Automática (Power BI Service)
- Necesitas publicar el informe en Power BI Service (nube)
- Configurar Gateway para actualización programada
- (Esto es más avanzado, lo podemos ver después)

---

## 💾 Paso 10: Guardar tu Trabajo

1. **Archivo** → **Guardar como**
2. Elige ubicación: `c:\Users\nsaz\proyectos\lgl-dw\powerbi\`
3. Nombre sugerido: `DW_Ventas_LGL.pbix`
4. Clic en **"Guardar"**

---

## 📚 Ejemplos de Medidas DAX Útiles

### Crear Medidas Calculadas:

En el panel **"Campos"**, haz clic derecho en `fact_ventas` → **"Nueva medida"**

#### Total Ventas:
```dax
Total Ventas = SUM(fact_ventas[monto_venta])
```

#### Cantidad Vendida:
```dax
Cantidad Total = SUM(fact_ventas[cantidad])
```

#### Ticket Promedio:
```dax
Ticket Promedio = 
    DIVIDE(
        SUM(fact_ventas[monto_venta]), 
        COUNT(fact_ventas[venta_id])
    )
```

#### Ventas Año Actual:
```dax
Ventas Año Actual = 
    CALCULATE(
        SUM(fact_ventas[monto_venta]),
        dim_tiempo[anio] = YEAR(TODAY())
    )
```

#### Ventas Año Anterior:
```dax
Ventas Año Anterior = 
    CALCULATE(
        SUM(fact_ventas[monto_venta]),
        dim_tiempo[anio] = YEAR(TODAY()) - 1
    )
```

#### Crecimiento vs Año Anterior:
```dax
Crecimiento % = 
    DIVIDE(
        [Ventas Año Actual] - [Ventas Año Anterior],
        [Ventas Año Anterior]
    ) * 100
```

#### Top 10 Clientes (Medida):
```dax
Top 10 Clientes = 
    IF(
        RANKX(
            ALL(dim_cliente[nombre]),
            [Total Ventas],
            ,
            DESC
        ) <= 10,
        [Total Ventas],
        BLANK()
    )
```

---

## 🎨 Recomendaciones de Visualizaciones

### Dashboard Principal (Página 1):

| Visualización          | Datos                                      |
|------------------------|--------------------------------------------|
| **Tarjetas (KPIs)**    | Total Ventas, Cantidad, Ticket Promedio   |
| **Gráfico de Líneas**  | Ventas por Mes (tendencia temporal)       |
| **Gráfico de Barras**  | Top 10 Productos                           |
| **Tabla**              | Top 10 Clientes                            |
| **Mapa**               | Ventas por Departamento                    |

### Análisis de Productos (Página 2):

| Visualización          | Datos                                      |
|------------------------|--------------------------------------------|
| **Matriz**             | Categoría × Mes                            |
| **Treemap**            | Productos por categoría (tamaño = ventas) |
| **Gráfico Circular**   | Ventas por Tipo de Producto               |

### Análisis de Clientes (Página 3):

| Visualización          | Datos                                      |
|------------------------|--------------------------------------------|
| **Tabla Dinámica**     | Cliente, Departamento, Antigüedad, Ventas |
| **Gráfico de Barras**  | Ventas por Segmento de Antigüedad         |
| **Gráfico de Barras**  | Ventas por Condición de Pago              |
| **Gráfico de Barras**  | Ventas por Tipo de Documento              |

### Análisis Geográfico (Página 4):

| Visualización          | Datos                                      |
|------------------------|--------------------------------------------|
| **Mapa de Coropletas** | Ventas por Departamento (dim_ubicacion)   |
| **Tabla**              | Municipio, Departamento, Total Ventas     |
| **Gráfico de Barras**  | Top 10 Municipios por Ventas              |

---

## 🚨 Solución de Problemas Comunes

### Error: "No se puede conectar al servidor"
**Solución:**
- Verifica que SQL Server esté corriendo
- Prueba la conexión desde SSMS primero
- Verifica el nombre del servidor: `localhost` o `localhost\SQLEXPRESS`

### Error: "Credenciales inválidas"
**Solución:**
- Usa Windows Authentication si tu usuario tiene permisos
- Verifica usuario/contraseña de SQL Server
- Asegúrate que el usuario tenga permisos `SELECT` en LGL_DW

### Las relaciones no funcionan
**Solución:**
- Ve a Vista de Modelo
- Verifica que las relaciones estén activas (línea sólida, no punteada)
- Verifica cardinalidad: debe ser `*:1` (muchos a uno)
- Dirección: `Única` (desde dimensión hacia hecho)

### Los filtros no afectan todas las visualizaciones
**Solución:**
- Verifica la dirección de filtro cruzado en las relaciones
- Debe ser `Única` o `Ambas` según necesites
- Para Star Schema, generalmente es `Única`

### Los totales no suman correctamente
**Solución:**
- Verifica que no haya registros duplicados
- Revisa las relaciones activas
- Si usas SCD Type 2, filtra por `es_actual = 1` en dim_cliente, dim_producto, dim_vendedor

---

## 📖 Recursos Adicionales

### Documentación Oficial:
- Power BI Desktop: https://powerbi.microsoft.com/documentation
- DAX Guide: https://dax.guide/
- Community Forums: https://community.powerbi.com/

### Tutoriales en YouTube:
- Busca: "Power BI tutorial español"
- Canal recomendado: "Power BI en Español"

### Datasets de Práctica:
- Tu DW ya tiene datos reales para practicar
- Experimenta creando diferentes tipos de gráficos

---

## ✅ Checklist de Verificación

Antes de crear reportes, verifica:

- [ ] Power BI Desktop instalado y abierto
- [ ] Conexión exitosa a SQL Server (localhost, LGL_DW)
- [ ] Todas las tablas cargadas (1 fact + 7 dims)
- [ ] Relaciones creadas y activas en Vista de Modelo
- [ ] fact_ventas tiene 40,884 registros
- [ ] dim_tiempo tiene 2,192 registros
- [ ] Primera visualización creada con éxito
- [ ] Archivo .pbix guardado en carpeta powerbi/

---

## 🎯 Próximos Pasos

1. **Explora los datos**: Arrastra campos y crea visualizaciones
2. **Crea medidas DAX**: Usa los ejemplos de arriba
3. **Diseña tu dashboard**: Organiza visualizaciones en páginas
4. **Aplica formato**: Colores, temas, títulos
5. **Publica (opcional)**: Sube a Power BI Service para compartir

---

## 💡 Tip Final

**Empieza simple**: 
- Crea 3-4 visualizaciones básicas
- Una tarjeta con Total Ventas
- Un gráfico de barras de ventas por año
- Una tabla de top productos
- Un gráfico de líneas de tendencia mensual

**Luego evoluciona**:
- Agrega interactividad con segmentadores (slicers)
- Crea medidas calculadas con DAX
- Diseña múltiples páginas temáticas
- Aplica formato profesional

---

¿Necesitas ayuda con algún paso específico? ¡Pregunta!
