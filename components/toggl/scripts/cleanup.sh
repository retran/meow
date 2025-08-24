#!/usr/bin/env bash

# Set strict mode for shell script.
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipefail: The return value of a pipeline is the status of the last command
#              to exit with a non-zero status, or zero if all commands exit
#              successfully.

# Source the UI library for consistent messaging and output formatting.
# The 'MEOW' environment variable is expected to point to the base directory
# where the 'lib/core/ui.sh' script is located.
source "${MEOW}/lib/core/ui.sh"

ui_info "Starting Toggl cleanup process..."

# Check if the Toggl configuration directory exists in the user's home directory.
if [[ -d "$HOME/.toggl" ]]; then
  ui_info "Cleaning Toggl configuration cache and log files in '$HOME/.toggl'..."
  # Attempt to remove the 'cache' directory and 'toggl.log' file.
  # 'rm -rf': Recursively remove directories and their contents without prompting.
  # 'rm -f': Forcefully remove files without prompting.
  # '2>/dev/null': Redirect standard error to /dev/null to suppress error messages
  #                (e.g., if the file/directory does not exist).
  # '|| true': Logical OR with 'true' ensures that the script does not exit
  #            due to 'set -e' if the 'rm' command fails. This is desirable for
  #            cleanup operations where files might already be missing.
  rm -rf "$HOME/.toggl/cache" 2>/dev/null || true
  rm -f "$HOME/.toggl/toggl.log" 2>/dev/null || true
fi

ui_info "Cleaning temporary Toggl files from '/tmp' and '$HOME'..."
# Remove temporary files created by Toggl in common temporary locations.
# Similar error handling with '2>/dev/null || true' is applied here.
rm -f "/tmp/toggl_*" 2>/dev/null || true
rm -f "$HOME/.toggl_tmp_*" 2>/dev/null || true

ui_info "Toggl API data and user settings are preserved."

ui_success "Toggl cleanup completed successfully."
