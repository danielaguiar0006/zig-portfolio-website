const std = @import("std");

const Self = @This();

/// Used to create buffer inside GetAsciiTableBuf() method which represents a border row
const MAX_BUFFER_TABLE_WIDTH: usize = 2048;

/// Each index holds a usize value that represents the width of the column in char lengths
/// NOTE: Make sure to check and always make sure the array.len is the same as columns_count
columns_widths: []usize = undefined,

/// Outer list represents every row and column
/// Inner list each represent a row themselves and each index represents a column
lists: std.ArrayList([][]const u8) = undefined,
allocator: std.mem.Allocator = undefined,

// Chars that make-up the table borders
corner_char: u8 = '+',
horizontal_char: u8 = '-',
vertical_char: u8 = '|',

// TODO: column count could probably be calculated from the column widths
/// ! DO NOT MODIFY DIRECTLY
columns_count: usize = undefined,

pub fn init(allocator: std.mem.Allocator, column_count: usize, column_widths: []usize) !Self {
    if (column_widths.len != column_count) {
        std.debug.print("ERROR: Column widths length does not match columns count\n", .{});
        return error.InvalidColumnWidthsLength;
    }

    return .{
        .allocator = allocator,
        .lists = std.ArrayList([][]const u8).init(allocator),
        .columns_count = column_count,
        .columns_widths = column_widths,
    };
}

pub fn deinit(self: *Self) void {
    self.lists.deinit();
}

/// NOTE: to add a row it must be done in a similar manner as the following:
/// var table_entry = \[_\]\[\]const u8{ "a", "b" };
/// try ascii_table.addRow(&table_entry);
pub fn addRow(self: *Self, row: [][]const u8) !void {
    if (row.len != self.columns_count) {
        // Commmented out for being to noisy when testing
        // std.debug.print("ERROR: Row length does not match columns count\n", .{});

        return error.InvalidRowLength;
    }

    try self.lists.append(row);
}

// TODO: eventually seperate out into two methods: GetAsciiTableBuff() and GetAsciiTableAlloc()
// and get rid of all the catch unreachables by handling errors properly
/// Both writes to the buffer and returns a slice of the exact length written (the exact length of the ascii table returned)
/// NOTE: There is a MAX_BUFFER_TABLE_WIDTH comptime value that should be adjusted if the table is too large
pub fn GetAsciiTable(self: *Self, ascii_buffer: []u8) []const u8 {
    var ascii_table_stream = std.io.fixedBufferStream(ascii_buffer);
    const ascii_table_writer = ascii_table_stream.writer();

    // repeated_chars represent the top and bottom horizontal table borders
    var repeated_chars: [MAX_BUFFER_TABLE_WIDTH]u8 = undefined; // NOTE: Adjust MAX_TABLE_WIDTH as needed
    var repeated_chars_stream = std.io.fixedBufferStream(&repeated_chars);
    const repeated_chars_writer = repeated_chars_stream.writer();

    // Get the repeated chars
    repeated_chars_writer.print("{c}", .{self.corner_char}) catch unreachable;
    for (0..self.columns_count) |i| {
        repeated_chars_writer.print(" ", .{}) catch unreachable;
        repeated_chars_writer.writeByteNTimes(self.horizontal_char, self.columns_widths[i]) catch unreachable;
        repeated_chars_writer.print(" {c}", .{self.corner_char}) catch unreachable;
    }

    // Write the top border
    ascii_table_writer.print("{s}", .{repeated_chars_stream.getWritten()}) catch unreachable;

    // Write the rows
    for (self.lists.items) |row| {
        for (0.., row) |j, column_value| {
            const current_column_width = self.columns_widths[j];

            // First column of a row - Create a new line for the next row
            if (j == 0) {
                ascii_table_writer.print("\n{c}", .{self.vertical_char}) catch unreachable;
            }

            // Write the column value into the table
            if (column_value.len > current_column_width) {
                ascii_table_writer.print(" {s} {c}", .{ column_value[0..current_column_width], self.vertical_char }) catch unreachable;
            } else {
                const padding_amount = current_column_width - column_value.len;
                ascii_table_writer.print(" {s} ", .{column_value}) catch unreachable;
                ascii_table_writer.writeByteNTimes(' ', padding_amount) catch unreachable;
                ascii_table_writer.print("{c}", .{self.vertical_char}) catch unreachable;
            }
        }
    }
    // Write the bottom border
    ascii_table_writer.print("\n{s}", .{repeated_chars_stream.getWritten()}) catch unreachable;

    // Return a slice of the buffer that was written to
    return ascii_buffer[0..ascii_table_stream.pos];
}

// TODO: pub fn GetAsciiTableBuf(self: *Self, buffer: []u8) []const u8 {}
// TODO: pub fn GetAsciiTableAlloc(self: *Self) []const u8 {}
// TODO: pub fn rowCount(self: *Self) usize { }
// TODO: pub fn columnCount(self: *Self) usize { }

test "Adding rows to the table" {
    const allocator = std.testing.allocator;

    var table_widths = [_]usize{ 3, 3 };
    var table = try init(allocator, 2, &table_widths);
    defer table.deinit();

    var row1 = [_][]const u8{ "a", "b" };
    var row2 = [_][]const u8{ "c", "d" };
    var row3 = [_][]const u8{"e"};
    var row4 = [_][]const u8{ "f", "g", "h", "i" };

    try table.addRow(&row1); // OK
    try table.addRow(&row2); // OK
    try std.testing.expectError(error.InvalidRowLength, table.addRow(&row3)); // ERROR
    try std.testing.expectError(error.InvalidRowLength, table.addRow(&row4)); // ERROR
}

test "Memory scope" {
    const allocator = std.testing.allocator;

    var table_widths = [_]usize{ 3, 3 };
    var table = try init(allocator, 2, &table_widths);
    defer table.deinit();

    for (0..1) |i| {
        _ = i;

        var row1 = [_][]const u8{ "a", "b" };
        try table.addRow(&row1);
    }

    try std.testing.expectEqualStrings("a", table.lists.items[0][0]);
    try std.testing.expectEqualStrings("b", table.lists.items[0][1]);
}

test "GetAsciiTable - Small column values" {
    const allocator = std.testing.allocator;

    var table_widths = [_]usize{ 3, 3 };
    var table = try init(allocator, 2, &table_widths);
    defer table.deinit();

    var row1 = [_][]const u8{ "a", "b" };
    var row2 = [_][]const u8{ "c", "d" };

    try table.addRow(&row1);
    try table.addRow(&row2);

    const expected_table =
        \\+ --- + --- +
        \\| a   | b   |
        \\| c   | d   |
        \\+ --- + --- +
    ;

    var buffer: [2048]u8 = undefined;
    const generated_table = table.GetAsciiTable(&buffer);

    try std.testing.expectEqualStrings(expected_table, generated_table);
}

test "GetAsciiTable - large/overflowing column values" {
    const allocator = std.testing.allocator;

    var table_widths = [_]usize{ 5, 3, 10, 1 };
    var table = try init(allocator, 4, &table_widths);
    defer table.deinit();

    var row1 = [_][]const u8{ "Daniel", "Aguiar", "yo-reign", "yo" };
    var row2 = [_][]const u8{ "a", "-", " ", "" };

    try table.addRow(&row1);
    try table.addRow(&row2);

    const expected_table =
        \\+ ----- + --- + ---------- + - +
        \\| Danie | Agu | yo-reign   | y |
        \\| a     | -   |            |   |
        \\+ ----- + --- + ---------- + - +
    ;

    var buffer: [2048]u8 = undefined;
    const generated_table = table.GetAsciiTable(&buffer);

    try std.testing.expectEqualStrings(expected_table, generated_table);
}
