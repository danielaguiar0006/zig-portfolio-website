const std = @import("std");

const Self = @This();

// TODO: Create a list of lists of strings
// outer list represents every row and column
// inner list each represent a row themselves and each index represents a column

allocator: std.mem.Allocator = undefined,
lists: std.ArrayList([][]const u8) = undefined,

/// ! DO NOT MODIFY DIRECTLY
columns_count: usize = undefined,

/// ! DO NOT MODIFY DIRECTLY
// TODO: each index holds a usize that represents the width of the column in char lengths
// Make sure to check and always make sure its length is the same as columns_count
//columns_widths: []usize = undefined,

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

pub fn GetAsciiTable(self: *Self) []const u8 {
    var ascii_table: [1024]u8 = undefined;
    var ascii_table_stream = std.io.fixedBufferStream(&ascii_table);
    const ascii_table_writer = ascii_table_stream.writer();

    ascii_table_writer.print("{c} {c}{c}{c} {c} ", .{ self.corner_char, self.horizontal_char, self.horizontal_char, self.horizontal_char, self.corner_char }) catch unreachable;
    ascii_table_writer.print("{c}{c}{c} {c}\n", .{ self.horizontal_char, self.horizontal_char, self.horizontal_char, self.corner_char }) catch unreachable;
    std.debug.print("Buffer:\n{s}\n", .{ascii_table});

    for (self.lists.items) |row| {
        for (row) |column| {
            ascii_table_writer.print("{c}  {s}  ", .{ self.vertical_char, column }) catch unreachable;
        }
        ascii_table_writer.print("{c}\n", .{self.vertical_char}) catch unreachable;
    }
    ascii_table_writer.print("{c} {c}{c}{c} {c} ", .{ self.corner_char, self.horizontal_char, self.horizontal_char, self.horizontal_char, self.corner_char }) catch unreachable;
    ascii_table_writer.print("{c}{c}{c} {c}", .{ self.horizontal_char, self.horizontal_char, self.horizontal_char, self.corner_char }) catch unreachable;

    std.debug.print("Buffer:\n{s}\n", .{ascii_table});

    // ? Not entirely sure which is the best way to return the slice
    //return &ascii_table;
    //return ascii_table[0..ascii_table.len];
    return ascii_table_stream.getWritten();
}

// TODO: pub fn rowCount(self: *Self) usize { }
// TODO: pub fn columnCount(self: *Self) usize { }

test "Adding rows to the table" {
    const allocator = std.testing.allocator;
    var table = init(allocator, 2);
    defer table.deinit();

    var row1 = [_][]const u8{ "a", "b" };
    var row2 = [_][]const u8{ "c", "d" };
    var row3 = [_][]const u8{"e"};
    var row4 = [_][]const u8{ "f", "g", "h", "i" };

    try table.addRow(&row1); // OK
    try table.addRow(&row2); // OK
    try std.testing.expectError(error.InvalidRowLength, table.addRow(&row3)); // ERROR
    try std.testing.expectError(error.InvalidRowLength, table.addRow(&row4)); // ERROR

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

test "GetAsciiTable" {
    const allocator = std.testing.allocator;
    var table = init(allocator, 2);
    defer table.deinit();

    var row1 = [_][]const u8{ "a", "b" };
    var row2 = [_][]const u8{ "c", "d" };

    try table.addRow(&row1); // OK
    try table.addRow(&row2); // OK

    const expected_table =
        \\+ --- + --- +
        \\|  a  |  b  |
        \\|  c  |  d  |
        \\+ --- + --- +
    ;
    const generated_table = table.GetAsciiTable();
    std.debug.print("Generated Table:\n{s}\n", .{generated_table});

    try std.testing.expectEqualStrings(expected_table, generated_table);

    //std.debug.print("Generated Table:\n{s}\n", .{generated_table});
    //std.debug.print("Expected Table:\n{s}\n", .{expected_table});
}

// TODO:
// test "Printing ascii table with two columns" {
//     const allocator = std.testing.allocator;
//     var table = init(allocator, 2);
//     defer table.deinit();
//
//     var row1 = [_][]const u8{ "a", "b" };
//     var row2 = [_][]const u8{ "c", "d" };
//
//     try table.addRow(&row1); // OK
//     try table.addRow(&row2); // OK
//
//     std.testing.expectEqualStrings("+ ---", table.GetAsciiTable());
//
//     std.debug.print("Table:\n{s}\n", .{table.GetAsciiTable()});
// }
//
// test "Printing ascii table with three columns" {
//     const allocator = std.testing.allocator;
//     var table = init(allocator, 3);
//     defer table.deinit();
//
//     var row1 = [_][]const u8{ "a", "b", "c" };
//     var row2 = [_][]const u8{ "d", "e", "f" };
//
//     try table.addRow(&row1); // OK
//     try table.addRow(&row2); // OK
//
//     std.debug.print("Table:\n{s}\n", .{table.GetAsciiTable()});
// }
