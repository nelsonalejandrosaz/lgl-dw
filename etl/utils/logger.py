"""
Módulo de Logging para ETL
Configura y proporciona logging usando loguru
"""
import os
import sys
from datetime import datetime
from pathlib import Path
from loguru import logger
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()


class ETLLogger:
    """Configuración centralizada de logging para ETL"""
    
    def __init__(self, log_name: str = "etl"):
        self.log_level = os.getenv('LOG_LEVEL', 'INFO')
        self.log_path = Path(os.getenv('LOG_PATH', './logs'))
        self.log_name = log_name
        self.environment = os.getenv('ENVIRONMENT', 'development')
        
        # Crear directorio de logs si no existe
        self.log_path.mkdir(parents=True, exist_ok=True)
        
        # Configurar logger
        self._setup_logger()
    
    def _setup_logger(self):
        """Configurar loguru con múltiples handlers"""
        
        # Remover configuración por defecto
        logger.remove()
        
        # Handler para consola (stdout) - más simple
        logger.add(
            sys.stdout,
            format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <level>{message}</level>",
            level=self.log_level,
            colorize=True
        )
        
        # Handler para archivo general (todos los niveles)
        date_str = datetime.now().strftime("%Y%m%d")
        log_file = self.log_path / f"{self.log_name}_{date_str}.log"
        
        logger.add(
            log_file,
            format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}",
            level="DEBUG",
            rotation="00:00",  # Rotar a medianoche
            retention="30 days",  # Mantener logs 30 días
            compression="zip",  # Comprimir logs antiguos
            encoding="utf-8"
        )
        
        # Handler para errores (archivo separado)
        error_file = self.log_path / f"{self.log_name}_errors_{date_str}.log"
        
        logger.add(
            error_file,
            format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} | {message}",
            level="ERROR",
            rotation="00:00",
            retention="90 days",  # Mantener errores 90 días
            compression="zip",
            encoding="utf-8"
        )
    
    def get_logger(self):
        """Obtener instancia del logger"""
        return logger


# Instancia global del logger
_etl_logger = None


def get_logger(log_name: str = "etl"):
    """
    Obtener logger configurado
    
    Args:
        log_name: Nombre base para los archivos de log
    
    Returns:
        Logger configurado
    """
    global _etl_logger
    if _etl_logger is None:
        _etl_logger = ETLLogger(log_name)
    return _etl_logger.get_logger()


def log_etl_start(process_name: str):
    """Log de inicio de proceso ETL"""
    log = get_logger()
    log.info("=" * 80)
    log.info(f"INICIO DEL PROCESO: {process_name}")
    log.info(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log.info("=" * 80)


def log_etl_end(process_name: str, success: bool = True, records: int = 0):
    """Log de fin de proceso ETL"""
    log = get_logger()
    status = "EXITOSO" if success else "FALLIDO"
    log.info("-" * 80)
    log.info(f"FIN DEL PROCESO: {process_name} - {status}")
    if records > 0:
        log.info(f"Registros procesados: {records:,}")
    log.info(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    log.info("=" * 80)


def log_step(step_name: str, details: str = ""):
    """Log de paso individual"""
    log = get_logger()
    message = f"> {step_name}"
    if details:
        message += f" - {details}"
    log.info(message)


def log_error(error_message: str, exception: Exception = None):
    """Log de error con excepción opcional"""
    log = get_logger()
    log.error(f"[X] ERROR: {error_message}")
    if exception:
        log.exception(exception)


def log_warning(warning_message: str):
    """Log de advertencia"""
    log = get_logger()
    log.warning(f"[!] ADVERTENCIA: {warning_message}")


def log_success(success_message: str):
    """Log de éxito"""
    log = get_logger()
    log.success(f"[OK] {success_message}")


if __name__ == "__main__":
    # Prueba del logger
    log_etl_start("Prueba de Logger")
    log_step("Paso 1", "Conectando a base de datos")
    log_success("Conexión exitosa")
    log_step("Paso 2", "Extrayendo datos")
    log_warning("Algunos registros tienen valores nulos")
    log_step("Paso 3", "Transformando datos")
    try:
        raise ValueError("Error de ejemplo")
    except Exception as e:
        log_error("Error en transformación", e)
    log_etl_end("Prueba de Logger", success=False)
