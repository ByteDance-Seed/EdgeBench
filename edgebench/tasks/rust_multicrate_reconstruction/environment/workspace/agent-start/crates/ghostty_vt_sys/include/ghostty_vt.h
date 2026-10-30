/**
 * @file ghostty_vt.h
 * @brief C API for libghostty-vt terminal emulation
 *
 * This header provides the C interface to Ghostty's terminal emulation library.
 * It allows embedding terminal emulation in applications without the full
 * Ghostty terminal application.
 */

#ifndef GHOSTTY_VT_H
#define GHOSTTY_VT_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Opaque handle to a terminal instance.
 */
typedef void* ghostty_vt_terminal_t;

/**
 * RGB color value.
 */
typedef struct {
    uint8_t r;
    uint8_t g;
    uint8_t b;
} ghostty_vt_rgb_t;

/**
 * Cell style information.
 */
typedef struct {
    ghostty_vt_rgb_t fg;
    ghostty_vt_rgb_t bg;
    uint32_t flags;
} ghostty_vt_cell_style_t;

/**
 * Style run for efficient rendering.
 * Represents a contiguous range of cells with the same style.
 */
typedef struct {
    uint32_t start_col;
    uint32_t end_col;
    ghostty_vt_cell_style_t style;
} ghostty_vt_style_run_t;

/* Cell style flags */
#define GHOSTTY_VT_STYLE_BOLD          (1 << 0)
#define GHOSTTY_VT_STYLE_ITALIC        (1 << 1)
#define GHOSTTY_VT_STYLE_UNDERLINE     (1 << 2)
#define GHOSTTY_VT_STYLE_STRIKETHROUGH (1 << 3)
#define GHOSTTY_VT_STYLE_INVERSE       (1 << 4)
#define GHOSTTY_VT_STYLE_BLINK         (1 << 5)
#define GHOSTTY_VT_STYLE_DIM           (1 << 6)
#define GHOSTTY_VT_STYLE_HIDDEN        (1 << 7)

/* Key modifier flags */
#define GHOSTTY_VT_MOD_SHIFT (1 << 0)
#define GHOSTTY_VT_MOD_CTRL  (1 << 1)
#define GHOSTTY_VT_MOD_ALT   (1 << 2)
#define GHOSTTY_VT_MOD_SUPER (1 << 3)

/* ============================================================================
 * Terminal Lifecycle
 * ========================================================================= */

/**
 * Create a new terminal instance.
 *
 * @param rows Number of rows.
 * @param cols Number of columns.
 * @return Terminal handle, or NULL on failure.
 */
ghostty_vt_terminal_t ghostty_vt_terminal_new(uint32_t rows, uint32_t cols);

/**
 * Free a terminal instance.
 *
 * @param terminal Terminal handle (may be NULL).
 */
void ghostty_vt_terminal_free(ghostty_vt_terminal_t terminal);

/* ============================================================================
 * Input Processing
 * ========================================================================= */

/**
 * Feed data to the terminal (process PTY output).
 *
 * @param terminal Terminal handle.
 * @param data Byte data to process.
 * @param len Length of data in bytes.
 * @return 0 on success, non-zero on error.
 */
int ghostty_vt_terminal_feed(ghostty_vt_terminal_t terminal,
                              const uint8_t* data,
                              size_t len);

/* ============================================================================
 * Terminal Dimensions
 * ========================================================================= */

/**
 * Resize the terminal.
 *
 * @param terminal Terminal handle.
 * @param rows New number of rows.
 * @param cols New number of columns.
 * @return 0 on success, non-zero on error.
 */
int ghostty_vt_terminal_resize(ghostty_vt_terminal_t terminal,
                                uint32_t rows,
                                uint32_t cols);

/**
 * Get cursor position.
 *
 * @param terminal Terminal handle.
 * @param row Output: cursor row (0-indexed).
 * @param col Output: cursor column (0-indexed).
 */
void ghostty_vt_terminal_cursor_position(ghostty_vt_terminal_t terminal,
                                          uint32_t* row,
                                          uint32_t* col);

/* ============================================================================
 * Color Palette
 * ========================================================================= */

/**
 * Set the terminal color palette.
 *
 * @param terminal Terminal handle.
 * @param colors Array of 256 RGB entries.
 * @param len Length of colors array (must be 256).
 * @return 0 on success, non-zero on error.
 */
int ghostty_vt_terminal_set_palette(
    ghostty_vt_terminal_t terminal,
    const ghostty_vt_rgb_t* colors,
    size_t len);

/* ============================================================================
 * Viewport Content
 * ========================================================================= */

/**
 * Dump viewport content as UTF-8.
 *
 * @param terminal Terminal handle.
 * @param out_len Output: length of returned buffer.
 * @return Pointer to UTF-8 buffer (must be freed with ghostty_vt_bytes_free),
 *         or NULL on error.
 */
char* ghostty_vt_terminal_dump_viewport(ghostty_vt_terminal_t terminal,
                                         size_t* out_len);

/**
 * Get cell styles for a viewport row.
 *
 * @param terminal Terminal handle.
 * @param row Row index (0-indexed from viewport top).
 * @param out_count Output: number of styles returned.
 * @return Pointer to style array (must be freed with ghostty_vt_bytes_free),
 *         or NULL on error.
 */
ghostty_vt_cell_style_t* ghostty_vt_terminal_dump_viewport_row_cell_styles(
    ghostty_vt_terminal_t terminal,
    uint32_t row,
    size_t* out_count);

/**
 * Get style runs for a viewport row.
 *
 * Style runs are more efficient for rendering as they group consecutive
 * cells with the same style.
 *
 * @param terminal Terminal handle.
 * @param row Row index (0-indexed from viewport top).
 * @param out_count Output: number of runs returned.
 * @return Pointer to style run array (must be freed with ghostty_vt_bytes_free),
 *         or NULL on error.
 */
ghostty_vt_style_run_t* ghostty_vt_terminal_dump_viewport_row_style_runs(
    ghostty_vt_terminal_t terminal,
    uint32_t row,
    size_t* out_count);

/**
 * Get rows that have changed since last call.
 *
 * This function returns the indices of rows that have been modified and
 * clears the dirty flags.
 *
 * @param terminal Terminal handle.
 * @param out_count Output: number of dirty row indices.
 * @return Pointer to array of row indices (must be freed with ghostty_vt_bytes_free),
 *         or NULL if no dirty rows.
 */
uint32_t* ghostty_vt_terminal_take_dirty_viewport_rows(
    ghostty_vt_terminal_t terminal,
    size_t* out_count);

/* ============================================================================
 * Scrolling
 * ========================================================================= */

/**
 * Scroll viewport.
 *
 * @param terminal Terminal handle.
 * @param delta Lines to scroll (positive = down, negative = up).
 * @return 0 on success, non-zero on error.
 */
int ghostty_vt_terminal_scroll_viewport(ghostty_vt_terminal_t terminal,
                                         int delta);

/**
 * Get and reset scroll delta since last call.
 *
 * @param terminal Terminal handle.
 * @return Scroll delta since last call.
 */
int ghostty_vt_terminal_take_viewport_scroll_delta(
    ghostty_vt_terminal_t terminal);

/* ============================================================================
 * Colors
 * ========================================================================= */

/**
 * Set default foreground and background colors.
 *
 * @param terminal Terminal handle.
 * @param fg Default foreground color.
 * @param bg Default background color.
 */
void ghostty_vt_terminal_set_default_colors(ghostty_vt_terminal_t terminal,
                                             ghostty_vt_rgb_t fg,
                                             ghostty_vt_rgb_t bg);

/* ============================================================================
 * Hyperlinks
 * ========================================================================= */

/**
 * Get hyperlink URI at position.
 *
 * @param terminal Terminal handle.
 * @param row Row index.
 * @param col Column index.
 * @param out_len Output: length of URI string.
 * @return Pointer to URI string (must be freed with ghostty_vt_bytes_free),
 *         or NULL if no hyperlink at position.
 */
char* ghostty_vt_terminal_hyperlink_at(ghostty_vt_terminal_t terminal,
                                        uint32_t row,
                                        uint32_t col,
                                        size_t* out_len);

/* ============================================================================
 * Key Encoding
 * ========================================================================= */

/**
 * Encode a named key (arrows, function keys, etc.).
 *
 * @param key Key name (e.g., "Up", "Down", "F1").
 * @param modifiers Modifier flags (GHOSTTY_VT_MOD_*).
 * @param out_buf Output buffer for encoded sequence.
 * @param buf_len Length of output buffer.
 * @return Number of bytes written, or negative on error.
 */
int ghostty_vt_encode_key_named(const char* key,
                                 uint8_t modifiers,
                                 uint8_t* out_buf,
                                 size_t buf_len);

/* ============================================================================
 * Memory Management
 * ========================================================================= */

/**
 * Free a buffer returned by ghostty_vt functions.
 *
 * @param ptr Pointer to buffer (may be NULL).
 */
void ghostty_vt_bytes_free(void* ptr);

#ifdef __cplusplus
}
#endif

#endif /* GHOSTTY_VT_H */
