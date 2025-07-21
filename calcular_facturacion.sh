#!/bin/bash

# Script para calcular facturación
# Autor: DevelPudu (https://github.com/develpudu)
# Fecha: 2025-07-17

# Configuración base
SALARIO_MENSUAL=2200
HORAS_SEMANALES=40
DIAS_LABORALES=5
HORAS_POR_DIA=8
SEMANAS_POR_MES=4
MONEDA="U\$S"

# Función para calcular días en un mes específico
calcular_dias_mes() {
    local mes_anio="$1"
    local mes=""
    local anio=""

    if [[ "$mes_anio" =~ ^[0-9]{4}-[0-9]{1,2}$ ]]; then
        # Formato YYYY-MM
        anio=$(echo "$mes_anio" | cut -d'-' -f1)
        mes=$(echo "$mes_anio" | cut -d'-' -f2)
    elif [[ "$mes_anio" =~ ^[0-9]{1,2}$ ]]; then
        # Solo mes, usar año actual
        anio=$(date +%Y)
        mes="$mes_anio"
    else
        echo "0"
        return
    fi

    # Remover ceros a la izquierda del mes
    mes=$((10#$mes))

    # Validar mes
    if [ "$mes" -lt 1 ] || [ "$mes" -gt 12 ]; then
        echo "0"
        return
    fi

    # Calcular días del mes
    case $mes in
        1|3|5|7|8|10|12) echo "31" ;;
        4|6|9|11) echo "30" ;;
        2)
            # Febrero - verificar año bisiesto
            if [ $((anio % 4)) -eq 0 ] && ([ $((anio % 100)) -ne 0 ] || [ $((anio % 400)) -eq 0 ]); then
                echo "29"
            else
                echo "28"
            fi
            ;;
    esac
}

# Cálculos de tarifas
HORAS_MENSUALES=$((HORAS_SEMANALES * SEMANAS_POR_MES))
TARIFA_HORARIA=$(echo "scale=2; $SALARIO_MENSUAL / $HORAS_MENSUALES" | bc)
TARIFA_DIARIA=$(echo "scale=2; $TARIFA_HORARIA * $HORAS_POR_DIA" | bc)
TARIFA_SEMANAL=$(echo "scale=2; $TARIFA_HORARIA * $HORAS_SEMANALES" | bc)

# Función para mostrar ayuda
mostrar_ayuda() {
    echo "=== CALCULADORA DE FACTURACIÓN ==="
    echo ""
    echo "Uso: $0 [OPCIONES] [--moneda MONEDA]"
    echo ""
    echo "Opciones (se pueden combinar):"
    echo "  -h, --horas CANTIDAD     Agregar horas trabajadas"
    echo "  -d, --dias CANTIDAD      Agregar días trabajados"
    echo "  -s, --semanas CANTIDAD   Agregar semanas trabajadas"
    echo "  -m, --meses MES          Agregar mes específico (MM o YYYY-MM)"
    echo "  --tarifas                Mostrar tabla de tarifas"
    echo "  --moneda MONEDA          Establecer moneda (por defecto: U\$S)"
    echo "  --help                   Mostrar esta ayuda"
    echo ""
    echo "Formatos de mes:"
    echo "  MM                       Mes del año actual (ej: 02 para febrero)"
    echo "  YYYY-MM                  Mes de año específico (ej: 2024-02)"
    echo ""
    echo "Ejemplos simples:"
    echo "  $0 -h 120                # Calcular por 120 horas"
    echo "  $0 -d 15                 # Calcular por 15 días"
    echo "  $0 -s 2                  # Calcular por 2 semanas"
    echo "  $0 -m 02                 # Febrero del año actual"
    echo "  $0 -m 2024-02            # Febrero 2024 (28 días)"
    echo "  $0 -m 2024-01            # Enero 2024 (31 días)"
    echo ""
    echo "Ejemplos combinados:"
    echo "  $0 -m 01 -d 5            # Enero + 5 días adicionales"
    echo "  $0 -s 2 -d 3 -h 4        # 2 semanas + 3 días + 4 horas"
    echo "  $0 -m 2024-02 -s 1       # Febrero 2024 + 1 semana"
    echo "  $0 -d 15 --moneda EUR    # 15 días en euros"
    echo ""
}

# Función para mostrar tarifas
mostrar_tarifas() {
    echo "=== TABLA DE TARIFAS ==="
    echo ""
    echo "Configuración base:"
    echo "  Salario mensual: $MONEDA $SALARIO_MENSUAL"
    echo "  Horas semanales: $HORAS_SEMANALES"
    echo "  Días laborales: $DIAS_LABORALES"
    echo "  Horas por día: $HORAS_POR_DIA"
    echo "  Moneda: $MONEDA"
    echo ""
    echo "Tarifas calculadas:"
    echo "  Por hora: $MONEDA $TARIFA_HORARIA"
    echo "  Por día: $MONEDA $TARIFA_DIARIA"
    echo "  Por semana: $MONEDA $TARIFA_SEMANAL"
    echo "  Por mes: $MONEDA $SALARIO_MENSUAL"
    echo ""
}

# Función para calcular total combinado
calcular_total() {
    local total_horas=0
    local detalles=""

    # Calcular horas de meses específicos
    if [ ${#MESES_ESPECIFICOS[@]} -gt 0 ]; then
        local total_dias_meses=0
        local detalle_meses=""

        for mes_info in "${MESES_ESPECIFICOS[@]}"; do
            local mes_param=$(echo "$mes_info" | cut -d':' -f1)
            local dias_mes=$(echo "$mes_info" | cut -d':' -f2)
            local horas_mes=$((dias_mes * HORAS_POR_DIA))
            total_dias_meses=$((total_dias_meses + dias_mes))

            if [ -z "$detalle_meses" ]; then
                detalle_meses="$mes_param ($dias_mes días)"
            else
                detalle_meses="$detalle_meses, $mes_param ($dias_mes días)"
            fi
        done

        local horas_meses=$((total_dias_meses * HORAS_POR_DIA))
        total_horas=$((total_horas + horas_meses))
        detalles="$detalles\n  Meses: $detalle_meses = $total_dias_meses días × $HORAS_POR_DIA horas = $horas_meses horas"
    fi

    # Calcular horas de semanas
    if [ $TOTAL_SEMANAS -gt 0 ]; then
        local horas_semanas=$((TOTAL_SEMANAS * HORAS_SEMANALES))
        total_horas=$((total_horas + horas_semanas))
        detalles="$detalles\n  Semanas: $TOTAL_SEMANAS × $HORAS_SEMANALES horas = $horas_semanas horas"
    fi

    # Calcular horas de días
    if [ $TOTAL_DIAS -gt 0 ]; then
        local horas_dias=$((TOTAL_DIAS * HORAS_POR_DIA))
        total_horas=$((total_horas + horas_dias))
        detalles="$detalles\n  Días: $TOTAL_DIAS × $HORAS_POR_DIA horas = $horas_dias horas"
    fi

    # Agregar horas adicionales
    if [ $TOTAL_HORAS -gt 0 ]; then
        total_horas=$((total_horas + TOTAL_HORAS))
        detalles="$detalles\n  Horas adicionales: $TOTAL_HORAS horas"
    fi

    # Calcular total a facturar
    local total_facturar=$(echo "scale=2; $total_horas * $TARIFA_HORARIA" | bc)

    echo "=== CÁLCULO DE FACTURACIÓN ==="
    echo ""
    echo "Desglose de tiempo trabajado:"
    echo -e "$detalles"
    echo ""
    echo "RESUMEN:"
    echo "  Total de horas: $total_horas"
    echo "  Tarifa por hora: $MONEDA $TARIFA_HORARIA"
    echo "  TOTAL A FACTURAR: $MONEDA $total_facturar"
}

# Verificar que bc esté instalado
if ! command -v bc &> /dev/null; then
    echo "Error: bc no está instalado. Instálalo con: brew install bc (macOS) o apt-get install bc (Linux)"
    exit 1
fi

# Variables acumuladoras para tiempo
MESES_ESPECIFICOS=()
TOTAL_SEMANAS=0
TOTAL_DIAS=0
TOTAL_HORAS=0
MOSTRAR_TARIFAS=false
MOSTRAR_AYUDA=false

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--meses)
            if [ -z "$2" ]; then
                echo "Error: Debes especificar el mes (MM o YYYY-MM)"
                exit 1
            fi
            dias_del_mes=$(calcular_dias_mes "$2")
            if [ "$dias_del_mes" -eq 0 ]; then
                echo "Error: Formato de mes inválido. Usa MM o YYYY-MM (ej: 02 o 2024-02)"
                exit 1
            fi
            MESES_ESPECIFICOS+=("$2:$dias_del_mes")
            shift 2
            ;;
        -s|--semanas)
            if [ -z "$2" ]; then
                echo "Error: Debes especificar la cantidad de semanas"
                exit 1
            fi
            TOTAL_SEMANAS=$((TOTAL_SEMANAS + $2))
            shift 2
            ;;
        -d|--dias)
            if [ -z "$2" ]; then
                echo "Error: Debes especificar la cantidad de días"
                exit 1
            fi
            TOTAL_DIAS=$((TOTAL_DIAS + $2))
            shift 2
            ;;
        -h|--horas)
            if [ -z "$2" ]; then
                echo "Error: Debes especificar la cantidad de horas"
                exit 1
            fi
            TOTAL_HORAS=$((TOTAL_HORAS + $2))
            shift 2
            ;;
        --moneda)
            if [ -z "$2" ]; then
                echo "Error: Debes especificar la moneda"
                exit 1
            fi
            MONEDA="$2"
            shift 2
            ;;
        --tarifas)
            MOSTRAR_TARIFAS=true
            shift
            ;;
        --help)
            MOSTRAR_AYUDA=true
            shift
            ;;
        *)
            echo "Error: Opción no válida: $1"
            echo "Usa '$0 --help' para ver las opciones disponibles"
            exit 1
            ;;
    esac
done

# Ejecutar acciones basadas en argumentos procesados
if [ "$MOSTRAR_AYUDA" = true ]; then
    mostrar_ayuda
elif [ "$MOSTRAR_TARIFAS" = true ]; then
    mostrar_tarifas
elif [ ${#MESES_ESPECIFICOS[@]} -eq 0 ] && [ $TOTAL_SEMANAS -eq 0 ] && [ $TOTAL_DIAS -eq 0 ] && [ $TOTAL_HORAS -eq 0 ]; then
    mostrar_ayuda
else
    calcular_total
fi
