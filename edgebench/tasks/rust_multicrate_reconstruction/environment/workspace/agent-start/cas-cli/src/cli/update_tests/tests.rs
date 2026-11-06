use crate::cli::update::*;

#[test]
fn test_is_newer() {
    assert!(is_newer("0.3.0", "0.2.0"));
    assert!(is_newer("0.2.1", "0.2.0"));
    assert!(is_newer("1.0.0", "0.9.9"));
    assert!(!is_newer("0.2.0", "0.2.0"));
    assert!(!is_newer("0.1.0", "0.2.0"));
    assert!(is_newer("v0.3.0", "0.2.0"));
    assert!(is_newer("0.3.0", "v0.2.0"));
}
