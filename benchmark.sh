#!/bin/bash

# Performance benchmark script for facturator
# Compares bash vs Go implementation performance
# Author: DevelPudu (https://github.com/develpudu)
# Date: 2025-07-17

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ITERATIONS=100
BASH_SCRIPT="./calcular_facturacion.sh"
GO_BINARY="./facturator"
RESULTS_FILE="benchmark_results.txt"

# Test cases
declare -a TEST_CASES=(
    "Simple hours|-h 120"
    "Simple days|-d 15"
    "Simple weeks|-s 2"
    "Simple month|-m 02"
    "Complex month|-m 2024-01"
    "Leap year Feb|-m 2024-02"
    "Combined simple|-d 5 -h 8"
    "Combined complex|-m 01 -d 5 -s 1"
    "Multiple months|-m 2024-01 -m 2024-02"
    "Full combination|-m 01 -s 2 -d 3 -h 4"
    "Large calculation|-h 500 -d 100 -s 10"
    "Show rates|--tarifas"
)

# Function to check if required tools are available
check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"

    # Check if bash script exists
    if [ ! -f "$BASH_SCRIPT" ]; then
        echo -e "${RED}Error: Bash script not found at $BASH_SCRIPT${NC}"
        exit 1
    fi

    # Make sure bash script is executable
    chmod +x "$BASH_SCRIPT"

    # Check if Go binary exists, if not try to build it
    if [ ! -f "$GO_BINARY" ]; then
        echo -e "${YELLOW}Go binary not found. Building...${NC}"
        if ! go build -o "$GO_BINARY" .; then
            echo -e "${RED}Error: Failed to build Go binary${NC}"
            exit 1
        fi
    fi

    # Check if bc is available (required by bash script)
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}Error: bc is required for bash script but not installed${NC}"
        exit 1
    fi

    # Check if time command is available
    if ! command -v time &> /dev/null; then
        echo -e "${RED}Error: time command not available${NC}"
        exit 1
    fi

    echo -e "${GREEN}All prerequisites satisfied${NC}"
}

# Function to run a single test and measure time
run_timed_test() {
    local cmd="$1"
    local iterations="$2"
    local total_time=0

    for ((i=1; i<=iterations; i++)); do
        # Use time command to measure execution time
        local execution_time=$( { time $cmd > /dev/null 2>&1; } 2>&1 | grep real | awk '{print $2}' | sed 's/[ms]//g' )

        # Convert time to milliseconds if needed
        if [[ $execution_time == *"s"* ]]; then
            execution_time=$(echo "$execution_time" | sed 's/s//')
            execution_time=$(echo "$execution_time * 1000" | bc -l)
        fi

        total_time=$(echo "$total_time + $execution_time" | bc -l)
    done

    # Calculate average
    local avg_time=$(echo "scale=3; $total_time / $iterations" | bc -l)
    echo "$avg_time"
}

# Function to run benchmark for a specific test case
run_benchmark() {
    local test_name="$1"
    local test_args="$2"

    echo -e "${BLUE}Running benchmark: $test_name${NC}"
    echo "Test args: $test_args"

    # Handle special case for rates display (different flags for bash vs go)
    local bash_args="$test_args"
    local go_args="$test_args"

    if [[ "$test_args" == *"--tarifas"* ]]; then
        go_args=$(echo "$test_args" | sed 's/--tarifas/--rates/')
    fi

    # Run bash version
    echo -n "  Bash script: "
    local bash_time=$(run_timed_test "$BASH_SCRIPT $bash_args" $ITERATIONS)
    echo "${bash_time}ms (avg over $ITERATIONS runs)"

    # Run Go version
    echo -n "  Go binary:   "
    local go_time=$(run_timed_test "$GO_BINARY $go_args" $ITERATIONS)
    echo "${go_time}ms (avg over $ITERATIONS runs)"

    # Calculate improvement
    local improvement=$(echo "scale=2; ($bash_time - $go_time) / $bash_time * 100" | bc -l)
    local speedup=$(echo "scale=2; $bash_time / $go_time" | bc -l)

    if (( $(echo "$go_time < $bash_time" | bc -l) )); then
        echo -e "  ${GREEN}Go is ${improvement}% faster (${speedup}x speedup)${NC}"
    else
        local slowdown=$(echo "scale=2; $go_time / $bash_time" | bc -l)
        echo -e "  ${RED}Go is slower by ${slowdown}x${NC}"
    fi

    echo ""

    # Save results to file
    echo "$test_name,$bash_time,$go_time,$improvement,$speedup" >> "$RESULTS_FILE"
}

# Function to verify output consistency
verify_output_consistency() {
    echo -e "${BLUE}Verifying output consistency...${NC}"

    local test_cases_for_verification=(
        "-h 120"
        "-d 15"
        "-s 2"
        "-m 2024-01"
        "-d 5 -h 8"
    )

    local inconsistencies=0

    for test_case in "${test_cases_for_verification[@]}"; do
        echo "Testing: $test_case"

        # Get outputs (remove timing/formatting differences)
        local bash_output=$($BASH_SCRIPT $test_case 2>/dev/null | grep -E "(Total de horas|TOTAL A FACTURAR)" | tr -d ' ')
        local go_output=$($GO_BINARY $test_case 2>/dev/null | grep -E "(Total de horas|TOTAL A FACTURAR)" | tr -d ' ')

        if [ "$bash_output" != "$go_output" ]; then
            echo -e "  ${RED}Inconsistency found!${NC}"
            echo "  Bash: $bash_output"
            echo "  Go:   $go_output"
            inconsistencies=$((inconsistencies + 1))
        else
            echo -e "  ${GREEN}✓ Outputs match${NC}"
        fi
    done

    if [ $inconsistencies -eq 0 ]; then
        echo -e "${GREEN}All outputs are consistent!${NC}"
    else
        echo -e "${RED}Found $inconsistencies inconsistencies!${NC}"
    fi
    echo ""
}

# Function to test error handling performance
test_error_handling() {
    echo -e "${BLUE}Testing error handling performance...${NC}"

    local error_cases=(
        "--invalid-flag"
        "-m 13"
        "-m invalid"
        "-h -5"
        "-d -10"
    )

    for error_case in "${error_cases[@]}"; do
        echo "Testing error case: $error_case"

        # Test bash script
        echo -n "  Bash: "
        local bash_time=$( { time $BASH_SCRIPT $error_case > /dev/null 2>&1; } 2>&1 | grep real | awk '{print $2}' )
        echo "$bash_time"

        # Test Go binary
        echo -n "  Go:   "
        local go_time=$( { time $GO_BINARY $error_case > /dev/null 2>&1; } 2>&1 | grep real | awk '{print $2}' )
        echo "$go_time"
        echo ""
    done
}

# Function to test memory usage
test_memory_usage() {
    echo -e "${BLUE}Testing memory usage...${NC}"

    local test_case="-m 2024-01 -m 2024-02 -m 2024-03 -s 5 -d 10 -h 50"

    echo "Test case: $test_case"

    # Test bash script memory usage
    if command -v valgrind &> /dev/null; then
        echo "  Using valgrind for memory measurement..."
        valgrind --tool=massif --pages-as-heap=yes --massif-out-file=massif.bash.out $BASH_SCRIPT $test_case > /dev/null 2>&1
        valgrind --tool=massif --pages-as-heap=yes --massif-out-file=massif.go.out $GO_BINARY $test_case > /dev/null 2>&1
        echo "  Memory usage files: massif.bash.out, massif.go.out"
    elif command -v time &> /dev/null; then
        echo "  Using time command for basic memory measurement..."
        echo -n "  Bash max memory: "
        /usr/bin/time -v $BASH_SCRIPT $test_case 2>&1 | grep "Maximum resident set size" | awk '{print $6}' || echo "N/A"
        echo -n "  Go max memory: "
        /usr/bin/time -v $GO_BINARY $test_case 2>&1 | grep "Maximum resident set size" | awk '{print $6}' || echo "N/A"
    else
        echo "  Memory measurement tools not available"
    fi
    echo ""
}

# Function to generate report
generate_report() {
    echo -e "${BLUE}Generating final report...${NC}"

    if [ ! -f "$RESULTS_FILE" ]; then
        echo -e "${RED}No results file found!${NC}"
        return
    fi

    echo "=== BENCHMARK REPORT ===" | tee benchmark_report.txt
    echo "Date: $(date)" | tee -a benchmark_report.txt
    echo "Iterations per test: $ITERATIONS" | tee -a benchmark_report.txt
    echo "" | tee -a benchmark_report.txt

    # Calculate overall statistics
    local total_tests=$(wc -l < "$RESULTS_FILE")
    local avg_bash_time=$(awk -F',' '{sum+=$2} END {print sum/NR}' "$RESULTS_FILE")
    local avg_go_time=$(awk -F',' '{sum+=$3} END {print sum/NR}' "$RESULTS_FILE")
    local avg_improvement=$(awk -F',' '{sum+=$4} END {print sum/NR}' "$RESULTS_FILE")

    echo "Overall Statistics:" | tee -a benchmark_report.txt
    echo "  Total tests: $total_tests" | tee -a benchmark_report.txt
    echo "  Average bash time: ${avg_bash_time}ms" | tee -a benchmark_report.txt
    echo "  Average Go time: ${avg_go_time}ms" | tee -a benchmark_report.txt
    echo "  Average improvement: ${avg_improvement}%" | tee -a benchmark_report.txt
    echo "" | tee -a benchmark_report.txt

    echo "Detailed Results:" | tee -a benchmark_report.txt
    echo "Test Name,Bash Time (ms),Go Time (ms),Improvement (%),Speedup (x)" | tee -a benchmark_report.txt
    cat "$RESULTS_FILE" | tee -a benchmark_report.txt

    echo "" | tee -a benchmark_report.txt
    echo "=== CONCLUSION ===" | tee -a benchmark_report.txt

    if (( $(echo "$avg_improvement > 0" | bc -l) )); then
        echo -e "${GREEN}Go implementation is on average ${avg_improvement}% faster than bash${NC}" | tee -a benchmark_report.txt
    else
        echo -e "${RED}Bash implementation is faster on average${NC}" | tee -a benchmark_report.txt
    fi
}

# Main execution
main() {
    echo -e "${YELLOW}=== FACTURATOR PERFORMANCE BENCHMARK ===${NC}"
    echo ""

    # Initialize results file
    echo "test_name,bash_time_ms,go_time_ms,improvement_percent,speedup" > "$RESULTS_FILE"

    # Run all checks and tests
    check_prerequisites
    echo ""

    verify_output_consistency

    # Run benchmarks for all test cases
    echo -e "${BLUE}Running performance benchmarks...${NC}"
    for test_case in "${TEST_CASES[@]}"; do
        IFS='|' read -r test_name test_args <<< "$test_case"
        run_benchmark "$test_name" "$test_args"
    done

    test_error_handling
    test_memory_usage
    generate_report

    echo -e "${GREEN}Benchmark completed! Check benchmark_report.txt for detailed results.${NC}"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
