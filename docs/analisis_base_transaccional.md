## Observaciones
- Detalle de ventas se encuentra en tabla `salidas`
- La relacion de ventas pasa primero por la tabla `orden_pedidos` antes de llegar a `salidas`
- La cantidad vendida se encuentra en el campo `salidas.cantidad` 
- La tabla `movimientos` también registra entradas y salidas, pero para el análisis de ventas solo se consideran las salidas registradas en `salidas`
- Dentro de `salidas` se encuentran los campos `precio_unitario` y `venta_gravada` que son relevantes para el análisis de ventas, no hay un campo impuesto en esta tabla.
- Los impuestos unicamente se podrían calcular a partir de la tabla `ventas`, ya que tiene los campos `venta_total` y `venta_total_con_impuestos`, pero esta tabla no tiene el detalle por producto necesario para la tabla de hechos. 
- No se tomará en cuenta el campo `flete` para este análisis, ya que no es relevante para las métricas de ventas.


## 
Para la tabla de hechos `fact_ventas`, los campos se pueden mapear de la siguiente manera:

| Campo en `fact_ventas`       | Fuente en BD Transaccional          | Descripción                                      |
|------------------------------|------------------------------------|--------------------------------------------------|
| cantidad_vendida             | salidas.cantidad                   | Cantidad de productos vendidos                    |
| precio_unitario              | salidas.precio_unitario            | Precio unitario del producto                      |
| venta_exenta                 | N/A                                | No aplica en este contexto                        |
| venta_gravada                | salidas.venta_gravada              | Monto de la venta gravada                         |
| venta_total    | salidas.venta_gravada * 1.13 | Total de la venta incluyendo impuestos            |
| iva                | salidas.venta_gravada * 0.13 | Cálculo del IVA (13% sobre venta gravada)        |
| venta_total_con_impuestos    | salidas.venta_gravada * 1.13 | Total de la venta incluyendo impuestos            |
| flete                      | N/A                                | No aplica en este contexto                        |



