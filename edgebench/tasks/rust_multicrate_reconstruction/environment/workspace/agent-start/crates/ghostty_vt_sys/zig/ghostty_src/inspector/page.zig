const std = @import("std");
const Allocator = std.mem.Allocator;
const cimgui = @import("dcimgui");
const terminal = @import("../terminal/main.zig");
const units = @import("units.zig");

pub fn render(page: *const terminal.Page) void {
    cimgui.c.ImGui_PushIDPtr(page);
    defer cimgui.c.ImGui_PopID();

    _ = cimgui.c.ImGui_BeginTable(
        "##page_state",
        2,
        cimgui.c.ImGuiTableFlags_None,
    );
    defer cimgui.c.ImGui_EndTable();

    {
        cimgui.c.ImGui_TableNextRow();
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Memory Size");
        }
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("%d bytes (%d KiB)", page.memory.len, units.toKibiBytes(page.memory.len));
            cimgui.c.ImGui_Text("%d VM pages", page.memory.len / std.heap.page_size_min);
        }
    }
    {
        cimgui.c.ImGui_TableNextRow();
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Unique Styles");
        }
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("%d", page.styles.count());
        }
    }
    {
        cimgui.c.ImGui_TableNextRow();
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Grapheme Entries");
        }
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("%d", page.graphemeCount());
        }
    }
    {
        cimgui.c.ImGui_TableNextRow();
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Capacity");
        }
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            _ = cimgui.c.ImGui_BeginTable(
                "##capacity",
                2,
                cimgui.c.ImGuiTableFlags_None,
            );
            defer cimgui.c.ImGui_EndTable();

            const cap = page.capacity;
            {
                cimgui.c.ImGui_TableNextRow();
                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                    cimgui.c.ImGui_Text("Columns");
                }

                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                    cimgui.c.ImGui_Text("%d", @as(u32, @intCast(cap.cols)));
                }
            }

            {
                cimgui.c.ImGui_TableNextRow();
                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                    cimgui.c.ImGui_Text("Rows");
                }

                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                    cimgui.c.ImGui_Text("%d", @as(u32, @intCast(cap.rows)));
                }
            }

            {
                cimgui.c.ImGui_TableNextRow();
                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                    cimgui.c.ImGui_Text("Unique Styles");
                }

                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                    cimgui.c.ImGui_Text("%d", @as(u32, @intCast(cap.styles)));
                }
            }

            {
                cimgui.c.ImGui_TableNextRow();
                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                    cimgui.c.ImGui_Text("Grapheme Bytes");
                }

                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                    cimgui.c.ImGui_Text("%d", cap.grapheme_bytes);
                }
            }
        }
    }
    {
        cimgui.c.ImGui_TableNextRow();
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Size");
        }
        {
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            _ = cimgui.c.ImGui_BeginTable(
                "##size",
                2,
                cimgui.c.ImGuiTableFlags_None,
            );
            defer cimgui.c.ImGui_EndTable();

            const size = page.size;
            {
                cimgui.c.ImGui_TableNextRow();
                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                    cimgui.c.ImGui_Text("Columns");
                }

                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                    cimgui.c.ImGui_Text("%d", @as(u32, @intCast(size.cols)));
                }
            }
            {
                cimgui.c.ImGui_TableNextRow();
                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(0);
                    cimgui.c.ImGui_Text("Rows");
                }

                {
                    _ = cimgui.c.ImGui_TableSetColumnIndex(1);
                    cimgui.c.ImGui_Text("%d", @as(u32, @intCast(size.rows)));
                }
            }
        }
    } // size table
}
