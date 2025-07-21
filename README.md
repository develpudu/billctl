# Billctl - Professional Billing Calculator

A high-performance CLI tool for calculating billing amounts based on hours, days, weeks, and months. 

## 🚀 Features

- **Multiple Time Units**: Calculate billing for hours, days, weeks, and specific months
- **Smart Month Handling**: Automatic leap year detection and accurate days per month
- **Flexible Input**: Combine multiple time periods in a single calculation
- **Performance Optimized**: Go version is 70% faster than the original bash implementation
- **Cross-Platform**: Works on macOS, Linux, and Windows

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/develpudu/billctl.git
cd billctl

# Build the binary
go build -o billctl

# Optional: Install globally
go install
```

**Requirements**: Go 1.21+

## 🎯 Usage

### Basic Examples

```bash
# Calculate for 120 hours
./billctl -h 120

# Calculate for 15 days
./billctl -d 15

# Calculate for 2 weeks
./billctl -s 2

# Calculate for February (current year)
./billctl -m 02

# Calculate for January 2024 (31 days)
./billctl -m 2024-01

# Calculate for February 2024 (29 days - leap year)
./billctl -m 2024-02
```

### Advanced Examples

```bash
# Combine multiple time periods
./billctl -m 01 -d 5 -h 8           # January + 5 days + 8 hours
./billctl -s 2 -d 3 -h 4            # 2 weeks + 3 days + 4 hours
./billctl -m 2024-01 -m 2024-02     # Multiple months

# Use different currencies
./billctl -d 15 --currency EUR      # 15 days in euros
./billctl -m 03 --currency USD      # March in US dollars

# Show rate table
./billctl --rates                   # Display all rates
./billctl --rates --currency EUR    # Rates in euros
```

### Command Reference

| Flag | Short | Description | Example |
|------|-------|-------------|---------|
| `--hours` | `-h` | Add worked hours | `-h 120` |
| `--days` | `-d` | Add worked days | `-d 15` |
| `--weeks` | `-s` | Add worked weeks | `-s 2` |
| `--months` | `-m` | Add specific months | `-m 02` or `-m 2024-02` |
| `--currency` | | Set currency symbol | `--currency EUR` |
| `--rates` | | Show rate table | `--rates` |
| `--help` | | Show help message | `--help` |

## 📊 Configuration

| Configuration | Value |
|---------------|-------|
| Monthly Salary | $2,200 USD |
| Weekly Hours | 40 hours |
| Hours per Day | 8 hours |
| Hourly Rate | $13.75 |

## 📅 Month Format Examples

| Format | Description | Days Calculated |
|--------|-------------|-----------------|
| `01` | January (current year) | 31 days |
| `02` | February (current year) | 28/29 days* |
| `2024-01` | January 2024 | 31 days |
| `2024-02` | February 2024 | 29 days (leap year) |
| `2023-02` | February 2023 | 28 days (not leap year) |

*Automatically detects leap years

## 🔥 Performance

The Go version is **70% faster on average** than the bash implementation:
- Simple calculations: ~15ms → ~2ms
- Complex calculations: ~25ms → ~3ms
- 60% less memory usage
- No external dependencies

## 🧪 Testing

```bash
# Run tests
go test ./...

# Run benchmarks
go test -bench=. ./...

# Performance comparison
./benchmark.sh
```

## 📈 Example Calculations

### January 2024 (31 days)
```bash
$ ./billctl -m 2024-01

=== CÁLCULO DE FACTURACIÓN ===

Desglose de tiempo trabajado:
  Meses: 2024-01 (31 días) = 31 días × 8 horas = 248 horas

RESUMEN:
  Total de horas: 248
  Tarifa por hora: U$S 13.75
  TOTAL A FACTURAR: U$S 3,410.00
```

### Combined Calculation
```bash
$ ./billctl -m 01 -s 1 -d 3 -h 5

=== CÁLCULO DE FACTURACIÓN ===

Desglose de tiempo trabajado:
  Meses: 01 (31 días) = 31 días × 8 horas = 248 horas
  Semanas: 1 × 40 horas = 40 horas
  Días: 3 × 8 horas = 24 horas
  Horas adicionales: 5 horas

RESUMEN:
  Total de horas: 317
  Tarifa por hora: U$S 13.75
  TOTAL A FACTURAR: U$S 4,358.75
```

## 🛠️ Development

```bash
# Download dependencies
go mod download

# Build
go build -o billctl

# Cross-compile
make cross-compile

# Run all automation
make help
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch  
3. Add tests for new functionality
4. Submit a pull request

---

**Author**: [DevelPudu](https://github.com/develpudu)  
**License**: MIT