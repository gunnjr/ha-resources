# Bathroom Lighting Normalization + TS004F Knob Control
A multi-part Home Assistant project for achieving **smooth, consistent, synchronized dimming** across mixed hardware—driven by a **physical Zigbee rotary knob**.

This project combines:
- A **custom integration** for dimming normalization
- A **HACS integration** for dynamic log level control
- A **TS004F smart knob blueprint** for intuitive physical control
- A **Home Assistant light group** tying normalized proxies together

This README explains the architecture and how the components fit together.

---

# 🎯 Goal
To provide a **single physical rotary knob** that reliably and smoothly dims **multiple heterogeneous lights in sync**, even if the underlying lights:

- Have different dimming curves  
- Support different brightness ranges  
- Behave inconsistently at low/high brightness  

The end result is a cohesive, natural-feeling dimming experience.

---

# 🧩 Project Components

## 1. Normalize Lights Integration
A custom integration that creates **normalized light proxy entities**.  
Each proxy:

- Maps HA brightness (0–255) into a custom range between:
  - **LLV** – Low Light Value  
  - **HLD** – High Light Dimming  
- Smooths out perceived brightness differences between bulbs
- Ensures all wrapped lights feel consistent when dimmed together
- Provides a foundation for **room-level controllers** later

This makes dissimilar hardware behave as if it were matched.

> **Repo:** https://github.com/gunnjr/normalize_lights_integration


---

## 2. Logger Manager (HACS Integration)
During development, I needed fine-grained log control for debugging:

- Zigbee events  
- State transitions on normalized entities  
- Mapping behavior between proxies and real lights  

The **logger_manager** integration provides:
- UI-based logger level changes  
- Real‑time log tuning without restarting HA  
- Multi‑logger presets for troubleshooting  

[![Open in Home Assistant](https://my.home-assistant.io/badges/hacs_repository.svg)](https://my.home-assistant.io/redirect/hacs_repository/?owner=gunnjr&repository=ha-logger-manager&category=integration)
> **Repo:** https://github.com/gunnjr/ha-logger-manager

---

## 3. TS004F Knob Blueprint
A reusable Home Assistant blueprint for the **Tuya TS004F Smart Knob**.

Features:
- Smooth rotation → brightness up/down  
- Short/long press → configurable actions  
- Sensible defaults for dimmable entities  
- Works with either:
  - A single light  
  - A normalized proxy  
  - A multi‑light group  

This is the “physical interface” for the whole system.

> **Blueprint repo:** https://github.com/gunnjr/ha-resources/tree/main/ha-assets/blueprints/tuya-ts004f

---

# 🔗 How Everything Works Together

```
TS004F Knob Events
        ↓
Blueprint
        ↓
Normalized Light Group (target)
        ↓
Normalize Lights Integration
        ↓
Per‑Light Proxy Mapping (LLV/HLD curves)
        ↓
Physical Lights
```

### Result:
- All lights rise/fall **together**
- The brightness curve feels **natural**
- The knob behaves like a true wired dimmer, but smarter

---

# 🛠️ Example Setup Structure

Entities (example):

```
light.mba_s1_1         → Wrapped by → light.mba_s1_1_normalized
light.mba_s1_2         → Wrapped by → light.mba_s1_2_normalized
light.mba_s1_3         → Wrapped by → light.mba_s1_3_normalized

Group: light.mba_all_normalized
    members:
      - light.mba_s1_1_normalized
      - light.mba_s1_2_normalized
      - light.mba_s1_3_normalized

Blueprint → light.mba_all_normalized
```

---

# 🚀 What This Enables

### ✓ Use a physical rotary knob as a room dimmer  
Feels like a high‑end wall dimmer—even in a retrofit scenario.

### ✓ Normalize inconsistent hardware  
Philips LEDs, smart drivers, and no‑name Zigbee lights can all be matched.

### ✓ Build room‑level scenes and controllers  
The proxy layer makes multi-device behavior predictable.

### ✓ Debugging that doesn’t require YAML edits or HA restarts  
`logger_manager` keeps troubleshooting fast.

---

# 📌 Why This Exists
I built this because nothing in HA (or any integration) could solve:

- Mixed dimmer behavior across brands  
- Low-end flickering  
- Uneven brightness at matching percentages  
- Physical controls that feel right  

What started as a bathroom tweak became a generalized, reusable solution.

---

# 📈 Roadmap Ideas
- UI for LLV/HLD calibration  
- Per-room controller entity  
- Scene-aware rotation handling  
- More knob/device support  
- Normalize color temperature or RGBW values  

---

# 💬 Feedback Welcome
Open issues, PRs, or discussions for:

- Better bright/dim curve modeling  
- Enhancing the TS004F behavior  
- Support for additional Zigbee knobs  
- Ideas for a more generic “room controller” entity  

---

# 🙌 Thanks
Huge shoutout to the Home Assistant community—docs, quirks, blueprints, and discussions all made this project possible.

If any part of this architecture is helpful for your setup, feel free to reuse, fork, remix, or build on top of it.
