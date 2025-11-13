"""
Módulo de Funciones Auxiliares para ETL
Funciones comunes para transformación y limpieza de datos
"""
from datetime import datetime, date
from typing import Any, Optional
import pandas as pd
import numpy as np


def clean_string(value: Any) -> Optional[str]:
    """
    Limpiar y normalizar strings
    
    Args:
        value: Valor a limpiar
    
    Returns:
        String limpio o None
    """
    if pd.isna(value) or value is None:
        return None
    
    # Convertir a string y limpiar
    cleaned = str(value).strip()
    
    # Reemplazar múltiples espacios por uno solo
    cleaned = ' '.join(cleaned.split())
    
    # Retornar None si está vacío
    return cleaned if cleaned else None


def safe_float(value: Any, default: float = 0.0) -> float:
    """
    Convertir valor a float de forma segura
    
    Args:
        value: Valor a convertir
        default: Valor por defecto si falla la conversión
    
    Returns:
        Float o valor por defecto
    """
    if pd.isna(value) or value is None:
        return default
    
    try:
        return float(value)
    except (ValueError, TypeError):
        return default


def safe_int(value: Any, default: int = 0) -> int:
    """
    Convertir valor a int de forma segura
    
    Args:
        value: Valor a convertir
        default: Valor por defecto si falla la conversión
    
    Returns:
        Int o valor por defecto
    """
    if pd.isna(value) or value is None:
        return default
    
    try:
        return int(float(value))
    except (ValueError, TypeError):
        return default


def safe_date(value: Any, default: Optional[date] = None) -> Optional[date]:
    """
    Convertir valor a date de forma segura
    
    Args:
        value: Valor a convertir
        default: Valor por defecto si falla la conversión
    
    Returns:
        Date o valor por defecto
    """
    if pd.isna(value) or value is None:
        return default
    
    # Si ya es date
    if isinstance(value, date):
        return value
    
    # Si es datetime
    if isinstance(value, datetime):
        return value.date()
    
    # Si es Timestamp de pandas
    if isinstance(value, pd.Timestamp):
        return value.date()
    
    # Intentar parsear string
    try:
        if isinstance(value, str):
            dt = pd.to_datetime(value)
            return dt.date()
    except:
        pass
    
    return default


def safe_bool(value: Any, default: bool = False) -> bool:
    """
    Convertir valor a bool de forma segura
    
    Args:
        value: Valor a convertir
        default: Valor por defecto si falla la conversión
    
    Returns:
        Bool o valor por defecto
    """
    if pd.isna(value) or value is None:
        return default
    
    # Si ya es bool
    if isinstance(value, bool):
        return value
    
    # Si es número
    if isinstance(value, (int, float)):
        return bool(value)
    
    # Si es string
    if isinstance(value, str):
        value_lower = value.lower().strip()
        if value_lower in ('true', 'yes', 'si', 'sí', '1', 't', 'y', 's'):
            return True
        if value_lower in ('false', 'no', '0', 'f', 'n'):
            return False
    
    return default


def normalize_dataframe_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Normalizar nombres de columnas del DataFrame
    
    Args:
        df: DataFrame a normalizar
    
    Returns:
        DataFrame con columnas normalizadas
    """
    # Convertir nombres a minúsculas y reemplazar espacios por guiones bajos
    df.columns = df.columns.str.lower().str.strip().str.replace(' ', '_')
    return df


def fill_missing_values(df: pd.DataFrame, numeric_fill: Any = 0, string_fill: str = '') -> pd.DataFrame:
    """
    Llenar valores faltantes en DataFrame
    
    Args:
        df: DataFrame a procesar
        numeric_fill: Valor para columnas numéricas
        string_fill: Valor para columnas de texto
    
    Returns:
        DataFrame con valores faltantes llenados
    """
    # Identificar tipos de columnas
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    string_cols = df.select_dtypes(include=['object']).columns
    
    # Llenar valores
    df[numeric_cols] = df[numeric_cols].fillna(numeric_fill)
    df[string_cols] = df[string_cols].fillna(string_fill)
    
    return df


def remove_duplicates(df: pd.DataFrame, subset: list = None, keep: str = 'first') -> pd.DataFrame:
    """
    Eliminar duplicados del DataFrame
    
    Args:
        df: DataFrame a procesar
        subset: Lista de columnas para identificar duplicados
        keep: 'first', 'last' o False
    
    Returns:
        DataFrame sin duplicados
    """
    initial_count = len(df)
    df_clean = df.drop_duplicates(subset=subset, keep=keep)
    removed_count = initial_count - len(df_clean)
    
    if removed_count > 0:
        print(f"Se eliminaron {removed_count} registros duplicados")
    
    return df_clean


def format_decimal(value: float, decimals: int = 2) -> float:
    """
    Formatear decimal a número específico de decimales
    
    Args:
        value: Valor a formatear
        decimals: Número de decimales
    
    Returns:
        Valor formateado
    """
    if pd.isna(value) or value is None:
        return 0.0
    
    try:
        return round(float(value), decimals)
    except:
        return 0.0


def get_timestamp() -> datetime:
    """Obtener timestamp actual"""
    return datetime.now()


def get_date_key(date_value: date) -> int:
    """
    Convertir fecha a formato entero YYYYMMDD
    
    Args:
        date_value: Fecha a convertir
    
    Returns:
        Entero en formato YYYYMMDD
    """
    if not date_value:
        return -1
    
    try:
        if isinstance(date_value, str):
            date_value = pd.to_datetime(date_value).date()
        
        return int(date_value.strftime('%Y%m%d'))
    except:
        return -1


def batch_dataframe(df: pd.DataFrame, batch_size: int = 1000):
    """
    Dividir DataFrame en lotes
    
    Args:
        df: DataFrame a dividir
        batch_size: Tamaño de cada lote
    
    Yields:
        DataFrame de cada lote
    """
    total_rows = len(df)
    for start_idx in range(0, total_rows, batch_size):
        end_idx = min(start_idx + batch_size, total_rows)
        yield df.iloc[start_idx:end_idx]


def compare_dataframes(df1: pd.DataFrame, df2: pd.DataFrame, key_columns: list) -> dict:
    """
    Comparar dos DataFrames e identificar nuevos, modificados y eliminados
    
    Args:
        df1: DataFrame origen (actual)
        df2: DataFrame destino (anterior)
        key_columns: Columnas que identifican registros únicos
    
    Returns:
        Diccionario con 'nuevos', 'modificados', 'eliminados'
    """
    # Crear llaves únicas
    df1['_key'] = df1[key_columns].astype(str).agg('-'.join, axis=1)
    df2['_key'] = df2[key_columns].astype(str).agg('-'.join, axis=1)
    
    # Identificar diferencias
    keys1 = set(df1['_key'])
    keys2 = set(df2['_key'])
    
    nuevos = df1[df1['_key'].isin(keys1 - keys2)].drop('_key', axis=1)
    eliminados = df2[df2['_key'].isin(keys2 - keys1)].drop('_key', axis=1)
    
    # Para modificados, comparar registros con misma llave
    common_keys = keys1.intersection(keys2)
    df1_common = df1[df1['_key'].isin(common_keys)].drop('_key', axis=1)
    df2_common = df2[df2['_key'].isin(common_keys)].drop('_key', axis=1)
    
    # Merge y comparar
    merged = df1_common.merge(
        df2_common, 
        on=key_columns, 
        how='inner', 
        suffixes=('_new', '_old')
    )
    
    # Identificar cambios
    changed_mask = False
    for col in df1_common.columns:
        if col not in key_columns:
            if f"{col}_new" in merged.columns and f"{col}_old" in merged.columns:
                changed_mask |= (merged[f"{col}_new"] != merged[f"{col}_old"])
    
    modificados = merged[changed_mask] if isinstance(changed_mask, pd.Series) else df1_common.iloc[:0]
    
    return {
        'nuevos': nuevos,
        'modificados': modificados,
        'eliminados': eliminados
    }


if __name__ == "__main__":
    # Pruebas de funciones
    print("Pruebas de funciones auxiliares:")
    print(f"clean_string('  Hola   Mundo  ') = '{clean_string('  Hola   Mundo  ')}'")
    print(f"safe_float('123.45') = {safe_float('123.45')}")
    print(f"safe_int('123.45') = {safe_int('123.45')}")
    print(f"safe_bool('True') = {safe_bool('True')}")
    print(f"get_date_key(date(2024, 1, 15)) = {get_date_key(date(2024, 1, 15))}")
