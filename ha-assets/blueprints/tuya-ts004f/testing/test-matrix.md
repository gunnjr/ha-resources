# TS004F Enhanced Blueprint - Test Matrix

## Pre-Test Setup

### 1. Configure Logger
Add to `configuration.yaml`:
```yaml
logger:
  default: warning
  logs:
    homeassistant.components.automation: info
```

Then reload: **Developer Tools → YAML → Reload Logger Configuration**

### 2. Verify Debug Logging Enabled
Ensure the debug logging condition block (line ~241) has:
```yaml
- conditions:
    - "{{ true }}"  # Always logs every event
```

### 3. Test Environment
- **Device**: TS004F Rotary Knob
- **Current Mode**: Dimmer Mode (verify via mode sensor)
- **Test Light**: Configure a test light entity
- **Auto-Toggle**: Disabled (unless testing that feature specifically)

---

## Test Sections

### Section A: Brightness Control (Cluster 8 Step Commands)

| Test ID | Physical Action | Expected Behavior | Expected Events | Expected Logs | Result | Notes |
|---------|----------------|-------------------|-----------------|---------------|--------|-------|
| A-01 | Rotate right (slow) | Light brightness increases | `step` + `rotate_type` + `right` | INFO: step, DEBUG: rotate_type, DEBUG: right | ☐ PASS ☐ FAIL | |
| A-02 | Rotate left (slow) | Light brightness decreases | `step` + `rotate_type` + `left` | INFO: step, DEBUG: rotate_type, DEBUG: left | ☐ PASS ☐ FAIL | |
| A-03 | Rotate right (fast) | Light brightness increases faster | `step` (larger step_size) + extras | INFO: step, DEBUG: extras | ☐ PASS ☐ FAIL | |
| A-04 | Rotate left (fast) | Light brightness decreases faster | `step` (larger step_size) + extras | INFO: step, DEBUG: extras | ☐ PASS ☐ FAIL | |
| A-05 | Rotate at minimum brightness | Light stays off or at minimum | `step` | INFO: step | ☐ PASS ☐ FAIL | Edge case |
| A-06 | Rotate at maximum brightness | Light stays at maximum | `step` | INFO: step | ☐ PASS ☐ FAIL | Edge case |

**Validation Criteria:**
- [ ] Brightness changes smoothly
- [ ] Step size correlates with rotation speed
- [ ] Transition time is appropriate (fast/medium/slow)
- [ ] No WARNING level logs
- [ ] `step_mode`, `step_size`, `transition_time` captured correctly

---

### Section B: Color Temperature Control (Cluster 768)

| Test ID | Physical Action | Expected Behavior | Expected Events | Expected Logs | Result | Notes |
|---------|----------------|-------------------|-----------------|---------------|--------|-------|
| B-01 | Press + rotate right | Color temp warmer (increase mireds) | `step_color_temp` | INFO: step_color_temp | ☐ PASS ☐ FAIL | |
| B-02 | Press + rotate left | Color temp cooler (decrease mireds) | `step_color_temp` | INFO: step_color_temp | ☐ PASS ☐ FAIL | |
| B-03 | Press + rotate at warmest | Color temp stays at max mireds (500) | `step_color_temp` | INFO: step_color_temp | ☐ PASS ☐ FAIL | Boundary test |
| B-04 | Press + rotate at coolest | Color temp stays at min mireds (153) | `step_color_temp` | INFO: step_color_temp | ☐ PASS ☐ FAIL | Boundary test |

**Validation Criteria:**
- [ ] Color temperature changes visibly
- [ ] Bounds checking prevents out-of-range values (153-500 mireds)
- [ ] `color_step_mode`, `color_step_size` captured correctly
- [ ] No WARNING level logs

---

### Section C: Button Actions

#### C.1 Single Press

| Test ID | Physical Action | Expected Behavior | Expected Events | Expected Logs | Result | Notes |
|---------|----------------|-------------------|-----------------|---------------|--------|-------|
| C-01 | Single press button | User-configured action executes | `remote_button_short_press` + `press_type` + `toggle` | INFO: all 3 events, DEBUG: press_type, DEBUG: toggle | ☐ PASS ☐ FAIL | |
| C-02 | Verify toggle ignored | No auto-toggle (disabled) | `toggle` event | DEBUG: "Ignoring toggle" | ☐ PASS ☐ FAIL | |

#### C.2 Double Press

| Test ID | Physical Action | Expected Behavior | Expected Events | Expected Logs | Result | Notes |
|---------|----------------|-------------------|-----------------|---------------|--------|-------|
| C-03 | Double press button | User-configured action executes | `remote_button_double_press` + `press_type` + `on` | INFO: all 3, DEBUG: press_type, DEBUG: on | ☐ PASS ☐ FAIL | |

#### C.3 Long Press

| Test ID | Physical Action | Expected Behavior | Expected Events | Expected Logs | Result | Notes |
|---------|----------------|-------------------|-----------------|---------------|--------|-------|
| C-04 | Long press button | User-configured action executes | `remote_button_long_press` + `press_type` + `move_saturation` + `stop_move_step` (×2) | INFO: remote_button_long_press, DEBUG: all others | ☐ PASS ☐ FAIL | |
| C-05 | Verify color commands ignored | No color changes | `move_saturation`, `stop_move_step` | DEBUG: "Ignoring long-press color command" | ☐ PASS ☐ FAIL | |

**Validation Criteria:**
- [ ] Button actions trigger user-configured sequences
- [ ] Redundant events (`press_type`, `on`, `toggle`, color commands) logged at DEBUG level
- [ ] No WARNING level logs

---

### Section D: Auto-Toggle Feature

**Pre-test:** Enable `auto_toggle_single_press` in blueprint configuration, reload automation

| Test ID | Physical Action | Expected Behavior | Expected Events | Expected Logs | Result | Notes |
|---------|----------------|-------------------|-----------------|---------------|--------|-------|
| D-01 | Single press with auto-toggle ON | Light toggles on/off | `remote_button_short_press` + `toggle` | INFO: both events | ☐ PASS ☐ FAIL | |
| D-02 | Verify toggle handled | Toggle command processed | `toggle` | INFO: toggle processed | ☐ PASS ☐ FAIL | Check automation trace |

**Post-test:** Disable `auto_toggle_single_press`, reload automation

**Validation Criteria:**
- [ ] Light toggles when auto-toggle enabled
- [ ] Toggle event handled (not ignored) when enabled
- [ ] No WARNING level logs

---

### Section E: Mode Switching (Triple-Click)

**Pre-test:** Verify device in Dimmer Mode (mode_sensor = "Dimmer Mode")

| Test ID | Physical Action | Expected Behavior | Expected Events | Expected Logs | Result | Notes |
|---------|----------------|-------------------|-----------------|---------------|--------|-------|
| E-01 | Triple-click (Dimmer → Scene) | Mode sensor updates to "Scene Control Mode" | `attribute_updated` (switch_mode, value=1) | INFO: attribute_updated | ☐ PASS ☐ FAIL | |
| E-02 | Verify notification (if enabled) | Notification sent with warning message | - | - | ☐ PASS ☐ FAIL | Optional |
| E-03 | Rotate in Scene Mode | Brightness does NOT change | Various events but NO `step` with cluster 8 | INFO: events logged | ☐ PASS ☐ FAIL | **Critical test** |
| E-04 | Triple-click (Scene → Dimmer) | Mode sensor updates to "Dimmer Mode" | `attribute_updated` (switch_mode, value=0) | INFO: attribute_updated | ☐ PASS ☐ FAIL | |
| E-05 | Verify notification (if enabled) | Notification sent with success message | - | - | ☐ PASS ☐ FAIL | Optional |
| E-06 | Rotate in Dimmer Mode | Brightness changes normally | `step` + extras | INFO: step | ☐ PASS ☐ FAIL | Verify dimming restored |

**Validation Criteria:**
- [ ] Mode sensor updates correctly (both directions)
- [ ] Brightness dimming disabled in Scene Control Mode
- [ ] Brightness dimming restored in Dimmer Mode
- [ ] `updated_attrib_name` = "switch_mode"
- [ ] `updated_attrib_value` = 1 or 0 (integer, not enum)
- [ ] No WARNING level logs

---

### Section F: Event Logging Verification

| Test ID | Verification | Expected Result | Result | Notes |
|---------|--------------|-----------------|--------|-------|
| F-01 | Review all INFO logs | Every event has corresponding INFO log entry | ☐ PASS ☐ FAIL | |
| F-02 | Review all DEBUG logs | Ignored events logged at DEBUG level | ☐ PASS ☐ FAIL | |
| F-03 | Review WARNING logs | No unexpected WARNING entries | ☐ PASS ☐ FAIL | Document any warnings |
| F-04 | Verify variable extraction | All local variables captured correctly in logs | ☐ PASS ☐ FAIL | Check step_mode, step_size, etc. |
| F-05 | Check for enum wrapping issues | No `<EnumType.Value: N>` in conditional failures | ☐ PASS ☐ FAIL | |

**Expected DEBUG Log Messages:**
- "Ignoring unneeded rotate command=rotate_type/left/right"
- "Ignoring long-press color command=move_saturation/stop_move_step"
- "Ignoring press_type (redundant with remote_button_* events)"
- "Ignoring 'on' from double press"
- "Ignoring toggle (auto_toggle disabled)"

**No WARNING logs should appear for normal operations.**

---

## Event Pattern Reference

### Complete Event Signatures

| Physical Action | All Events Generated |
|----------------|---------------------|
| Rotate right/left | `step`, `rotate_type`, `left`/`right` |
| Press + rotate | `step_color_temp` |
| Single press | `remote_button_short_press`, `press_type`, `toggle` |
| Double press | `remote_button_double_press`, `press_type`, `on` |
| Long press | `remote_button_long_press`, `press_type`, `move_saturation`, `stop_move_step` (×2) |
| Triple-click | `attribute_updated` (switch_mode) |

### Event Handling Classification

**HANDLED (INFO level):**
- `step` (cluster 8) - Brightness control
- `step_color_temp` (cluster 768) - Color temperature
- `remote_button_short_press`, `remote_button_double_press`, `remote_button_long_press` - Button actions
- `toggle` (when auto_toggle enabled)
- `attribute_updated` (switch_mode only) - Mode switching

**IGNORED (DEBUG level):**
- `rotate_type`, `left`, `right` - Redundant with `step`
- `press_type` - Redundant with `remote_button_*`
- `on` - Redundant with `remote_button_double_press`
- `toggle` (when auto_toggle disabled)
- `move_hue`, `move_saturation`, `stop_move_step` - Long-press color commands (not implemented)
- `attribute_updated` (non-switch_mode attributes)

**UNEXPECTED (WARNING level):**
- Any command not in the above two categories

---

## Post-Test Cleanup

### 1. Disable Debug Logging
Comment out or change the always-true debug condition (line ~241):
```yaml
# - conditions:
#     - "{{ true }}"  # Disable for production
```

Or change to conditional:
```yaml
- conditions:
    - "{{ false }}"  # Disabled
```

Reload automation.

### 2. Review Results
- [ ] All tests passed
- [ ] No WARNING level logs during normal operation
- [ ] Event patterns match expected signatures
- [ ] Mode switching works correctly
- [ ] Brightness/color temp controls function properly

### 3. Document Issues
List any failures, unexpected behaviors, or WARNING logs below:

---

## Test Results Summary

**Test Date:** _______________
**Tested By:** _______________
**HA Version:** _______________
**ZHA Version:** _______________

**Results:**
- Total Tests: ___ / ___
- Passed: ___
- Failed: ___
- Skipped: ___

**Issues Found:**
1.
2.
3.

**Notes:**
