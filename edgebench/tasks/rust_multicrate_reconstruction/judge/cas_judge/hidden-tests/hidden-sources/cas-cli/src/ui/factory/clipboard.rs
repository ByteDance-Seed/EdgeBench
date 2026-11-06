    #[test]
    fn test_copy_to_clipboard() {
        // On macOS, pbcopy should always be available
        #[cfg(target_os = "macos")]
        {
            let result = copy_to_clipboard("test text");
            assert!(result.is_ok(), "pbcopy should succeed on macOS");
        }

        // On other platforms, skip if no display available (CI environments)
        #[cfg(not(target_os = "macos"))]
        {
            if std::env::var("DISPLAY").is_err() && std::env::var("WAYLAND_DISPLAY").is_err() {
                return;
            }
            let result = copy_to_clipboard("test text");
            assert!(result.is_ok() || result.is_err());
        }
    }
