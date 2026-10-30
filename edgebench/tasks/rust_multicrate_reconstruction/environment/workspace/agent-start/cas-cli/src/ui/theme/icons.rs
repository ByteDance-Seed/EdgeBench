//! Centralized Unicode icon/symbol definitions

/// Unicode icons and symbols for consistent UI rendering
pub struct Icons;

impl Icons {
    // Status indicators
    pub const CHECK: &'static str = "\u{2713}"; // ✓
    pub const CROSS: &'static str = "\u{2717}"; // ✗
    pub const WARNING: &'static str = "\u{26A0}"; // ⚠
    pub const INFO: &'static str = "\u{2139}"; // ℹ
    pub const QUESTION: &'static str = "?";

    // Circles
    pub const CIRCLE_FILLED: &'static str = "\u{25CF}"; // ●
    pub const CIRCLE_EMPTY: &'static str = "\u{25CB}"; // ○
    pub const CIRCLE_HALF: &'static str = "\u{25D0}"; // ◐
    pub const CIRCLE_DOTTED: &'static str = "\u{25CC}"; // ◌
    pub const CIRCLE_X: &'static str = "\u{2298}"; // ⊘
    pub const CIRCLE_DOT: &'static str = "\u{2299}"; // ⊙

    // Progress/spinners
    pub const SPINNER: [&'static str; 10] = [
        "\u{280B}", "\u{2819}", "\u{2839}", "\u{2838}", "\u{283C}", "\u{2834}", "\u{2826}",
        "\u{2827}", "\u{2807}", "\u{280F}",
    ];
    pub const SPINNER_STATIC: &'static str = "\u{25D4}"; // ◔ - static spinner for non-animated contexts
    pub const BLOCKED: &'static str = "\u{26D4}"; // ⛔ - blocked/no entry
    pub const PROGRESS_EMPTY: &'static str = "\u{2591}"; // ░
    pub const PROGRESS_LIGHT: &'static str = "\u{2592}"; // ▒
    pub const PROGRESS_MEDIUM: &'static str = "\u{2593}"; // ▓
    pub const PROGRESS_FULL: &'static str = "\u{2588}"; // █

    // Arrows
    pub const ARROW_RIGHT: &'static str = "\u{2192}"; // →
    pub const ARROW_LEFT: &'static str = "\u{2190}"; // ←
    pub const ARROW_UP: &'static str = "\u{2191}"; // ↑
    pub const ARROW_DOWN: &'static str = "\u{2193}"; // ↓
    pub const ARROW_UP_RIGHT: &'static str = "\u{2197}"; // ↗
    pub const ARROW_DOWN_RIGHT: &'static str = "\u{2198}"; // ↘

    // Chevrons
    pub const CHEVRON_RIGHT: &'static str = "\u{203A}"; // ›
    pub const CHEVRON_LEFT: &'static str = "\u{2039}"; // ‹
    pub const CHEVRON_DOWN: &'static str = "\u{02C5}"; // ˅
    pub const CHEVRON_UP: &'static str = "\u{02C4}"; // ˄

    // Triangles
    pub const TRIANGLE_RIGHT: &'static str = "\u{25B8}"; // ▸
    pub const TRIANGLE_DOWN: &'static str = "\u{25BE}"; // ▾
    pub const TRIANGLE_UP: &'static str = "\u{25B4}"; // ▴
    pub const TRIANGLE_LEFT: &'static str = "\u{25C2}"; // ◂

    // Priority indicators
    pub const PRIORITY_CRITICAL: &'static str = "!!";
    pub const PRIORITY_HIGH: &'static str = "!";
    pub const PRIORITY_MEDIUM: &'static str = "\u{25B8}"; // ▸
    pub const PRIORITY_LOW: &'static str = "\u{25CB}"; // ○
    pub const PRIORITY_BACKLOG: &'static str = "\u{00B7}"; // ·

    // Task type icons
    pub const TYPE_BUG: &'static str = "\u{1F41B}"; // 🐛
    pub const TYPE_FEATURE: &'static str = "\u{2728}"; // ✨
    pub const TYPE_TASK: &'static str = "\u{1F4CB}"; // 📋
    pub const TYPE_EPIC: &'static str = "\u{1F3AF}"; // 🎯
    pub const TYPE_CHORE: &'static str = "\u{1F527}"; // 🔧

    // List markers
    pub const BULLET: &'static str = "\u{2022}"; // •
    pub const DASH: &'static str = "\u{2013}"; // –
    pub const LIST_POINTER: &'static str = "\u{203A} "; // ›
    pub const LIST_POINTER_ACTIVE: &'static str = "\u{25B6} "; // ▶

    // Box drawing - rounded corners
    pub const BOX_ROUND_TL: &'static str = "\u{256D}"; // ╭
    pub const BOX_ROUND_TR: &'static str = "\u{256E}"; // ╮
    pub const BOX_ROUND_BL: &'static str = "\u{2570}"; // ╰
    pub const BOX_ROUND_BR: &'static str = "\u{256F}"; // ╯
    pub const BOX_HORIZONTAL: &'static str = "\u{2500}"; // ─
    pub const BOX_VERTICAL: &'static str = "\u{2502}"; // │

    // Separators
    pub const SEPARATOR: &'static str = "\u{2500}"; // ─
    pub const SEPARATOR_DOUBLE: &'static str = "\u{2550}"; // ═
    pub const SEPARATOR_DOTTED: &'static str = "\u{2504}"; // ┄
    pub const VERTICAL_LINE: &'static str = "\u{2502}"; // │
    pub const PIPE: &'static str = " \u{2502} "; // │ with spacing

    // Miscellaneous
    pub const ELLIPSIS: &'static str = "\u{2026}"; // …
    pub const STAR: &'static str = "\u{2605}"; // ★
    pub const STAR_EMPTY: &'static str = "\u{2606}"; // ☆
    pub const HEART: &'static str = "\u{2665}"; // ♥
    pub const LOCK: &'static str = "\u{1F512}"; // 🔒
    pub const UNLOCK: &'static str = "\u{1F513}"; // 🔓
    pub const FOLDER: &'static str = "\u{1F4C1}"; // 📁
    pub const FILE: &'static str = "\u{1F4C4}"; // 📄
    pub const CLOCK: &'static str = "\u{23F1}"; // ⏱
    pub const LIGHTNING: &'static str = "\u{26A1}"; // ⚡
    pub const SEARCH: &'static str = "\u{1F50D}"; // 🔍
    pub const GEAR: &'static str = "\u{2699}"; // ⚙

    // Trend indicators
    pub const TREND_UP: &'static str = "\u{25B2}"; // ▲
    pub const TREND_DOWN: &'static str = "\u{25BC}"; // ▼
    pub const TREND_FLAT: &'static str = "\u{25AC}"; // ▬

    // Agent types
    pub const AGENT_PRIMARY: &'static str = "P";
    pub const AGENT_SUB: &'static str = "S";
    pub const AGENT_WORKER: &'static str = "W";
    pub const AGENT_CI: &'static str = "C";
}
