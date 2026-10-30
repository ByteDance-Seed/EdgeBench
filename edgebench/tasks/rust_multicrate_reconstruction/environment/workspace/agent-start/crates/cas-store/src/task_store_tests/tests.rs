use crate::task_store::*;
use tempfile::TempDir;

fn create_test_store() -> (TempDir, SqliteTaskStore) { todo!() }

#[test]
fn test_task_crud() {
    let (_temp, store) = create_test_store();

    // Create task
    let id = store.generate_id().unwrap();
    let mut task = Task::new(id.clone(), "Test task".to_string());
    task.priority = Priority::HIGH;
    store.add(&task).unwrap();

    // Get task
    let retrieved = store.get(&id).unwrap();
    assert_eq!(retrieved.title, "Test task");
    assert_eq!(retrieved.priority, Priority::HIGH);

    // Update task
    task.status = TaskStatus::InProgress;
    task.notes = "Working on it".to_string();
    store.update(&task).unwrap();

    let retrieved = store.get(&id).unwrap();
    assert_eq!(retrieved.status, TaskStatus::InProgress);
    assert_eq!(retrieved.notes, "Working on it");

    // List tasks
    let all_tasks = store.list(None).unwrap();
    assert_eq!(all_tasks.len(), 1);

    let in_progress = store.list(Some(TaskStatus::InProgress)).unwrap();
    assert_eq!(in_progress.len(), 1);

    let open = store.list(Some(TaskStatus::Open)).unwrap();
    assert_eq!(open.len(), 0);

    // Delete task
    store.delete(&id).unwrap();
    assert!(store.get(&id).is_err());
}

#[test]
fn test_dependencies() {
    let (_temp, store) = create_test_store();

    // Create two tasks
    let task1 = Task::new(store.generate_id().unwrap(), "Task 1".to_string());
    let task2 = Task::new(store.generate_id().unwrap(), "Task 2".to_string());
    store.add(&task1).unwrap();
    store.add(&task2).unwrap();

    // Add dependency: task2 blocks task1
    let dep = Dependency::new(task1.id.clone(), task2.id.clone(), DependencyType::Blocks);
    store.add_dependency(&dep).unwrap();

    // Check dependencies
    let deps = store.get_dependencies(&task1.id).unwrap();
    assert_eq!(deps.len(), 1);
    assert_eq!(deps[0].to_id, task2.id);

    // Check dependents
    let dependents = store.get_dependents(&task2.id).unwrap();
    assert_eq!(dependents.len(), 1);
    assert_eq!(dependents[0].from_id, task1.id);

    // Check blockers
    let blockers = store.get_blockers(&task1.id).unwrap();
    assert_eq!(blockers.len(), 1);
    assert_eq!(blockers[0].id, task2.id);

    // Remove dependency
    store.remove_dependency(&task1.id, &task2.id).unwrap();
    let deps = store.get_dependencies(&task1.id).unwrap();
    assert!(deps.is_empty());
}

#[test]
fn test_ready_tasks() {
    let (_temp, store) = create_test_store();

    // Create tasks
    let task1 = Task::new(store.generate_id().unwrap(), "Task 1".to_string());
    let task2 = Task::new(store.generate_id().unwrap(), "Task 2".to_string());
    let task3 = Task::new(store.generate_id().unwrap(), "Task 3".to_string());
    store.add(&task1).unwrap();
    store.add(&task2).unwrap();
    store.add(&task3).unwrap();

    // All should be ready initially
    let ready = store.list_ready().unwrap();
    assert_eq!(ready.len(), 3);

    // Add blocking dependency: task2 blocks task1
    let dep = Dependency::new(task1.id.clone(), task2.id.clone(), DependencyType::Blocks);
    store.add_dependency(&dep).unwrap();

    // task1 should not be ready
    let ready = store.list_ready().unwrap();
    assert_eq!(ready.len(), 2);
    assert!(!ready.iter().any(|t| t.id == task1.id));

    // Close task2, task1 should be ready again
    let mut task2_updated = store.get(&task2.id).unwrap();
    task2_updated.status = TaskStatus::Closed;
    store.update(&task2_updated).unwrap();

    let ready = store.list_ready().unwrap();
    assert_eq!(ready.len(), 2); // task1 and task3 (task2 is closed)
    assert!(ready.iter().any(|t| t.id == task1.id));
}

#[test]
fn test_cycle_detection() {
    let (_temp, store) = create_test_store();

    // Create tasks
    let task1 = Task::new(store.generate_id().unwrap(), "Task 1".to_string());
    let task2 = Task::new(store.generate_id().unwrap(), "Task 2".to_string());
    let task3 = Task::new(store.generate_id().unwrap(), "Task 3".to_string());
    store.add(&task1).unwrap();
    store.add(&task2).unwrap();
    store.add(&task3).unwrap();

    // Create chain: task1 -> task2 -> task3
    let dep1 = Dependency::new(task1.id.clone(), task2.id.clone(), DependencyType::Blocks);
    let dep2 = Dependency::new(task2.id.clone(), task3.id.clone(), DependencyType::Blocks);
    store.add_dependency(&dep1).unwrap();
    store.add_dependency(&dep2).unwrap();

    // Trying to add task3 -> task1 should detect cycle
    assert!(store.would_create_cycle(&task3.id, &task1.id).unwrap());

    // But task3 -> task2 won't create a cycle (already exists in reverse)
    assert!(!store.would_create_cycle(&task1.id, &task3.id).unwrap());
}

#[test]
fn test_sibling_notes_and_parent_epic() {
    let (_temp, store) = create_test_store();

    // Create epic
    let mut epic = Task::new(store.generate_id().unwrap(), "Test Epic".to_string());
    epic.task_type = TaskType::Epic;
    store.add(&epic).unwrap();

    // Create subtasks with notes
    let mut subtask1 = Task::new(store.generate_id().unwrap(), "Subtask 1".to_string());
    subtask1.notes = "[2026-02-03 14:30] 💡 DISCOVERY API uses camelCase".to_string();
    store.add(&subtask1).unwrap();

    let mut subtask2 = Task::new(store.generate_id().unwrap(), "Subtask 2".to_string());
    subtask2.notes = "[2026-02-03 15:00] ✅ DECISION Use existing helper".to_string();
    store.add(&subtask2).unwrap();

    let subtask3 = Task::new(store.generate_id().unwrap(), "Subtask 3".to_string());
    // No notes on subtask3
    store.add(&subtask3).unwrap();

    // Link subtasks to epic via ParentChild dependency
    let dep1 = Dependency::new(
        subtask1.id.clone(),
        epic.id.clone(),
        DependencyType::ParentChild,
    );
    let dep2 = Dependency::new(
        subtask2.id.clone(),
        epic.id.clone(),
        DependencyType::ParentChild,
    );
    let dep3 = Dependency::new(
        subtask3.id.clone(),
        epic.id.clone(),
        DependencyType::ParentChild,
    );
    store.add_dependency(&dep1).unwrap();
    store.add_dependency(&dep2).unwrap();
    store.add_dependency(&dep3).unwrap();

    // Test get_sibling_notes from subtask3's perspective
    let siblings = store.get_sibling_notes(&epic.id, &subtask3.id).unwrap();
    assert_eq!(siblings.len(), 2); // subtask1 and subtask2 have notes

    // Verify the notes content
    let notes_content: Vec<&str> = siblings.iter().map(|(_, _, n)| n.as_str()).collect();
    assert!(notes_content.iter().any(|n| n.contains("camelCase")));
    assert!(notes_content.iter().any(|n| n.contains("existing helper")));

    // Test get_parent_epic
    let parent = store.get_parent_epic(&subtask1.id).unwrap();
    assert!(parent.is_some());
    assert_eq!(parent.unwrap().id, epic.id);

    // Epic itself has no parent
    let no_parent = store.get_parent_epic(&epic.id).unwrap();
    assert!(no_parent.is_none());
}
