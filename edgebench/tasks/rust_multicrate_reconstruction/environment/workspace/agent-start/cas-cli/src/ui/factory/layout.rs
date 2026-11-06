//! Layout calculation for the factory TUI

use std::collections::HashMap;

use cas_mux::Mux;
use ratatui::layout::{Constraint, Direction as RatatuiDirection, Layout, Rect};

use crate::ui::factory::input::LayoutSizes;

/// Minimum width in columns for a worker pane to be usable
pub const MIN_WORKER_WIDTH: u16 = 45;
/// Height of the worker tab bar in tabbed mode
pub const WORKER_TAB_BAR_HEIGHT: u16 = 3;

/// Pane ID for the sidecar panel
pub const PANE_SIDECAR: &str = "sidecar";

/// Direction for pane navigation
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Direction {
    Up,
    Down,
    Left,
    Right,
}

/// Spatial grid for pane navigation
///
/// Tracks the (row, col) position of each pane for arrow-key navigation.
/// The grid layout is:
///
/// Side-by-side mode (with workers):
/// ```text
/// Col 0    Col 1    Col 2    Col 3         Col 4
/// Row 0: [W1]     [W2]     [W3]     [Supervisor]  [Sidecar]
/// Row 1: [W4]     [W5]     [W6]     [Supervisor]  [Sidecar]
/// ```
///
/// Tabbed mode (with workers):
/// ```text
/// Col 0         Col 1         Col 2
/// [Workers]     [Supervisor]  [Sidecar]
/// ```
///
/// No workers:
/// ```text
/// Col 0         Col 1
/// [Supervisor]  [Sidecar]
/// ```
#[derive(Debug, Clone)]
pub struct PaneGrid {
    /// Map (row, col) -> pane_id
    grid: HashMap<(usize, usize), String>,
    /// Reverse map: pane_id -> (row, col)
    positions: HashMap<String, (usize, usize)>,
    /// Grid dimensions (rows, cols)
    dims: (usize, usize),
    /// Number of worker columns (0 if no workers or tabbed)
    worker_cols: usize,
    /// Column index of supervisor
    supervisor_col: usize,
}

impl PaneGrid {
    /// Build a PaneGrid from worker/supervisor configuration
    ///
    /// # Arguments
    /// * `worker_names` - Names of worker panes (in order)
    /// * `supervisor_name` - Name of the supervisor pane
    /// * `is_tabbed` - Whether tabbed mode is active
    pub fn new(worker_names: &[String], supervisor_name: &str, is_tabbed: bool) -> Self { todo!() }

    /// Build a PaneGrid from the current layout configuration
    ///
    /// # Arguments
    /// * `layout` - The calculated FactoryLayout
    /// * `worker_names` - Names of worker panes (in order)
    /// * `supervisor_name` - Name of the supervisor pane
    pub fn from_layout(
        layout: &FactoryLayout,
        worker_names: &[String],
        supervisor_name: &str,
    ) -> Self { todo!() }

    /// Get the pane at a specific grid position
    pub fn pane_at(&self, row: usize, col: usize) -> Option<&str> { todo!() }

    /// Get the grid position of a pane
    pub fn position_of(&self, pane_id: &str) -> Option<(usize, usize)> { todo!() }

    /// Get the neighbor pane in a given direction
    ///
    /// Returns the pane ID of the adjacent pane, or None if at edge.
    /// For supervisor/sidecar (which span all rows), up/down stays at same pane.
    pub fn neighbor(&self, pane_id: &str, dir: Direction) -> Option<&str> { todo!() }

    /// Get the grid dimensions (rows, cols)
    pub fn dims(&self) -> (usize, usize) { todo!() }

    /// Get all pane IDs in the grid
    pub fn pane_ids(&self) -> impl Iterator<Item = &str> { todo!(); #[allow(unreachable_code)] std::iter::empty() }
}

/// Layout areas for the factory UI
pub struct FactoryLayout {
    /// Area for the header bar
    pub header_bar: Rect,
    /// Area for the worker tab bar (only in tabbed mode with workers)
    pub worker_tab_bar: Option<Rect>,
    /// Areas for individual worker panes (side-by-side mode)
    pub worker_areas: Vec<Rect>,
    /// Area for tabbed worker content (tabbed mode only)
    pub worker_content: Option<Rect>,
    /// Area for the supervisor pane
    pub supervisor_area: Rect,
    /// Area for the sidecar panels (Tasks, Agents, Changes, Activity)
    pub sidecar_area: Rect,
    /// Area for the status bar
    pub status_bar: Rect,
    /// Whether tabbed mode is active (either requested or auto-enabled due to space)
    pub is_tabbed: bool,
}

impl FactoryLayout {
    /// Calculate layout for the given area
    ///
    /// Side-by-side mode (default):
    /// ```text
    /// [              Header Bar (2 rows)            ]
    /// [ Worker1 | Worker2 | ... ] [Supervisor] [Sidecar]
    /// [              Status Bar                     ]
    /// ```
    ///
    /// Tabbed mode:
    /// ```text
    /// [              Header Bar (2 rows)            ]
    /// [ [1] w1 [2] w2 ] [Supervisor] [Sidecar]  <- Tab bar
    /// [  Worker View  ] [           ] [        ]
    /// [              Status Bar                     ]
    /// ```
    pub fn calculate(
        area: Rect,
        _mux: &Mux,
        worker_names: &[String],
        tabbed: bool,
        sidecar_collapsed: bool,
        custom_sizes: Option<LayoutSizes>,
    ) -> Self { todo!() }

    /// Calculate layout without requiring a Mux reference
    ///
    /// This is useful when rendering state that has been serialized or when
    /// the Mux is not available (e.g., in playback mode).
    pub fn calculate_from_names(
        area: Rect,
        worker_names: &[String],
        _supervisor_name: &str,
        tabbed: bool,
        sidecar_collapsed: bool,
        custom_sizes: Option<LayoutSizes>,
    ) -> Self { todo!() }

    /// Calculate layout without requiring a Mux reference, with configurable header rows.
    pub fn calculate_from_names_with_header_rows(
        area: Rect,
        worker_names: &[String],
        tabbed: bool,
        sidecar_collapsed: bool,
        custom_sizes: Option<LayoutSizes>,
        header_rows: u16,
    ) -> Self { todo!() }
}

/// Layout areas for the Mission Control dashboard view.
///
/// ```text
/// [ Status Strip (1 row): epic + counts + chips ]
/// [      Workers Panel (2 lines per worker)      ]
/// [ Tasks (40%) | Changes (25%) | Activity (35%)]
/// [              Status Bar (1 row)              ]
/// ```
pub struct MissionControlLayout {
    /// Status strip: compact epic progress + task counts + worker chips (1 row).
    pub status_strip: Rect,
    /// Workers table area (dynamic height, full width).
    pub workers_area: Rect,
    /// Tasks panel (bottom-left, 40%).
    pub tasks_area: Rect,
    /// Changes panel (bottom-center, 25%).
    pub changes_area: Rect,
    /// Activity panel (bottom-right, 35%).
    pub activity_area: Rect,
    /// Status bar (1 row).
    pub status_bar: Rect,
}

impl MissionControlLayout {
    /// Calculate Mission Control layout for the given terminal area.
    ///
    /// `worker_count` drives the dynamic height of the workers table:
    /// each worker gets two rows (status + detail), plus border rows,
    /// clamped so the bottom panels always have room.
    pub fn calculate(area: Rect, worker_count: usize) -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::ui::factory::layout::*;

    /// Create a mock FactoryLayout for testing
    fn mock_layout(is_tabbed: bool) -> FactoryLayout {
        FactoryLayout {
            header_bar: Rect::default(),
            worker_tab_bar: None,
            worker_areas: vec![],
            worker_content: None,
            supervisor_area: Rect::default(),
            sidecar_area: Rect::default(),
            status_bar: Rect::default(),
            is_tabbed,
        }
    }

    #[test]
    fn test_no_workers_grid() {
        let layout = mock_layout(false);
        let grid = PaneGrid::from_layout(&layout, &[], "supervisor");

        // Should have 2 columns: supervisor, sidecar
        assert_eq!(grid.dims(), (1, 2));

        // Check positions
        assert_eq!(grid.position_of("supervisor"), Some((0, 0)));
        assert_eq!(grid.position_of(PANE_SIDECAR), Some((0, 1)));

        // Check pane_at
        assert_eq!(grid.pane_at(0, 0), Some("supervisor"));
        assert_eq!(grid.pane_at(0, 1), Some(PANE_SIDECAR));

        // Navigation
        assert_eq!(
            grid.neighbor("supervisor", Direction::Right),
            Some(PANE_SIDECAR)
        );
        assert_eq!(grid.neighbor("supervisor", Direction::Left), None);
        assert_eq!(
            grid.neighbor(PANE_SIDECAR, Direction::Left),
            Some("supervisor")
        );
        assert_eq!(grid.neighbor(PANE_SIDECAR, Direction::Right), None);
    }

    #[test]
    fn test_tabbed_mode_grid() {
        let layout = mock_layout(true);
        let workers = vec!["w1".to_string(), "w2".to_string()];
        let grid = PaneGrid::from_layout(&layout, &workers, "supervisor");

        // Should have 3 columns: workers, supervisor, sidecar
        assert_eq!(grid.dims(), (1, 3));

        // All workers map to same position
        assert_eq!(grid.position_of("w1"), Some((0, 0)));
        assert_eq!(grid.position_of("w2"), Some((0, 0)));
        assert_eq!(grid.position_of("supervisor"), Some((0, 1)));
        assert_eq!(grid.position_of(PANE_SIDECAR), Some((0, 2)));

        // Navigation from worker column to supervisor
        assert_eq!(grid.neighbor("w1", Direction::Right), Some("supervisor"));
        assert_eq!(grid.neighbor("supervisor", Direction::Left), Some("w2")); // Last inserted worker
        assert_eq!(
            grid.neighbor("supervisor", Direction::Right),
            Some(PANE_SIDECAR)
        );
    }

    #[test]
    fn test_side_by_side_single_row() {
        let layout = mock_layout(false);
        let workers = vec!["w1".to_string(), "w2".to_string(), "w3".to_string()];
        let grid = PaneGrid::from_layout(&layout, &workers, "supervisor");

        // 3 workers + supervisor + sidecar = 5 columns, 1 row
        assert_eq!(grid.dims(), (1, 5));

        // Check worker positions
        assert_eq!(grid.position_of("w1"), Some((0, 0)));
        assert_eq!(grid.position_of("w2"), Some((0, 1)));
        assert_eq!(grid.position_of("w3"), Some((0, 2)));
        assert_eq!(grid.position_of("supervisor"), Some((0, 3)));
        assert_eq!(grid.position_of(PANE_SIDECAR), Some((0, 4)));

        // Horizontal navigation
        assert_eq!(grid.neighbor("w1", Direction::Right), Some("w2"));
        assert_eq!(grid.neighbor("w2", Direction::Right), Some("w3"));
        assert_eq!(grid.neighbor("w3", Direction::Right), Some("supervisor"));
        assert_eq!(
            grid.neighbor("supervisor", Direction::Right),
            Some(PANE_SIDECAR)
        );
        assert_eq!(grid.neighbor(PANE_SIDECAR, Direction::Right), None);

        assert_eq!(
            grid.neighbor(PANE_SIDECAR, Direction::Left),
            Some("supervisor")
        );
        assert_eq!(grid.neighbor("supervisor", Direction::Left), Some("w3"));
        assert_eq!(grid.neighbor("w1", Direction::Left), None);

        // No vertical navigation with 1 row
        assert_eq!(grid.neighbor("w1", Direction::Up), None);
        assert_eq!(grid.neighbor("w1", Direction::Down), None);
    }

    #[test]
    fn test_side_by_side_multiple_rows() {
        let layout = mock_layout(false);
        let workers = vec![
            "w1".to_string(),
            "w2".to_string(),
            "w3".to_string(),
            "w4".to_string(),
            "w5".to_string(),
        ];
        let grid = PaneGrid::from_layout(&layout, &workers, "supervisor");

        // 3 workers per row, 2 rows, + supervisor + sidecar columns = 5 cols
        assert_eq!(grid.dims(), (2, 5));

        // Check positions
        // Row 0: w1, w2, w3, supervisor, sidecar
        // Row 1: w4, w5, -, supervisor, sidecar
        assert_eq!(grid.position_of("w1"), Some((0, 0)));
        assert_eq!(grid.position_of("w2"), Some((0, 1)));
        assert_eq!(grid.position_of("w3"), Some((0, 2)));
        assert_eq!(grid.position_of("w4"), Some((1, 0)));
        assert_eq!(grid.position_of("w5"), Some((1, 1)));

        // Vertical navigation within workers
        assert_eq!(grid.neighbor("w1", Direction::Down), Some("w4"));
        assert_eq!(grid.neighbor("w4", Direction::Up), Some("w1"));
        assert_eq!(grid.neighbor("w2", Direction::Down), Some("w5"));
        assert_eq!(grid.neighbor("w5", Direction::Up), Some("w2"));

        // w3 has no worker below (row 1 only has 2 workers)
        assert_eq!(grid.neighbor("w3", Direction::Down), None);

        // Supervisor navigation - stays on supervisor (spans all rows)
        assert_eq!(
            grid.neighbor("supervisor", Direction::Up),
            Some("supervisor")
        );
        assert_eq!(
            grid.neighbor("supervisor", Direction::Down),
            Some("supervisor")
        );

        // Moving left from supervisor on different rows
        // From row 0, should go to w3
        assert_eq!(grid.neighbor("supervisor", Direction::Left), Some("w3"));

        // Right from rightmost worker goes to supervisor
        assert_eq!(grid.neighbor("w3", Direction::Right), Some("supervisor"));
        assert_eq!(grid.neighbor("w5", Direction::Right), Some("supervisor"));
    }

    #[test]
    fn test_pane_ids_iteration() {
        let layout = mock_layout(false);
        let workers = vec!["w1".to_string(), "w2".to_string()];
        let grid = PaneGrid::from_layout(&layout, &workers, "supervisor");

        let mut ids: Vec<&str> = grid.pane_ids().collect();
        ids.sort();

        assert_eq!(ids, vec![PANE_SIDECAR, "supervisor", "w1", "w2"]);
    }

    #[test]
    fn test_unknown_pane() {
        let layout = mock_layout(false);
        let grid = PaneGrid::from_layout(&layout, &[], "supervisor");

        assert_eq!(grid.position_of("unknown"), None);
        assert_eq!(grid.neighbor("unknown", Direction::Right), None);
    }

    #[test]
    fn test_mission_control_layout_areas() {
        let area = Rect::new(0, 0, 120, 40);
        let mc = MissionControlLayout::calculate(area, 3);

        // Status strip: 1 row at top
        assert_eq!(mc.status_strip.height, 1);
        assert_eq!(mc.status_strip.y, 0);
        assert_eq!(mc.status_strip.width, 120);

        // Workers: 2 border + 3*2 rows = 8 rows
        assert_eq!(mc.workers_area.height, 8);
        assert_eq!(mc.workers_area.y, 1);

        // Status bar: 1 row at bottom
        assert_eq!(mc.status_bar.height, 1);
        assert_eq!(mc.status_bar.y, 39);

        // Bottom panels share the remaining rows
        let bottom_y = mc.tasks_area.y;
        assert_eq!(mc.changes_area.y, bottom_y);
        assert_eq!(mc.activity_area.y, bottom_y);
        assert_eq!(mc.tasks_area.height, mc.changes_area.height);
        assert_eq!(mc.tasks_area.height, mc.activity_area.height);

        // Three columns sum to full width
        let total_w = mc.tasks_area.width + mc.changes_area.width + mc.activity_area.width;
        assert_eq!(total_w, 120);

        // Tasks ~40%, Changes ~25%, Activity ~35%
        assert!(mc.tasks_area.width >= 46 && mc.tasks_area.width <= 50);
        assert!(mc.changes_area.width >= 28 && mc.changes_area.width <= 32);
        assert!(mc.activity_area.width >= 40 && mc.activity_area.width <= 44);
    }

    #[test]
    fn test_mission_control_layout_many_workers_clamped() {
        let area = Rect::new(0, 0, 100, 30);
        let mc = MissionControlLayout::calculate(area, 50);

        // Workers table should be clamped so bottom panels get >= 6 rows
        let bottom_height = mc.tasks_area.height;
        assert!(
            bottom_height >= 6,
            "Bottom panels need >= 6 rows, got {bottom_height}"
        );

        // Status bar at the very bottom
        assert_eq!(mc.status_bar.y, 29);
        assert_eq!(mc.status_bar.height, 1);
    }

}
