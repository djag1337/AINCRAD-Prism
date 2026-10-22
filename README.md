# AINCRAD Prism

AINCRAD Prism is the native macOS theme workshop and the sole write authority for AINCRAD themes.

It creates, edits, saves, duplicates, deletes, imports, exports and assigns themes. AINCRAD, AINCRAD Browser and AINCRAD Discovery remain independent applications and consume the same files read-only from `~/Library/Application Support/AINCRAD/themes/`.

## Safety and migration

- **Migration Backup** copies every current theme plus assignment files into `~/Library/Application Support/AINCRAD/backups/prism/migration-<date>/` without altering originals.
- Every save, assignment and deletion first creates a timestamped backup.
- Existing JSON fields in assignment files are preserved.
- Prism uses the existing schema and distributed notifications, so running consumer apps repaint live.

## Assignment

- **Use across AINCRAD** assigns the selected theme to AINCRAD and Discovery; Browser follows it by default.
- **Browser follows AINCRAD** removes Browser's independent choice without deleting it from disk.
- **Use only in Browser** assigns the selected theme to Browser while leaving AINCRAD unchanged.

Build with XcodeGen and the `AINCRADPrism` scheme. The source-of-truth project description is `project.yml`.
