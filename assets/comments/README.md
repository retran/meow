# Greeting System Comments Configuration

The greeting system uses YAML configuration files to manage comments and messages, making them easily customizable without modifying code.

## Configuration Files

Comments are organized in `assets/comments/` directory:

- `uptime.yaml` - System uptime related comments
- `disk.yaml` - Disk space related comments  
- `ram.yaml` - Memory usage related comments
- `package.yaml` - Package update related comments
- `task.yaml` - Task management related comments
- `greeting.yaml` - Time-based greeting messages

## YAML Structure

Each file follows this structure:

```yaml
category:
  subcategory:
    - "Comment option 1"
    - "Comment option 2"
    - "Comment option 3"
```

### Example: uptime.yaml

```yaml
uptime:
  base:
    - "such endurance!"
    - "running longer than a cat nap!"
  hours:
    - "Recently awakened from its slumber!"
    - "Fresh and ready for a productive session!"
  fallback:
    - "your system's awake time"
    - "how long your digital companion has been running"
```

## Adding New Comments

1. Edit the appropriate YAML file in `assets/comments/`
2. Add new messages to existing subcategories or create new ones
3. The system will automatically pick up changes on next run

## Customization

Users can customize comments by:

1. Editing existing YAML files
2. Adding new comment categories
3. Modifying the selection logic in `lib/greeting/comments.sh`

## Backward Compatibility

The YAML system maintains full backward compatibility with existing code:

- All original function names work unchanged
- Comment selection behavior is preserved
- Random selection from comment pools works the same way

## Technical Implementation

- Uses `yq` tool for YAML parsing
- Falls back gracefully if YAML files are missing
- Maintains mapping between old collection names and new YAML structure
- Loads comments dynamically when `init_comment_collections()` is called