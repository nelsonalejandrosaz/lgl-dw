"""
Módulo de Conexión a Bases de Datos
Proporciona clases para conectar a MariaDB (origen) y SQL Server (destino)
"""
import os
from typing import Optional
import pymysql
import pyodbc
from dotenv import load_dotenv
from contextlib import contextmanager

# Cargar variables de entorno
load_dotenv()


class DatabaseConnection:
    """Clase base para conexiones a bases de datos"""
    
    def __init__(self):
        self.connection = None
    
    def __enter__(self):
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.close()
    
    def close(self):
        """Cerrar conexiones"""
        if self.connection:
            self.connection.close()


class SourceDatabase(DatabaseConnection):
    """Conexión a la base de datos origen (MariaDB/MySQL)"""
    
    def __init__(self):
        super().__init__()
        self.host = os.getenv('SOURCE_DB_HOST', 'localhost')
        self.port = int(os.getenv('SOURCE_DB_PORT', 3306))
        self.database = os.getenv('SOURCE_DB_NAME', 'lgl_transaccional')
        self.user = os.getenv('SOURCE_DB_USER', 'root')
        self.password = os.getenv('SOURCE_DB_PASSWORD', '')
    
    def get_connection(self):
        """Obtener conexión pymysql"""
        if not self.connection:
            self.connection = pymysql.connect(
                host=self.host,
                port=self.port,
                user=self.user,
                password=self.password,
                database=self.database,
                charset='utf8mb4',
                cursorclass=pymysql.cursors.DictCursor
            )
        return self.connection
    
    def test_connection(self) -> bool:
        """Probar conexión a la base de datos"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            result = cursor.fetchone()
            cursor.close()
            return True
        except Exception as e:
            print(f"Error conectando a MariaDB: {e}")
            return False


class TargetDatabase(DatabaseConnection):
    """Conexión a la base de datos destino (SQL Server)"""
    
    def __init__(self):
        super().__init__()
        self.host = os.getenv('TARGET_DB_HOST', 'localhost')
        self.port = int(os.getenv('TARGET_DB_PORT', 1433))
        self.database = os.getenv('TARGET_DB_NAME', 'LGL_DW')
        self.user = os.getenv('TARGET_DB_USER', 'sa')
        self.password = os.getenv('TARGET_DB_PASSWORD', '')
    
    def get_connection(self):
        """Obtener conexión pyodbc"""
        if not self.connection:
            # Verificar si usar autenticación de Windows
            if not self.user or not self.password:
                connection_string = (
                    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                    f"SERVER={self.host},{self.port};"
                    f"DATABASE={self.database};"
                    f"Trusted_Connection=yes;"
                    f"TrustServerCertificate=yes;"
                )
            else:
                connection_string = (
                    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                    f"SERVER={self.host},{self.port};"
                    f"DATABASE={self.database};"
                    f"UID={self.user};"
                    f"PWD={self.password};"
                    f"TrustServerCertificate=yes;"
                )
            
            self.connection = pyodbc.connect(connection_string, timeout=10)
        return self.connection
    
    def test_connection(self) -> bool:
        """Probar conexión a la base de datos"""
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            result = cursor.fetchone()[0]
            cursor.close()
            return result == 1
        except Exception as e:
            print(f"Error conectando a SQL Server: {e}")
            return False
    
    def execute_stored_procedure(self, sp_name: str, params: dict = None):
        """
        Ejecutar un stored procedure
        
        Args:
            sp_name: Nombre del stored procedure
            params: Diccionario con los parámetros
        """
        try:
            conn = self.get_connection()
            cursor = conn.cursor()
            
            if params:
                param_list = ', '.join([f"@{key} = ?" for key in params.keys()])
                query = f"EXEC {sp_name} {param_list}"
                cursor.execute(query, list(params.values()))
            else:
                cursor.execute(f"EXEC {sp_name}")
            
            conn.commit()
            cursor.close()
            return True
        except Exception as e:
            print(f"Error ejecutando SP {sp_name}: {e}")
            return False


@contextmanager
def get_source_connection():
    """Context manager para conexión origen"""
    db = SourceDatabase()
    try:
        yield db
    finally:
        db.close()


@contextmanager
def get_target_connection():
    """Context manager para conexión destino"""
    db = TargetDatabase()
    try:
        yield db
    finally:
        db.close()


def test_connections():
    """Probar ambas conexiones"""
    print("Probando conexiones...")
    
    with get_source_connection() as source_db:
        if source_db.test_connection():
            print("✓ Conexión a MariaDB exitosa")
        else:
            print("✗ Error en conexión a MariaDB")
    
    with get_target_connection() as target_db:
        if target_db.test_connection():
            print("✓ Conexión a SQL Server exitosa")
        else:
            print("✗ Error en conexión a SQL Server")


if __name__ == "__main__":
    test_connections()
