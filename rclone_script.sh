#!/bin/bash

# Define common rclone mount options with full caching
RCLONE_MOUNT_OPTIONS="--vfs-cache-mode full --allow-other --allow-non-empty"

# Path to rclone.conf
RCLONE_CONF="/path/to/rclone.conf"

# Base path to mount
BASE_MOUNT_PATH="/path/to/basemount"

# Base path to MergerFS
BASE_MERGE_PATH="/path/to/basemerge"

# Name of the generated script
GENERATED_SCRIPT="rclone_mount.sh"

# Name of the generated unmount script
UNMOUNT_SCRIPT="rclone_unmount.sh"

# Define common MergerFS options
MERGERFS_OPTIONS="-o async_read=true,use_ino,allow_other,auto_cache,func.getattr=newest,cache.files=off,dropcacheonclose=true,category.create=mfs"

# Check if rclone.conf exists
if [ ! -f "$RCLONE_CONF" ]; then
    echo "Error: rclone.conf not found at $RCLONE_CONF"
    exit 1
fi

# Redirect output to the generated script files
> "$GENERATED_SCRIPT"
> "$UNMOUNT_SCRIPT"

# Add shebang line to the generated scripts
echo "#!/bin/bash" >> "$GENERATED_SCRIPT"
echo "#!/bin/bash" >> "$UNMOUNT_SCRIPT"
echo >> "$GENERATED_SCRIPT"
echo >> "$UNMOUNT_SCRIPT"

# Add common rclone mount options to the generated script
echo "# Common rclone mount options" >> "$GENERATED_SCRIPT"
echo "RCLONE_MOUNT_OPTIONS=\"$RCLONE_MOUNT_OPTIONS\"" >> "$GENERATED_SCRIPT"
echo >> "$GENERATED_SCRIPT"

# Add common MergerFS options to the generated script
echo "# Common MergerFS options" >> "$GENERATED_SCRIPT"
echo "MERGERFS_OPTIONS=\"$MERGERFS_OPTIONS\"" >> "$GENERATED_SCRIPT"
echo >> "$GENERATED_SCRIPT"

# Add common Unmount options to Unmount Script
echo "# Define a function to unmount with sudo" >> "$UNMOUNT_SCRIPT"
echo "fusermount() {" >> "$UNMOUNT_SCRIPT"
echo "    sudo fusermount -uz \"\$1\"" >> "$UNMOUNT_SCRIPT"
echo "}" >> "$UNMOUNT_SCRIPT"
echo >> "$UNMOUNT_SCRIPT"

# Parse rclone.conf and store remote names in an array
remote_names=()
while IFS= read -r line; do
    if [[ $line =~ ^\[.*\]$ ]]; then
        remote_name="${line#[}"
        remote_name="${remote_name%]}"
        remote_names+=("$remote_name")
    fi
done < "$RCLONE_CONF"

# Function to generate rclone mount commands for a directory
generate_rclone_mount_commands() {
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

                # Add unmount command for this rclone mount
                echo "# Unmount $folder_name remote" >> "$UNMOUNT_SCRIPT"
                echo "fusermount ${BASE_MOUNT_PATH}/${sub_path}${folder_name}" >> "$UNMOUNT_SCRIPT"
                echo >> "$UNMOUNT_SCRIPT"
            fi

            # Recursively process subdirectories
            generate_rclone_mount_commands "$sub_dir" "$sub_path$folder_name/"
        fi
    done
}

# Function to generate MergerFS merge commands for a directory
generate_mergerfs_merge_commands() {
    local dir="$1"
    local sub_path="$2"
    local sub_dirs=()

    for sub_dir in "$dir"/*; do
        if [ -d "$sub_dir" ]; then
            folder_name=$(basename "$sub_dir")

            # Check if the subdirectory has a matching remote name in rclone.conf
            if [[ " ${remote_names[@]} " =~ " $folder_name " ]]; then
                sub_dirs+=("${BASE_MOUNT_PATH}/${sub_path}${folder_name}")
                fsname=$(basename "$dir")
            fi

            # Recursively process subdirectories
            generate_mergerfs_merge_commands "$sub_dir" "$sub_path$folder_name/"
        fi
    done

    # If there are matching subdirectories, create a MergerFS merge
    if [ ${#sub_dirs[@]} -gt 0 ]; then
        mergerfs_sources=$(IFS=: ; echo "${sub_dirs[*]}")
        echo "# Merge $fsname directory" >> "$GENERATED_SCRIPT"
        echo "sudo mergerfs \$MERGERFS_OPTIONS -o fsname=Jelly$fsname $mergerfs_sources ${BASE_MERGE_PATH}/$fsname &" >> "$GENERATED_SCRIPT"
        echo >> "$GENERATED_SCRIPT"

        # Add unmount command for this MergerFS merge
        echo "# Unmount $fsname directory" >> "$UNMOUNT_SCRIPT"
        echo "fusermount ${BASE_MERGE_PATH}/$fsname" >> "$UNMOUNT_SCRIPT"
    fi
}

# Generate rclone mount commands for the base directory and its subdirectories
generate_rclone_mount_commands "$BASE_MOUNT_PATH" ""

# Generate MergerFS merge commands for the base directory and its subdirectories
generate_mergerfs_merge_commands "$BASE_MOUNT_PATH" ""

# Add infinite loop to keep the rclone script running
echo "# Run an infinite loop in the background to keep the rclone script running" >> "$GENERATED_SCRIPT"
echo "while :; do" >> "$GENERATED_SCRIPT"
echo "    sleep 1" >> "$GENERATED_SCRIPT"
echo "done" >> "$GENERATED_SCRIPT"

# Make the generated scripts executable
chmod +x "$GENERATED_SCRIPT"
chmod +x "$UNMOUNT_SCRIPT"

echo "Generated scripts '$GENERATED_SCRIPT' and '$UNMOUNT_SCRIPT' created"