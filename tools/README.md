# Home Assistant Tools

Shell scripts and utilities for Home Assistant management, testing, and debugging.

> **Note:** This directory is named `tools/` (not `scripts/`) to avoid confusion with Home Assistant's YAML "scripts" feature.

---

## Directory Structure

### `zigbee/` - ZHA and Zigbee Device Tools

Tools for working with Zigbee devices and ZHA integration.

**Contents:**
- `capture_ts004f_events.sh` - Interactive test script for capturing TS004F device events
- `ha_zigbee_logfmt.sh` - Format ZHA logs for readability
- `ha_zigbee_logfmt.py` - Python version of log formatter

**Usage:**
```bash
# Capture events from TS004F device
./zigbee/capture_ts004f_events.sh

# Format Zigbee logs
ha core logs | grep TS004F | ./zigbee/ha_zigbee_logfmt.sh
```

---

### `logging/` - Log Capture and Analysis

Tools for capturing and analyzing Home Assistant logs.

**Contents:**
- `ha_get_logs.sh` - Retrieve logs from Home Assistant (via SSH or local)

**Usage:**
```bash
# Get recent logs
./logging/ha_get_logs.sh

# Save logs to file
./logging/ha_get_logs.sh > ha-logs-$(date +%Y%m%d).log
```

---

### `device-testing/` - Device-Specific Test Scripts

(Reserved for future device test scripts)

Placeholder for scripts that test specific device behaviors, similar to `capture_ts004f_events.sh` but for other devices.

---

### `ha-core/` - General HA Management Utilities

(Reserved for future general utilities)

Placeholder for scripts that manage Home Assistant itself (backups, config validation, etc.).

---

## General Usage Notes

### Running on Home Assistant OS

Most scripts need to run on the Home Assistant host:

```bash
# Copy to HA
scp tools/zigbee/script.sh root@homeassistant.local:/tmp/

# SSH to HA
ssh root@homeassistant.local

# Run script
/tmp/script.sh
```

### Running Remotely

Some scripts (like log retrieval) can run from your dev machine:

```bash
# Assumes SSH access to HA
./logging/ha_get_logs.sh
```

---

## Script Conventions

All scripts in this repo follow these conventions:

1. **Shebang:** `#!/bin/bash` (portable)
2. **Header comment:** Purpose and usage
3. **Error handling:** Exit on error where appropriate
4. **Idempotent:** Safe to run multiple times
5. **Comments:** Inline explanations for complex logic

---

## Adding New Tools

When adding tools:

1. **Choose the right subdirectory:**
   - Zigbee-specific → `zigbee/`
   - Log-related → `logging/`
   - Device testing → `device-testing/`
   - General HA → `ha-core/`

2. **Name clearly:**
   - Use underscores: `ha_get_logs.sh`
   - Prefix with context: `capture_ts004f_events.sh`

3. **Add header comment:**
   ```bash
   #!/bin/bash
   # Script purpose and usage
   # Example: ./script.sh [args]
   ```

4. **Make executable:**
   ```bash
   chmod +x your-script.sh
   ```

5. **Update this README** if adding a new category

---

## Related Documentation

- **Device Research:** [zigbee/devices/](../research/zigbee/devices/)
- **Blueprints:** [blueprints/](../ha-assets/blueprints/)
- **Build Plan:** [BUILD_PLAN.md](../BUILD_PLAN.md)

---

## Contributing

Tools welcome! Submit PRs with:
- Clear purpose and usage
- Tested on HA OS (or note requirements)
- Following conventions above
