#[test]
fn doctor_no_color_env() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let output = cas_in_dir(&temp)
        .arg("doctor")
        .env("NO_COLOR", "1")
        .output()
        .expect("failed to run cas doctor");

    let stdout = String::from_utf8(output.stdout).unwrap();
    assert!(
        !stdout.contains('\x1b'),
        "NO_COLOR=1 output contains ANSI escape codes:\n{stdout}"
    );
}

#[test]
fn help_piped_no_ansi() {
    let output = cas_cmd()
        .arg("--help")
        .output()
        .expect("failed to run cas --help");

    let stdout = String::from_utf8(output.stdout).unwrap();
    assert!(
        !stdout.contains('\x1b'),
        "Help output contains ANSI escape codes:\n{stdout}"
    );
}

#[test]
fn doctor_snapshot() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let output = cas_in_dir(&temp)
        .arg("doctor")
        .env("NO_COLOR", "1")
        .output()
        .expect("failed to run cas doctor");

    let stdout = String::from_utf8(output.stdout).unwrap();
    // Redact dynamic values (paths, timestamps, sizes)
    let redacted = redact_dynamic_values(&stdout);
    insta::assert_snapshot!(redacted);
}

#[test]
fn status_empty_snapshot() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let output = cas_in_dir(&temp)
        .arg("status")
        .env("NO_COLOR", "1")
        .output()
        .expect("failed to run cas status");

    let stdout = String::from_utf8(output.stdout).unwrap();
    let redacted = redact_dynamic_values(&stdout);
    insta::assert_snapshot!(redacted);
}
