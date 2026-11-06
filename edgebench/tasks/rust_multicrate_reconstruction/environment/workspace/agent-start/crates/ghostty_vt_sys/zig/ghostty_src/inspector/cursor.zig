const cimgui = @import("dcimgui");
const terminal = @import("../terminal/main.zig");

/// Render cursor information with a table already open.
pub fn renderInTable(
    t: *const terminal.Terminal,
    cursor: *const terminal.Screen.Cursor,
) void {
    {
        cimgui.c.ImGui_TableNextRow();
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Position (x, y)");
        }
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("(%d, %d)", cursor.x, cursor.y);
        }
    }

    {
        cimgui.c.ImGui_TableNextRow();
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Style");
        }
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("%s", @tagName(cursor.cursor_style).ptr);
        }
    }

    if (cursor.pending_wrap) {
        cimgui.c.ImGui_TableNextRow();
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Pending Wrap");
        }
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("%s", if (cursor.pending_wrap) "true".ptr else "false".ptr);
        }
    }

    // If we have a color then we show the color
    cimgui.c.ImGui_TableNextRow();
    _ = cimgui.c.ImGui_TableSetColumnIndex(0);
    cimgui.c.ImGui_Text("Foreground Color");
    _ = cimgui.c.ImGui_TableSetColumnIndex(1);
    switch (cursor.style.fg_color) {
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
    switch (cursor.style.bg_color) {
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
        if (!@field(cursor.style.flags, style)) break :style;

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
}
