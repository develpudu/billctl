package calculator

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"billctl/internal/config"
)

// MonthInfo holds month calculation details
type MonthInfo struct {
	Input string
	Days  int
	Year  int
	Month int
}

// TimeInput represents user input for time calculations
type TimeInput struct {
	Hours  []int
	Days   []int
	Weeks  []int
	Months []string
}

// CalculationResult holds the breakdown and total
type CalculationResult struct {
	MonthDetails []MonthInfo
	TotalWeeks   int
	TotalDays    int
	TotalHours   int
	TotalTime    int
	TotalAmount  float64
	Currency     string
}

// Calculator handles all billing calculations
type Calculator struct {
	config *config.BillingConfig
}

// NewCalculator creates a new calculator instance
func NewCalculator(config *config.BillingConfig) *Calculator {
	return &Calculator{
		config: config,
	}
}

// IsLeapYear checks if a year is a leap year
func IsLeapYear(year int) bool {
	return year%4 == 0 && (year%100 != 0 || year%400 == 0)
}

// GetDaysInMonth returns the number of days in a given month and year
func GetDaysInMonth(month, year int) int {
	switch month {
	case 1, 3, 5, 7, 8, 10, 12:
		return 31
	case 4, 6, 9, 11:
		return 30
	case 2:
		if IsLeapYear(year) {
			return 29
		}
		return 28
	default:
		return 0
	}
}

// ParseMonth parses month input in MM or YYYY-MM format
func ParseMonth(input string) (MonthInfo, error) {
	var info MonthInfo
	info.Input = input

	// Regex for YYYY-MM format
	yearMonthRegex := regexp.MustCompile(`^(\d{4})-(\d{1,2})$`)
	// Regex for MM format
	monthRegex := regexp.MustCompile(`^(\d{1,2})$`)

	if matches := yearMonthRegex.FindStringSubmatch(input); matches != nil {
		year, err := strconv.Atoi(matches[1])
		if err != nil {
			return info, fmt.Errorf("invalid year in input: %s", input)
		}

		month, err := strconv.Atoi(matches[2])
		if err != nil {
			return info, fmt.Errorf("invalid month in input: %s", input)
		}

		if month < 1 || month > 12 {
			return info, fmt.Errorf("invalid month: %d (must be 1-12)", month)
		}

		info.Year = year
		info.Month = month
		info.Days = GetDaysInMonth(month, year)
	} else if matches := monthRegex.FindStringSubmatch(input); matches != nil {
		month, err := strconv.Atoi(matches[1])
		if err != nil {
			return info, fmt.Errorf("invalid month in input: %s", input)
		}

		if month < 1 || month > 12 {
			return info, fmt.Errorf("invalid month: %d (must be 1-12)", month)
		}

		info.Year = time.Now().Year()
		info.Month = month
		info.Days = GetDaysInMonth(month, info.Year)
	} else {
		return info, fmt.Errorf("invalid month format: %s (use MM or YYYY-MM)", input)
	}

	return info, nil
}

// ValidateInput validates the time input
func (c *Calculator) ValidateInput(input TimeInput) error {
	// Validate hours
	for _, h := range input.Hours {
		if h < 0 {
			return fmt.Errorf("hours cannot be negative: %d", h)
		}
	}

	// Validate days
	for _, d := range input.Days {
		if d < 0 {
			return fmt.Errorf("days cannot be negative: %d", d)
		}
	}

	// Validate weeks
	for _, w := range input.Weeks {
		if w < 0 {
			return fmt.Errorf("weeks cannot be negative: %d", w)
		}
	}

	// Validate months
	for _, monthStr := range input.Months {
		if _, err := ParseMonth(monthStr); err != nil {
			return fmt.Errorf("invalid month '%s': %v", monthStr, err)
		}
	}

	return nil
}

// Calculate performs the main calculation
func (c *Calculator) Calculate(input TimeInput, currency string) (*CalculationResult, error) {
	if err := c.ValidateInput(input); err != nil {
		return nil, err
	}

	result := &CalculationResult{
		Currency: currency,
	}

	// Parse months
	for _, monthStr := range input.Months {
		monthInfo, err := ParseMonth(monthStr)
		if err != nil {
			return nil, fmt.Errorf("failed to parse month '%s': %v", monthStr, err)
		}
		result.MonthDetails = append(result.MonthDetails, monthInfo)
	}

	// Sum all values
	for _, h := range input.Hours {
		result.TotalHours += h
	}
	for _, d := range input.Days {
		result.TotalDays += d
	}
	for _, w := range input.Weeks {
		result.TotalWeeks += w
	}

	// Calculate total hours from all sources
	totalHours := result.TotalHours
	totalHours += result.TotalDays * c.config.HoursPerDay
	totalHours += result.TotalWeeks * c.config.WeeklyHours

	// Add hours from months
	for _, monthInfo := range result.MonthDetails {
		totalHours += monthInfo.Days * c.config.HoursPerDay
	}

	result.TotalTime = totalHours
	result.TotalAmount = float64(totalHours) * c.config.HourlyRate

	return result, nil
}

// FormatResult formats the calculation result for display
func (c *Calculator) FormatResult(result *CalculationResult) string {
	var output strings.Builder

	output.WriteString("=== CÁLCULO DE FACTURACIÓN ===\n\n")
	output.WriteString("Desglose de tiempo trabajado:\n")

	// Show month details
	if len(result.MonthDetails) > 0 {
		var monthParts []string
		totalMonthDays := 0
		for _, monthInfo := range result.MonthDetails {
			monthParts = append(monthParts, fmt.Sprintf("%s (%d días)", monthInfo.Input, monthInfo.Days))
			totalMonthDays += monthInfo.Days
		}
		monthHours := totalMonthDays * c.config.HoursPerDay
		output.WriteString(fmt.Sprintf("  Meses: %s = %d días × %d horas = %d horas\n",
			strings.Join(monthParts, ", "), totalMonthDays, c.config.HoursPerDay, monthHours))
	}

	// Show weeks
	if result.TotalWeeks > 0 {
		weekHours := result.TotalWeeks * c.config.WeeklyHours
		output.WriteString(fmt.Sprintf("  Semanas: %d × %d horas = %d horas\n",
			result.TotalWeeks, c.config.WeeklyHours, weekHours))
	}

	// Show days
	if result.TotalDays > 0 {
		dayHours := result.TotalDays * c.config.HoursPerDay
		output.WriteString(fmt.Sprintf("  Días: %d × %d horas = %d horas\n",
			result.TotalDays, c.config.HoursPerDay, dayHours))
	}

	// Show additional hours
	if result.TotalHours > 0 {
		output.WriteString(fmt.Sprintf("  Horas adicionales: %d horas\n", result.TotalHours))
	}

	output.WriteString("\nRESUMEN:\n")
	output.WriteString(fmt.Sprintf("  Total de horas: %d\n", result.TotalTime))
	output.WriteString(fmt.Sprintf("  Tarifa por hora: %s %.2f\n", result.Currency, c.config.HourlyRate))
	output.WriteString(fmt.Sprintf("  TOTAL A FACTURAR: %s %.2f\n", result.Currency, result.TotalAmount))

	return output.String()
}

// FormatRates formats the rates table for display
func (c *Calculator) FormatRates(currency string) string {
	var output strings.Builder

	output.WriteString("=== TABLA DE TARIFAS ===\n\n")
	output.WriteString("Configuración base:\n")
	output.WriteString(fmt.Sprintf("  Salario mensual: %s %.2f\n", currency, c.config.MonthlySalary))
	output.WriteString(fmt.Sprintf("  Horas semanales: %d\n", c.config.WeeklyHours))
	output.WriteString(fmt.Sprintf("  Días laborales: %d\n", c.config.WorkDays))
	output.WriteString(fmt.Sprintf("  Horas por día: %d\n", c.config.HoursPerDay))
	output.WriteString(fmt.Sprintf("  Moneda: %s\n", currency))
	output.WriteString("\nTarifas calculadas:\n")
	output.WriteString(fmt.Sprintf("  Por hora: %s %.2f\n", currency, c.config.HourlyRate))
	output.WriteString(fmt.Sprintf("  Por día: %s %.2f\n", currency, c.config.DailyRate))
	output.WriteString(fmt.Sprintf("  Por semana: %s %.2f\n", currency, c.config.WeeklyRate))
	output.WriteString(fmt.Sprintf("  Por mes: %s %.2f\n", currency, c.config.MonthlySalary))
	output.WriteString("\n")

	return output.String()
}

// CalculateQuickRates calculates rates for common time periods
func (c *Calculator) CalculateQuickRates(currency string) map[string]float64 {
	return map[string]float64{
		"hourly":  c.config.HourlyRate,
		"daily":   c.config.DailyRate,
		"weekly":  c.config.WeeklyRate,
		"monthly": c.config.MonthlySalary,
	}
}

// GetMonthSummary returns a summary of hours and amount for a specific month
func (c *Calculator) GetMonthSummary(monthInput string, currency string) (string, error) {
	monthInfo, err := ParseMonth(monthInput)
	if err != nil {
		return "", err
	}

	hours := monthInfo.Days * c.config.HoursPerDay
	amount := float64(hours) * c.config.HourlyRate

	return fmt.Sprintf("Mes %s: %d días × %d horas = %d horas → %s %.2f",
		monthInput, monthInfo.Days, c.config.HoursPerDay, hours, currency, amount), nil
}
