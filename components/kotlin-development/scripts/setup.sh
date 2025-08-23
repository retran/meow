#!/usr/bin/env bash

set -euo pipefail

COMPONENT_NAME="$1"
MEOW="$2"

source "${MEOW}/lib/core/platform.sh"
source "${MEOW}/lib/core/ui.sh"
source "${MEOW}/lib/strings/strings.sh"

ui_action_start "$(get_static_message "kotlin_dev_configuring")"

if [[ -d "/Applications/IntelliJ IDEA.app" ]]; then
  ui_info "$(get_static_message "kotlin_dev_configuring_intellij")"

  intellij_config_dir="$HOME/Library/Application Support/JetBrains/IntelliJIdea"
  mkdir -p "$intellij_config_dir/options" 2>/dev/null || true

  if [[ ! -f "$intellij_config_dir/options/ide.general.xml" ]]; then
    cat > "$intellij_config_dir/options/ide.general.xml" << 'EOF'
<application>
  <component name="GeneralSettings">
    <option name="autoSaveFiles" value="true" />
    <option name="autoSaveIfInactive" value="true" />
    <option name="inactiveTimeout" value="15" />
    <option name="confirmExit" value="false" />
    <option name="showTipsOnStartup" value="false" />
  </component>
</application>
EOF
  fi

  if [[ ! -f "$intellij_config_dir/options/kotlin.xml" ]]; then
    cat > "$intellij_config_dir/options/kotlin.xml" << 'EOF'
<application>
  <component name="KotlinPluginSettings">
    <option name="updateChannel" value="Stable" />
  </component>
</application>
EOF
  fi
fi

ui_info "$(get_static_message "kotlin_dev_configuring_gradle")"
gradle_dir="$HOME/.gradle"
mkdir -p "$gradle_dir" 2>/dev/null || true

if [[ ! -f "$gradle_dir/gradle.properties" ]]; then
  cat > "$gradle_dir/gradle.properties" << 'EOF'
# Gradle performance optimizations
org.gradle.daemon=true
org.gradle.parallel=true
org.gradle.caching=true
org.gradle.configureondemand=true

# Kotlin compilation optimizations
kotlin.code.style=official
kotlin.incremental=true
kotlin.incremental.multiplatform=true
kotlin.parallel.tasks.in.project=true

# JVM options
org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=512m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
EOF
fi

ui_action_success "$(get_static_message "kotlin_dev_configured_successfully")"
