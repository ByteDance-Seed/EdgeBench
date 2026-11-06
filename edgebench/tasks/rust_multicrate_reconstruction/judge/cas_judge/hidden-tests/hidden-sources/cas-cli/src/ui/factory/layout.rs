    #[test]
    fn test_mission_control_layout_zero_workers() {
        let area = Rect::new(0, 0, 80, 24);
        let mc = MissionControlLayout::calculate(area, 0);

        // Workers table should get minimum 3 rows
        assert!(mc.workers_area.height >= 3);

        // All areas should be non-zero width
        assert!(mc.tasks_area.width > 0);
        assert!(mc.changes_area.width > 0);
        assert!(mc.activity_area.width > 0);
    }
