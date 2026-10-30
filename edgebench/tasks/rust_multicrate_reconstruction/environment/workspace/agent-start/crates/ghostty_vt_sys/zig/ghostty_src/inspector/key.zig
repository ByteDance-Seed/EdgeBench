const std = @import("std");
const Allocator = std.mem.Allocator;
const input = @import("../input.zig");
const CircBuf = @import("../datastruct/main.zig").CircBuf;
const cimgui = @import("dcimgui");

/// Circular buffer of key events.
pub const EventRing = CircBuf(Event, undefined);

/// Represents a recorded keyboard event.
pub const Event = struct {
    /// The input event.
    event: input.KeyEvent,

    /// The binding that was triggered as a result of this event.
    /// Multiple bindings are possible if they are chained.
    binding: []const input.Binding.Action = &.{},

    /// The data sent to the pty as a result of this keyboard event.
    /// This is allocated using the inspector allocator.
    pty: []const u8 = "",

    /// State for the inspector GUI. Do not set this unless you're the inspector.
    imgui_state: struct {
        selected: bool = false,
    } = .{},

    pub fn init(alloc: Allocator, event: input.KeyEvent) !Event {
        var copy = event;
        copy.utf8 = "";
        if (event.utf8.len > 0) copy.utf8 = try alloc.dupe(u8, event.utf8);
        return .{ .event = copy };
    }

    pub fn deinit(self: *const Event, alloc: Allocator) void {
        alloc.free(self.binding);
        if (self.event.utf8.len > 0) alloc.free(self.event.utf8);
        if (self.pty.len > 0) alloc.free(self.pty);
    }

    /// Returns a label that can be used for this event. This is null-terminated
    /// so it can be easily used with C APIs.
    pub fn label(self: *const Event, buf: []u8) ![:0]const u8 {
        var buf_stream = std.io.fixedBufferStream(buf);
        const writer = buf_stream.writer();

        switch (self.event.action) {
            .press => try writer.writeAll("Press: "),
            .release => try writer.writeAll("Release: "),
            .repeat => try writer.writeAll("Repeat: "),
        }

        if (self.event.mods.shift) try writer.writeAll("Shift+");
        if (self.event.mods.ctrl) try writer.writeAll("Ctrl+");
        if (self.event.mods.alt) try writer.writeAll("Alt+");
        if (self.event.mods.super) try writer.writeAll("Super+");

        // Write our key. If we have an invalid key we attempt to write
        // the utf8 associated with it if we have it to handle non-ascii.
        try writer.writeAll(switch (self.event.key) {
            .unidentified => if (self.event.utf8.len > 0) self.event.utf8 else @tagName(self.event.key),
            else => @tagName(self.event.key),
        });

        // Deadkey
        if (self.event.composing) try writer.writeAll(" (composing)");

        // Null-terminator
        try writer.writeByte(0);
        return buf[0..(buf_stream.getWritten().len - 1) :0];
    }

    /// Render this event in the inspector GUI.
    pub fn render(self: *const Event) void {
        _ = cimgui.c.ImGui_BeginTable(
            "##event",
            2,
            cimgui.c.ImGuiTableFlags_None,
        );
        defer cimgui.c.ImGui_EndTable();

        if (self.binding.len > 0) {
            cimgui.c.ImGui_TableNextRow();
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Triggered Binding");
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);

            const height: f32 = height: {
                const item_count: f32 = @floatFromInt(@min(self.binding.len, 5));
                const padding = cimgui.c.ImGui_GetStyle().*.FramePadding.y * 2;
                break :height cimgui.c.ImGui_GetTextLineHeightWithSpacing() * item_count + padding;
            };
            if (cimgui.c.ImGui_BeginListBox("##bindings", .{ .x = 0, .y = height })) {
                defer cimgui.c.ImGui_EndListBox();
                for (self.binding) |action| {
                    _ = cimgui.c.ImGui_SelectableEx(
                        @tagName(action).ptr,
                        false,
                        cimgui.c.ImGuiSelectableFlags_None,
                        .{ .x = 0, .y = 0 },
                    );
                }
            }
        }

        pty: {
            cimgui.c.ImGui_TableNextRow();
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Encoding to Pty");
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            if (self.pty.len == 0) {
                cimgui.c.ImGui_TextDisabled("(no data)");
                break :pty;
            }

            self.renderPty() catch {
                cimgui.c.ImGui_TextDisabled("(error rendering pty data)");
                break :pty;
            };
        }

        {
            cimgui.c.ImGui_TableNextRow();
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Action");
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("%s", @tagName(self.event.action).ptr);
        }
        {
            cimgui.c.ImGui_TableNextRow();
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Key");
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("%s", @tagName(self.event.key).ptr);
        }
        if (!self.event.mods.empty()) {
            cimgui.c.ImGui_TableNextRow();
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Mods");
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            if (self.event.mods.shift) cimgui.c.ImGui_Text("shift ");
            if (self.event.mods.ctrl) cimgui.c.ImGui_Text("ctrl ");
            if (self.event.mods.alt) cimgui.c.ImGui_Text("alt ");
            if (self.event.mods.super) cimgui.c.ImGui_Text("super ");
        }
        if (self.event.composing) {
            cimgui.c.ImGui_TableNextRow();
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("Composing");
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            cimgui.c.ImGui_Text("true");
        }
        utf8: {
            cimgui.c.ImGui_TableNextRow();
            _ = cimgui.c.ImGui_TableSetColumnIndex(0);
            cimgui.c.ImGui_Text("UTF-8");
            _ = cimgui.c.ImGui_TableSetColumnIndex(1);
            if (self.event.utf8.len == 0) {
                cimgui.c.ImGui_TextDisabled("(empty)");
                break :utf8;
            }

            self.renderUtf8(self.event.utf8) catch {
                cimgui.c.ImGui_TextDisabled("(error rendering utf-8)");
                break :utf8;
            };
        }
    }

    fn renderUtf8(self: *const Event, utf8: []const u8) !void {
        _ = self;

        // Format the codepoint sequence
        var buf: [1024]u8 = undefined;
        var buf_stream = std.io.fixedBufferStream(&buf);
        const writer = buf_stream.writer();
        if (std.unicode.Utf8View.init(utf8)) |view| {
            var it = view.iterator();
            while (it.nextCodepoint()) |cp| {
                try writer.print("U+{X} ", .{cp});
            }
        } else |_| {
            try writer.writeAll("(invalid utf-8)");
        }
        try writer.writeByte(0);

        // Render as a textbox
        _ = cimgui.c.ImGui_InputText(
            "##utf8",
            &buf,
            buf_stream.getWritten().len - 1,
            cimgui.c.ImGuiInputTextFlags_ReadOnly,
        );
    }

    fn renderPty(self: *const Event) !void {
        // Format the codepoint sequence
        var buf: [1024]u8 = undefined;
        var buf_stream = std.io.fixedBufferStream(&buf);
        const writer = buf_stream.writer();

        for (self.pty) |byte| {
            // Print ESC special because its so common
            if (byte == 0x1B) {
                try writer.writeAll("ESC ");
                continue;
            }

            // Print ASCII as-is
            if (byte > 0x20 and byte < 0x7F) {
                try writer.writeByte(byte);
                continue;
            }

            // Everything else as a hex byte
            try writer.print("0x{X} ", .{byte});
        }

        try writer.writeByte(0);

        // Render as a textbox
        _ = cimgui.c.ImGui_InputText(
            "##pty",
            &buf,
            buf_stream.getWritten().len - 1,
            cimgui.c.ImGuiInputTextFlags_ReadOnly,
        );
    }
};

test "event string" {
    const testing = std.testing;
    const alloc = testing.allocator;

    var event = try Event.init(alloc, .{ .key = .key_a });
    defer event.deinit(alloc);

    var buf: [1024]u8 = undefined;
    try testing.expectEqualStrings("Press: key_a", try event.label(&buf));
}
