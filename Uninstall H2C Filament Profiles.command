#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BBL_ROOT="$HOME/Library/Application Support/BambuStudio/system"
BBL_JSON="$BBL_ROOT/BBL.json"
MANIFEST="$SCRIPT_DIR/manifests/profiles.json"

echo "Bambu Lab H2C Third-Party Filament Profiles"
echo "macOS uninstaller"
echo

if pgrep -x "BambuStudio" >/dev/null 2>&1 || pgrep -x "Bambu Studio" >/dev/null 2>&1; then
	echo "Please quit Bambu Studio completely before running this uninstaller."
	read -r -p "Press Return to close..."
	exit 1
fi

if [ ! -f "$BBL_JSON" ]; then
	echo "Could not find:"
	echo "$BBL_JSON"
	read -r -p "Press Return to close..."
	exit 1
fi

if [ ! -f "$MANIFEST" ]; then
	echo "Could not find the profile manifest:"
	echo "$MANIFEST"
	read -r -p "Press Return to close..."
	exit 1
fi

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

	let managed = {};
	Object.keys(library.brands).forEach(function(brand) {
		library.brands[brand].forEach(function(entry) {
			managed[entry.name] = true;
		});
	});

	let before = bbl.filament_list.length;
	bbl.filament_list = bbl.filament_list.filter(function(entry) {
		return !(entry && managed[entry.name]);
	});

	let baseDir = bblPath.substring(0, bblPath.lastIndexOf("/"));
	Object.keys(library.brands).forEach(function(brand) {
		let destDir = baseDir + "/BBL/filament/" + brand;
		library.brands[brand].forEach(function(entry) {
			let dest = destDir + "/" + entry.name + ".json";
			app.doShellScript("/bin/rm -f " + shellQuote(dest));
		});
	});

	writeFile(app, bblPath, JSON.stringify(bbl, null, 4) + "\n");
	return "Removed " + (before - bbl.filament_list.length) + " managed Bambu Studio entries.";
}
JXA

echo
echo "Uninstallation complete."
echo "No Python, Git, Xcode, Homebrew, or Command Line Tools are required."
echo
read -r -p "Press Return to close..."
