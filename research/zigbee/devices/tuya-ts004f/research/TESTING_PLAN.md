# Tuya TS004F Rotary Knob Testing Plan

## Device Information
- **Model**: TS004F
- **Manufacturer**: _TZ3000_gwkzibhs
- **Network Address**: 0x92A7
- **IEEE**: a4:c1:38:7d:21:bd:e8:bf

## Known Behaviors from Log Analysis

### Mode A (switch_mode=0)
- **Rotation**: Cluster 6 cmd 0xFC → Cluster 8 cmd 0x02 (LevelControl step)
- **Clockwise**: `rotate_type=0` followed by `step_mode=Up (0)`
- **Counter-clockwise**: `rotate_type=1` followed by `step_mode=Down (1)`

### Mode B (switch_mode=1)
- **Rotation**: Cluster 6 cmd 0xFC → Cluster 6 cmd 0x03/0x04
- **Clockwise**: `rotate_type=0` followed by cmd 0x03
- **Counter-clockwise**: `rotate_type=1` followed by cmd 0x04

### Button Press
- **Single press**: Cluster 6 cmd 0xFD `press_type(0)` → cmd 0x02 `toggle()`
- **Triple-click**: Mode change (switch_mode attribute report)

## Testing Sequence

### Test 1: Mode A - Slow Rotation (COMPLETED)
✓ Captured in all-zig-test.knob-only.log
- Clockwise rotation (slow) → LevelControl step_size=13
- Counter-clockwise rotation (slow) → LevelControl step_size=13

### Test 2: Mode A - Fast Rotation (COMPLETED)
✓ Captured in all-zig-test.knob-only.log
- Fast clockwise → step_size=91, 65
- Fast counter-clockwise → step_size=104, 143

### Test 3: Mode B - Rotation (COMPLETED)
✓ Captured in all-zig-test.knob-only.log
- Clockwise → cmd 0x03
- Counter-clockwise → cmd 0x04

### Test 4: Button Actions (PARTIAL)
✓ Single press captured
☐ Double-click (need to capture)
✓ Triple-click mode change captured
☐ Long press (need to capture if supported)

### Test 5: Additional Actions to Map
☐ Rotate + button press (if supported)
☐ Multi-endpoint behavior (if device has multiple endpoints)
☐ Scene mode behaviors (if any)

## Test Script Template

```bash
#!/bin/bash
# Run this before each test session
echo "Starting ZHA log capture for TS004F test..."
echo "Test: [DESCRIBE WHAT YOU'RE TESTING]"
echo "Actions: [LIST ACTIONS YOU'LL PERFORM]"
echo "---"
ha core logs -f | grep "0x92A7" > captured_logs/test_$(date +%Y%m%d_%H%M%S).log
```

## Log Analysis Checklist

For each captured log:
- [ ] Identify command sequences (cmd → followup cmd)
- [ ] Map timing between commands (important for cadence)
- [ ] Note step_size patterns for different rotation speeds
- [ ] Check TSN (transaction sequence numbers) for command pairing
- [ ] Verify mode (switch_mode attribute value)

## Quirk Requirements Based on Testing

### Must Handle:
1. **Cluster 6 (OnOff) Commands**:
   - 0xFC: `rotate_type(0|1)` - rotation event
   - 0xFD: `press_type(0)` - button press
   - 0x02: `toggle()` - standard toggle
   - 0x03: Mode B clockwise rotation (unknown command)
   - 0x04: Mode B counter-clockwise rotation (unknown command)

2. **Cluster 8 (LevelControl) Commands**:
   - 0x02: `step(step_mode, step_size, transition_time)` - Mode A rotation

3. **Cluster 6 Attributes**:
   - 0x8004: `switch_mode` - Mode A (0) vs Mode B (1)

### Should Emit:
- `zha_event` with `command: knob_rotate` for all rotation events
- `zha_event` with `command: knob_press` for button events
- `zha_event` with `command: knob_mode_change` for mode switches

## Next Steps
1. ✓ Analyze existing log
2. Run additional tests for missing scenarios
3. Update quirk code based on findings
4. Install quirk in Home Assistant
5. Test with real light control
6. Iterate based on results
