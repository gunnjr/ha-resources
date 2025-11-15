# Tuya TS004F Complete Command Mapping

**Device**: TS004F
**Manufacturer**: _TZ3000_gwkzibhs
**Test Date**: 2025-11-14
**Log**: test_20251114_083926_full_device_test.log

---

## Clusters Supported

- **Cluster 6 (0x0006)**: OnOff - Button and rotation events
- **Cluster 8 (0x0008)**: LevelControl - Brightness control (Mode A only)
- **Cluster 768 (0x0300)**: Color - Hue/Saturation control (Long press)

---

## Button Actions

### Single Press
```
Command: 0xFD press_type(press_type=0)
  ↓ (~250ms later)
Command: 0x02 toggle()
```
**Use**: Toggle on/off

### Double-Click
```
Command: 0xFD press_type(press_type=1)
  ↓ (~250ms later)
Command: 0x01 on()
```
**Use**: Turn on

### Long Press (Hold ~2-3 seconds)
```
Command: 0xFD press_type(press_type=2)
  ↓ (~250ms later)
Cluster 768 Command: 0x04 move_saturation(move_mode=Up, rate=200)
  ↓ (~500ms later)
Cluster 768 Command: 0x01 move_hue(move_mode=Up, rate=15)
  ↓ (on release)
Cluster 768 Command: 0x47 stop_move_step()
```
**Use**: Color cycling (hue + saturation)

### Triple-Click
```
Command: 0xFD press_type(?) [Not clearly captured]
  ↓ (~few seconds later)
Attribute Report: switch_mode changes (0 ↔ 1)
```
**Use**: Toggle between Mode A and Mode B

---

## Mode A (switch_mode=0) - Brightness Control

### Rotation Pattern
```
Cluster 6 Command: 0xFC rotate_type(0 or 1)
  ↓ (~250ms later)
Cluster 8 Command: 0x02 step(step_mode, step_size, transition_time)
```

### Clockwise Rotation
```
rotate_type=0  →  step_mode=Up (0), step_size=13-52
```
- Slow: step_size=13, transition_time=1-2
- Fast: step_size=52+, transition_time=2

### Counter-Clockwise Rotation
```
rotate_type=1  →  step_mode=Down (1), step_size=13-65
```
- Slow: step_size=13, transition_time=1
- Fast: step_size=65+, transition_time=2

**Step Size Correlation**: Faster rotation = larger step_size (cadence-based)

---

## Mode B (switch_mode=1) - Scene/Command Mode

### Rotation Pattern
```
Cluster 6 Command: 0xFC rotate_type(0 or 1)
  ↓ (~no LevelControl command)
Cluster 6 Command: 0x03 or 0x04 (unknown commands)
```

### Clockwise Rotation
```
rotate_type=0  →  Command 0x03 (empty payload)
```

### Counter-Clockwise Rotation
```
rotate_type=1  →  Command 0x04 (empty payload)
```

**Note**: These commands (0x03/0x04) are unknown/unhandled by default ZHA

---

## Command Summary Table

| Action | Cluster | Command | Payload | Notes |
|--------|---------|---------|---------|-------|
| Single press | 6 | 0xFD | press_type=0 | Followed by toggle |
| - followup | 6 | 0x02 | - | toggle() |
| Double-click | 6 | 0xFD | press_type=1 | Followed by on |
| - followup | 6 | 0x01 | - | on() |
| Long press | 6 | 0xFD | press_type=2 | Enters color mode |
| - color start | 768 | 0x04 | move_mode=1, rate=200 | move_saturation |
| - color cycle | 768 | 0x01 | move_mode=1, rate=15 | move_hue |
| - color stop | 768 | 0x47 | - | stop_move_step |
| Triple-click | 6 | 0x0A | attr 0x8004 | Mode switch report |
| **Mode A Rotate CW** | 6 | 0xFC | rotate_type=0 | Direction event |
| - followup | 8 | 0x02 | step_mode=0, size varies | LevelControl step up |
| **Mode A Rotate CCW** | 6 | 0xFC | rotate_type=1 | Direction event |
| - followup | 8 | 0x02 | step_mode=1, size varies | LevelControl step down |
| **Mode B Rotate CW** | 6 | 0xFC | rotate_type=0 | Direction event |
| - followup | 6 | 0x03 | - | Unknown command |
| **Mode B Rotate CCW** | 6 | 0xFC | rotate_type=1 | Direction event |
| - followup | 6 | 0x04 | - | Unknown command |

---

## Key Findings

1. **Device is multi-functional**: Supports brightness, on/off, AND color control
2. **Button press types**: Single, double, long-press, triple-click all produce different commands
3. **Two rotation modes**: Mode A sends LevelControl, Mode B sends custom commands
4. **Cadence-based step sizes**: Faster rotation = larger step_size in LevelControl
5. **Color control on long-press**: Unexpected feature for a "simple" rotary knob!
6. **Mode attribute**: 0x8004 on cluster 6 indicates current mode (0=Mode A, 1=Mode B)

---

## Quirk Requirements

The quirk must handle:
1. ✅ Cluster 6 commands 0xFC, 0xFD, 0x02, 0x01, 0x03, 0x04
2. ✅ Cluster 8 command 0x02 (step)
3. ✅ Cluster 768 commands 0x01, 0x04, 0x47 (color control)
4. ✅ Attribute 0x8004 (switch_mode)
5. ✅ Emit appropriate zha_events for all actions
6. ✅ Handle both Mode A and Mode B behaviors

---

## Next Steps

1. Build quirk to handle all these commands
2. Map to appropriate Home Assistant events/services
3. Test with actual lights (dimmable + color)
4. Document usage patterns for end users
