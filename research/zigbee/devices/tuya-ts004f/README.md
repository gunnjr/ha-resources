# Tuya TS004F - Comprehensive Device Research

Complete analysis of the TS004F rotary knob based on 147 captured ZHA events across 15 distinct physical actions.

---

## Quick Links

### Research Documents
- **[Event Catalog](research/ts004f-event-catalog.md)** - Detailed analysis of all 15 actions with automation examples
- **[Event Mapping (YAML)](research/ts004f-event-mapping.yaml)** - Structured machine-readable reference
- **[Event Coverage Audit](../../ha-assets/quirks/blueprints/tuya-ts004f/event-coverage-audit.md)** - Blueprint completeness analysis
- **[Blueprint Comparison](../../ha-assets/quirks/blueprints/tuya-ts004f/blueprint-comparison.md)** - Analysis vs community versions

### Captured Data
- **[Example Log](captured-logs/example-capture.log)** - Raw event capture from test session

### Ready-to-Use
- **[Enhanced Blueprint](../../ha-assets/quirks/blueprints/tuya-ts004f/)** - Production-ready automation blueprint

---

## Key Research Findings

### 🔴 Critical Discovery: Mode 2 Breaks Dimming

The device has two modes (triple-click to switch):

| Mode | switch_mode | Behavior | Recommendation |
|------|-------------|----------|----------------|
| **Mode 1** | 0 | Full cluster 8 support (dimming works) | ✅ **Use this!** |
| **Mode 2** | 1 | NO cluster 8 events (dimming broken) | ❌ **Avoid!** |

**Impact:** Existing community blueprints don't detect mode switches, leading to user confusion when dimming mysteriously stops working.

---

### 🎯 Speed Detection Parameters

Rotation events include speed indicators:

| Parameter | Value | Meaning | Blueprint Usage |
|-----------|-------|---------|-----------------|
| `step_mode` | 0 | RIGHT/clockwise (brightness up) | Direction |
| `step_mode` | 1 | LEFT/counter-clockwise (brightness down) | Direction |
| `step_size` | 13 | Single slow notch | ~6-7% brightness change |
| `step_size` | 26-52 | Fast rotation | Larger brightness jumps |
| `step_size` | 78-91+ | Very fast rotation | Maximum accumulation |
| `transition_time` | 1 | Fast rotation | 0.3s transition |
| `transition_time` | 2 | Moderate rotation | 0.5s transition |
| `transition_time` | 3 | Slow rotation | 0.8s transition |

**Finding:** Community blueprints only check `transition_time == 1`, mapping 67% of rotations incorrectly.

---

### 🐛 Double-Trigger Bug in Community Blueprints

Rotation generates 3 events:
1. `right` or `left` (directional indicator)
2. `rotate_type` (redundant directional info)
3. `step` (the actual dimming command)

**Bug:** Community blueprints trigger on `right`/`left` commands, causing:
- Mode 1: Both user action AND dimming fire (double-trigger)
- Mode 2: Only user action fires (expected, but inconsistent)

**Fix:** Only trigger on `step` commands (cluster 8).

---

### 📊 Event Clusters

| Cluster ID | Name | Purpose |
|------------|------|---------|
| 6 | OnOff | Button presses, directional indicators, mode switching |
| 8 | LevelControl | Brightness dimming (Mode 1 rotation) |
| 768 | ColorControl | Color temperature/hue (press + rotate) |

**Key Insight:** Press + rotate uses cluster 768, NOT cluster 8. Separate automation required.

---

## Complete Action Mapping

### Button Actions (Cluster 6)

| Physical Action | Primary Event | Secondary Events | Timing |
|----------------|---------------|------------------|--------|
| Single press | `remote_button_short_press` | `press_type: 0`, `toggle` | ~250ms between |
| Double press | `remote_button_double_press` | `press_type: 1`, `on` | ~250ms between |
| Long press | `remote_button_long_press` | `press_type: 2`, color commands | During hold |

### Rotation Actions (Mode 1)

| Physical Action | Events Generated | Best Trigger |
|----------------|------------------|--------------|
| Rotate right (any speed) | `right`, `rotate_type`, `step` | `step` with `step_mode: 0` |
| Rotate left (any speed) | `left`, `rotate_type`, `step` | `step` with `step_mode: 1` |

### Press + Rotate (Color Control)

| Physical Action | Events Generated | Best Trigger |
|----------------|------------------|--------------|
| Press + rotate right | `right`, `rotate_type`, `step_color_temp`, `long_press` | `step_color_temp` with `step_mode: 1` |
| Press + rotate left | `left`, `rotate_type`, `step_color_temp`, `long_press` | `step_color_temp` with `step_mode: 3` |

### Mode Switching

| Physical Action | Event Generated |
|----------------|----------------|
| Triple-click | `attribute_updated` with `switch_mode: 0 or 1` |

---

## Test Methodology

### Test Equipment
- **Device:** TS004F (_TZ3000_4fjiwweb variant)
- **Hub:** Home Assistant with ZHA
- **Method:** Automated test capture script with user-guided actions

### Test Session
- **Date:** 2025-11-15
- **Events Captured:** 147 total
- **Actions Tested:** 15 distinct physical interactions
- **Test Script:** [capture_ts004f_events.sh](../../tools/zigbee/capture_ts004f_events.sh)

### Actions Tested
1. Single click
2. Double click
3. Long press
4-7. Rotation (right/left, slow/fast) in Mode 1
8-11. Press + rotate (all combinations) in Mode 1
12. Triple-click → Mode 2
13. Rotation in Mode 2 (proving breakage)
14. Triple-click → Mode 1
15. Rotation verification (proving restoration)

---

## For Quirk Developers

### Device Signature
```yaml
Model: TS004F
Manufacturers:
  - _TZ3000_4fjiwweb
  - _TZ3000_qja6nq5z
  - Others

Clusters:
  - 0x0006 (OnOff)
  - 0x0008 (LevelControl)
  - 0x0300 (ColorControl)
```

### Custom Commands
The device implements Tuya-specific commands:
- `right` / `left` - Directional indicators
- `rotate_type` - Redundant direction (0=right, 1=left)
- `press_type` - Press type indicator (0=single, 1=double, 2=long)
- `attribute_updated` - Mode switching (attribute_id: 32772, attribute_name: switch_mode)

### Recommended Quirk Approach
1. **Expose Mode State** - Make `switch_mode` attribute visible in HA UI
2. **Document Mode Behavior** - Warn users that Mode 2 disables cluster 8
3. **Consider Quirk-Level Handling** - Could auto-restore Mode 1 or warn user

---

## Statistics

### Event Distribution
- **Button events:** 21 events (14%)
- **Rotation events:** 108 events (73%)
- **Mode switch events:** 2 events (1%)
- **Color control events:** 16 events (11%)

### Parameter Values Observed

**step_mode:**
- `0` (right): 60 occurrences
- `1` (left): 48 occurrences

**step_size:**
- `13` (slow): 42 occurrences
- `26` (moderate): 3 occurrences
- `52-78` (fast): 6 occurrences
- `91` (very fast): 1 occurrence

**transition_time:**
- `1` (fast): 38 occurrences
- `2` (moderate): 68 occurrences
- `3` (slow): 2 occurrences

---

## Automation Recommendations

### ✅ Recommended Patterns

**Dimming:**
```yaml
trigger:
  - platform: event
    event_type: zha_event
    event_data:
      device_id: YOUR_DEVICE
      command: step
      cluster_id: 8

action:
  - variables:
      direction: "{{ trigger.event.data.params.step_mode }}"
      amount: "{{ trigger.event.data.params.step_size / 2 }}"
  - service: light.turn_on
    data:
      brightness_step_pct: "{{ amount if direction == 0 else -amount }}"
```

**Color Temperature:**
```yaml
trigger:
  - platform: event
    event_type: zha_event
    event_data:
      device_id: YOUR_DEVICE
      command: step_color_temp
      cluster_id: 768
```

### ❌ Anti-Patterns

**Don't trigger on directional indicators:**
```yaml
# BAD - causes double-trigger in Mode 1
trigger:
  - platform: event
    event_data:
      command: right
```

**Don't use array indexing:**
```yaml
# BAD - fragile, unclear
value: "{{ trigger.event.data.args[1] / 2 }}"

# GOOD - named parameters
value: "{{ trigger.event.data.params.step_size / 2 }}"
```

---

## Tools

### Event Capture Script
[capture_ts004f_events.sh](../../tools/zigbee/capture_ts004f_events.sh)

Interactive script that:
- Guides user through 15 test actions
- Injects markers into log for correlation
- Supports retry on failed actions
- Outputs timestamped event log

### Log Formatter
[ha_zigbee_logfmt.sh](../../tools/zigbee/ha_zigbee_logfmt.sh)

Formats raw HA logs into readable ZHA event format.

---

## Related Resources

- **[Enhanced Blueprint](../../ha-assets/quirks/blueprints/tuya-ts004f/)** - Ready-to-use automation
- **[Home Assistant Community Post]** - Coming soon
- **[GitHub Issues](https://github.com/gunnjr/ha-resources/issues)** - Bug reports & questions

---

## Contributing

Found additional insights or tested other manufacturer variants?

**Contributions welcome:**
- Additional manufacturer variant testing
- Mode 2 use case discovery
- Quirk development
- Documentation improvements

---

## Citation

If you use this research in your own work:

```
TS004F Rotary Knob - Comprehensive Device Research
https://github.com/gunnjr/ha-resources/tree/main/research/zigbee/devices/tuya-ts004f
Based on 147-event analysis, November 2025
```

---

**Research Status:** Complete ✅ | **Blueprint Status:** Production-ready ✅
