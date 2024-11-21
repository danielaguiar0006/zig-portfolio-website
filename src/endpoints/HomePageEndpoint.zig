const std = @import("std");
const zap = @import("zap");

const AsciiTable = @import("../AsciiTable.zig");
const Cell = @import("../AsciiTable.zig").Cell;

pub const Self = @This();

endpoint: zap.Endpoint = undefined,
allocator: std.mem.Allocator = undefined,

/// Holds all of the html content for this page (except for the html templates)
var content: std.ArrayList(u8) = undefined;
// TODO: HTML Template should probably be available to every/most endpoints, so make it somehow...
var html_template_top_bun: []const u8 = undefined;
var html_template_bottom_bun: []const u8 = undefined;

var menu_table: AsciiTable = undefined;

pub fn init(allocator: std.mem.Allocator, path: []const u8) Self {
    // INIT CONTENT
    content = std.ArrayList(u8).init(allocator);
    const content_writer = content.writer();

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

    // MENU - TODO: Make a global menu so modifying it in one place affects all other pages
    var column_widths = [_]usize{15};
    menu_table = AsciiTable.init(allocator, &column_widths);

    // TODO: Add links to their respective pages
    var row_1 = [_]Cell{.{ .display_text = "-> Home", .is_bold = true }};
    var row_2 = [_]Cell{.{ .display_text = "Projects", .is_bold = true }};
    var row_3 = [_]Cell{.{ .display_text = "Info", .is_bold = true }};
    var row_4 = [_]Cell{.{ .display_text = "Contact", .is_bold = true }};
    var row_5 = [_]Cell{.{ .display_text = "FAQ", .is_bold = true }};
    var row_6 = [_]Cell{.{ .display_text = "Reign's Mind", .is_bold = true }};

    menu_table.addRow(&row_1) catch unreachable;
    menu_table.addRow(&row_2) catch unreachable;
    menu_table.addRow(&row_3) catch unreachable;
    menu_table.addRow(&row_4) catch unreachable;
    menu_table.addRow(&row_5) catch unreachable;
    menu_table.addRow(&row_6) catch unreachable;

    menu_table.generateTableAlloc() catch unreachable;

    // WRITE CONTENT
    content_writer.print("{s}\n", .{homepage_banner_template}) catch unreachable; // Banner
    content_writer.print("<div id=\"menu\"><b># MENU</b><pre>{s}</pre></div>", .{menu_table.generated_alloc_table.?.items}) catch unreachable; // Menu

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
    menu_table.deinit();
    content.deinit();
}

pub fn getEndpoint(self: *Self) *zap.Endpoint {
    return &self.endpoint;
}

fn get(e: *zap.Endpoint, r: zap.Request) void {
    _ = e;

    // Using a fixed buffer size to avoid heap
    var buffer: [4096]u8 = undefined;
    const html = std.fmt.bufPrint(&buffer, "{s}{s}{s}", .{ html_template_top_bun, content.items, html_template_bottom_bun }) catch unreachable;

    r.sendBody(html) catch return;
}
