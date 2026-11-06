use crate::error::StoreError;
use crate::sqlite::{SCHEMA, SqliteRuleStore};
use crate::tracing::{DevTracer, TraceTimer};
use crate::{Result, RuleStore};
use cas_types::{Rule, RuleStatus};
use chrono::Utc;
use rusqlite::{OptionalExtension, params};

impl RuleStore for SqliteRuleStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, rule: &Rule) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Rule> { todo!() }

    fn update(&self, rule: &Rule) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self) -> Result<Vec<Rule>> { todo!() }

    fn list_proven(&self) -> Result<Vec<Rule>> { todo!() }

    fn list_critical(&self) -> Result<Vec<Rule>> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}
