    #[test]
    fn test_tool_not_found_error() {
        let err = McpError::ToolNotFound("unknown_tool".to_string());
        assert!(err.to_string().contains("tool not found"));
        assert!(err.to_string().contains("unknown_tool"));
    }

    #[test]
    fn test_transport_error() {
        let err = McpError::Transport("connection lost".to_string());
        assert!(err.to_string().contains("transport error"));
    }

    #[test]
    fn test_other_error() {
        let err = McpError::Other("something went wrong".to_string());
        assert_eq!(err.to_string(), "something went wrong");
    }
