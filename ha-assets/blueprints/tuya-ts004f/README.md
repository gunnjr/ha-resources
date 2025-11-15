# Tuya TS004F Smart Knob - Enhanced Blueprint

Control lights with the TS004F rotary knob. Works with all manufacturer variants.

![Device](https://via.placeholder.com/300x200?text=TS004F+Photo)

## Quick Import

**Home Assistant Blueprint Import:**

```
https://github.com/gunnjr/ha-resources/blob/main/ha-assets/blueprints/tuya-ts004f/ts004f-enhanced.yaml
```

Or use the My Home Assistant link:
[![Import Blueprint](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https://github.com/gunnjr/ha-resources/blob/main/ha-assets/blueprints/tuya-ts004f/ts004f-enhanced.yaml)

---

## Features

✅ **Brightness Dimming** - Rotate to dim with automatic speed detection
- Slow rotation = smooth, small steps
- Fast rotation = larger jumps
- Adjustable sensitivity multiplier

✅ **Color Temperature Control** - Press + rotate for warm/cool adjustment
- Right rotation = warmer (increase mireds)
- Left rotation = cooler (decrease mireds)
- Safe bounds checking (153-500 mireds)

✅ **Customizable Button Actions**
- Single press - customizable action
- Double press - customizable action
- Long press - customizable action
- Optional auto-toggle on single press

✅ **Mode Awareness** - Detects device mode switches
- Triple-click detection
- Warning notifications when entering Mode 2
- Explains why dimming stops working

✅ **Universal Compatibility**
- Works with ALL TS004F manufacturer variants
- `_TZ3000_4fjiwweb`
- `_TZ3000_qja6nq5z`
- And others!

---

## Supported Hardware

**Model:** TS004F
**Manufacturers:** _TZ3000_4fjiwweb, _TZ3000_qja6nq5z, and other variants
**Brands:** Moes, Girier, etc.
**Purchase:** Available on AliExpress, Amazon

---

## Basic Setup Example

1. **Import the blueprint** (link above)
2. **Create automation** from blueprint
3. **Configure:**
   - Select your TS004F device
   - Choose light for dimming
   - (Optional) Choose light for color temp
   - (Optional) Enable auto-toggle
   - (Optional) Enable mode notifications

**Minimal Configuration:**
```yaml
Device: [Your TS004F]
Dimmer Light: light.living_room
```

**Full Configuration:**
```yaml
Device: [Your TS004F]
Dimmer Light: light.living_room
Color Temp Light: light.living_room
Auto-Toggle on Single Press: ✅ Enabled
Notify on Mode Switch: ✅ Enabled
Brightness Multiplier: 1.0
```

---

## Important: Device Modes

The TS004F has two modes (switch via triple-click):

### Mode 1 (Default) - ✅ RECOMMENDED
- Full brightness dimming support
- All blueprint features work
- This is the mode you should use!

### Mode 2 (Event/Scene) - ⚠️ NOT RECOMMENDED
- Brightness dimming **BREAKS** (no cluster 8 events)
- Only directional indicators fire
- Blueprint will warn you if you enter this mode

**If dimming stops working:** Triple-click to return to Mode 1!

---

## Advanced Features

### Speed Detection
The blueprint automatically adjusts dimming smoothness based on rotation speed:
- `transition_time: 1` → 0.3s (fast rotation)
- `transition_time: 2` → 0.5s (moderate)
- `transition_time: 3` → 0.8s (slow rotation)

### Brightness Multiplier
Adjust dimming sensitivity (default: 1.0):
- `0.5` = Half speed (more control, less sensitive)
- `1.0` = Normal (recommended)
- `2.0` = Double speed (less control, more sensitive)

### Mode Switch Notifications
Get notified when the device switches modes:
```
⚠️ Mode 2 active - dimming DISABLED!
Triple-click to return to Mode 1.
```

---

## Comparison with Community Blueprints

This enhanced blueprint fixes several issues found in existing community versions:

| Feature | Community | Enhanced |
|---------|-----------|----------|
| Device variants | Single variant only | All TS004F variants ✅ |
| Speed mapping | 33% accurate | 100% accurate ✅ |
| Mode awareness | No detection | Detects & notifies ✅ |
| Double-trigger bug | Present | Fixed ✅ |
| Brightness tuning | Fixed | Adjustable ✅ |
| Modern syntax | Deprecated | Current ✅ |

See [detailed comparison](blueprint-comparison.md)

---

## Deep Dive: Device Research

Want to understand how this device really works?

📖 **[Complete Device Research](../../../research/zigbee/devices/tuya-ts004f/)**

Includes:
- Comprehensive event catalog (147 events analyzed!)
- Structured event mapping (YAML)
- Event coverage audit
- Comparison with community blueprints
- Test capture scripts

This blueprint is based on exhaustive device research, not guesswork.

---

## Troubleshooting

### Dimming Stopped Working
**Cause:** Device in Mode 2
**Solution:** Triple-click button to return to Mode 1

### Rotation Too Sensitive/Not Sensitive Enough
**Solution:** Adjust "Brightness Step Multiplier" setting
- Decrease for less sensitivity
- Increase for more sensitivity

### Device Not Found in Selector
**Cause:** Unusual manufacturer variant
**Solution:** This shouldn't happen (supports all TS004F), but please report!

### Color Temperature Not Working
**Ensure:**
- Your light supports color temperature
- You've configured "Color Temp Light" setting
- You're using press + rotate (not just rotate)

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

**Current Version:** 1.1
- ✅ Enhanced device behavior documentation
- ✅ Auto-toggle feature
- ✅ Mode awareness
- ✅ Speed detection
- ✅ All manufacturer variants

---

## Community

**Forum Post:** [Coming soon]
**Issues:** [GitHub Issues](https://github.com/gunnjr/ha-resources/issues)

---

## License

MIT License - Use freely with attribution

---

**Built with comprehensive device analysis** | [View Research](../../../research/zigbee/devices/tuya-ts004f/)
