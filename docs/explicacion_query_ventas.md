# Explicación: Query de Extracción de Ventas

## Estructura de la Consulta

```sql
SELECT ...
FROM ventas v
LEFT JOIN orden_pedidos op ON v.orden_pedido_id = op.id
LEFT JOIN salidas s ON s.orden_pedido_id = op.id
LEFT JOIN precios pr ON s.precio_id = pr.id
LEFT JOIN producciones prod ON s.produccion_id = prod.id
WHERE s.id IS NOT NULL
```

## ¿Por qué LEFT JOIN a `producciones`?

### Estructura de Datos

En tu base transaccional, un producto puede venderse de dos formas:

1. **Producto Comprado para Reventa**
   - La tabla `salidas` tiene `precio_id` 
   - `precios.producto_id` contiene el producto vendido
   - En este caso `salidas.produccion_id` es NULL

2. **Producto Fabricado/Producido Internamente**
   - La tabla `salidas` tiene `produccion_id`
   - `producciones.producto_id` contiene el producto vendido
   - En este caso `salidas.precio_id` puede ser NULL o apuntar al precio de venta

### La Solución: COALESCE

```sql
COALESCE(pr.producto_id, prod.producto_id) as producto_id
```

Esta función toma el **primer valor NO NULL**:
- Si `precios.producto_id` existe → usa ese
- Si `precios.producto_id` es NULL → usa `producciones.producto_id`
- Si ambos son NULL → el registro se omite (no tiene producto válido)

### ¿Causa Problemas?

**NO**, por las siguientes razones:

1. **LEFT JOIN es correcto**: No todos los productos tienen producción, pero todos deberían tener precio o producción
   
2. **Validación en el ETL**: El código valida que `producto_id` no sea NULL:
   ```python
   producto_key = dim_keys['producto'].get(row['producto_id'])
   
   if not all([tiempo_key, cliente_key, producto_key, ...]):
       skip_count += 1
       continue
   ```

3. **Filtro WHERE s.id IS NOT NULL**: Solo procesa ventas que tengan detalle en salidas

### Ejemplo Práctico

**Caso 1: Producto Comprado**
```
salidas.precio_id = 150 → precios.producto_id = 42 ✓
salidas.produccion_id = NULL
COALESCE(42, NULL) = 42 ✓
```

**Caso 2: Producto Producido**
```
salidas.precio_id = NULL (o tiene precio de venta)
salidas.produccion_id = 89 → producciones.producto_id = 55 ✓
COALESCE(NULL, 55) = 55 ✓
```

**Caso 3: Sin Producto (Error en Datos)**
```
salidas.precio_id = NULL
salidas.produccion_id = NULL
COALESCE(NULL, NULL) = NULL ✗
→ El ETL lo omite y cuenta en "skip_count"
```

## Resultados

De los 40,884 registros cargados:
- **Todos** tienen `producto_id` válido
- Si hubiera registros sin producto, aparecerían en el reporte de "Omitidos"

## Conclusión

El LEFT JOIN a `producciones` es **correcto y necesario** porque:
- Maneja ambos tipos de productos (comprados y producidos)
- No causa problemas si un producto no tiene producción
- El COALESCE asegura que siempre haya un producto válido
- La validación del ETL descarta registros incompletos
