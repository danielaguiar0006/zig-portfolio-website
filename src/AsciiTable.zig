//! ASCII Table Generator in Zig.
//!
//! Provides functionality to create and generate ASCII tables with customizable column widths and border characters.
//! Allows adding rows to the table and generating the table as a string or writing it to a buffer.
//!
//! Usage:
//! - Initialize the table with `init`, specifying the allocator and column widths.
//! - Create a row by create an array of `Cell` structs ie:
//!     `var row1 = [_]Cell{ .{ .display_text = "a" }, .{ .display_text = "b", .link = "https://example.com", .open_in_new_tab = true } };`
//! - Add rows using `addRow(<row>)`.
//! - Generate the table using `generateTableToBuf()` or `generateTableAlloc()`.

const std = @import("std");

const Self = @This();

pub const Cell = struct {
    display_text: []const u8,
    link: ?[]const u8 = null,
    open_in_new_tab: bool = false,
};

/// Used to create buffer inside generateTableToBuf() method which represents a border row.
const MAX_BUFFER_TABLE_WIDTH: usize = 2048;

/// ! DO NOT MODIFY DIRECTLY
///
/// Used to (possibly?) hold the generated table from the generateTableAlloc() method.
/// Memory is automatically freed when the AsciiTable struct is deinited.
///
/// NOTE: This is not necessary if the caller is using the generateTableToBuf() method
/// instead, and if generateTableAlloc() is never called this remains null.
generated_alloc_table: ?std.ArrayList(u8) = null,

/// Each index holds a usize value that represents the width of the column in char lengths.
/// Also used to calculate the column count.
columns_widths: []usize = undefined,

/// Outer list represents every row and column.
/// Inner list each represent a row themselves and each index represents a column.
lists: std.ArrayList([]Cell) = undefined,
allocator: std.mem.Allocator = undefined,

// Chars that make-up the table borders
corner_char: u8 = '+',
horizontal_char: u8 = '-',
vertical_char: u8 = '|',

pub fn init(allocator: std.mem.Allocator, column_widths: []usize) Self {
    return .{
        .lists = std.ArrayList([]Cell).init(allocator),
        .allocator = allocator,
        .columns_widths = column_widths,
    };
}

pub fn deinit(self: *Self) void {
    for (self.lists.items) |row| {
        // Don't need this because only rows are allocated and freed
        // for (row) |cell| {
        //     self.allocator.free(cell.display_text);
        //     if (cell.link) |link| {
        //         self.allocator.free(link);
        //     }
        // }

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
/// - `row`: An array of `Cell`s representing the row to be added.
///
/// Errors: Returns `error.InvalidRowLength` if the row length does not match the number of columns.
pub fn addRow(self: *Self, row: []Cell) !void {
    if (row.len != self.columnCount()) {
        // Commmented out for being to noisy when testing
        // std.debug.print("ERROR: Row length does not match columns count\n", .{});

        return error.InvalidRowLength;
    }

    // Copy the row into a new array to avoid dangling pointers
    const row_copy = try self.allocator.alloc(Cell, row.len);
    std.mem.copyForwards(Cell, row_copy, row);

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
        for (0.., row) |j, cell| {
            const current_column_width = self.columns_widths[j];

            // First column of a row - Create a new line for the next row
            if (j == 0) {
                try ascii_table_writer.print("\n{c}", .{self.vertical_char});
            }

            // Write the column value into the table
            if (cell.display_text.len > current_column_width) {
                if (cell.link) |link| {
                    if (cell.open_in_new_tab) {
                        try ascii_table_writer.print(" <a href=\"{s}\" target=\"_blank\">{s}</a>", .{ link, cell.display_text[0..current_column_width] });
                    } else {
                        try ascii_table_writer.print(" <a href=\"{s}\">{s}</a>", .{ link, cell.display_text[0..current_column_width] });
                    }
                } else {
                    try ascii_table_writer.print(" {s}", .{cell.display_text[0..current_column_width]});
                }

                try ascii_table_writer.print(" {c}", .{self.vertical_char});
            } else {
                if (cell.link) |link| {
                    if (cell.open_in_new_tab) {
                        try ascii_table_writer.print(" <a href=\"{s}\" target=\"_blank\">{s}</a> ", .{ link, cell.display_text });
                    } else {
                        try ascii_table_writer.print(" <a href=\"{s}\">{s}</a> ", .{ link, cell.display_text });
                    }
                } else {
                    try ascii_table_writer.print(" {s} ", .{cell.display_text});
                }

                const padding_amount = current_column_width - cell.display_text.len;
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

    var row1 = [_]Cell{ .{ .display_text = "a" }, .{ .display_text = "b" } };
    var row2 = [_]Cell{ .{ .display_text = "c" }, .{ .display_text = "d" } };
    var row3 = [_]Cell{.{ .display_text = "e" }};
    var row4 = [_]Cell{ .{ .display_text = "f" }, .{ .display_text = "g" }, .{ .display_text = "h" }, .{ .display_text = "i" } };

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

        var row1: []Cell = undefined;
        row1 = try allocator.alloc(Cell, 2);

        row1[0] = .{ .display_text = "a" };
        row1[1] = .{ .display_text = "b" };

        try table.addRow(row1);
        allocator.free(row1);
    }

    try std.testing.expectEqualStrings("a", table.lists.items[0][0].display_text);
    try std.testing.expectEqualStrings("b", table.lists.items[0][1].display_text);
}

test "generateTableToBuf() - Small column values" {
    const allocator = std.testing.allocator;

    var column_widths = [_]usize{ 3, 3 };
    var table = init(allocator, &column_widths);
    defer table.deinit();

    var row1 = [_]Cell{ .{ .display_text = "a" }, .{ .display_text = "b" } };
    var row2 = [_]Cell{ .{ .display_text = "c" }, .{ .display_text = "d" } };

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

test "generateTableAlloc() - Small column values" {
    const allocator = std.testing.allocator;

    var column_widths = [_]usize{ 3, 3 };
    var table = init(allocator, &column_widths);
    defer table.deinit();

    var row1 = [_]Cell{ .{ .display_text = "a" }, .{ .display_text = "b" } };
    var row2 = [_]Cell{ .{ .display_text = "c" }, .{ .display_text = "d" } };

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

    var row1 = [_]Cell{ .{ .display_text = "Daniel" }, .{ .display_text = "Aguiar" }, .{ .display_text = "yo-reign" }, .{ .display_text = "yo" } };
    var row2 = [_]Cell{ .{ .display_text = "a" }, .{ .display_text = "-" }, .{ .display_text = " " }, .{ .display_text = "" } };

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

test "Table with links" {
    const allocator = std.testing.allocator;

    var column_widths = [_]usize{ 8, 4 };
    var table = init(allocator, &column_widths);
    defer table.deinit();

    var row1 = [_]Cell{ .{ .display_text = "Youtube" }, .{ .display_text = "Link", .link = "https://www.youtube.com" } };
    var row2 = [_]Cell{ .{ .display_text = "GitHub" }, .{ .display_text = "Lin", .link = "https://github.com/yo-reign" } };
    var row3 = [_]Cell{ .{ .display_text = "LinkedIn" }, .{ .display_text = "Links", .link = "https://www.linkedin.com/in/daniel-aguiar-reign", .open_in_new_tab = true } };

    try table.addRow(&row1);
    try table.addRow(&row2);
    try table.addRow(&row3);

    const expected_table =
        \\+ -------- + ---- +
        \\| Youtube  | <a href="https://www.youtube.com">Link</a> |
        \\| GitHub   | <a href="https://github.com/yo-reign">Lin</a>  |
        \\| LinkedIn | <a href="https://www.linkedin.com/in/daniel-aguiar-reign" target="_blank">Link</a> |
        \\+ -------- + ---- +
    ;

    try table.generateTableAlloc();

    try std.testing.expectEqualStrings(expected_table, table.generated_alloc_table.?.items);
}
