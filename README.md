# Live Wallpaper Script for HyDE

This script automatically changes your wallpaper based on the active window, while integrating smoothly with your current theme in HyDE.

## How to Use

### Requirements
- **HyDE**: Ensure you have HyDE installed and properly configured.
- **`swww`**: A wallpaper utility that allows smooth background transitions, needs to be installed and running.
- **`jq`**: Needs to be installed for JSON processing.

### Setup
1. **Download the Script**: Make sure the `live-wallpaper-script-copy.sh` is saved in your desired directory.

2. **Give Execution Permission**:
   ```bash
   chmod +x /path/to/live-wallpaper-script-copy.sh
   ```

3. **Start the Script**:
   ```bash
   /path/to/live-wallpaper-script-copy.sh
   ```
   This will start the wallpaper changer daemon.

### Commands
- **Stop**: To stop the script:
  ```bash
  /path/to/live-wallpaper-script-copy.sh stop
  ```
- **Status**: To check if the script is running:
  ```bash
  /path/to/live-wallpaper-script-copy.sh status
  ```
- **View Logs**: To view logs of wallpaper changes:
  ```bash
  /path/to/live-wallpaper-script-copy.sh log
  ```

### Customization
- *Edit Commands*: Customize the script's behavior by editing `live-wallpaper-script-copy.sh`.
- *Configure Wallpapers*: Place your wallpapers in the respective theme directory under `$HOME/.config/hyde/themes/{theme-name}/wallpapers`.

### Uninstallation
- Remove the script and related configuration files from your system.

## Notes
- Ensure all dependencies and configurations are correctly set for optimal functionality.

## Troubleshooting
- Check if `swww` is running if you face issues with wallpapers not changing.
- Review logs for specific error messages using the `log` command described above.
