"""
Script Orquestador: Carga de Todas las Dimensiones
Ejecuta todos los procesos ETL de dimensiones en el orden correcto
"""
import sys
from pathlib import Path
from datetime import datetime
import argparse

# Agregar el directorio raíz al path
sys.path.append(str(Path(__file__).parent.parent))

from etl.utils.logger import get_logger, log_etl_start, log_etl_end, log_step, log_error, log_success
from etl.load.load_dim_tiempo import load_dim_tiempo
from etl.load.load_dim_static import (
    load_dim_tipo_documento,
    load_dim_condicion_pago,
    load_dim_estado_venta,
    load_dim_ubicacion
)
from etl.load.load_dim_cliente import load_dim_cliente
from etl.load.load_dim_producto import load_dim_producto
from etl.load.load_dim_vendedor import load_dim_vendedor


def main(modo: str = 'full', skip_tiempo: bool = False):
    """
    Ejecutar carga completa de dimensiones
    
    Args:
        modo: 'full' o 'incremental'
        skip_tiempo: Si True, omite la carga de dim_tiempo
    """
    log = get_logger("main_dimensions")
    log_etl_start(f"CARGA COMPLETA DE DIMENSIONES - Modo: {modo.upper()}")
    
    start_time = datetime.now()
    resultados = {}
    
    try:
        # FASE 1: Dimensión Tiempo (calendario)
        if not skip_tiempo:
            log_step("=" * 80)
            log_step("FASE 1: Dimensión Tiempo")
            log_step("=" * 80)
            resultados['dim_tiempo'] = load_dim_tiempo()
        else:
            log_step("Omitiendo carga de dim_tiempo")
            resultados['dim_tiempo'] = True
        
        # FASE 2: Dimensiones Estáticas (lookup tables)
        log_step("=" * 80)
        log_step("FASE 2: Dimensiones Estáticas")
        log_step("=" * 80)
        
        resultados['dim_tipo_documento'] = load_dim_tipo_documento()
        resultados['dim_condicion_pago'] = load_dim_condicion_pago()
        resultados['dim_estado_venta'] = load_dim_estado_venta()
        resultados['dim_ubicacion'] = load_dim_ubicacion()
        
        # FASE 3: Dimensiones con SCD Type 2
        log_step("=" * 80)
        log_step("FASE 3: Dimensiones con SCD Type 2")
        log_step("=" * 80)
        
        resultados['dim_cliente'] = load_dim_cliente(modo)
        resultados['dim_producto'] = load_dim_producto(modo)
        resultados['dim_vendedor'] = load_dim_vendedor(modo)
        
        # RESUMEN FINAL
        log_step("=" * 80)
        log_step("RESUMEN DE EJECUCIÓN")
        log_step("=" * 80)
        
        exitosas = sum(1 for v in resultados.values() if v)
        fallidas = sum(1 for v in resultados.values() if not v)
        total = len(resultados)
        
        for dimension, success in resultados.items():
            status = "✓ EXITOSO" if success else "✗ FALLIDO"
            log_step(f"{status:12} | {dimension}")
        
        log_step("-" * 80)
        log_step(f"Total dimensiones: {total}")
        log_step(f"Exitosas: {exitosas}")
        log_step(f"Fallidas: {fallidas}")
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        log_step(f"Tiempo de ejecución: {duration:.2f} segundos")
        
        all_success = all(resultados.values())
        
        if all_success:
            log_success("TODAS LAS DIMENSIONES SE CARGARON EXITOSAMENTE")
        else:
            log_error(f"SE ENCONTRARON {fallidas} ERROR(ES) EN LA CARGA DE DIMENSIONES")
        
        log_etl_end("CARGA COMPLETA DE DIMENSIONES", success=all_success)
        
        return all_success
        
    except Exception as e:
        log_error("Error crítico en la ejecución del proceso", e)
        log_etl_end("CARGA COMPLETA DE DIMENSIONES", success=False)
        return False


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description='Orquestador de carga de dimensiones del Data Warehouse',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  # Carga completa (todas las dimensiones, modo full)
  python main_load_dimensions.py
  
  # Carga incremental (solo cambios)
  python main_load_dimensions.py --modo incremental
  
  # Carga completa sin dim_tiempo
  python main_load_dimensions.py --skip-tiempo
  
  # Carga incremental sin dim_tiempo
  python main_load_dimensions.py --modo incremental --skip-tiempo
        """
    )
    
    parser.add_argument(
        '--modo',
        type=str,
        choices=['full', 'incremental'],
        default='full',
        help='Modo de carga: full (completa) o incremental (solo cambios)'
    )
    
    parser.add_argument(
        '--skip-tiempo',
        action='store_true',
        help='Omitir carga de dim_tiempo (útil si ya está poblada)'
    )
    
    args = parser.parse_args()
    
    print("\n" + "=" * 80)
    print("DATA WAREHOUSE - CARGA DE DIMENSIONES")
    print("=" * 80)
    print(f"Modo: {args.modo.upper()}")
    print(f"Incluir dim_tiempo: {'No' if args.skip_tiempo else 'Sí'}")
    print("=" * 80 + "\n")
    
    success = main(modo=args.modo, skip_tiempo=args.skip_tiempo)
    
    sys.exit(0 if success else 1)
