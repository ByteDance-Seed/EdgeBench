use crate::ui::factory::app::imports::*;

fn bool_prop(value: bool) -> &'static str { todo!() }

fn shutdown_scope(count: Option<usize>, names: &[String]) -> &'static str { todo!() }

impl FactoryApp {
    /// Get the current epic state
    pub fn epic_state(&self) -> &EpicState { todo!() }

    /// Handle epic state transitions based on detected events
    ///
    /// Returns true if state changed (for branch management).
    pub fn handle_epic_events(&mut self, events: &[DirectorEvent]) -> Vec<EpicStateChange> { todo!() }

    /// Reset epic state to idle (after merge completes)
    pub fn reset_epic_state(&mut self) { todo!() }

    /// Add a new worker at runtime (synchronous - blocks during worktree creation).
    ///
    /// Creates a worktree (if isolate is true and worktrees enabled) and spawns a Claude instance.
    /// For non-blocking spawning, use `prepare_worker_spawn` + `finish_worker_spawn`.
    pub fn spawn_worker(&mut self, name: Option<&str>, isolate: bool) -> anyhow::Result<String> { todo!() }

    /// Phase 1: Prepare spawn data (fast, runs on main thread).
    ///
    /// Resolves the worker name, computes paths, and returns a `WorkerSpawnPrep`
    /// that can be sent to a background thread for the slow git operations.
    ///
    /// When `isolate` is true and worktrees are configured, each worker gets its
    /// own git worktree and branch. When false, workers share the main working directory.
    pub fn prepare_worker_spawn(
        &mut self,
        name: Option<&str>,
        isolate: bool,
    ) -> anyhow::Result<WorkerSpawnPrep> { todo!() }

    /// Phase 3: Finish spawn on main thread (fast - adds pane to mux, updates tracking).
    ///
    /// `teams` provides per-worker Agent Teams CLI flags. When `Some`, the spawned
    /// agent will bootstrap with native Teams inbox polling. The daemon builds this
    /// from `TeamsManager::spawn_config_for()` for each worker individually.
    pub fn finish_worker_spawn(
        &mut self,
        result: WorkerSpawnResult,
        teams: Option<cas_mux::TeamsSpawnConfig>,
    ) -> anyhow::Result<String> { todo!() }

    /// Shutdown a worker by name
    ///
    /// Removes the worker pane and cleans up its clone (if any).
    ///
    /// # Arguments
    /// * `name` - Worker name to shutdown
    /// * `_force` - Reserved for compatibility; supervisor should decide shutdown safety
    pub fn shutdown_worker(&mut self, name: &str, _force: bool) -> anyhow::Result<()> { todo!() }

    /// Mark a worker as crashed (removes from tracking, keeps worktree for respawn)
    ///
    /// This is called when a worker PTY exits unexpectedly. Unlike `shutdown_worker`,
    /// this does not try to remove from mux (it's already gone) and preserves the
    /// worktree directory for potential respawn.
    pub fn mark_worker_crashed(&mut self, name: &str) { todo!() }

    /// Respawn a crashed worker
    ///
    /// Re-creates a worker with the same name, reusing its existing worktree if available.
    pub fn respawn_worker(
        &mut self,
        name: &str,
        teams: Option<cas_mux::TeamsSpawnConfig>,
    ) -> anyhow::Result<()> { todo!() }

    /// Shutdown N workers (least recently used first, or by name)
    ///
    /// If count is 0 or None, shuts down all workers.
    ///
    /// # Arguments
    /// * `count` - Number of workers to shutdown (0 or None = all)
    /// * `names` - Specific worker names to shutdown (overrides count)
    /// * `force` - Reserved for compatibility; supervisor should pre-check worktree safety
    pub fn shutdown_workers(
        &mut self,
        count: Option<usize>,
        names: &[String],
        force: bool,
    ) -> anyhow::Result<usize> { todo!() }
}
