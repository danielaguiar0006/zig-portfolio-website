// TODO: Add support for html links inside column values

//! ASCII Table Generator in Zig.
//!
//! Provides functionality to create and generate ASCII tables with customizable column widths and border characters.
//! Allows adding rows to the table and generating the table as a string or writing it to a buffer.
//!
//! Usage:
//! - Initialize the table with `init`, specifying the allocator and column widths.
//! - Add rows using `addRow`.
//! - Generate the table using `generateTableToBuf` or `generateTableAlloc`.

const std = @import("std");

const Self = @This();

/// Used to create buffer inside generateTableToBuf() method which represents a border row.
const MAX_BUFFER_TABLE_WIDTH: usize = 2048;

/// ! DO NOT MODIFY DIRECTLY
///
/// Used to (possibly) hold the generated table from the generateTableAlloc() method.
/// Memory is automatically freed when the AsciiTable struct is deinited.
///
/// NOTE: This is not necessary if the caller is using the generateTableToBuf() method
/// instead, and if generateTableAlloc() is never called this remains undefined.
generated_alloc_table: ?std.ArrayList(u8) = null,

/// Each index holds a usize value that represents the width of the column in char lengths.
/// Also used to calculate the column count.
columns_widths: []usize = undefined,

/// Outer list represents every row and column.
/// Inner list each represent a row themselves and each index represents a column.
lists: std.ArrayList([][]const u8) = undefined,
allocator: std.mem.Allocator = undefined,

// Chars that make-up the table borders
corner_char: u8 = '+',
horizontal_char: u8 = '-',
vertical_char: u8 = '|',

pub fn init(allocator: std.mem.Allocator, column_widths: []usize) Self {
    return .{
        .lists = std.ArrayList([][]const u8).init(allocator),
        .allocator = allocator,
        .columns_widths = column_widths,
    };
}

pub fn deinit(self: *Self) void {
    for (self.lists.items) |row| {
        for (row) |column| {
            self.allocator.free(column);
        }
        self.allocator.free(row);
    }
    self.lists.deinit();

    if (self.generated_alloc_table) |generated_table| {
        generated_table.deinit();
    }
}

/// Returns the number of rows in the table.
pub fn rowCount(self: *Self) usize {
    return self.lists.items.len;
}

/// Returns the number of columns in the table.
pub fn columnCount(self: *Self) usize {
    return self.columns_widths.len;
}

/// Adds a row to the ASCII table.
///
/// Parameters:
/// - `self`: Pointer to the struct containing the table configuration.
/// - `row`: A 2D array of `const u8` representing the row to be added.
///
/// Errors: Returns `error.InvalidRowLength` if the row length does not match the number of columns.
///
/// NOTE: to add a row it must be done in a similar manner as the following:
/// var table_entry = \[_\]\[\]const u8{ "a", "b" };
/// try ascii_table.addRow(&table_entry);
pub fn addRow(self: *Self, row: [][]const u8) !void {
    if (row.len != self.columnCount()) {
        // Commmented out for being to noisy when testing
        // std.debug.print("ERROR: Row length does not match columns count\n", .{});

        return error.InvalidRowLength;
    }

    // Copy the row into a new array of []const u8 to avoid dangling pointers
    var row_copy = try self.allocator.alloc([]u8, row.len);
    for (0.., row) |i, column| {
        row_copy[i] = try self.allocator.alloc(u8, column.len);
        std.mem.copyForwards(u8, row_copy[i], column);
    }

    try self.lists.append(row_copy);
}

/// Generates an ASCII table and writes it to a provided buffer.
/// The caller is responsible for ensuring the buffer is large enough.
///
/// Parameters:
/// - `self`: Pointer to the AsciiTable struct itself.
/// - `ascii_buffer`: A mutable slice of `u8` where the ASCII table will be written.
///
/// Returns: A slice of `u8` containing the written ASCII table (with the exact length of the ascii table returned).
///
/// Errors: Returns an error if any memory writes fail or if the buffer is not large enough.
/// NOTE: There is a MAX_BUFFER_TABLE_WIDTH comptime value that should be adjusted if the table
/// is too large consider using generateTableAlloc() instead.
pub fn generateTableToBuf(self: *Self, ascii_buffer: []u8) ![]const u8 {
    // Get the necessary streams and writers
    var ascii_table_stream = std.io.fixedBufferStream(ascii_buffer);
    const ascii_table_writer = ascii_table_stream.writer();

    var repeated_chars: [MAX_BUFFER_TABLE_WIDTH]u8 = undefined; // NOTE: Adjust MAX_TABLE_WIDTH as needed
    var repeated_chars_stream = std.io.fixedBufferStream(&repeated_chars);
    const repeated_chars_writer = repeated_chars_stream.writer();

    // Get the repeated chars - which represent the top and bottom horizontal table borders
    try self.getRepeatedChars(&repeated_chars_writer);

    // Write the ascii table
    try ascii_table_writer.print("{s}", .{repeated_chars_stream.getWritten()}); // Top border
    try self.writeRows(&ascii_table_writer);
    try ascii_table_writer.print("\n{s}", .{repeated_chars_stream.getWritten()}); // Bottom border

    // Return a slice of the buffer that was written to
    return ascii_buffer[0..ascii_table_stream.pos];
}

/// Generates an ASCII table and assigns it to `generated_alloc_table` member variable.
/// generated_alloc_table is automatically freed when the AsciiTable struct is deinited.
///
/// Parameters: `self`: Pointer to the AsciiTable struct itself.
///
/// Errors: Returns an error if any memory allocations or writes fail.
pub fn generateTableAlloc(self: *Self) !void {
    // Get the necessary streams and writers
    var ascii_table = std.ArrayList(u8).init(self.allocator);
    const ascii_table_writer = ascii_table.writer();

    var repeated_chars = std.ArrayList(u8).init(self.allocator);
    defer repeated_chars.deinit();
    const repeated_chars_writer = repeated_chars.writer();

    // Get the repeated chars - which represent the top and bottom horizontal table borders
    try self.getRepeatedChars(&repeated_chars_writer);

    // Write the ascii table
    try ascii_table_writer.print("{s}", .{repeated_chars.items}); // Top border
    try self.writeRows(&ascii_table_writer);
    try ascii_table_writer.print("\n{s}", .{repeated_chars.items}); // Bottom border

    self.generated_alloc_table = ascii_table;
}

fn writeRows(self: *Self, ascii_table_writer: anytype) !void {
    for (self.lists.items) |row| {
        for (0.., row) |j, column_value| {
            const current_column_width = self.columns_widths[j];

            // First column of a row - Create a new line for the next row
            if (j == 0) {
                try ascii_table_writer.print("\n{c}", .{self.vertical_char});
            }

            // Write the column value into the table
            if (column_value.len > current_column_width) {
                try ascii_table_writer.print(" {s} {c}", .{ column_value[0..current_column_width], self.vertical_char });
            } else {
                const padding_amount = current_column_width - column_value.len;
                try ascii_table_writer.print(" {s} ", .{column_value});
                try ascii_table_writer.writeByteNTimes(' ', padding_amount);
                try ascii_table_writer.print("{c}", .{self.vertical_char});
            }
        }
    }
}

fn getRepeatedChars(self: *Self, repeated_chars_writer: anytype) !void {
    try repeated_chars_writer.print("{c}", .{self.corner_char});
    for (0..self.columnCount()) |i| {
        try repeated_chars_writer.print(" ", .{});
        try repeated_chars_writer.writeByteNTimes(self.horizontal_char, self.columns_widths[i]);
        try repeated_chars_writer.print(" {c}", .{self.corner_char});
    }
}

test "Adding rows to the table" {
    const allocator = std.testing.allocator;

    var table_widths = [_]usize{ 3, 3 };
    var table = init(allocator, &table_widths);
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

test "addRow() - Memory scope" {
    const allocator = std.testing.allocator;

    var column_widths = [_]usize{ 3, 3 };
    var table = init(allocator, &column_widths);
    defer table.deinit();

    for (0..1) |i| {
        _ = i;

        var row1: [][]u8 = undefined;
        row1 = try allocator.alloc([]u8, 2);

        row1[0] = try allocator.alloc(u8, 1);
        row1[1] = try allocator.alloc(u8, 1);
        std.mem.copyForwards(u8, row1[0], "a");
        std.mem.copyForwards(u8, row1[1], "b");

        try table.addRow(row1);

        for (row1) |column| {
            allocator.free(column);
        }
        allocator.free(row1);
    }

    try std.testing.expectEqualStrings("a", table.lists.items[0][0]);
    try std.testing.expectEqualStrings("b", table.lists.items[0][1]);
}

test "generateTableToBuf() - Small column values" {
    const allocator = std.testing.allocator;

    var column_widths = [_]usize{ 3, 3 };
    var table = init(allocator, &column_widths);
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
    const generated_table = try table.generateTableToBuf(&buffer);

    try std.testing.expectEqualStrings(expected_table, generated_table);
}

test "generateTableToBuf() - large/overflowing column values" {
    const allocator = std.testing.allocator;

    var column_widths = [_]usize{ 5, 3, 10, 1 };
    var table = init(allocator, &column_widths);
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
    const generated_table = try table.generateTableToBuf(&buffer);

    try std.testing.expectEqualStrings(expected_table, generated_table);
}

test "generateTableAlloc() - Small column values" {
    const allocator = std.testing.allocator;

    var column_widths = [_]usize{ 3, 3 };
    var table = init(allocator, &column_widths);
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

    try table.generateTableAlloc();

    try std.testing.expectEqualStrings(expected_table, table.generated_alloc_table.?.items);
}

test "generateTableAlloc() - large/overflowing column values" {
    const allocator = std.testing.allocator;

    var column_widths = [_]usize{ 5, 3, 10, 1 };
    var table = init(allocator, &column_widths);
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

    try table.generateTableAlloc();

    try std.testing.expectEqualStrings(expected_table, table.generated_alloc_table.?.items);
}
