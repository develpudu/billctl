# Facturator Usage Examples

This directory contains practical examples of how to use the Facturator CLI tool for various billing scenarios.

## 📚 Basic Usage Examples

### Simple Time Calculations

```bash
# Calculate billing for specific hours
./facturator -h 40
# Output: 40 hours × $13.75 = $550.00

# Calculate billing for days
./facturator -d 10
# Output: 10 days × 8 hours × $13.75 = $1,100.00

# Calculate billing for weeks
./facturator -s 3
# Output: 3 weeks × 40 hours × $13.75 = $1,650.00
```

### Monthly Calculations

```bash
# Current year months
./facturator -m 01    # January (31 days)
./facturator -m 02    # February (28/29 days)
./facturator -m 04    # April (30 days)

# Specific year months
./facturator -m 2024-01   # January 2024 (31 days)
./facturator -m 2024-02   # February 2024 (29 days - leap year)
./facturator -m 2023-02   # February 2023 (28 days - not leap year)
```

## 🔥 Advanced Combinations

### Mixed Time Periods

```bash
# Month + additional days
./facturator -m 01 -d 5
# January (248 hours) + 5 days (40 hours) = 288 hours

# Month + weeks + days
./facturator -m 2024-02 -s 1 -d 3
# February 2024 (232 hours) + 1 week (40 hours) + 3 days (24 hours) = 296 hours

# Full combination
./facturator -m 01 -s 2 -d 3 -h 4
# January (248h) + 2 weeks (80h) + 3 days (24h) + 4 hours = 356 hours
```

### Multiple Months

```bash
# Calculate for multiple months
./facturator -m 2024-01 -m 2024-02
# January 2024 (248h) + February 2024 (232h) = 480 hours

# Quarter calculation
./facturator -m 2024-01 -m 2024-02 -m 2024-03
# Q1 2024: 248h + 232h + 248h = 728 hours
```

## 💰 Currency Examples

### Different Currencies

```bash
# Euros
./facturator -d 15 --currency EUR
# Output: 15 days × 8 hours × €13.75 = €1,650.00

# US Dollars
./facturator -m 03 --currency USD
# Output: March (248 hours) × $13.75 = $3,410.00

# Argentine Pesos
./facturator -s 4 --currency ARS
# Output: 4 weeks × 40 hours × ARS 13.75 = ARS 2,200.00
```

### Rate Tables in Different Currencies

```bash
# Show rates in EUR
./facturator --rates --currency EUR

# Show rates in USD
./facturator --rates --currency USD
```

## 🏢 Real-World Scenarios

### Freelance Project Billing

```bash
# Project lasted 1.5 months with extra work
./facturator -m 2024-01 -d 15 -h 20
# January (248h) + 15 days (120h) + 20 hours = 388 hours

# Part-time month with additional weekend work
./facturator -m 02 -d 8
# February (224h) + 8 weekend days (64h) = 288 hours
```

### Monthly Retainer Plus Extra Work

```bash
# Monthly retainer + 1 week of extra work
./facturator -m 2024-03 -s 1
# March 2024 (248h) + 1 week (40h) = 288 hours

# Monthly retainer + specific additional hours
./facturator -m 04 -h 32
# April (240h) + 32 additional hours = 272 hours
```

### Contract Extensions

```bash
# Original month + 2-week extension
./facturator -m 2024-01 -s 2
# January 2024 (248h) + 2 weeks (80h) = 328 hours

# Multi-month contract with modifications
./facturator -m 2024-01 -m 2024-02 -d 10 -h 16
# Jan (248h) + Feb (232h) + 10 days (80h) + 16h = 576 hours
```

## 📊 Common Billing Patterns

### Weekly Billing Patterns

```bash
# 2 weeks of work
./facturator -s 2
# 2 × 40 hours = 80 hours = $1,100.00

# 3.5 weeks (3 weeks + 2 days)
./facturator -s 3 -d 2
# 3 weeks (120h) + 2 days (16h) = 136 hours = $1,870.00

# Part-time week (3 days)
./facturator -d 3
# 3 days × 8 hours = 24 hours = $330.00
```

### Monthly Variations

```bash
# Standard month
./facturator -m 01
# January: 31 days × 8 hours = 248 hours = $3,410.00

# Short month
./facturator -m 04
# April: 30 days × 8 hours = 240 hours = $3,300.00

# February (leap year)
./facturator -m 2024-02
# February 2024: 29 days × 8 hours = 232 hours = $3,190.00

# February (non-leap year)
./facturator -m 2023-02
# February 2023: 28 days × 8 hours = 224 hours = $3,080.00
```

## 🎯 Specific Use Cases

### Emergency/Rush Work

```bash
# Weekend emergency work (16 hours)
./facturator -h 16
# 16 hours × $13.75 = $220.00

# Rush project (2 days extra work)
./facturator -d 2
# 2 days × 8 hours = 16 hours = $220.00
```

### Partial Month Billing

```bash
# First half of month (15 days)
./facturator -d 15
# 15 days × 8 hours = 120 hours = $1,650.00

# Three weeks of a month
./facturator -s 3
# 3 weeks × 40 hours = 120 hours = $1,650.00

# One week + 3 days
./facturator -s 1 -d 3
# 1 week (40h) + 3 days (24h) = 64 hours = $880.00
```

### Overtime/Extra Hours

```bash
# Regular month + 20 hours overtime
./facturator -m 01 -h 20
# January (248h) + 20 hours = 268 hours = $3,685.00

# Half month + weekend work
./facturator -d 15 -h 16
# 15 days (120h) + 16 hours = 136 hours = $1,870.00
```

## 📈 Output Examples

### Sample Output for Complex Calculation

```bash
$ ./facturator -m 2024-01 -s 1 -d 3 -h 5 --currency EUR

=== CÁLCULO DE FACTURACIÓN ===

Desglose de tiempo trabajado:
  Meses: 2024-01 (31 días) = 31 días × 8 horas = 248 horas
  Semanas: 1 × 40 horas = 40 horas
  Días: 3 × 8 horas = 24 horas
  Horas adicionales: 5 horas

RESUMEN:
  Total de horas: 317
  Tarifa por hora: EUR 13.75
  TOTAL A FACTURAR: EUR 4,358.75
```

### Rate Table Output

```bash
$ ./facturator --rates --currency USD

=== TABLA DE TARIFAS FIMAL ===

Configuración base:
  Salario mensual: USD 2200.00
  Horas semanales: 40
  Días laborales: 5
  Horas por día: 8
  Moneda: USD

Tarifas calculadas:
  Por hora: USD 13.75
  Por día: USD 110.00
  Por semana: USD 550.00
  Por mes: USD 2200.00
```

## 🚨 Error Handling Examples

### Common Errors and Solutions

```bash
# Invalid month
./facturator -m 13
# Error: invalid month: 13 (must be 1-12)

# Invalid format
./facturator -m january
# Error: invalid month format: january (use MM or YYYY-MM)

# Negative values
./facturator -h -10
# Error: hours cannot be negative: -10

# Missing arguments
./facturator -m
# Error: flag needs an argument: -m
```

## 📝 Tips and Best Practices

### 1. Always Verify Leap Years
```bash
# Check February in different years
./facturator -m 2024-02  # 29 days (leap year)
./facturator -m 2023-02  # 28 days (regular year)
```

### 2. Use Specific Years for Historical Billing
```bash
# For invoices from previous years
./facturator -m 2023-01 -m 2023-02 -m 2023-03
```

### 3. Combine Rate Display with Calculations
```bash
# Show rates first, then calculate
./facturator --rates --currency EUR
./facturator -m 01 -d 5 --currency EUR
```

### 4. Document Complex Calculations
```bash
# For complex projects, document the breakdown
./facturator -m 2024-01 -m 2024-02 -d 10 -h 20
# Project: 2 months + 10 days revision + 20 hours meetings
```

## 🔧 Automation Examples

### Batch Processing
```bash
# Create a script for common calculations
#!/bin/bash
echo "Q1 2024 billing:"
./facturator -m 2024-01 -m 2024-02 -m 2024-03

echo "Q2 2024 billing:"
./facturator -m 2024-04 -m 2024-05 -m 2024-06
```

### Monthly Reports
```bash
# Generate monthly reports
for month in {01..12}; do
    echo "Month $month:"
    ./facturator -m 2024-$month
done
```

---

💡 **Pro Tip**: Use the `--rates` flag to double-check your hourly calculations and ensure accuracy in your billing.