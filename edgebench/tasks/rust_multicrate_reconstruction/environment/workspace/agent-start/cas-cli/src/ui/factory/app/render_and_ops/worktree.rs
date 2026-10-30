use crate::ui::factory::app::imports::*;

impl FactoryApp {
    /// Get the project path
    pub fn project_path(&self) -> &std::path::Path { todo!() }

    /// Create an epic branch from the current branch
    pub fn create_epic_branch(&self, epic_title: &str) -> anyhow::Result<String> { todo!() }

    /// Merge all worker branches to the epic branch
    pub fn merge_workers_to_epic(&self) -> anyhow::Result<Vec<(String, bool, Option<String>)>> { todo!() }

    /// Cleanup worker branches after epic completion
    ///
    /// Deletes all worker branches that have been merged into the epic branch.
    pub fn cleanup_worker_branches(&self, force: bool) -> anyhow::Result<Vec<String>> { todo!() }
}
