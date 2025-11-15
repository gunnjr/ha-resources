# Home Assistant Resources – Build-Out Plan

This document captures the plan for how this repository will be built out over time, along with key design decisions and notes from the initial planning discussion.

The goal is to keep the repo **self-documenting** so that it can grow without requiring constant manual updates to this file or the top-level README.

---

## 1. Purpose of This Repo

- Provide a **single landing zone** for Home Assistant-related artifacts:
  - Blueprints (starting with Tuya TS004F smart knob).
  - Zigbee/ZHA device research and notes.
  - Shell scripts and tooling (e.g., log helpers, troubleshooting aids).
  - Operational and hardening docs for a Home Assistant environment.
- Serve as the **canonical source of truth** for things shared with the HA community (e.g., via forum posts).
- Act as a staging area for anything that might later be contributed to more formal upstream projects (ZHA quirks, HACS integrations, etc.).

---

## 2. Guiding Principles

These principles are meant to keep the repo maintainable and low-friction:

1. **Self-documenting structure**
   - Let directory names and local READMEs/INDEX files do most of the explaining.
   - Avoid giant, fragile tables in the root README that must be edited every time something is added.

2. **Single repo for shared artifacts**
   - Use this repo for blueprints, docs, scripts, and general tooling.
   - Reserve separate repos only for items that have strong structural constraints (e.g., HACS integrations).

3. **Forum for distribution, repo for source of truth**
   - Share finished artifacts (blueprints, guides, tools) on the Home Assistant Community Forum.
   - Link back here for canonical files, raw imports, and deeper documentation.

4. **Incremental build-out**
   - Start small with a minimal scaffold.
   - Add structure, docs, and content **as needed**, driven by real use and sharing.

5. **Low-update README**
   - Keep the main README intentionally generic and stable.
   - Put fast-changing details in per-folder docs instead.

---

## 3. Initial Directory Layout

The scaffold created by the setup script looks like this:

- `blueprints/`
  - `tuya-ts004f/` – Blueprints, notes, and research related to the Tuya TS004F smart knob.
- `scripts/` – Shell scripts and small utilities (e.g., log helpers, analysis tools).
- `zigbee/`
  - `quirks/` – Device- or vendor-specific quirks notes.
- `tools/` – Supporting tools that are **not** HACS integrations.
- `docs/` – Longer-form documentation, how-tos, and reference notes.

Each directory is expected to grow its own short `README.md` or `INDEX.md` when there is something non-obvious to explain.

---

## 4. Planned Build-Out Phases

This plan is intentionally high-level so it stays valid as the repo evolves.

### Phase 1 – Foundations

- [ ] Initialize the repo and commit the scaffold.
- [ ] Add an improved blueprint for the **Tuya TS004F Smart Knob** under `blueprints/tuya-ts004f/`.
- [ ] Add a small `README.md` in `blueprints/tuya-ts004f/` describing:
  - Supported hardware.
  - Blueprint variants (e.g., command/dimmer vs event/scene focused).
  - How to import the blueprint into Home Assistant.

### Phase 2 – Device Research and Documentation

- [ ] Add a `device-notes.md` or similar file for the TS004F, including:
  - Zigbee signature and clusters.
  - Notes on modes (command/dimmer vs event/scene).
  - Known quirks and workarounds.
  - Example `zha_event` payloads.
- [ ] Start a `zigbee/device-database.md` documenting other devices as they are analyzed.

### Phase 3 – Scripts and Operational Tooling

- [ ] Add scripts related to HA logs and troubleshooting, for example:
  - `save-log.sh` – Save a snapshot of `ha core logs` output.
  - `tail-ha-logs.sh` – Follow Home Assistant core logs.
  - `tail-zha.sh` – Focus specifically on ZHA-related log lines.
- [ ] Add usage comments at the top of each script so they are self-explanatory.
- [ ] Optionally add a `scripts/README.md` that describes conventions and examples.

### Phase 4 – Broader Docs and Hardening Notes

- [ ] Add `docs/ha-hardening.md` for environment-hardening approaches.
- [ ] Add `docs/zha-vs-z2m.md` with notes on tradeoffs and migration considerations.
- [ ] Capture lessons learned from real debugging sessions (Zigbee routing issues, device dropouts, logging strategies, etc.).

### Phase 5 – Community Integration

- [ ] Publish a post on the Home Assistant Community Forum for the TS004F blueprint(s) and link back to this repo.
- [ ] As other artifacts mature, create forum posts that:
  - Explain the problem being solved.
  - Point to the specific folder or file in this repo.
  - Optionally include HA blueprint import links or config snippets.

### Phase 6 – Upstream and Ecosystem Contributions (As Needed)

- [ ] For any robust Zigbee device understanding:
  - Evaluate whether a ZHA or zigpy quirk contribution is appropriate.
- [ ] For any generalized tooling:
  - Consider extracting into dedicated repos and optionally publishing via HACS.

These later phases are opportunistic and only happen if/when the artifacts prove broadly useful.

---

## 5. Key Design Decisions (Summary of Discussion)

This section summarizes the reasoning behind the current approach and captures the core of the prior discussion.

1. **Start with a personal repo rather than hunting for a perfect central hub.**
   - There are partial hubs (HA Community Forum, "awesome" lists, HACS, Zigbee2MQTT device pages), but none that serve as a flexible, general-purpose home for:
     - Blueprints
     - Device research
     - Scripts
     - Hardening and operations docs
   - Conclusion: create a canonical personal repo and use the existing community channels for distribution.

2. **Single repo for most artifacts, separate repos for HACS integrations.**
   - HACS integrations have strict structural requirements and deserve their own dedicated repos.
   - Everything else (blueprints, scripts, docs, research) can live here without friction.

3. **Forum as the main communication channel.**
   - The Home Assistant Community Forum is where people actually discover and discuss content.
   - This repo acts as the backing store that forum posts can link to.

4. **Prefer incremental structure over heavy up-front design.**
   - Start with a handful of well-named directories.
   - Let real use drive the need for additional structure and documentation.

5. **Minimize maintenance overhead for documentation.**
   - Keep the root README small and timeless.
   - Use small, local docs in subdirectories for specifics.
   - Keep this `BUILD_PLAN.md` high-level so it remains accurate as the repo grows.

---

## 6. How to Extend This Plan

As the repo evolves:

- When you add a new category of content (e.g., another device family, another logging tool):
  - Create a directory with a clear, descriptive name.
  - Add a tiny `README.md` inside explaining the purpose and how to use the contents.
- When a pattern of work emerges (e.g., repeated device research notes):
  - Add or refine a template inside the relevant directory.
- If you make a significant structural or strategic decision:
  - Add a short bullet to the **Key Design Decisions** section above.

This way, the repo can grow organically without constant top-level surgery.

