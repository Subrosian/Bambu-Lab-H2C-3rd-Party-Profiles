# Bambu Lab H2C Third-Party Filament Profiles

A brand-independent collection of third-party filament profiles for the Bambu Lab H2C.

The goal of this project is to provide sensible starting profiles for third-party filament manufacturers that do not yet provide complete H2C presets in Bambu Studio.
## ⚠️ Important: AI-Assisted Project

This project was created and is maintained with substantial assistance from AI.

AI has been used to help:

- Research filament manufacturers' published specifications
- Compare material specifications with Bambu Studio profiles
- Generate and review filament profile JSON files
- Develop the macOS and Windows installers
- Organize and maintain the profile library
- Perform automated consistency and validation checks
- Write portions of this documentation
Every effort is made to verify generated profiles against manufacturer-published specifications and current Bambu Studio configuration data, but AI-generated information can be incorrect, incomplete, outdated, or based on an incorrect interpretation of source material.
### These profiles are starting points — not manufacturer-certified profiles

Unless specifically stated otherwise:
- These profiles are not created, tested, endorsed, or certified by Bambu Lab or the filament manufacturer.
- Not every profile has been physically print-tested on an H2C.
- A profile passing automated verification does not mean that it has been experimentally validated.
- Different filament colors, batches, moisture levels, nozzle sizes, and printer conditions can require different settings.
- High-speed and maximum-volumetric-speed values should be treated as starting limits rather than guaranteed capabilities.
Before relying on a profile for important or long prints, users should perform their own calibration and test prints.

At minimum, consider running:

1. Flow Dynamics calibration
2. Flow Rate calibration
3. A temperature test when necessary
4. A maximum volumetric flow test before substantially increasing MVS

Use these profiles at your own risk.

If you discover an incorrect or unsafe setting, please open an issue or submit a pull request so it can be investigated and corrected.

---
## Current brands

- SUNLU — 29 verified profiles
- ELEGOO — 16 verified profiles
- Inland — 9 verified profiles
- Flashforge — 1 verified profile (PETG-CF)
## Architecture

`profiles/<BRAND>/<MATERIAL>/` contains system profiles. `importable_profiles/<BRAND>/<MATERIAL>/` contains user-importable copies. `manifests/profiles.json` is the machine-readable registry used by both installers. `verification/` stores audit results. `sources/` records manufacturer/source references.

The installers are brand-independent. Adding a future brand only requires adding its profiles and manifest entries; the macOS and Windows installers do not need to be rewritten.
## macOS

Quit Bambu Studio, then Control-click `Install H2C Filament Profiles.command` > Open.

The macOS installer uses only tools included with macOS. **Python, Git, Xcode, Homebrew, and the Xcode Command Line Tools are not required.**

The installer uses macOS JavaScript for Automation only for JSON parsing/writing and built-in shell tools for file operations; it does not depend on Foundation Objective-C bridging.

The `.command` installer and uninstaller are packaged with executable permissions. If macOS reports an access-permissions error after downloading or extracting the repository, you can restore the permission with the built-in Terminal command `chmod +x` without installing developer tools.


### H2C schema validation

The pack now validates against the current H2C direct-dual E3D filament structure before installation. H2C per-channel filament vectors are three values wide, and profiles use `fdm_filament_template_direct_dual_e3d`.

If you installed an older broken build, keep Bambu Studio closed and run the current installer. It replaces the managed profile JSON files in place. The installer makes a timestamped `BBL.json` backup before modifying Bambu Studio.

## Windows

Quit Bambu Studio, then run `Install H2C Filament Profiles.bat`.

Both installers back up Bambu Studio's BBL.json before modifying it.

### Updating an existing installation

Quit Bambu Studio and run the current installer again. Existing managed profile files are replaced in place and existing manifest entries are not duplicated.

If an older release caused Bambu Studio to report a failed profile load, install the corrected release while Bambu Studio is closed before reopening it. You should not need to delete the entire Bambu Studio `system` folder.
## Future additions

New brands should be added under their own directory and verified against:

1. the manufacturer's current material specifications;
2. current Bambu Studio H2C profile identifiers/structure;
3. JSON/schema and unique-ID checks;
4. nozzle/material compatibility;
5. conservative MVS assumptions unless physically validated.

The current SUNLU, ELEGOO, Inland, and Flashforge verification files have been preserved in the verified pack.
