# Greeting System Functional API

The greeting system now provides functional versions of key functions that reduce global variable dependencies and improve testability.

## Functional Functions

### System Information

**get_system_info_structured()**
- Returns system info as key-value pairs instead of setting global variables
- Output format: `KEY=value` pairs, one per line
- Available keys: `DATE_FULL`, `TIME_CURRENT`, `OS_INFO`, `UPTIME_INFO`, `HOME_DISK_SPACE`, `RAM_STATS`, `OUTDATED_PACKAGES`, `HOUR_NUM`

```bash
# Usage example
system_info=$(get_system_info_structured)
while IFS='=' read -r key value; do
  case "$key" in
    DATE_FULL) date_full="$value" ;;
    TIME_CURRENT) time_current="$value" ;;
  esac
done <<< "$system_info"
```

### Art Loading

**load_art_functional(art_file, result_array_name)**
- Takes art file path and result array name as parameters
- Loads ASCII art without modifying global `art` array
- Better for testing and modularity

```bash
# Usage example
my_art=()
load_art_functional "assets/ascii/greeting.ascii" my_art
echo "Loaded ${#my_art[@]} art lines"
```

### Greeting Building

**build_greeting_functional(hour_num, date_full, time_current, result_array_name)**
- Takes system info parameters and result array name
- Builds greeting without modifying global `commentary_lines` array
- Enables testing with specific inputs

```bash
# Usage example
my_greeting=()
build_greeting_functional 14 "Wednesday, July 16, 2025" "14:30:00" my_greeting
echo "Built ${#my_greeting[@]} greeting lines"
```

## Benefits

### Improved Testability
- Functions can be tested with specific inputs
- No need to set up global state for testing
- Easier to write unit tests

### Reduced Coupling
- Functions don't depend on global variables
- Clearer function interfaces
- Better separation of concerns

### Better Maintainability
- Easier to understand what each function needs
- Less hidden dependencies
- More predictable behavior

## Backward Compatibility

All original functions remain unchanged:
- `get_system_info()` - Still sets global variables
- `load_art()` - Still uses global `art` array
- `build_greeting()` - Still uses global `commentary_lines` array
- `show_greeting()` - Works exactly the same

## Migration Path

To gradually adopt the functional approach:

1. Use functional versions for new code
2. Consider refactoring existing code to use functional versions
3. Original functions provide a stable API during transition

## Example Usage

See `show_greeting_functional_demo()` in `lib/greeting/greeting.sh` for a complete example of using the functional API.