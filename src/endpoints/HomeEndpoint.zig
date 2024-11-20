const std = @import("std");
const zap = @import("zap");

const AsciiTable = @import("../AsciiTable.zig");
const Cell = @import("../AsciiTable.zig").Cell;

pub const Self = @This();

endpoint: zap.Endpoint = undefined,
allocator: std.mem.Allocator = undefined,

// TODO: HTML Template should probably be available to every/most endpoints, so make it somehow...
var html_template_top_bun: []const u8 = undefined;
var html_template_bottom_bun: []const u8 = undefined;
var ascii_table: AsciiTable = undefined;
var content: []const u8 = undefined;

pub fn init(allocator: std.mem.Allocator, path: []const u8) Self {
    // READ TEMPLATES
    const homepage_banner_template = std.fs.cwd().readFileAlloc(allocator, "src/templates/homepage_banner.html", std.math.maxInt(usize)) catch unreachable;
    defer allocator.free(homepage_banner_template);

    const html_template = std.fs.cwd().readFileAlloc(allocator, "src/templates/index.html", std.math.maxInt(usize)) catch unreachable;
    defer allocator.free(html_template);
    var html_template_stream = std.io.fixedBufferStream(html_template);
    const html_template_reader = html_template_stream.reader();

    // WRITE TEMPLATE CONTENTS TO VARS
    // NOTE: Some of these are heap allocated and should be freed in the deinit() method
    html_template_top_bun = html_template_reader.readUntilDelimiterAlloc(allocator, '~', std.math.maxInt(usize)) catch unreachable;
    html_template_bottom_bun = html_template_reader.readAllAlloc(allocator, std.math.maxInt(usize)) catch unreachable;

    // ASCII TABLE
    var column_widths = [_]usize{ 10, 30 };
    ascii_table = AsciiTable.init(allocator, &column_widths);

    var row1 = [_]Cell{ .{ .display_text = "YouTube" }, .{ .display_text = "TODO: Update this link", .link = "https://www.youtube.com", .open_in_new_tab = true } };
    var row2 = [_]Cell{ .{ .display_text = "GitHub" }, .{ .display_text = "yo-reign", .link = "https://github.com/yo-reign", .open_in_new_tab = true } };
    var row3 = [_]Cell{ .{ .display_text = "LinkedIn" }, .{ .display_text = "daniel-aguiar-reign", .link = "https://www.linkedin.com/in/daniel-aguiar-reign", .open_in_new_tab = true } };

    ascii_table.addRow(&row1) catch unreachable;
    ascii_table.addRow(&row2) catch unreachable;
    ascii_table.addRow(&row3) catch unreachable;

    ascii_table.generateTableAlloc() catch unreachable;

    // WRITE CONTENT - NOTE: writing only once through allocPrint() simplifies the deinit() method
    content = std.fmt.allocPrint(allocator, "{s}\n<pre>{s}</pre>", .{
        homepage_banner_template,
        ascii_table.generated_alloc_table.?.items,
    }) catch unreachable;

    return .{
        .endpoint = zap.Endpoint.init(.{
            .path = path,
            .get = get,
        }),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(html_template_top_bun);
    self.allocator.free(html_template_bottom_bun);
    ascii_table.deinit();
    self.allocator.free(content);
}

pub fn getEndpoint(self: *Self) *zap.Endpoint {
    return &self.endpoint;
}

fn get(e: *zap.Endpoint, r: zap.Request) void {
    _ = e;

    // HACK: Random buffer size, make sure to increase if needed
    var buffer: [4096]u8 = undefined;
    const html = std.fmt.bufPrint(&buffer, "{s}{s}{s}", .{ html_template_top_bun, content, html_template_bottom_bun }) catch unreachable;

    r.sendBody(html) catch return;
}
