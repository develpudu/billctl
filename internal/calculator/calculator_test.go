package calculator

import (
	"strings"
	"testing"
	"time"

	"billctl/internal/config"
)

func TestIsLeapYear(t *testing.T) {
	tests := []struct {
		year     int
		expected bool
	}{
		{2000, true},  // Divisible by 400
		{2004, true},  // Divisible by 4, not by 100
		{1900, false}, // Divisible by 100, not by 400
		{2001, false}, // Not divisible by 4
		{2020, true},  // Divisible by 4, not by 100
		{2100, false}, // Divisible by 100, not by 400
	}

	for _, test := range tests {
		t.Run(string(rune(test.year)), func(t *testing.T) {
			result := IsLeapYear(test.year)
			if result != test.expected {
				t.Errorf("IsLeapYear(%d) = %v, want %v", test.year, result, test.expected)
			}
		})
	}
}

func TestGetDaysInMonth(t *testing.T) {
	tests := []struct {
		month    int
		year     int
		expected int
	}{
		{1, 2024, 31},  // January
		{2, 2024, 29},  // February (leap year)
		{2, 2023, 28},  // February (non-leap year)
		{3, 2024, 31},  // March
		{4, 2024, 30},  // April
		{5, 2024, 31},  // May
		{6, 2024, 30},  // June
		{7, 2024, 31},  // July
		{8, 2024, 31},  // August
		{9, 2024, 30},  // September
		{10, 2024, 31}, // October
		{11, 2024, 30}, // November
		{12, 2024, 31}, // December
		{13, 2024, 0},  // Invalid month
		{0, 2024, 0},   // Invalid month
	}

	for _, test := range tests {
		t.Run("", func(t *testing.T) {
			result := GetDaysInMonth(test.month, test.year)
			if result != test.expected {
				t.Errorf("GetDaysInMonth(%d, %d) = %d, want %d", test.month, test.year, result, test.expected)
			}
		})
	}
}

func TestParseMonth(t *testing.T) {
	currentYear := time.Now().Year()

	tests := []struct {
		input       string
		expected    MonthInfo
		expectError bool
	}{
		{
			input: "01",
			expected: MonthInfo{
				Input: "01",
				Year:  currentYear,
				Month: 1,
				Days:  31,
			},
			expectError: false,
		},
		{
			input: "2024-02",
			expected: MonthInfo{
				Input: "2024-02",
				Year:  2024,
				Month: 2,
				Days:  29, // 2024 is a leap year
			},
			expectError: false,
		},
		{
			input: "2023-02",
			expected: MonthInfo{
				Input: "2023-02",
				Year:  2023,
				Month: 2,
				Days:  28, // 2023 is not a leap year
			},
			expectError: false,
		},
		{
			input:       "13",
			expectError: true, // Invalid month
		},
		{
			input:       "2024-13",
			expectError: true, // Invalid month
		},
		{
			input:       "invalid",
			expectError: true, // Invalid format
		},
		{
			input:       "2024-0",
			expectError: true, // Invalid month
		},
	}

	for _, test := range tests {
		t.Run(test.input, func(t *testing.T) {
			result, err := ParseMonth(test.input)

			if test.expectError {
				if err == nil {
					t.Errorf("ParseMonth(%s) expected error, got nil", test.input)
				}
				return
			}

			if err != nil {
				t.Errorf("ParseMonth(%s) unexpected error: %v", test.input, err)
				return
			}

			if result.Input != test.expected.Input {
				t.Errorf("ParseMonth(%s) Input = %s, want %s", test.input, result.Input, test.expected.Input)
			}
			if result.Year != test.expected.Year {
				t.Errorf("ParseMonth(%s) Year = %d, want %d", test.input, result.Year, test.expected.Year)
			}
			if result.Month != test.expected.Month {
				t.Errorf("ParseMonth(%s) Month = %d, want %d", test.input, result.Month, test.expected.Month)
			}
			if result.Days != test.expected.Days {
				t.Errorf("ParseMonth(%s) Days = %d, want %d", test.input, result.Days, test.expected.Days)
			}
		})
	}
}

func TestCalculatorValidateInput(t *testing.T) {
	cfg := config.NewBillingConfig()
	calc := NewCalculator(cfg)

	tests := []struct {
		name        string
		input       TimeInput
		expectError bool
	}{
		{
			name: "valid input",
			input: TimeInput{
				Hours:  []int{8, 4},
				Days:   []int{5, 10},
				Weeks:  []int{2},
				Months: []string{"01", "2024-02"},
			},
			expectError: false,
		},
		{
			name: "negative hours",
			input: TimeInput{
				Hours: []int{-5},
			},
			expectError: true,
		},
		{
			name: "negative days",
			input: TimeInput{
				Days: []int{-3},
			},
			expectError: true,
		},
		{
			name: "negative weeks",
			input: TimeInput{
				Weeks: []int{-1},
			},
			expectError: true,
		},
		{
			name: "invalid month format",
			input: TimeInput{
				Months: []string{"invalid"},
			},
			expectError: true,
		},
		{
			name: "invalid month number",
			input: TimeInput{
				Months: []string{"13"},
			},
			expectError: true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			err := calc.ValidateInput(test.input)

			if test.expectError && err == nil {
				t.Errorf("ValidateInput() expected error, got nil")
			}
			if !test.expectError && err != nil {
				t.Errorf("ValidateInput() unexpected error: %v", err)
			}
		})
	}
}

func TestCalculatorCalculate(t *testing.T) {
	cfg := config.NewBillingConfig()
	calc := NewCalculator(cfg)

	tests := []struct {
		name           string
		input          TimeInput
		currency       string
		expectedHours  int
		expectedAmount float64
		expectError    bool
	}{
		{
			name: "hours only",
			input: TimeInput{
				Hours: []int{10, 5},
			},
			currency:       "USD",
			expectedHours:  15,
			expectedAmount: 15 * cfg.HourlyRate,
			expectError:    false,
		},
		{
			name: "days only",
			input: TimeInput{
				Days: []int{5, 3},
			},
			currency:       "EUR",
			expectedHours:  8 * 8, // 8 days * 8 hours per day
			expectedAmount: 64 * cfg.HourlyRate,
			expectError:    false,
		},
		{
			name: "weeks only",
			input: TimeInput{
				Weeks: []int{2},
			},
			currency:       "U$S",
			expectedHours:  2 * 40, // 2 weeks * 40 hours per week
			expectedAmount: 80 * cfg.HourlyRate,
			expectError:    false,
		},
		{
			name: "january 2024",
			input: TimeInput{
				Months: []string{"2024-01"},
			},
			currency:       "U$S",
			expectedHours:  31 * 8, // 31 days * 8 hours per day
			expectedAmount: 248 * cfg.HourlyRate,
			expectError:    false,
		},
		{
			name: "february leap year",
			input: TimeInput{
				Months: []string{"2024-02"},
			},
			currency:       "U$S",
			expectedHours:  29 * 8, // 29 days * 8 hours per day (leap year)
			expectedAmount: 232 * cfg.HourlyRate,
			expectError:    false,
		},
		{
			name: "february non-leap year",
			input: TimeInput{
				Months: []string{"2023-02"},
			},
			currency:       "U$S",
			expectedHours:  28 * 8, // 28 days * 8 hours per day (non-leap year)
			expectedAmount: 224 * cfg.HourlyRate,
			expectError:    false,
		},
		{
			name: "combined calculation",
			input: TimeInput{
				Hours:  []int{4},
				Days:   []int{3},
				Weeks:  []int{1},
				Months: []string{"2024-01"},
			},
			currency: "U$S",
			// 4 hours + (3 days * 8) + (1 week * 40) + (31 days * 8) = 4 + 24 + 40 + 248 = 316
			expectedHours:  316,
			expectedAmount: 316 * cfg.HourlyRate,
			expectError:    false,
		},
		{
			name: "invalid month",
			input: TimeInput{
				Months: []string{"invalid"},
			},
			currency:    "U$S",
			expectError: true,
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			result, err := calc.Calculate(test.input, test.currency)

			if test.expectError {
				if err == nil {
					t.Errorf("Calculate() expected error, got nil")
				}
				return
			}

			if err != nil {
				t.Errorf("Calculate() unexpected error: %v", err)
				return
			}

			if result.TotalTime != test.expectedHours {
				t.Errorf("Calculate() TotalTime = %d, want %d", result.TotalTime, test.expectedHours)
			}

			if result.TotalAmount != test.expectedAmount {
				t.Errorf("Calculate() TotalAmount = %.2f, want %.2f", result.TotalAmount, test.expectedAmount)
			}

			if result.Currency != test.currency {
				t.Errorf("Calculate() Currency = %s, want %s", result.Currency, test.currency)
			}
		})
	}
}

func TestCalculatorFormatResult(t *testing.T) {
	cfg := config.NewBillingConfig()
	calc := NewCalculator(cfg)

	result := &CalculationResult{
		MonthDetails: []MonthInfo{
			{Input: "2024-01", Days: 31},
		},
		TotalWeeks:  1,
		TotalDays:   5,
		TotalHours:  10,
		TotalTime:   338, // (31 * 8) + (1 * 40) + (5 * 8) + 10
		TotalAmount: 338 * cfg.HourlyRate,
		Currency:    "U$S",
	}

	output := calc.FormatResult(result)

	// Check that output contains expected elements
	expectedSubstrings := []string{
		"=== CÁLCULO DE FACTURACIÓN ===",
		"Desglose de tiempo trabajado:",
		"Meses: 2024-01 (31 días)",
		"Semanas: 1 × 40 horas = 40 horas",
		"Días: 5 × 8 horas = 40 horas",
		"Horas adicionales: 10 horas",
		"RESUMEN:",
		"Total de horas: 338",
		"TOTAL A FACTURAR:",
	}

	for _, expected := range expectedSubstrings {
		if !strings.Contains(output, expected) {
			t.Errorf("FormatResult() output missing expected substring: %s", expected)
		}
	}
}

func TestCalculatorFormatRates(t *testing.T) {
	cfg := config.NewBillingConfig()
	calc := NewCalculator(cfg)

	output := calc.FormatRates("EUR")

	// Check that output contains expected elements
	expectedSubstrings := []string{
		"=== TABLA DE TARIFAS FIMAL ===",
		"Configuración base:",
		"Salario mensual: EUR 2200.00",
		"Horas semanales: 40",
		"Días laborales: 5",
		"Horas por día: 8",
		"Moneda: EUR",
		"Tarifas calculadas:",
		"Por hora: EUR",
		"Por día: EUR",
		"Por semana: EUR",
		"Por mes: EUR",
	}

	for _, expected := range expectedSubstrings {
		if !strings.Contains(output, expected) {
			t.Errorf("FormatRates() output missing expected substring: %s", expected)
		}
	}
}

func TestCalculatorGetMonthSummary(t *testing.T) {
	cfg := config.NewBillingConfig()
	calc := NewCalculator(cfg)

	tests := []struct {
		monthInput  string
		currency    string
		expectError bool
	}{
		{
			monthInput:  "2024-01",
			currency:    "U$S",
			expectError: false,
		},
		{
			monthInput:  "02",
			currency:    "EUR",
			expectError: false,
		},
		{
			monthInput:  "invalid",
			currency:    "USD",
			expectError: true,
		},
	}

	for _, test := range tests {
		t.Run(test.monthInput, func(t *testing.T) {
			summary, err := calc.GetMonthSummary(test.monthInput, test.currency)

			if test.expectError {
				if err == nil {
					t.Errorf("GetMonthSummary() expected error, got nil")
				}
				return
			}

			if err != nil {
				t.Errorf("GetMonthSummary() unexpected error: %v", err)
				return
			}

			// Check that summary contains expected elements
			expectedSubstrings := []string{
				test.monthInput,
				"días",
				"horas",
				test.currency,
			}

			for _, expected := range expectedSubstrings {
				if !strings.Contains(summary, expected) {
					t.Errorf("GetMonthSummary() output missing expected substring: %s", expected)
				}
			}
		})
	}
}

func TestCalculatorQuickRates(t *testing.T) {
	cfg := config.NewBillingConfig()
	calc := NewCalculator(cfg)

	rates := calc.CalculateQuickRates("U$S")

	expectedRates := map[string]float64{
		"hourly":  cfg.HourlyRate,
		"daily":   cfg.DailyRate,
		"weekly":  cfg.WeeklyRate,
		"monthly": cfg.MonthlySalary,
	}

	for key, expectedValue := range expectedRates {
		if rate, exists := rates[key]; !exists {
			t.Errorf("CalculateQuickRates() missing rate: %s", key)
		} else if rate != expectedValue {
			t.Errorf("CalculateQuickRates() %s = %.2f, want %.2f", key, rate, expectedValue)
		}
	}
}

// Benchmark tests
func BenchmarkParseMonth(b *testing.B) {
	for i := 0; i < b.N; i++ {
		ParseMonth("2024-02")
	}
}

func BenchmarkCalculate(b *testing.B) {
	cfg := config.NewBillingConfig()
	calc := NewCalculator(cfg)
	input := TimeInput{
		Hours:  []int{10, 5},
		Days:   []int{5, 3},
		Weeks:  []int{2},
		Months: []string{"2024-01", "2024-02"},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		calc.Calculate(input, "U$S")
	}
}

func BenchmarkIsLeapYear(b *testing.B) {
	for i := 0; i < b.N; i++ {
		IsLeapYear(2024)
	}
}

func BenchmarkGetDaysInMonth(b *testing.B) {
	for i := 0; i < b.N; i++ {
		GetDaysInMonth(2, 2024)
	}
}
