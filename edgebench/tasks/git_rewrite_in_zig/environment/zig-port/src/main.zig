const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const stderr = std.io.getStdErr().writer();

    if (args.len < 2) {
        try stderr.print("usage: git <command> [<args>]\n", .{});
        std.process.exit(1);
    }

    try stderr.print("git: '{s}' is not a git command. See 'git --help'.\n", .{args[1]});
    std.process.exit(1);
}
