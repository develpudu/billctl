package main

import (
	"fmt"
	"os"

	"facturator/internal/calculator"
	"facturator/internal/config"

	"github.com/spf13/cobra"
)

// Version information (set during build)
var (
	Version   = "1.0.0"
	BuildTime = "unknown"
	GitCommit = "unknown"
)

// Command line flags
var (
	hours       []int
	days        []int
	weeks       []int
	months      []string
	currency    string
	showRates   bool
	showVersion bool
)

var rootCmd = &cobra.Command{
	Use:   "facturator",
	Short: "FIMAL Billing Calculator",
	Long: `=== CALCULADORA DE FACTURACIÓN FIMAL ===

A CLI tool for calculating billing amounts based on hours, days, weeks, and months.
You can combine multiple time periods for complex calculations.

Examples:
  facturator -h 120                    # Calculate for 120 hours
  facturator -d 15                     # Calculate for 15 days
  facturator -s 2                      # Calculate for 2 weeks
  facturator -m 02                     # February of current year
  facturator -m 2024-02                # February 2024 (28 days)
  facturator -m 01 -d 5                # January + 5 additional days
  facturator -s 2 -d 3 -h 4            # 2 weeks + 3 days + 4 hours
  facturator -d 15 --currency EUR      # 15 days in euros
  facturator -m 2024-01 -m 2024-02     # Multiple months

Month formats:
  MM                                   # Month of current year (e.g., 02 for February)
  YYYY-MM                              # Month of specific year (e.g., 2024-02)

Supported operations:
  --rates                              # Show rate table
  --currency CURRENCY                  # Set currency (default: U$S)
  --version                            # Show version information
  --help, -?                           # Show help message`,
	RunE: func(cmd *cobra.Command, args []string) error {
		// Check for manual help flag
		if help, _ := cmd.Flags().GetBool("help"); help {
			return cmd.Help()
		}

		// Initialize configuration
		cfg := config.NewBillingConfig()
		if err := cfg.Validate(); err != nil {
			return fmt.Errorf("configuration error: %v", err)
		}

		// Initialize calculator
		calc := calculator.NewCalculator(cfg)

		// If --version flag is set, show version and exit
		if showVersion {
			fmt.Printf("Facturator v%s\n", Version)
			fmt.Printf("Build Time: %s\n", BuildTime)
			fmt.Printf("Git Commit: %s\n", GitCommit)
			fmt.Printf("Go Version: %s\n", "go1.21+")
			return nil
		}

		// If --rates flag is set, show rates and exit
		if showRates {
			fmt.Print(calc.FormatRates(currency))
			return nil
		}

		// Check if any time parameters were provided
		if len(hours) == 0 && len(days) == 0 && len(weeks) == 0 && len(months) == 0 {
			return cmd.Help()
		}

		// Prepare input
		input := calculator.TimeInput{
			Hours:  hours,
			Days:   days,
			Weeks:  weeks,
			Months: months,
		}

		// Calculate and display result
		result, err := calc.Calculate(input, currency)
		if err != nil {
			return fmt.Errorf("calculation error: %v", err)
		}

		fmt.Print(calc.FormatResult(result))
		return nil
	},
}

func init() {
	// Disable default help command to avoid conflict with -h for hours
	rootCmd.SetHelpCommand(&cobra.Command{Hidden: true})

	// Define flags
	rootCmd.Flags().IntSliceVarP(&hours, "hours", "h", []int{}, "Add worked hours (can be used multiple times)")
	rootCmd.Flags().IntSliceVarP(&days, "days", "d", []int{}, "Add worked days (can be used multiple times)")
	rootCmd.Flags().IntSliceVarP(&weeks, "weeks", "s", []int{}, "Add worked weeks (can be used multiple times)")
	rootCmd.Flags().StringSliceVarP(&months, "months", "m", []string{}, "Add specific months (MM or YYYY-MM format, can be used multiple times)")
	rootCmd.Flags().StringVar(&currency, "currency", "U$S", "Set currency (default: U$S)")
	rootCmd.Flags().BoolVar(&showRates, "rates", false, "Show rate table")
	rootCmd.Flags().BoolVar(&showVersion, "version", false, "Show version information")

	// Add manual help flag to replace the disabled default one
	rootCmd.Flags().BoolP("help", "?", false, "Show help message")

	// Add flag aliases for backward compatibility
	rootCmd.Flags().Lookup("currency").NoOptDefVal = "U$S"

	// Set flag usage messages
	rootCmd.Flags().SetAnnotation("hours", "help", []string{"Specify additional hours worked"})
	rootCmd.Flags().SetAnnotation("days", "help", []string{"Specify additional days worked"})
	rootCmd.Flags().SetAnnotation("weeks", "help", []string{"Specify additional weeks worked"})
	rootCmd.Flags().SetAnnotation("months", "help", []string{"Specify months in MM or YYYY-MM format"})
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
