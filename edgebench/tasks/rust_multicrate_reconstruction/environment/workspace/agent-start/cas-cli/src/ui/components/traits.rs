//! Core component traits for CAS TUI
//!
//! Two-tier trait system:
//! - `Renderable`: Static output (tables, lists, status displays)
//! - `Component`: Interactive Elm Architecture (select menus, wizards, confirmations)

use std::io;

use super::formatter::Formatter;

/// Result of a component update cycle
pub enum Action<Msg> {
    /// No side effects
    None,
    /// Execute a command that produces a message
    Cmd(Box<dyn FnOnce() -> Msg + Send>),
    /// Batch of commands to execute
    Batch(Vec<Box<dyn FnOnce() -> Msg + Send>>),
    /// Component requests exit
    Quit,
}

/// Static output component — render once and done.
///
/// Use for tables, lists, status displays, and any output that doesn't need
/// keyboard interaction. The formatter handles TTY detection and styling.
///
/// ```ignore
/// struct TaskList { tasks: Vec<Task> }
///
/// impl Renderable for TaskList {
///     fn render(&self, fmt: &mut Formatter) -> io::Result<()> {
///         fmt.heading("Tasks")?;
///         for task in &self.tasks {
///             fmt.status(&task.title, &task.status)?;
///         }
///         Ok(())
///     }
/// }
/// ```
pub trait Renderable {
    /// Render this component to the formatter's output stream.
    fn render(&self, fmt: &mut Formatter) -> io::Result<()>;
}

/// Interactive component using the Elm Architecture (Model/Update/View).
///
/// Components receive messages (typically from keyboard events), update their
/// state, and re-render. The `Program` runner drives the event loop.
///
/// ```ignore
/// struct SelectMenu {
///     items: Vec<String>,
///     selected: usize,
/// }
///
/// enum SelectMsg {
///     Up,
///     Down,
///     Confirm,
///     Cancel,
/// }
///
/// impl Component for SelectMenu {
///     type Msg = SelectMsg;
///     type Output = Option<usize>;
///
///     fn update(&mut self, msg: SelectMsg) -> Action<SelectMsg> {
///         match msg {
///             SelectMsg::Up => { self.selected = self.selected.saturating_sub(1); Action::None }
///             SelectMsg::Down => { self.selected = (self.selected + 1).min(self.items.len() - 1); Action::None }
///             SelectMsg::Confirm => Action::Quit,
///             SelectMsg::Cancel => { self.selected = usize::MAX; Action::Quit }
///         }
///     }
///
///     fn view(&self, fmt: &mut Formatter) -> io::Result<()> {
///         for (i, item) in self.items.iter().enumerate() {
///             if i == self.selected {
///                 fmt.write_accent(&format!("› {item}"))?;
///             } else {
///                 fmt.write_secondary(&format!("  {item}"))?;
///             }
///             fmt.newline()?;
///         }
///         Ok(())
///     }
///
///     fn output(&self) -> Option<usize> {
///         if self.selected < self.items.len() { Some(self.selected) } else { None }
///     }
/// }
/// ```
pub trait Component {
    /// Message type for this component (keyboard events, timer ticks, etc.)
    type Msg;

    /// Output type extracted after the component quits
    type Output;

    /// Update state in response to a message, returning an action.
    fn update(&mut self, msg: Self::Msg) -> Action<Self::Msg>;

    /// Render the current state to the formatter.
    fn view(&self, fmt: &mut Formatter) -> io::Result<()>;

    /// Extract the final output after the component has quit.
    fn output(&self) -> Self::Output;
}

#[cfg(test)]
mod tests {
    use super::*;

    struct Counter {
        count: i32,
    }

    enum CounterMsg {
        Increment,
        Decrement,
        Quit,
    }

    impl Component for Counter {
        type Msg = CounterMsg;
        type Output = i32;

        fn update(&mut self, msg: CounterMsg) -> Action<CounterMsg> {
            match msg {
                CounterMsg::Increment => {
                    self.count += 1;
                    Action::None
                }
                CounterMsg::Decrement => {
                    self.count -= 1;
                    Action::None
                }
                CounterMsg::Quit => Action::Quit,
            }
        }

        fn view(&self, fmt: &mut Formatter) -> io::Result<()> {
            fmt.write_primary(&format!("Count: {}", self.count))?;
            fmt.newline()
        }

        fn output(&self) -> i32 {
            self.count
        }
    }


    #[test]
    fn test_component_view_renders() {
        let counter = Counter { count: 42 };
        let mut buf = Vec::new();
        let mut fmt = Formatter::plain(&mut buf);

        counter.view(&mut fmt).unwrap();
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Count: 42"));
    }

    struct StaticMessage {
        text: String,
    }

    impl Renderable for StaticMessage {
        fn render(&self, fmt: &mut Formatter) -> io::Result<()> {
            fmt.write_primary(&self.text)?;
            fmt.newline()
        }
    }


    #[test]
    fn test_action_cmd_produces_message() {
        let action: Action<CounterMsg> = Action::Cmd(Box::new(|| CounterMsg::Increment));

        match action {
            Action::Cmd(f) => {
                let msg = f();
                assert!(matches!(msg, CounterMsg::Increment));
            }
            _ => panic!("Expected Cmd"),
        }
    }

    #[test]
    fn test_action_batch() {
        let action: Action<CounterMsg> = Action::Batch(vec![
            Box::new(|| CounterMsg::Increment),
            Box::new(|| CounterMsg::Increment),
        ]);

        match action {
            Action::Batch(cmds) => assert_eq!(cmds.len(), 2),
            _ => panic!("Expected Batch"),
        }
    }
}
