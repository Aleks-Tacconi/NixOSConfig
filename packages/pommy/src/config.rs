//! Resolve the daily notes directory from the environment.
use std::{
    env, io,
    path::{Path, PathBuf},
};

/// Read the required notes directory and expand a leading home-directory marker.
pub fn notes_dir() -> io::Result<PathBuf> {
    let directory = env::var_os("POMMY_NOTES_DIR")
        .ok_or_else(|| io::Error::other("Set POMMY_NOTES_DIR to your daily notes directory"))?;
    let home = env::var_os("HOME").map(PathBuf::from);
    resolve_directory(Path::new(&directory), home.as_deref())
}

/// Accept absolute paths or paths starting with ~, including directory names with spaces.
fn resolve_directory(directory: &Path, home: Option<&Path>) -> io::Result<PathBuf> {
    let path = if let Ok(relative) = directory.strip_prefix("~") {
        home.ok_or_else(|| io::Error::other("HOME is required to expand ~ in POMMY_NOTES_DIR"))?
            .join(relative)
    } else {
        directory.to_path_buf()
    };
    if !path.is_absolute() {
        return Err(io::Error::other(
            "POMMY_NOTES_DIR must be an absolute path or start with ~/",
        ));
    }
    Ok(path)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Directory resolution preserves spaces and expands only a leading home marker.
    #[test]
    fn resolves_directory() {
        let home = Some(Path::new("/home/aleks"));
        assert_eq!(
            resolve_directory(Path::new("~/ObsidianVault/04 DailyNotes"), home).unwrap(),
            PathBuf::from("/home/aleks/ObsidianVault/04 DailyNotes")
        );
        assert_eq!(
            resolve_directory(Path::new("/tmp/notes"), None).unwrap(),
            PathBuf::from("/tmp/notes")
        );
        for invalid in ["", "notes", "~someone/notes"] {
            assert!(resolve_directory(Path::new(invalid), home).is_err());
        }
        assert!(resolve_directory(Path::new("~/notes"), None).is_err());
    }
}
