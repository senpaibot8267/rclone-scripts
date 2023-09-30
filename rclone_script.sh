#!/bin/bash

# Define common rclone mount options with full caching
RCLONE_MOUNT_OPTIONS="--vfs-cache-mode full --allow-other --allow-non-empty"

# Path to rclone.conf
RCLONE_CONF="/path/to/rclone.conf"

# Base path to mount
BASE_MOUNT_PATH="/path/to/basemount"

# Name of the generated script
GENERATED_SCRIPT="rclone_mount.sh"

# Check if rclone.conf exists
if [ ! -f "$RCLONE_CONF" ]; then
    echo "Error: rclone.conf not found at $RCLONE_CONF"
    exit 1
fi

# Redirect output to the generated script file
> "$GENERATED_SCRIPT"

# Add shebang line to the generated script
echo "#!/bin/bash" >> "$GENERATED_SCRIPT"
echo >> "$GENERATED_SCRIPT"

# Add common rclone mount options to the generated script
echo "# Common rclone mount options" >> "$GENERATED_SCRIPT"
echo "RCLONE_MOUNT_OPTIONS=\"$RCLONE_MOUNT_OPTIONS\"" >> "$GENERATED_SCRIPT"
echo >> "$GENERATED_SCRIPT"

# Parse rclone.conf and store remote names in an array
remote_names=()
while IFS= read -r line; do
    if [[ $line =~ ^\[.*\]$ ]]; then
        remote_name="${line#[}"
        remote_name="${remote_name%]}"
        remote_names+=("$remote_name")
    fi
done < "$RCLONE_CONF"

# Function to generate mount commands for a directory
generate_mount_commands() {
    local dir="$1"
    local sub_path="$2"

    for sub_dir in "$dir"/*; do
        if [ -d "$sub_dir" ]; then
            folder_name=$(basename "$sub_dir")

            # Check if the subdirectory has a matching remote name in rclone.conf
            if [[ " ${remote_names[@]} " =~ " $folder_name " ]]; then
                echo "# Mount $folder_name remote" >> "$GENERATED_SCRIPT"
                echo "rclone mount \$RCLONE_MOUNT_OPTIONS -v ${folder_name}: ${BASE_MOUNT_PATH}/${sub_path}${folder_name} &" >> "$GENERATED_SCRIPT"
                echo >> "$GENERATED_SCRIPT"
            fi

            # Recursively process subdirectories
            generate_mount_commands "$sub_dir" "$sub_path$folder_name/"
        fi
    done
}

# Generate mount commands for the base directory and its subdirectories
generate_mount_commands "$BASE_MOUNT_PATH" ""

# Make the generated script executable
chmod +x "$GENERATED_SCRIPT"

echo "Generated script '$GENERATED_SCRIPT' created"
