fn main() {
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("macos") {
        // Bundled apps load the embedded framework. Unbundled development and
        // test binaries need the verified local framework installed by setup.
        println!("cargo:rustc-link-arg=-Wl,-rpath,@executable_path/../Frameworks");
        if std::env::var("PROFILE").as_deref() == Ok("debug") {
            println!(
                "cargo:rustc-link-arg=-Wl,-rpath,{}",
                std::env::var("CARGO_MANIFEST_DIR").unwrap()
            );
        }
    }
    tauri_build::build()
}
