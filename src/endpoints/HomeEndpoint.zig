const std = @import("std");
const zap = @import("zap");

const AsciiTable = @import("../AsciiTable.zig");

pub const Self = @This();

endpoint: zap.Endpoint = undefined,
allocator: std.mem.Allocator = undefined,

// TODO: HTML Template should probably be available to every/most endpoints, so make it somehow...
var html_template_top_bun: []const u8 = undefined;
var html_template_bottom_bun: []const u8 = undefined;
var content: []const u8 = undefined;
var ascii_table: AsciiTable = undefined;

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

    // This causes whitespace between each line in the dom
    // content =
    //     \\<h1>Hello from Zig and ZAP!!!</h1>
    //     \\<p>This is a simple web server written in Zig.</p>
    // ;
    content = std.fmt.allocPrint(allocator, "{s}", .{homepage_banner_template}) catch unreachable;

    // ASCII TABLE
    // TODO: generate the actual table text and add it to the content

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
    self.allocator.free(content);
    ascii_table.deinit();
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
