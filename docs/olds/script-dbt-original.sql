--
-- Table structure for table `abonos`
--

CREATE TABLE `abonos` (
  `id` int(10) UNSIGNED NOT NULL,
  `venta_id` int(10) UNSIGNED NOT NULL,
  `cliente_id` int(10) UNSIGNED NOT NULL,
  `recibo_caja` int(11) DEFAULT NULL,
  `fecha` date NOT NULL,
  `detalle` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cantidad` double(10,2) NOT NULL,
  `forma_pago_id` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `tipo_abono_id` int(10) UNSIGNED NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `categorias`
--

CREATE TABLE `categorias` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cierre_muensual`
--

CREATE TABLE `cierre_muensual` (
  `id` int(10) UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `detalle` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `inventario_inicial` decimal(16,2) NOT NULL,
  `inventario_final` decimal(16,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `clientes`
--

CREATE TABLE `clientes` (
  `id` int(10) UNSIGNED NOT NULL,
  `municipio_id` int(11) NOT NULL DEFAULT 1,
  `nombre` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre_alternativo` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefono_1` varchar(25) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefono_2` varchar(25) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `direccion` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `correo` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vendedor_id` int(10) UNSIGNED DEFAULT NULL,
  `nit` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nrc` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `giro` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre_contacto` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `saldo` double(12,4) NOT NULL DEFAULT 0.0000,
  `retencion` tinyint(1) NOT NULL DEFAULT 0,
  `cuenta_contable` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ajustes`
--

CREATE TABLE `ajustes` (
  `id` int(10) UNSIGNED NOT NULL,
  `tipo_ajuste_id` int(10) UNSIGNED NOT NULL,
  `detalle` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `fecha` date NOT NULL,
  `realizado_id` int(10) UNSIGNED NOT NULL,
  `cantidad_anterior` double(12,4) NOT NULL,
  `valor_unitario_anterior` double(12,4) NOT NULL,
  `cantidad_ajuste` double(12,4) DEFAULT NULL,
  `valor_unitario_ajuste` double(12,4) DEFAULT NULL,
  `diferencia_ajuste` double(12,4) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `componentes`
--

CREATE TABLE `componentes` (
  `id` int(10) UNSIGNED NOT NULL,
  `formula_id` int(10) UNSIGNED NOT NULL,
  `producto_id` int(10) UNSIGNED NOT NULL,
  `porcentaje` double(16,4) DEFAULT NULL,
  `cantidad` double(16,4) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `compras`
--

CREATE TABLE `compras` (
  `id` int(10) UNSIGNED NOT NULL,
  `proveedor_id` int(10) UNSIGNED NOT NULL,
  `numero` int(10) UNSIGNED NOT NULL,
  `detalle` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha` date NOT NULL,
  `compra_total` double(12,4) DEFAULT NULL,
  `compra_total_con_impuestos` double(12,4) DEFAULT NULL,
  `ingresado_id` int(10) UNSIGNED DEFAULT NULL,
  `bodega_id` int(10) UNSIGNED DEFAULT NULL,
  `ruta_archivo` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'sindocumento.jpg',
  `condicion_pago_id` int(10) UNSIGNED NOT NULL,
  `estado_compra_id` int(11) NOT NULL DEFAULT 1,
  `saldo` double(12,4) NOT NULL DEFAULT 0.0000,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `condiciones_pago`
--

CREATE TABLE `condiciones_pago` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `configuraciones`
--

CREATE TABLE `configuraciones` (
  `id` int(10) UNSIGNED NOT NULL,
  `iva` double(8,2) NOT NULL,
  `comisiones` double(8,2) NOT NULL,
  `color_tema` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `numero_factura` int(11) DEFAULT NULL,
  `numero_credito` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `conversion_unidades_medidas`
--

CREATE TABLE `conversion_unidades_medidas` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `unidad_medida_origen_id` int(10) UNSIGNED NOT NULL,
  `unidad_medida_destino_id` int(10) UNSIGNED NOT NULL,
  `factor` double(12,4) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `departamentos`
--

CREATE TABLE `departamentos` (
  `id` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `isocode` varchar(6) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zonesv_id` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `detalle_exportacions`
--

CREATE TABLE `detalle_exportacions` (
  `id` int(10) UNSIGNED NOT NULL,
  `exportacion_sac_id` int(10) UNSIGNED NOT NULL,
  `fecha` date NOT NULL,
  `cargo` decimal(14,2) NOT NULL,
  `abono` decimal(14,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `detalle_otras_ventas`
--

CREATE TABLE `detalle_otras_ventas` (
  `id` int(10) UNSIGNED NOT NULL,
  `venta_id` int(10) UNSIGNED NOT NULL,
  `detalle` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `cantidad` double(12,4) NOT NULL,
  `precio_unitario` double(12,4) NOT NULL,
  `venta_exenta` double(12,4) NOT NULL,
  `venta_gravada` double(12,4) NOT NULL,
  `venta_total` double(12,4) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `detalle_producciones`
--

CREATE TABLE `detalle_producciones` (
  `id` int(10) UNSIGNED NOT NULL,
  `bodega_id` int(10) UNSIGNED NOT NULL,
  `produccion_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `entradas`
--

CREATE TABLE `entradas` (
  `id` int(10) UNSIGNED NOT NULL,
  `compra_id` int(10) UNSIGNED DEFAULT NULL,
  `produccion_id` int(10) UNSIGNED DEFAULT NULL,
  `unidad_medida_id` int(10) UNSIGNED NOT NULL,
  `cantidad` double(12,4) NOT NULL,
  `costo_unitario` double(12,4) NOT NULL,
  `costo_total` double(12,4) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `estados_compra`
--

CREATE TABLE `estados_compra` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `estados_orden_pedido`
--

CREATE TABLE `estados_orden_pedido` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `estados_ventas`
--

CREATE TABLE `estados_ventas` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `exportacion_sacs`
--

CREATE TABLE `exportacion_sacs` (
  `id` int(10) UNSIGNED NOT NULL,
  `id_cuenta` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `concepto` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `formulas`
--

CREATE TABLE `formulas` (
  `id` int(10) UNSIGNED NOT NULL,
  `producto_id` int(11) NOT NULL,
  `cantidad_formula` double(8,2) DEFAULT NULL,
  `fecha` date NOT NULL,
  `ingresado_id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `version` double(8,2) NOT NULL DEFAULT 1.00,
  `activa` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `movimientos`
--

CREATE TABLE `movimientos` (
  `id` int(10) UNSIGNED NOT NULL,
  `producto_id` int(10) UNSIGNED NOT NULL,
  `tipo_movimiento_id` int(10) UNSIGNED NOT NULL,
  `entrada_id` int(10) UNSIGNED DEFAULT NULL,
  `salida_id` int(10) UNSIGNED DEFAULT NULL,
  `ajuste_id` int(10) UNSIGNED DEFAULT NULL,
  `fecha` date NOT NULL,
  `detalle` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cantidad` double(12,4) NOT NULL,
  `costo_unitario` double(12,4) NOT NULL,
  `costo_total` double(12,4) NOT NULL,
  `cantidad_existencia` double(12,4) DEFAULT NULL,
  `costo_unitario_existencia` double(12,4) DEFAULT NULL,
  `costo_total_existencia` double(12,4) DEFAULT NULL,
  `fecha_procesado` datetime DEFAULT NULL,
  `procesado` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `municipios`
--

CREATE TABLE `municipios` (
  `id` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `departamento_id` int(11) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `orden_pedidos`
--

CREATE TABLE `orden_pedidos` (
  `id` int(10) UNSIGNED NOT NULL,
  `cliente_id` int(10) UNSIGNED NOT NULL,
  `tipo_documento_id` int(10) UNSIGNED DEFAULT NULL,
  `numero` int(11) NOT NULL,
  `detalle` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha` date NOT NULL,
  `fecha_procesado` datetime DEFAULT NULL,
  `fecha_entrega` date DEFAULT NULL,
  `condicion_pago_id` int(10) UNSIGNED DEFAULT NULL,
  `vendedor_id` int(10) UNSIGNED NOT NULL,
  `bodega_id` int(10) UNSIGNED DEFAULT NULL,
  `ventas_exentas` double(12,4) DEFAULT 0.0000,
  `ventas_gravadas` double(12,4) DEFAULT 0.0000,
  `venta_total` double(12,4) DEFAULT NULL,
  `ruta_archivo` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'sindocumento.jpg',
  `estado_id` int(11) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `tipo_orden_pedido_id` int(10) UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `precios`
--

CREATE TABLE `precios` (
  `id` int(10) UNSIGNED NOT NULL,
  `producto_id` int(10) UNSIGNED NOT NULL,
  `unidad_medida_id` int(10) UNSIGNED NOT NULL,
  `presentacion` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre_factura` varchar(25) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `precio` double(12,4) NOT NULL,
  `factor` double(12,4) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `producciones`
--

CREATE TABLE `producciones` (
  `id` int(10) UNSIGNED NOT NULL,
  `bodega_id` int(10) UNSIGNED NOT NULL,
  `formula_id` int(10) UNSIGNED NOT NULL,
  `producto_id` int(10) UNSIGNED DEFAULT NULL,
  `cantidad` double(16,4) NOT NULL,
  `fecha` date NOT NULL,
  `lote` int(11) DEFAULT NULL,
  `fecha_vencimiento` date DEFAULT NULL,
  `detalle` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `procesado` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `productos`
--

CREATE TABLE `productos` (
  `id` int(10) UNSIGNED NOT NULL,
  `unidad_medida_id` int(10) UNSIGNED NOT NULL,
  `tipo_producto_id` int(10) UNSIGNED NOT NULL,
  `categoria_id` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre_alternativo` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `codigo` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `existencia_min` double(12,4) DEFAULT 0.0000,
  `existencia_max` double(12,4) DEFAULT 100.0000,
  `cantidad_existencia` double(12,4) NOT NULL DEFAULT 0.0000,
  `cantidad_reserva` double(12,4) NOT NULL DEFAULT 0.0000,
  `costo` double(8,2) NOT NULL DEFAULT 0.00,
  `unidad_factor` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `factor_volumen` double(12,4) NOT NULL DEFAULT 0.0000,
  `producto_activo` tinyint(1) NOT NULL DEFAULT 1,
  `formula_activa` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `proveedores`
--

CREATE TABLE `proveedores` (
  `id` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telefono_1` varchar(25) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefono_2` varchar(25) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `direccion` varchar(140) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nit` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nrc` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nombre_contacto` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `saldo` double(12,4) NOT NULL DEFAULT 0.0000,
  `nacional` tinyint(1) NOT NULL DEFAULT 1,
  `percepcion` tinyint(1) NOT NULL DEFAULT 0,
  `cuenta_contable` int(11) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `roles`
--

CREATE TABLE `roles` (
  `id` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(25) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `salidas`
--

CREATE TABLE `salidas` (
  `id` int(10) UNSIGNED NOT NULL,
  `orden_pedido_id` int(10) UNSIGNED DEFAULT NULL,
  `produccion_id` int(10) UNSIGNED DEFAULT NULL,
  `unidad_medida_id` int(10) UNSIGNED NOT NULL,
  `precio_id` int(10) UNSIGNED DEFAULT NULL,
  `descripcion_presentacion` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cantidad` double(12,4) NOT NULL,
  `precio_unitario` double(12,4) NOT NULL,
  `venta_exenta` double(12,4) NOT NULL,
  `venta_gravada` double(12,4) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tipo_abonos`
--

CREATE TABLE `tipo_abonos` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `tipo_ajustes`
--

CREATE TABLE `tipo_ajustes` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `tipo_documentos`
--

CREATE TABLE `tipo_documentos` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `tipo_movimientos`
--

CREATE TABLE `tipo_movimientos` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --------------------------------------------------------

--
-- Table structure for table `tipo_orden_pedido`
--

CREATE TABLE `tipo_orden_pedido` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tipo_productos`
--

CREATE TABLE `tipo_productos` (
  `id` int(10) UNSIGNED NOT NULL,
  `codigo` varchar(2) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `unidad_medidas`
--

CREATE TABLE `unidad_medidas` (
  `id` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `abreviatura` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tipo` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `nombre` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `username` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `apellido` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefono` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ruta_imagen` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'default.png',
  `rol_id` int(11) NOT NULL,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ventas`
--

CREATE TABLE `ventas` (
  `id` int(10) UNSIGNED NOT NULL,
  `tipo_documento_id` int(10) UNSIGNED NOT NULL,
  `orden_pedido_id` int(10) UNSIGNED DEFAULT NULL,
  `estado_venta_id` int(10) UNSIGNED NOT NULL,
  `cliente_id` int(10) UNSIGNED DEFAULT NULL,
  `vendedor_id` int(10) UNSIGNED DEFAULT NULL,
  `condicion_pago_id` int(10) UNSIGNED DEFAULT NULL,
  `numero` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fecha` date NOT NULL,
  `venta_total` double(12,4) DEFAULT NULL,
  `venta_total_con_impuestos` double(12,4) DEFAULT NULL,
  `suma` double(12,4) DEFAULT NULL,
  `flete` double(12,4) DEFAULT NULL,
  `ruta_archivo` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'sindocumento.jpg',
  `saldo` double(12,4) NOT NULL DEFAULT 0.0000,
  `fecha_anulado` date DEFAULT NULL,
  `fecha_liquidado` date DEFAULT NULL,
  `comision` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;