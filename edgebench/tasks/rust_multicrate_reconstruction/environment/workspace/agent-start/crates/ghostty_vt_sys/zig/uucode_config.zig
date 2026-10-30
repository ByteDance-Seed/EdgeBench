const std = @import("std");
const assert = std.debug.assert;
const config = @import("config.zig");
const config_x = @import("config.x.zig");
const d = config.default;
const wcwidth = config_x.wcwidth;
const grapheme_break_no_control = config_x.grapheme_break_no_control;

const Allocator = std.mem.Allocator;

fn computeWidth(
    alloc: std.mem.Allocator,
    cp: u21,
    data: anytype,
    backing: anytype,
    tracking: anytype,
) Allocator.Error!void {
    _ = alloc;
    _ = cp;
    _ = backing;
    _ = tracking;

    if (data.wcwidth_zero_in_grapheme) {
        data.width = 0;
    } else {
        data.width = @min(2, data.wcwidth_standalone);
    }
}

const width = config.Extension{
    .inputs = &.{
        "wcwidth_standalone",
        "wcwidth_zero_in_grapheme",
    },
    .compute = &computeWidth,
    .fields = &.{
        .{ .name = "width", .type = u2 },
    },
};

fn computeIsSymbol(
    alloc: Allocator,
    cp: u21,
    data: anytype,
    backing: anytype,
    tracking: anytype,
) Allocator.Error!void {
    _ = alloc;
    _ = cp;
    _ = backing;
    _ = tracking;
    const block = data.block;
    data.is_symbol = data.general_category == .other_private_use or
        block == .arrows or
        block == .dingbats or
        block == .emoticons or
        block == .miscellaneous_symbols or
        block == .enclosed_alphanumerics or
        block == .enclosed_alphanumeric_supplement or
        block == .miscellaneous_symbols_and_pictographs or
        block == .transport_and_map_symbols;
}

const is_symbol = config.Extension{
    .inputs = &.{ "block", "general_category" },
    .compute = &computeIsSymbol,
    .fields = &.{
        .{ .name = "is_symbol", .type = bool },
    },
};

pub const tables = [_]config.Table{
    .{
        .name = "runtime",
        .extensions = &.{},
        .fields = &.{
            d.field("is_emoji_presentation"),
            d.field("case_folding_full"),
        },
    },
    .{
        .name = "buildtime",
        .extensions = &.{
            wcwidth,
            grapheme_break_no_control,
            width,
            is_symbol,
        },
        .fields = &.{
            width.field("width"),
            grapheme_break_no_control.field("grapheme_break_no_control"),
            is_symbol.field("is_symbol"),
            d.field("is_emoji_vs_base"),
        },
    },
};
