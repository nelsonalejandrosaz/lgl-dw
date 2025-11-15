# Tests - Verificación y Pruebas

Scripts para **probar y validar** el correcto funcionamiento del Data Warehouse.

## 🧪 Scripts de Testing

### SCD Type 2 Testing

#### `test_scd2.py` ⭐
**Verificación de historiales SCD Type 2**

```bash
# Ver estadísticas generales
python tests/test_scd2.py --dimension cliente stats
python tests/test_scd2.py --dimension producto stats
python tests/test_scd2.py --dimension vendedor stats

# Ver todas las versiones actuales
python tests/test_scd2.py --dimension cliente

# Ver historial de un cliente específico
python tests/test_scd2.py --dimension cliente --id 1
```

#### `guia_prueba_scd2.py`
**Guía para pruebas manuales de SCD Type 2**

```bash
# Ver instrucciones
python tests/guia_prueba_scd2.py

# Ver registros de ejemplo para modificar
python tests/guia_prueba_scd2.py --list
```

#### `prueba_automatica_scd2.py`
**Test automático que modifica datos y verifica versionamiento**

```bash
# Ejecutar test completo (modifica, carga, verifica, restaura)
python tests/prueba_automatica_scd2.py
```

⚠️ **Advertencia:** Este script modifica temporalmente datos en MariaDB.

---

### Connection Testing

#### `test_sqlserver.py`
**Verifica conexión a SQL Server**

```bash
python tests/test_sqlserver.py
```

---

## 🎯 Cuándo Usar Cada Script

| Situación | Script |
|-----------|--------|
| Verificar que SCD Type 2 funciona correctamente | `test_scd2.py --dimension X stats` |
| Ver historial de cambios de un cliente/producto | `test_scd2.py --dimension X --id N` |
| Probar manualmente SCD Type 2 (primera vez) | `guia_prueba_scd2.py` |
| Test automatizado completo | `prueba_automatica_scd2.py` |
| Verificar conexión a SQL Server | `test_sqlserver.py` |

---

## ✅ Tests Recomendados Post-Deployment

Después de cada carga incremental:

```bash
# 1. Verificar dimensiones SCD Type 2
python tests/test_scd2.py --dimension cliente stats
python tests/test_scd2.py --dimension producto stats
python tests/test_scd2.py --dimension vendedor stats

# 2. Verificar tabla de hechos
python ver_fact_ventas.py
```

---

## 📊 Ejemplo de Salida

```
python tests/test_scd2.py --dimension cliente stats

=== ESTADÍSTICAS: dim_cliente ===
Total de registros: 1,148
Registros actuales (es_actual=1): 1,146
Registros históricos (es_actual=0): 2
Clientes únicos: 1,146
Clientes con historial: 1
```
