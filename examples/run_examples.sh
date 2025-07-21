#!/bin/bash

# Billctl Examples Runner
# Demonstrates various usage scenarios for the Professional Billing Calculator
# Run this script to see practical examples in action

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
BILLCTL="../billctl"
FACTURATOR_BASH="../calcular_facturacion.sh"
PAUSE_BETWEEN_EXAMPLES=2

# Helper functions
print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_subheader() {
    echo -e "\n${CYAN}--- $1 ---${NC}"
}

print_example() {
    echo -e "\n${YELLOW}Example: $1${NC}"
    echo -e "${PURPLE}Command: $2${NC}"
    echo ""
}

run_command() {
    local cmd="$1"
    local description="$2"

    print_example "$description" "$cmd"

    if [[ $cmd == *"bash"* ]] && [[ ! -f "$FACTURATOR_BASH" ]]; then
        echo -e "${RED}Bash version not found at $FACTURATOR_BASH${NC}"
        return
    fi

    if [[ $cmd == *"billctl"* ]] && [[ ! -f "$BILLCTL" ]]; then
        echo -e "${RED}Go binary not found at $BILLCTL${NC}"
        echo -e "${YELLOW}Run 'make build' or 'go build' first${NC}"
        return
    fi

    eval "$cmd"

    if [ $PAUSE_BETWEEN_EXAMPLES -gt 0 ]; then
        sleep $PAUSE_BETWEEN_EXAMPLES
    fi
}

check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"

    # Check for Go binary
    if [[ ! -f "$BILLCTL" ]]; then
        echo -e "${YELLOW}Go binary not found. Attempting to build...${NC}"
        if command -v go &> /dev/null; then
            (cd .. && go build -o billctl)
            if [[ -f "$BILLCTL" ]]; then
                echo -e "${GREEN}Successfully built Go binary${NC}"
            else
                echo -e "${RED}Failed to build Go binary${NC}"
            fi
        else
            echo -e "${RED}Go not installed. Only bash examples will run.${NC}"
        fi
    fi

    # Check for bash script
    if [[ ! -f "$FACTURATOR_BASH" ]]; then
        echo -e "${YELLOW}Bash script not found at $FACTURATOR_BASH${NC}"
    fi

    # Check for bc (required by bash script)
    if ! command -v bc &> /dev/null; then
        echo -e "${YELLOW}bc not installed. Bash examples may fail.${NC}"
        echo -e "${CYAN}Install with: brew install bc (macOS) or apt-get install bc (Linux)${NC}"
    fi

    echo ""
}

# Example categories
basic_examples() {
    print_header "BASIC USAGE EXAMPLES"

    run_command "$BILLCTL -h 40" "Calculate 40 hours of work"
    run_command "$BILLCTL -d 10" "Calculate 10 days of work"
    run_command "$BILLCTL -s 3" "Calculate 3 weeks of work"
    run_command "$BILLCTL -m 01" "Calculate January (current year)"
    run_command "$BILLCTL -m 2024-02" "Calculate February 2024 (leap year)"
}

monthly_examples() {
    print_header "MONTHLY CALCULATIONS"

    run_command "$BILLCTL -m 2024-01" "January 2024 (31 days)"
    run_command "$BILLCTL -m 2024-02" "February 2024 (29 days - leap year)"
    run_command "$BILLCTL -m 2023-02" "February 2023 (28 days - regular year)"
    run_command "$BILLCTL -m 2024-04" "April 2024 (30 days)"
    run_command "$BILLCTL -m 12" "December (current year)"
}

combination_examples() {
    print_header "COMBINATION CALCULATIONS"

    run_command "$BILLCTL -m 01 -d 5" "January + 5 additional days"
    run_command "$BILLCTL -s 2 -d 3 -h 4" "2 weeks + 3 days + 4 hours"
    run_command "$BILLCTL -m 2024-01 -s 1" "January 2024 + 1 week extension"
    run_command "$BILLCTL -m 01 -m 02 -m 03" "Q1: January + February + March"
    run_command "$BILLCTL -m 2024-02 -s 2 -d 5 -h 10" "Complex: February + 2 weeks + 5 days + 10 hours"
}

currency_examples() {
    print_header "CURRENCY EXAMPLES"

    run_command "$BILLCTL -d 15 --currency EUR" "15 days in Euros"
    run_command "$BILLCTL -m 03 --currency USD" "March in US Dollars"
    run_command "$BILLCTL -s 4 --currency ARS" "4 weeks in Argentine Pesos"
    run_command "$BILLCTL --rates --currency EUR" "Rate table in Euros"
    run_command "$BILLCTL -h 100 --currency GBP" "100 hours in British Pounds"
}

real_world_scenarios() {
    print_header "REAL-WORLD SCENARIOS"

    print_subheader "Freelance Project Billing"
    run_command "$BILLCTL -m 2024-01 -d 15 -h 20" "1.5 month project with extra work"

    print_subheader "Monthly Retainer Plus Extra"
    run_command "$BILLCTL -m 04 -h 32" "April retainer + 32 additional hours"

    print_subheader "Contract Extension"
    run_command "$BILLCTL -m 2024-01 -s 2" "January + 2-week extension"

    print_subheader "Emergency/Rush Work"
    run_command "$BILLCTL -h 16" "Weekend emergency work (16 hours)"

    print_subheader "Partial Month Billing"
    run_command "$BILLCTL -d 15" "First half of month"
    run_command "$BILLCTL -s 1 -d 3" "One week + 3 days"

    print_subheader "Overtime Calculation"
    run_command "$BILLCTL -m 01 -h 20" "Regular January + 20 hours overtime"
}

comparison_examples() {
    print_header "BASH vs GO PERFORMANCE COMPARISON"

    if [[ -f "$FACTURATOR_BASH" ]] && [[ -f "$BILLCTL" ]]; then
        echo -e "${CYAN}Running identical calculations with both versions...${NC}\n"

        # Simple calculation
        print_subheader "Simple Calculation: 15 days"
        echo -e "${YELLOW}Bash version:${NC}"
        time $FACTURATOR_BASH -d 15
        echo -e "\n${YELLOW}Go version:${NC}"
        time $BILLCTL -d 15

        sleep 1

        # Complex calculation
        print_subheader "Complex Calculation: January + 2 weeks + 5 days + 10 hours"
        echo -e "${YELLOW}Bash version:${NC}"
        time $FACTURATOR_BASH -m 01 -s 2 -d 5 -h 10
        echo -e "\n${YELLOW}Go version:${NC}"
        time $BILLCTL -m 01 -s 2 -d 5 -h 10

        sleep 1

        # Rate display
        print_subheader "Rate Display"
        echo -e "${YELLOW}Bash version:${NC}"
        time $FACTURATOR_BASH --tarifas
        echo -e "\n${YELLOW}Go version:${NC}"
        time $BILLCTL --rates

    else
        echo -e "${YELLOW}Comparison skipped - both versions not available${NC}"
    fi
}

error_examples() {
    print_header "ERROR HANDLING EXAMPLES"

    echo -e "${CYAN}The following examples demonstrate error handling:${NC}\n"

    print_example "Invalid month number" "$BILLCTL -m 13"
    echo -e "${RED}Expected error:${NC}"
    $BILLCTL -m 13 2>&1 || true

    echo ""

    print_example "Invalid month format" "$BILLCTL -m january"
    echo -e "${RED}Expected error:${NC}"
    $BILLCTL -m january 2>&1 || true

    echo ""

    print_example "Negative hours" "$BILLCTL -h -10"
    echo -e "${RED}Expected error:${NC}"
    $BILLCTL -h -10 2>&1 || true

    echo ""

    print_example "No arguments" "$BILLCTL"
    echo -e "${YELLOW}Expected: Help message${NC}"
    $BILLCTL 2>&1 || true
}

rate_table_examples() {
    print_header "RATE TABLE EXAMPLES"

    run_command "$BILLCTL --rates" "Default rates (U\$S)"
    run_command "$BILLCTL --rates --currency EUR" "Rates in Euros"
    run_command "$BILLCTL --rates --currency USD" "Rates in US Dollars"
}

automation_examples() {
    print_header "AUTOMATION EXAMPLES"

    print_subheader "Quarterly Calculations"
    echo -e "${CYAN}Calculating Q1 2024 billing:${NC}"
    echo ""

    for month in 01 02 03; do
        echo -e "${YELLOW}Month $month:${NC}"
        $BILLCTL -m 2024-$month --currency USD
        echo ""
    done

    print_subheader "Weekly Pattern Analysis"
    echo -e "${CYAN}Comparing different weekly patterns:${NC}"
    echo ""

    patterns=("1:1 week" "2:2 weeks" "3:3 weeks" "4:4 weeks")
    for pattern in "${patterns[@]}"; do
        weeks=$(echo $pattern | cut -d: -f1)
        desc=$(echo $pattern | cut -d: -f2)
        echo -e "${YELLOW}$desc:${NC}"
        $BILLCTL -s $weeks
        echo ""
    done
}

performance_stress_test() {
    print_header "PERFORMANCE STRESS TEST"

    echo -e "${CYAN}Running performance tests with large calculations...${NC}\n"

    if [[ -f "$BILLCTL" ]]; then
        print_subheader "Large Hour Calculation"
        echo -e "${YELLOW}Calculating 10,000 hours:${NC}"
        time $BILLCTL -h 10000

        echo ""

        print_subheader "Multiple Large Values"
        echo -e "${YELLOW}Complex large calculation:${NC}"
        time $BILLCTL -h 1000 -d 500 -s 100

        echo ""

        print_subheader "Many Months"
        echo -e "${YELLOW}Full year calculation:${NC}"
        time $BILLCTL -m 2024-01 -m 2024-02 -m 2024-03 -m 2024-04 -m 2024-05 -m 2024-06 -m 2024-07 -m 2024-08 -m 2024-09 -m 2024-10 -m 2024-11 -m 2024-12
    else
        echo -e "${RED}Go binary not available for performance testing${NC}"
    fi
}

interactive_mode() {
    print_header "INTERACTIVE MODE"

    echo -e "${CYAN}Interactive examples - choose what to run:${NC}\n"

    options=(
        "Basic Examples"
        "Monthly Calculations"
        "Combination Examples"
        "Currency Examples"
        "Real-World Scenarios"
        "Performance Comparison"
        "Error Handling"
        "Rate Tables"
        "Automation Examples"
        "Performance Stress Test"
        "Run All Examples"
        "Exit"
    )

    PS3="Select an option: "
    select opt in "${options[@]}"; do
        case $opt in
            "Basic Examples")
                basic_examples
                ;;
            "Monthly Calculations")
                monthly_examples
                ;;
            "Combination Examples")
                combination_examples
                ;;
            "Currency Examples")
                currency_examples
                ;;
            "Real-World Scenarios")
                real_world_scenarios
                ;;
            "Performance Comparison")
                comparison_examples
                ;;
            "Error Handling")
                error_examples
                ;;
            "Rate Tables")
                rate_table_examples
                ;;
            "Automation Examples")
                automation_examples
                ;;
            "Performance Stress Test")
                performance_stress_test
                ;;
            "Run All Examples")
                run_all_examples
                break
                ;;
            "Exit")
                echo -e "${GREEN}Goodbye!${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option. Please try again.${NC}"
                ;;
        esac
        echo -e "\n${BLUE}Select another option or choose 'Exit':${NC}"
    done
}

run_all_examples() {
    print_header "RUNNING ALL EXAMPLES"

    echo -e "${CYAN}This will run all available examples. It may take a few minutes...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to interrupt at any time.${NC}\n"

    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        return
    fi

    basic_examples
    monthly_examples
    combination_examples
    currency_examples
    real_world_scenarios
    rate_table_examples
    automation_examples
    comparison_examples
    error_examples
    performance_stress_test

    print_header "ALL EXAMPLES COMPLETED"
    echo -e "${GREEN}✅ All examples have been successfully demonstrated!${NC}"
}

show_help() {
    cat << EOF
Billctl Examples Runner

Usage: $0 [option]

Options:
  -a, --all          Run all examples
  -b, --basic        Run basic examples only
  -m, --monthly      Run monthly calculation examples
  -c, --combination  Run combination examples
  -r, --real-world   Run real-world scenario examples
  -p, --performance  Run performance comparison
  -e, --error        Run error handling examples
  -i, --interactive  Run in interactive mode
  -q, --quick        Run quick examples (no pauses)
  -h, --help         Show this help message

Examples:
  $0 -a              # Run all examples
  $0 -b              # Run basic examples only
  $0 -i              # Interactive mode
  $0 -q -b           # Quick basic examples

EOF
}

# Main execution
main() {
    # Parse command line arguments
    case "${1:-}" in
        -a|--all)
            check_prerequisites
            run_all_examples
            ;;
        -b|--basic)
            check_prerequisites
            basic_examples
            ;;
        -m|--monthly)
            check_prerequisites
            monthly_examples
            ;;
        -c|--combination)
            check_prerequisites
            combination_examples
            ;;
        -r|--real-world)
            check_prerequisites
            real_world_scenarios
            ;;
        -p|--performance)
            check_prerequisites
            comparison_examples
            ;;
        -e|--error)
            check_prerequisites
            error_examples
            ;;
        -i|--interactive)
            check_prerequisites
            interactive_mode
            ;;
        -q|--quick)
            PAUSE_BETWEEN_EXAMPLES=0
            case "${2:-}" in
                -b|--basic)
                    check_prerequisites
                    basic_examples
                    ;;
                *)
                    check_prerequisites
                    run_all_examples
                    ;;
            esac
            ;;
        -h|--help|"")
            show_help
            if [[ -z "${1:-}" ]]; then
                echo -e "\n${CYAN}Running in interactive mode...${NC}"
                check_prerequisites
                interactive_mode
            fi
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Welcome message
echo -e "${WHITE}🧮 Billctl Examples Runner${NC}"
echo -e "${CYAN}Demonstrating the Professional Billing Calculator${NC}"
echo -e "${YELLOW}For help, run: $0 --help${NC}"

# Run main function with all arguments
main "$@"
