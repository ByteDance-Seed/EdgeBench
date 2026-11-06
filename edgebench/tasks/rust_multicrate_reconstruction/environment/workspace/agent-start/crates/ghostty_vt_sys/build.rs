use std::env;
use std::path::PathBuf;
use std::process::Command;

fn run(mut cmd: Command, what: &str) {
    let status = cmd.status().unwrap_or_else(|err| {
        panic!("failed to run {what}: {err}");
    });
    if !status.success() {
        panic!("{what} failed with status {status}");
    }
}

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let workspace_root = manifest_dir
        .parent()
        .and_then(|p| p.parent())
        .expect("Could not find workspace root");

    let stub_dir = workspace_root.join(".ghostty-stub");
    let stub_c = stub_dir.join("ghostty_vt_stub.c");
    let stub_o = stub_dir.join("ghostty_vt_stub.o");
    let stub_a = stub_dir.join("libghostty_vt.a");

    if stub_c.exists() {
        println!("cargo:rerun-if-changed={}", stub_c.display());

        let cc = env::var("CC").unwrap_or_else(|_| "cc".to_string());
        let mut compile = Command::new(cc);
        compile.arg("-c").arg(&stub_c).arg("-o").arg(&stub_o);
        run(compile, "compile ghostty VT C stub");

        if env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("macos")
            && Command::new("libtool").arg("-V").output().is_ok()
        {
            let mut archive = Command::new("libtool");
            archive.arg("-static").arg("-o").arg(&stub_a).arg(&stub_o);
            run(archive, "archive ghostty VT C stub");
        } else {
            let ar = env::var("AR").unwrap_or_else(|_| "ar".to_string());
            let mut archive = Command::new(ar);
            archive.arg("rcs").arg(&stub_a).arg(&stub_o);
            run(archive, "archive ghostty VT C stub");
        }
    }

    println!("cargo:rustc-link-search=native={}", stub_dir.display());
    println!("cargo:rustc-link-lib=static=ghostty_vt");
    println!("cargo:rustc-link-lib=c");
}
