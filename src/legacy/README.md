Archived legacy files

These files were identified as developer/test helper or legacy UI/system modules that are not required by the current game runtime on the `develop` branch.

Purpose
- Preserve the original files in a safe location so they can be reviewed, migrated, or deleted later.

How to restore
- To restore a file, move it back to its original location (e.g. `git mv src/legacy/filename.lua path/to/original`) and run the test suite.

Notes
- These are preserved copies only. They are not loaded by the running game unless you explicitly require them.
