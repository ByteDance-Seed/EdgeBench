    #[test]
    fn test_roundtrip_small() {
        let data = b"Hello, world!";
        let compressed = compress(data);
        let decompressed = decompress(&compressed).unwrap();
        assert_eq!(data.as_slice(), decompressed.as_slice());
    }

    #[test]
    fn test_incompressible_data_stays_uncompressed() {
        // High-entropy data that doesn't compress well
        // Even if above threshold, if compression makes it bigger, keep uncompressed
        let data: Vec<u8> = (0..300).map(|i| ((i * 127 + 53) % 256) as u8).collect();
        let result = compress(&data);
        let decompressed = decompress(&result).unwrap();
        assert_eq!(data, decompressed);
    }
