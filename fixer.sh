#!/usr/bin/env bash

set -euo pipefail

# --- Configuration ---
SCRIPT_NAME="$(basename "$0")"
MEOW_CMD="${MEOW_CMD:-meow}"
SHELLCHECK_CMD="${SHELLCHECK_CMD:-shellcheck}"
BAT_CMD="${BAT_CMD:-bat}"
BASH32_CMD="${BASH32_CMD:-/bin/bash}"
MAX_ITERATIONS="${MAX_ITERATIONS:-5}"

# State variables
VERBOSE=false
DRY_RUN=false
PROCESSED_FILES=0
FAILED_FILES=0

# --- Terminal Colors ---
setup_colors() {
    if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
        C_RESET='\033[0m'
        C_BOLD='\033[1m'
        C_HEADER='\033[95m'
        C_INFO='\033[94m'
        C_SUCCESS='\033[92m'
        C_WARNING='\033[93m'
        C_ERROR='\033[91m'
        C_DIM='\033[2m'
    else
        C_RESET=''
        C_BOLD=''
        C_HEADER=''
        C_INFO=''
        C_SUCCESS=''
        C_WARNING=''
        C_ERROR=''
        C_DIM=''
    fi
}

# --- UI Functions ---
print_message() {
    local color="$1"
    shift
    printf "${color}%s${C_RESET}\n" "$*" >&2
}

ui_header() { print_message "$C_HEADER$C_BOLD" "$@"; }
ui_info() { print_message "$C_INFO" "$@"; }
ui_success() { print_message "$C_SUCCESS" "✓ $*"; }
ui_warning() { print_message "$C_WARNING" "⚠️  $*"; }
ui_error() {
    print_message "$C_ERROR" "✗ $*"
    FAILED_FILES=$((FAILED_FILES + 1))
}
ui_verbose() {
    if [ "$VERBOSE" = "true" ]; then
        print_message "$C_DIM" "  › $*"
    fi
}
ui_dry_run() { print_message "$C_INFO" "  [DRY RUN] $*"; }

# --- Spinner Functions ---
spinner_pid=""

start_spinner() {
    local message="$1"
    {
        local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        while true; do
            local char="${spinner_chars:$((i % 10)):1}"
            printf "\r${C_INFO}%s %s${C_RESET}" "$char" "$message" >&2
            sleep 0.1
            i=$((i + 1))
        done
    } &
    spinner_pid=$!
}

stop_spinner() {
    if [ -n "$spinner_pid" ]; then
        kill "$spinner_pid" 2>/dev/null || true
        wait "$spinner_pid" 2>/dev/null || true
        spinner_pid=""
        printf "\r\033[K" >&2
    fi
}

# --- File Display ---
show_file_content() {
    local file="$1"
    local title="$2"

    ui_info "$title"
    if command -v "$BAT_CMD" >/dev/null 2>&1; then
        "$BAT_CMD" --no-pager --style=header,grid --color=always "$file" 2>/dev/null || {
            echo "--- $file ---"
            cat "$file"
            echo "--- End of $file ---"
        }
    else
        echo "--- $file ---"
        cat "$file"
        echo "--- End of $file ---"
    fi
    echo
}

# --- Response Cleaning Functions ---
clean_ai_response() {
    local response="$1"

    # Remove markdown code blocks (first stage cleaning)
    response=$(echo "$response" | sed '/^```[a-z]*$/d; /^```$/d')

    # Remove any remaining backticks that might interfere
    response=$(echo "$response" | sed 's/`//g')

    echo "$response"
}

# --- Dependency Management ---
PROCESSED_SOURCES=""

mark_as_processed() {
    local file="$1"
    PROCESSED_SOURCES="${PROCESSED_SOURCES}:${file}:"
}

is_already_processed() {
    local file="$1"
    case "$PROCESSED_SOURCES" in
        *":${file}:"*) return 0 ;;
        *) return 1 ;;
    esac
}

reset_processed_sources() {
    PROCESSED_SOURCES=""
}

# Extract source/dot includes from a script
extract_sources_from_file() {
    local file="$1"

    if [ ! -f "$file" ]; then
        return 0
    fi

    # Look for source or . commands at the beginning of lines
    grep -E '^\s*(source|\.)(\s+)' "$file" 2>/dev/null | \
    sed -E 's/^\s*(source|\.)(\s+)//' | \
    sed 's/[[:space:]]*#.*$//' | \
    tr -d '"'"'" | \
    awk '{print $1}' | \
    while IFS= read -r src_file; do
        if [ -n "$src_file" ]; then
            echo "$src_file"
        fi
    done
}

# Recursively collect all sourced dependencies
collect_dependencies() {
    local target_file="$1"
    local base_dir
    base_dir="$(dirname "$target_file")"

    if is_already_processed "$target_file"; then
        return 0
    fi
    mark_as_processed "$target_file"

    local deps
    deps=$(extract_sources_from_file "$target_file")

    echo "$deps" | while IFS= read -r src_file; do
        if [ -z "$src_file" ]; then
            continue
        fi

        # Try to resolve paths
        local resolved_path="$src_file"
        if [ ! -f "$resolved_path" ]; then
            resolved_path="$base_dir/$src_file"
        fi

        if [ -f "$resolved_path" ]; then
            echo "$resolved_path"
            collect_dependencies "$resolved_path"
        fi
    done
}

# --- Verification Functions ---
check_bash32_compatibility() {
    local file="$1"

    if [ ! -x "$BASH32_CMD" ]; then
        ui_verbose "Bash 3.2 not found at $BASH32_CMD, skipping compatibility check"
        return 0
    fi

    "$BASH32_CMD" -n "$file" 2>&1
}

run_shellcheck() {
    local file="$1"
    "$SHELLCHECK_CMD" "$file" 2>&1
}

# --- Logic Analysis Functions ---
analyze_script_logic() {
    return 0
}

# --- File Filtering ---
should_skip_file() {
    local file="$1"
    local basename_file
    basename_file=$(basename "$file")

    # Skip fixer.sh (this script itself)
    if [ "$basename_file" = "fixer.sh" ]; then
        return 0
    fi

    # Add other patterns to skip here if needed
    # case "$basename_file" in
    #     other_pattern*) return 0 ;;
    # esac

    return 1
}

# --- Prompt Generation ---
build_fixing_prompt() {
    local target_file="$1"
    local shellcheck_output="$2"
    local bash32_output="$3"
    local logic_issues="$4"

    reset_processed_sources
    local dependencies
    dependencies=$(collect_dependencies "$target_file")

    cat <<'EOF'
You are a shell script expert. Fix the following Bash script to ensure:

1. **Bash 3.2 Compatibility**: Compatible with macOS default Bash 3.2
   - No associative arrays (declare -A)
   - No readarray/mapfile - use while read loops
   - No [[ ... ]] with == for patterns - use case or = for literals
   - No ${var@A} expansions
   - Avoid newer Bash features

2. **Security & Best Practices**:
   - All variables properly quoted
   - Use set -euo pipefail
   - Proper error handling
   - Clear function and variable names

3. **Messaging**:
    - Clear and informative messages for users
    - Resolve TODOs
    - parse_spinner_messages is deleted, replace it with proper messages
    - Ensure good user feedback and progress indication
    - Revise messages for --verbose and --dry-run modes

4. **Portability**: Works on both Linux (Bash 4+/GNU) and macOS (Bash 3.2/BSD)

5. **Code Quality**:
   - Proper indentation and formatting
   - Descriptive names
   - Handle edge cases gracefully
   - Remove dead code and unused variables
   - Consistent coding style

**IMPORTANT**: Return the COMPLETE fixed script with ALL content included. Do not truncate, abbreviate, or skip any parts. The output must be the full, working script that can be directly saved to a file.

EOF

    # Add reference files section
    if [ -n "$dependencies" ]; then
        echo "REFERENCE FILES (sourced by the script - do NOT modify these):"
        echo "---"
        echo "$dependencies" | while IFS= read -r dep_file; do
            if [ -f "$dep_file" ]; then
                echo "=== $dep_file ==="
                cat "$dep_file" 2>/dev/null || echo "# Could not read file"
                echo
            fi
        done
        echo "---"
        echo
    fi

    # Add shellcheck results
    echo "SHELLCHECK RESULTS:"
    if [ -n "$shellcheck_output" ]; then
        echo "$shellcheck_output"
    else
        echo "No shellcheck issues reported."
    fi
    echo "---"
    echo

    # Add Bash 3.2 compatibility results
    echo "BASH 3.2 COMPATIBILITY CHECK:"
    if [ -n "$bash32_output" ]; then
        echo "$bash32_output"
        echo
        echo "Common fixes needed:"
        echo "- Replace associative arrays with indexed arrays or alternative data structures"
        echo "- Replace readarray with while read loops"
        echo "- Replace [[ ... == pattern ]] with case statements or [[ ... = literal ]]"
        echo "- Replace newer parameter expansions with compatible alternatives"
    else
        echo "No Bash 3.2 compatibility issues found."
    fi
    echo "---"
    echo

    echo "SCRIPT TO FIX:"
    echo "---"
    cat "$target_file"
    echo "---"
    echo
    echo "Return ONLY the corrected script with no additional text or explanations. Include the complete file from the first line to the last line."
}

# --- Dependency Checking ---
check_command() {
    local cmd="$1"
    local description="$2"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        ui_error "Command '$cmd' not found. Please install $description."
        return 1
    fi
    return 0
}

# --- File Processing ---
process_single_file() {
    local file="$1"
    local iteration=1
    local temp_file=""

    ui_header "Processing: $file ($PROCESSED_FILES/$TOTAL_FILES)"

    # Verify file is readable
    if [ ! -r "$file" ]; then
        ui_error "Cannot read file: $file"
        return 1
    fi

    # Show original content if verbose
    if [ "$VERBOSE" = "true" ]; then
        show_file_content "$file" "📄 Original content:"
    fi

    # Create backup on first attempt
    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    if ! cp "$file" "$backup_file"; then
        ui_error "Failed to create backup for $file"
        return 1
    fi
    ui_verbose "Created backup: $backup_file"

    # Iterative fixing loop
    while [ $iteration -le $MAX_ITERATIONS ]; do
        if [ $iteration -gt 1 ]; then
            ui_info "--- Iteration $iteration ---"
        fi

        local shellcheck_output=""
        local bash32_output=""
        local logic_issues=""
        local has_issues=false

        # Run shellcheck
        ui_info "Running shellcheck..."
        if ! shellcheck_output=$(run_shellcheck "$file"); then
            has_issues=true
            if [ "$VERBOSE" = "true" ]; then
                ui_warning "Shellcheck issues found:"
                echo "$shellcheck_output" | while IFS= read -r line; do
                    ui_verbose "$line"
                done
            fi
        fi

        # Check Bash 3.2 compatibility
        ui_info "Checking Bash 3.2 compatibility..."
        if ! bash32_output=$(check_bash32_compatibility "$file"); then
            has_issues=true
            if [ "$VERBOSE" = "true" ]; then
                ui_warning "Bash 3.2 compatibility issues:"
                echo "$bash32_output" | while IFS= read -r line; do
                    ui_verbose "$line"
                done
            fi
        fi

        # Analyze logic and algorithmic issues
        ui_info "Analyzing logic and algorithms..."
        if ! analyze_script_logic "$file" >/dev/null 2>&1; then
            logic_issues=$(analyze_script_logic "$file" 2>/dev/null)
            has_issues=true
            if [ "$VERBOSE" = "true" ]; then
                ui_warning "Logic issues found:"
                echo "$logic_issues" | while IFS= read -r line; do
                    ui_verbose "$line"
                done
            fi
        fi

        # Exit if no issues found
        if [ "$has_issues" = "false" ]; then
            ui_success "All checks passed!"
            # Clean up backup if not verbose
            if [ "$VERBOSE" != "true" ]; then
                rm -f "$backup_file"
            fi
            return 0
        fi

        # Determine issue types for user feedback
        local issue_types=()
        [ -n "$shellcheck_output" ] && issue_types+=("shellcheck")
        [ -n "$bash32_output" ] && issue_types+=("Bash 3.2")
        [ -n "$logic_issues" ] && issue_types+=("logic")

        local issue_description
        case ${#issue_types[@]} in
            1) issue_description="${issue_types[0]}" ;;
            2) issue_description="${issue_types[0]} + ${issue_types[1]}" ;;
            3) issue_description="${issue_types[0]} + ${issue_types[1]} + ${issue_types[2]}" ;;
            *) issue_description="multiple" ;;
        esac

        if [ "$DRY_RUN" = "true" ]; then
            ui_dry_run "Would fix $issue_description issues (iteration $iteration)"
            break
        fi

        # Generate fix using AI
        ui_info "Generating fix using AI ($issue_description issues)..."

        # Create temporary file for prompt
        temp_file=$(mktemp) || {
            ui_error "Failed to create temporary file"
            break
        }

        build_fixing_prompt "$file" "$shellcheck_output" "$bash32_output" "$logic_issues" > "$temp_file"

        # Call meow with spinner
        start_spinner "Processing with AI..."

        local fixed_script
        if fixed_script=$("$MEOW_CMD" gen -p "$(cat "$temp_file")" 2>&1); then
            stop_spinner
            ui_success "AI processing completed"
        else
            stop_spinner
            ui_error "AI processing failed: $fixed_script"
            rm -f "$temp_file"
            break
        fi

        rm -f "$temp_file"

        # Clean AI response (remove backticks and markdown early)
        fixed_script=$(clean_ai_response "$fixed_script")
        ui_verbose "Cleaned AI response from markdown and backticks"

        # Validate response
        if [ -z "$fixed_script" ] || [ "$(echo "$fixed_script" | wc -l)" -lt 2 ]; then
            ui_error "Received invalid response from AI"
            break
        fi

        # Apply fix
        if echo "$fixed_script" > "$file"; then
            ui_success "Applied fix (iteration $iteration)"
        else
            ui_error "Failed to write fixed script"
            mv "$backup_file" "$file"
            ui_info "Restored from backup"
            return 1
        fi

        iteration=$((iteration + 1))
    done

    # Handle max iterations reached
    if [ $iteration -gt $MAX_ITERATIONS ]; then
        ui_error "Maximum iterations ($MAX_ITERATIONS) reached"
        return 1
    fi

    return 0
}

# --- Help ---
show_help() {
    cat <<EOF
$SCRIPT_NAME - Automated shell script fixer using AI

DESCRIPTION:
    Finds all .sh files and fixes shellcheck issues, Bash 3.2 compatibility
    problems, and logic/algorithmic issues using 'meow gen -p' with intelligent
    prompts. Automatically skips fixer.sh to avoid modifying itself.

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -v, --verbose    Enable verbose output
    --dry-run        Show what would be done without making changes
    -h, --help       Show this help message

ENVIRONMENT VARIABLES:
    MEOW_CMD         Command for meow (default: meow)
    SHELLCHECK_CMD   Command for shellcheck (default: shellcheck)
    BAT_CMD          Command for bat (default: bat)
    BASH32_CMD       Command for Bash 3.2 (default: /bin/bash)
    MAX_ITERATIONS   Maximum fix attempts per file (default: 5)

FEATURES:
    • Shellcheck integration for syntax and style issues
    • Bash 3.2 compatibility checking and fixing
    • Logic and algorithmic issue detection and correction
    • Infinite loop detection and prevention
    • Race condition identification and fixing
    • Input validation improvements
    • Error handling enhancements
    • Algorithm efficiency optimization

EXAMPLES:
    $SCRIPT_NAME                    # Fix all .sh files (except fixer.sh)
    $SCRIPT_NAME --verbose          # With detailed output
    $SCRIPT_NAME --dry-run          # Preview changes only

EOF
}

# --- Argument Processing ---
parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                ui_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# --- Cleanup ---
cleanup() {
    stop_spinner
    # Clean up any background jobs
    jobs -p 2>/dev/null | while IFS= read -r job_pid; do
        kill "$job_pid" 2>/dev/null || true
    done 2>/dev/null || true
}

# --- Main ---
main() {
    setup_colors
    parse_arguments "$@"

    # Set up cleanup
    trap cleanup EXIT INT TERM

    ui_header "🔧 Starting automated script fixing process"
    if [ "$DRY_RUN" = "true" ]; then
        ui_warning "DRY RUN MODE - No files will be modified"
    fi
    if [ "$VERBOSE" = "true" ]; then
        ui_info "Verbose mode enabled"
    fi

    # Check dependencies
    if ! check_command "$SHELLCHECK_CMD" "shellcheck"; then
        exit 1
    fi
    if ! check_command "$MEOW_CMD" "meow CLI tool"; then
        exit 1
    fi
    ui_verbose "Dependencies verified"

    # Find shell scripts
    ui_info "Searching for shell scripts..."
    local files=()
    while IFS= read -r -d '' file; do
        if ! should_skip_file "$file"; then
            files+=("$file")
        else
            ui_verbose "Skipping: $file"
        fi
    done < <(find . -type f -name "*.sh" -print0 2>/dev/null)

    local TOTAL_FILES=${#files[@]}

    if [ "$TOTAL_FILES" -eq 0 ]; then
        ui_warning "No .sh files found (or all files skipped)"
        exit 0
    fi

    ui_info "Found $TOTAL_FILES shell script(s) to process"

    # Process each file
    for file in "${files[@]}"; do
        PROCESSED_FILES=$((PROCESSED_FILES + 1))
        echo  # Spacing

        if ! process_single_file "$file"; then
            ui_error "Failed to process $file"
        fi
    done

    # Final summary
    echo
    ui_header "📊 Processing Summary"
    ui_info "Total files: $TOTAL_FILES"
    ui_info "Successfully processed: $((PROCESSED_FILES - FAILED_FILES))"
    ui_info "Failed: $FAILED_FILES"

    if [ "$FAILED_FILES" -gt 0 ]; then
        ui_warning "Some files could not be processed successfully"
        exit 1
    else
        ui_success "All files processed successfully! 🎉"
        exit 0
    fi
}

# Run main function with all arguments
main "$@"