# rclone_script.sh

## Overview

`rclone_script.sh` is a Bash script designed to generate and execute mount commands for remote directories using [rclone](https://rclone.org/). It automates the process of mounting remote directories defined in an `rclone.conf` file, allowing you to easily access remote data as if it were locally mounted.

## Prerequisites

Before using this script, ensure the following prerequisites are met:

1. **rclone Configuration:** You must have a valid `rclone.conf` file configured with the remote endpoints you want to mount. Make sure to specify the path to this configuration file in the script's `RCLONE_CONF` variable.

2. **rclone Installation:** Ensure that rclone is installed on your system. You can download and install it from the [official website](https://rclone.org/downloads/).

3. **MergerFS Installation:** You also need to have MergerFS installed on your system. You can find installation instructions for MergerFS in the [MergerFS GitHub repository](https://github.com/trapexit/mergerfs).

## Warning

**Important:** This script does notsss create remote directories. You must ensure that the remote directories you intend to mount using this script already exist in your storage. The script assumes that the remote directories are preconfigured in your `rclone.conf` file and the empty mount directories are already present.

## Usage

1. Clone or download the `rclone_script.sh` script to your local machine.

2. Open the script in a text editor and configure the following variables according to your setup:

   - `RCLONE_MOUNT_OPTIONS`: Set your desired rclone mount options, such as caching and permissions.
   - `RCLONE_CONF`: Specify the path to your `rclone.conf` file.
   - `BASE_MOUNT_PATH`: Define the base directory where remote directories will be mounted.
   - `BASE_MERGE_PATH`: Define the base directory where MergerFS will merge the mounted directories.
   - `GENERATED_SCRIPT`: Choose a name for the generated script file.

3. Save the script after making the necessary changes.

4. Make the script executable by running the following command in your terminal:

   ```bash
   chmod +x rclone_script.sh

5. Run the script:

   ```bash
   ./rclone_script.sh


The script will generate a new script file with mount commands for each remote directory defined in your rclone.conf. These commands will mount the remote directories to the specified BASE_MOUNT_PATH and then merge them using MergerFS into the BASE_MERGE_PATH.

Execute the generated script to mount the remote directories.


## Important Notes

 This script assumes that your rclone.conf contains sections with remote names enclosed in square brackets (e.g., [my_remote]). It uses these remote names to determine which directories to mount.

 It is recommended to customize the RCLONE_MOUNT_OPTIONS variable according to your specific use case and security requirements.

 Make sure to review the generated script before executing it to ensure it aligns with your intended configuration.