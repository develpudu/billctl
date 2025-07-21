package config

import "fmt"

// BillingConfig holds all billing configuration
type BillingConfig struct {
	MonthlySalary   float64
	WeeklyHours     int
	WorkDays        int
	HoursPerDay     int
	WeeksPerMonth   int
	DefaultCurrency string

	// Calculated rates
	MonthlyHours int
	HourlyRate   float64
	DailyRate    float64
	WeeklyRate   float64
}

// NewBillingConfig creates a new billing configuration with default values
func NewBillingConfig() *BillingConfig {
	config := &BillingConfig{
		MonthlySalary:   2200.0,
		WeeklyHours:     40,
		WorkDays:        5,
		HoursPerDay:     8,
		WeeksPerMonth:   4,
		DefaultCurrency: "U$S",
	}

	config.calculateRates()
	return config
}

// calculateRates computes all derived rates from base configuration
func (c *BillingConfig) calculateRates() {
	c.MonthlyHours = c.WeeklyHours * c.WeeksPerMonth
	c.HourlyRate = c.MonthlySalary / float64(c.MonthlyHours)
	c.DailyRate = c.HourlyRate * float64(c.HoursPerDay)
	c.WeeklyRate = c.HourlyRate * float64(c.WeeklyHours)
}

// SetMonthlySalary updates the monthly salary and recalculates rates
func (c *BillingConfig) SetMonthlySalary(salary float64) error {
	if salary <= 0 {
		return fmt.Errorf("monthly salary must be positive, got: %.2f", salary)
	}
	c.MonthlySalary = salary
	c.calculateRates()
	return nil
}

// SetWeeklyHours updates weekly hours and recalculates rates
func (c *BillingConfig) SetWeeklyHours(hours int) error {
	if hours <= 0 {
		return fmt.Errorf("weekly hours must be positive, got: %d", hours)
	}
	c.WeeklyHours = hours
	c.calculateRates()
	return nil
}

// SetHoursPerDay updates hours per day and recalculates rates
func (c *BillingConfig) SetHoursPerDay(hours int) error {
	if hours <= 0 {
		return fmt.Errorf("hours per day must be positive, got: %d", hours)
	}
	c.HoursPerDay = hours
	c.calculateRates()
	return nil
}

// Validate checks if the configuration is valid
func (c *BillingConfig) Validate() error {
	if c.MonthlySalary <= 0 {
		return fmt.Errorf("monthly salary must be positive")
	}
	if c.WeeklyHours <= 0 {
		return fmt.Errorf("weekly hours must be positive")
	}
	if c.HoursPerDay <= 0 {
		return fmt.Errorf("hours per day must be positive")
	}
	if c.WorkDays <= 0 {
		return fmt.Errorf("work days must be positive")
	}
	if c.WeeksPerMonth <= 0 {
		return fmt.Errorf("weeks per month must be positive")
	}
	if c.DefaultCurrency == "" {
		return fmt.Errorf("default currency cannot be empty")
	}
	return nil
}

// String returns a formatted string representation of the configuration
func (c *BillingConfig) String() string {
	return fmt.Sprintf(
		"BillingConfig{MonthlySalary: %.2f, WeeklyHours: %d, HoursPerDay: %d, Currency: %s}",
		c.MonthlySalary, c.WeeklyHours, c.HoursPerDay, c.DefaultCurrency,
	)
}
