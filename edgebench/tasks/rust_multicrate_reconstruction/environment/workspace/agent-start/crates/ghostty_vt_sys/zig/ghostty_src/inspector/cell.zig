const std = @import("std");
const assert = @import("../quirks.zig").inlineAssert;
const Allocator = std.mem.Allocator;
const cimgui = @import("dcimgui");
const terminal = @import("../terminal/main.zig");

/// A cell being inspected. This duplicates much of the data in
/// the terminal data structure because we want the inspector to
/// not have a reference to the terminal state or to grab any
/// locks.
pub const Cell = struct {
    /// The main codepoint for this cell.
    codepoint: u21,

    /// Codepoints for this cell to produce a single grapheme cluster.
    /// This is only non-empty if the cell is part of a multi-codepoint
    /// grapheme cluster. This does NOT include the primary codepoint.
    cps: []const u21,

    /// The style of this cell.
    style: terminal.Style,

    /// Wide state of the terminal cell
    wide: terminal.Cell.Wide,

    pub fn init(
        alloc: Allocator,
        pin: terminal.Pin,
    ) !Cell {
        const cell = pin.rowAndCell().cell;
        const style = pin.style(cell);
        const cps: []const u21 = if (cell.hasGrapheme()) cps: {
            const src = pin.grapheme(cell).?;
            assert(src.len > 0);
            break :cps try alloc.dupe(u21, src);
        } else &.{};
        errdefer if (cps.len > 0) alloc.free(cps);

        return .{
            .codepoint = cell.codepoint(),
            .cps = cps,
            .style = style,
            .wide = cell.wide,
        };
    }

    pub fn deinit(self: *Cell, alloc: Allocator) void {
        if (self.cps.len > 0) alloc.free(self.cps);
    }

    pub fn renderTable(
        self: *const Cell,
        t: *const terminal.Terminal,
        x: usize,
        y: usize,
    ) void {
        // We have a selected cell, show information about it.
        _ = cimgui.c.ImGui_BeginTable(
            "table_cursor",
            2,
            cimgui.c.ImGuiTableFlags_None,
        );
        defer cimgui.c.ImGui_EndTable();

        {
            cimgui.c.ImGui_TableNextRow();
            {
                _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                cimgui.c.ImGui_Text("Grid Position");
            }
            {
                _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                cimgui.c.ImGui_Text("row=%d col=%d", y, x);
            }
        }

        // NOTE: we don't currently write the character itself because
        // we haven't hooked up imgui to our font system. That's hard! We
        // can/should instead hook up our renderer to imgui and just render
        // the single glyph in an image view so it looks _identical_ to the
        // terminal.
        codepoint: {
            cimgui.c.ImGui_TableNextRow();
            {
                _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                cimgui.c.ImGui_Text("Codepoints");
            }
            {
                _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                if (cimgui.c.ImGui_BeginListBox("##codepoints", .{ .x = 0, .y = 0 })) {
                    defer cimgui.c.ImGui_EndListBox();

                    if (self.codepoint == 0) {
                        _ = cimgui.c.ImGui_SelectableEx("(empty)", false, 0, .{});
                        break :codepoint;
                    }

                    // Primary codepoint
                    var buf: [256]u8 = undefined;
                    {
                        const key = std.fmt.bufPrintZ(&buf, "U+{X}", .{self.codepoint}) catch
                            "<internal error>";
                        _ = cimgui.c.ImGui_SelectableEx(key.ptr, false, 0, .{});
                    }

                    // All extras
                    for (self.cps) |cp| {
                        const key = std.fmt.bufPrintZ(&buf, "U+{X}", .{cp}) catch
                            "<internal error>";
                        _ = cimgui.c.ImGui_SelectableEx(key.ptr, false, 0, .{});
                    }
                }
            }
        }

        // Character width property
        cimgui.c.ImGui_TableNextRow();
        _ = cimgui.c.ImGui_TableSetColumnIndex(0);
        cimgui.c.ImGui_Text("Width Property");
        _ = cimgui.c.ImGui_TableSetColumnIndex(1);
        cimgui.c.ImGui_Text(@tagName(self.wide));

        // If we have a color then we show the color
        cimgui.c.ImGui_TableNextRow();
        _ = cimgui.c.ImGui_TableSetColumnIndex(0);
        cimgui.c.ImGui_Text("Foreground Color");
        _ = cimgui.c.ImGui_TableSetColumnIndex(1);
        switch (self.style.fg_color) {
            .none => cimgui.c.ImGui_Text("default"),
            .palette => |idx| {
                const rgb = t.colors.palette.current[idx];
                cimgui.c.ImGui_Text("Palette %d", idx);
                var color: [3]f32 = .{
                    @as(f32, @floatFromInt(rgb.r)) / 255,
                    @as(f32, @floatFromInt(rgb.g)) / 255,
                    @as(f32, @floatFromInt(rgb.b)) / 255,
                };
                _ = cimgui.c.ImGui_ColorEdit3(
                    "color_fg",
                    &color,
                    cimgui.c.ImGuiColorEditFlags_DisplayHex |
                        cimgui.c.ImGuiColorEditFlags_NoPicker |
                        cimgui.c.ImGuiColorEditFlags_NoLabel,
                );
            },

            .rgb => |rgb| {
                var color: [3]f32 = .{
                    @as(f32, @floatFromInt(rgb.r)) / 255,
                    @as(f32, @floatFromInt(rgb.g)) / 255,
                    @as(f32, @floatFromInt(rgb.b)) / 255,
                };
                _ = cimgui.c.ImGui_ColorEdit3(
                    "color_fg",
                    &color,
                    cimgui.c.ImGuiColorEditFlags_DisplayHex |
                        cimgui.c.ImGuiColorEditFlags_NoPicker |
                        cimgui.c.ImGuiColorEditFlags_NoLabel,
                );
            },
        }

        cimgui.c.ImGui_TableNextRow();
        _ = cimgui.c.ImGui_TableSetColumnIndex(0);
        cimgui.c.ImGui_Text("Background Color");
        _ = cimgui.c.ImGui_TableSetColumnIndex(1);
        switch (self.style.bg_color) {
            .none => cimgui.c.ImGui_Text("default"),
            .palette => |idx| {
                const rgb = t.colors.palette.current[idx];
                cimgui.c.ImGui_Text("Palette %d", idx);
                var color: [3]f32 = .{
                    @as(f32, @floatFromInt(rgb.r)) / 255,
                    @as(f32, @floatFromInt(rgb.g)) / 255,
                    @as(f32, @floatFromInt(rgb.b)) / 255,
                };
                _ = cimgui.c.ImGui_ColorEdit3(
                    "color_bg",
                    &color,
                    cimgui.c.ImGuiColorEditFlags_DisplayHex |
                        cimgui.c.ImGuiColorEditFlags_NoPicker |
                        cimgui.c.ImGuiColorEditFlags_NoLabel,
                );
            },

            .rgb => |rgb| {
                var color: [3]f32 = .{
                    @as(f32, @floatFromInt(rgb.r)) / 255,
                    @as(f32, @floatFromInt(rgb.g)) / 255,
                    @as(f32, @floatFromInt(rgb.b)) / 255,
                };
                _ = cimgui.c.ImGui_ColorEdit3(
                    "color_bg",
                    &color,
                    cimgui.c.ImGuiColorEditFlags_DisplayHex |
                        cimgui.c.ImGuiColorEditFlags_NoPicker |
                        cimgui.c.ImGuiColorEditFlags_NoLabel,
                );
            },
        }

        // Boolean styles
        const styles = .{
            "bold",    "italic",    "faint",         "blink",
            "inverse", "invisible", "strikethrough",
        };
        inline for (styles) |style| style: {
            if (!@field(self.style.flags, style)) break :style;

            cimgui.c.ImGui_TableNextRow();
            {
                _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                cimgui.c.ImGui_Text(style.ptr);
            }
            {
                _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                cimgui.c.ImGui_Text("true");
            }
        }

        cimgui.c.ImGui_TextDisabled("(Any styles not shown are not currently set)");
    }
};
