const std = @import("std");

const Self = @This();

// TODO: Create a list of lists of strings
// outer list represents every row and column
// inner list each represent a row themselves and each index represents a column

allocator: std.mem.Allocator = undefined,
lists: std.ArrayList([][]const u8) = undefined,
/// ! MUST NOT BE CHANGED AFTER INIT
columns_count: usize = undefined,

// Chars that make-up the table borders
corner_char: u8 = '+',
horizontal_char: u8 = '-',
vertical_char: u8 = '|',

// Probably not needed (instead return through methods):
// rows_count: usize = undefined,
// columns_count: usize = undefined,

pub fn init(allocator: std.mem.Allocator, column_count: usize) Self {
    return .{
        .allocator = allocator,
        .lists = std.ArrayList([][]const u8).init(allocator),
        .columns_count = column_count,
    };
}

pub fn deinit(self: *Self) void {
    self.lists.deinit();
}

// NOTE: to add a row it must be done in a similar manner as the following:
// var table_entry = [_][]const u8{ "a", "b" };
// try ascii_table.addRow(&table_entry);
pub fn addRow(self: *Self, row: [][]const u8) !void {
    if (row.len != self.columns_count) {
        std.debug.print("ERROR: Row length does not match columns count\n", .{});
        return error.InvalidRowLength;
    }

    try self.lists.append(row);
}

// TODO: pub fn GetAsciiTable(self: *Self) []const u8 {}
// TODO: pub fn rowCount(self: *Self) usize { }
// TODO: pub fn columnCount(self: *Self) usize { }

test "Adding rows to the table" {
    const allocator = std.testing.allocator;
    var table = init(allocator, 2);
    defer table.deinit();

    // The first two should be OK (no error) and the last one should be an error
    var row1 = [_][]const u8{ "a", "b" };
    var row2 = [_][]const u8{ "c", "d" };
    var row3 = [_][]const u8{ "e", "f", "g" };

    try table.addRow(&row1); // OK
    try table.addRow(&row2); // OK
    try std.testing.expectError(error.InvalidRowLength, table.addRow(&row3)); // ERROR

    std.debug.print("Table:\n{s}\n", .{table.lists.items});
}

test "Memory scope" {
    const allocator = std.testing.allocator;
    var table = init(allocator, 2);
    defer table.deinit();

    {
        var row1 = [_][]const u8{ "a", "b" };

        try table.addRow(&row1); // OK
    }

    try std.testing.expectEqualStrings("a", table.lists.items[0][0]);
    try std.testing.expectEqualStrings("b", table.lists.items[0][1]);

    std.debug.print("Table:\n{s}\n", .{table.lists.items});
}
