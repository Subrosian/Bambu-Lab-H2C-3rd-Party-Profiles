#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BBL_ROOT="$HOME/Library/Application Support/BambuStudio/system"
BBL_JSON="$BBL_ROOT/BBL.json"
MANIFEST="$SCRIPT_DIR/manifests/profiles.json"

echo "Bambu Lab H2C Third-Party Filament Profiles"
echo "macOS installer"
echo

if pgrep -x "BambuStudio" >/dev/null 2>&1 || pgrep -x "Bambu Studio" >/dev/null 2>&1; then
	echo "Please quit Bambu Studio completely before running this installer."
	read -r -p "Press Return to close..."
	exit 1
fi

if [ ! -f "$BBL_JSON" ]; then
	echo "Could not find:"
	echo "$BBL_JSON"
	echo
	echo "Open Bambu Studio once, then quit it and run this installer again."
	read -r -p "Press Return to close..."
	exit 1
fi

if [ ! -f "$MANIFEST" ]; then
	echo "Could not find the profile manifest:"
	echo "$MANIFEST"
	read -r -p "Press Return to close..."
	exit 1
fi

# Preflight every managed profile before touching Bambu Studio.
# This catches the H2C template/cardinality error that caused Bambu Studio to reject earlier builds.
/usr/bin/osascript -l JavaScript - "$SCRIPT_DIR" <<'JXA'
function run(argv) {
	let app = Application.currentApplication();
	app.includeStandardAdditions = true;
	let scriptDir = argv[0];
	let manifest = JSON.parse(app.read(Path(scriptDir + "/manifests/profiles.json"), {as: "text"}));
	let three = {
		filament_cooling_before_tower:1, filament_flow_ratio:1,
		filament_max_volumetric_speed:1, filament_retraction_length:1,
		filament_wipe:1, filament_wipe_distance:1, filament_z_hop_types:1,
		filament_pre_cooling_temperature:1, filament_pre_cooling_temperature_nc:1,
		filament_ramming_travel_time:1, filament_ramming_travel_time_nc:1,
		filament_ramming_volumetric_speed:1, filament_retract_length_nc:1,
		filament_preheat_temperature_delta:1, nozzle_temperature:1,
		nozzle_temperature_initial_layer:1, slow_down_min_speed:1
	};
	Object.keys(manifest.brands).forEach(function(brand) {
		manifest.brands[brand].forEach(function(entry) {
			let p = scriptDir + "/" + entry.path;
			let j = JSON.parse(app.read(Path(p), {as: "text"}));
			if (!j.include || j.include.length !== 1 || j.include[0] !== "fdm_filament_template_direct_dual_e3d")
				throw new Error(entry.name + ": invalid H2C include template");
			Object.keys(three).forEach(function(k) {
				if (j[k] && j[k].length !== 3)
					throw new Error(entry.name + ": " + k + " must have 3 H2C channel values");
			});
		});
	});
	return "Profile preflight passed.";
}
JXA

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$BBL_JSON.backup-$STAMP"
cp -p "$BBL_JSON" "$BACKUP"

echo "Backup created:"
echo "$BACKUP"
echo

/usr/bin/osascript -l JavaScript - "$SCRIPT_DIR" "$BBL_JSON" <<'JXA'
function shellQuote(s) {
	return "'" + String(s).replace(/'/g, "'\\''") + "'";
}

function readFile(app, path) {
	return app.read(Path(path), {as: "text"});
}

function writeFile(app, path, text) {
	let file = app.openForAccess(Path(path), {writePermission: true});
	try {
		app.setEof(file, {to: 0});
		app.write(text, {to: file, startingAt: 0});
	} finally {
		app.closeAccess(file);
	}
}

function run(argv) {
	let app = Application.currentApplication();
	app.includeStandardAdditions = true;

	let scriptDir = argv[0];
	let bblPath = argv[1];
	let manifestPath = scriptDir + "/manifests/profiles.json";

	let library = JSON.parse(readFile(app, manifestPath));
	let bbl = JSON.parse(readFile(app, bblPath));

	if (!Array.isArray(bbl.filament_list)) {
		throw new Error("BBL.json does not contain a filament_list array.");
	}

	let installed = {};
	bbl.filament_list.forEach(function(entry) {
		if (entry && entry.name) {
			installed[entry.name] = true;
		}
	});

	let baseDir = bblPath.substring(0, bblPath.lastIndexOf("/"));
	let added = 0;
	let copied = 0;

	Object.keys(library.brands).forEach(function(brand) {
		let destDir = baseDir + "/BBL/filament/" + brand;
		app.doShellScript("/bin/mkdir -p " + shellQuote(destDir));

		library.brands[brand].forEach(function(entry) {
			let source = scriptDir + "/" + entry.path;
			let filename = entry.name + ".json";
			let dest = destDir + "/" + filename;

			app.doShellScript(
				"/bin/test -f " + shellQuote(source) +
				" && /bin/cp -f " + shellQuote(source) + " " + shellQuote(dest)
			);
			copied++;

			if (!installed[entry.name]) {
				bbl.filament_list.push({
					name: entry.name,
					sub_path: "filament/" + brand + "/" + filename
				});
				installed[entry.name] = true;
				added++;
			}
		});
	});

	writeFile(app, bblPath, JSON.stringify(bbl, null, 4) + "\n");
	return "Copied/updated " + copied + " profile files; added " + added + " new Bambu Studio entries.";
}
JXA

echo
echo "Installation complete."
echo "No Python, Git, Xcode, Homebrew, or Command Line Tools are required."
echo
read -r -p "Press Return to close..."
