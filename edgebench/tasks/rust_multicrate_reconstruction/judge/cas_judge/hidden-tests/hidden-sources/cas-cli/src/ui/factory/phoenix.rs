    #[test]
    fn test_ws_url_http() {
        let url = ws_url("http://localhost:4000", "tok123");
        assert_eq!(
            url,
            "ws://localhost:4000/socket/websocket?token=tok123&vsn=2.0.0"
        );
    }
