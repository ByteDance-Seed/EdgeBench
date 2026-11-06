/*
 * Stub implementation of libghostty_vt for benchmark offline builds.
 * All functions return failure/empty values — sufficient for compilation
 * and test discovery but not for actual terminal emulation.
 */

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef void* ghostty_vt_terminal_t;

typedef struct { uint8_t r, g, b; } ghostty_vt_rgb_t;
typedef struct { ghostty_vt_rgb_t fg, bg; uint32_t flags; } ghostty_vt_cell_style_t;
typedef struct { uint32_t start_col, end_col; ghostty_vt_cell_style_t style; } ghostty_vt_style_run_t;

ghostty_vt_terminal_t ghostty_vt_terminal_new(uint32_t rows, uint32_t cols) {
    (void)rows; (void)cols;
    return calloc(1, 64);
}

void ghostty_vt_terminal_free(ghostty_vt_terminal_t terminal) {
    free(terminal);
}

int ghostty_vt_terminal_feed(ghostty_vt_terminal_t terminal,
                              const uint8_t* data, size_t len) {
    (void)terminal; (void)data; (void)len;
    return 0;
}

int ghostty_vt_terminal_resize(ghostty_vt_terminal_t terminal,
                                uint32_t rows, uint32_t cols) {
    (void)terminal; (void)rows; (void)cols;
    return 0;
}

void ghostty_vt_terminal_cursor_position(ghostty_vt_terminal_t terminal,
                                          uint32_t* row, uint32_t* col) {
    (void)terminal;
    if (row) *row = 0;
    if (col) *col = 0;
}

int ghostty_vt_terminal_set_palette(ghostty_vt_terminal_t terminal,
                                     uint8_t index,
                                     uint8_t r, uint8_t g, uint8_t b) {
    (void)terminal; (void)index; (void)r; (void)g; (void)b;
    return 0;
}

char* ghostty_vt_terminal_dump_viewport(ghostty_vt_terminal_t terminal,
                                         uint32_t row) {
    (void)terminal; (void)row;
    char* s = malloc(1);
    if (s) s[0] = '\0';
    return s;
}

ghostty_vt_cell_style_t* ghostty_vt_terminal_dump_viewport_row_cell_styles(
    ghostty_vt_terminal_t terminal, uint32_t row, uint32_t* count) {
    (void)terminal; (void)row;
    if (count) *count = 0;
    return NULL;
}

ghostty_vt_style_run_t* ghostty_vt_terminal_dump_viewport_row_style_runs(
    ghostty_vt_terminal_t terminal, uint32_t row, uint32_t* count) {
    (void)terminal; (void)row;
    if (count) *count = 0;
    return NULL;
}

uint32_t* ghostty_vt_terminal_take_dirty_viewport_rows(
    ghostty_vt_terminal_t terminal, uint32_t* count) {
    (void)terminal;
    if (count) *count = 0;
    return NULL;
}

int ghostty_vt_terminal_scroll_viewport(ghostty_vt_terminal_t terminal,
                                         int32_t delta) {
    (void)terminal; (void)delta;
    return 0;
}

int ghostty_vt_terminal_take_viewport_scroll_delta(
    ghostty_vt_terminal_t terminal, int32_t* delta) {
    (void)terminal;
    if (delta) *delta = 0;
    return 0;
}

void ghostty_vt_terminal_set_default_colors(ghostty_vt_terminal_t terminal,
                                              ghostty_vt_rgb_t fg,
                                              ghostty_vt_rgb_t bg) {
    (void)terminal; (void)fg; (void)bg;
}

char* ghostty_vt_terminal_hyperlink_at(ghostty_vt_terminal_t terminal,
                                        uint32_t row, uint32_t col) {
    (void)terminal; (void)row; (void)col;
    return NULL;
}

int ghostty_vt_encode_key_named(const char* key,
                                 uint32_t mods,
                                 char* buf,
                                 size_t buf_len,
                                 size_t* out_len) {
    (void)key; (void)mods; (void)buf; (void)buf_len;
    if (out_len) *out_len = 0;
    return -1;
}

void ghostty_vt_bytes_free(void* ptr) {
    free(ptr);
}

char* ghostty_vt_terminal_dump_viewport_row(ghostty_vt_terminal_t terminal,
                                              uint32_t row,
                                              uint32_t* len) {
    (void)terminal; (void)row;
    if (len) *len = 0;
    char* s = malloc(1);
    if (s) s[0] = '\0';
    return s;
}

char* ghostty_vt_terminal_dump_screen_row(ghostty_vt_terminal_t terminal,
                                            uint32_t row,
                                            uint32_t* len) {
    (void)terminal; (void)row;
    if (len) *len = 0;
    char* s = malloc(1);
    if (s) s[0] = '\0';
    return s;
}

typedef struct {
    uint32_t total_rows;
    uint32_t viewport_top;
} ghostty_vt_scrollback_info_t;

ghostty_vt_scrollback_info_t ghostty_vt_terminal_scrollback_info(
    ghostty_vt_terminal_t terminal) {
    (void)terminal;
    ghostty_vt_scrollback_info_t info = {0, 0};
    return info;
}

int ghostty_vt_terminal_scroll_viewport_top(ghostty_vt_terminal_t terminal) {
    (void)terminal;
    return 0;
}

int ghostty_vt_terminal_scroll_viewport_bottom(ghostty_vt_terminal_t terminal) {
    (void)terminal;
    return 0;
}

ghostty_vt_style_run_t* ghostty_vt_terminal_screen_row_style_runs(
    ghostty_vt_terminal_t terminal, uint32_t row, uint32_t* count) {
    (void)terminal; (void)row;
    if (count) *count = 0;
    return NULL;
}
