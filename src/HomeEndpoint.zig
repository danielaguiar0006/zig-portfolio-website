const std = @import("std");
const zap = @import("zap");

pub const Self = @This();

endpoint: zap.Endpoint = undefined,
allocator: std.mem.Allocator = undefined,

var html_template_top_bun: []const u8 = undefined;
var html_template_bottom_bun: []const u8 = undefined;
var content: []const u8 = undefined;

pub fn init(allocator: std.mem.Allocator, path: []const u8) Self {
    const html_template = std.fs.cwd().readFileAlloc(allocator, "src/index.html.template", std.math.maxInt(usize)) catch unreachable;
    defer allocator.free(html_template);

    var html_template_stream = std.io.fixedBufferStream(html_template);
    const html_template_reader = html_template_stream.reader();

    html_template_top_bun = html_template_reader.readUntilDelimiterAlloc(allocator, '~', std.math.maxInt(usize)) catch unreachable;
    html_template_bottom_bun = html_template_reader.readAllAlloc(allocator, std.math.maxInt(usize)) catch unreachable;
    content = "<h1>Hello from Zig and ZAP!!!</h1>" ++ "<p>This is a simple web server written in Zig.</p>";

    // This causes whitespace between each line in the dom
    // content =
    //     \\<h1>Hello from Zig and ZAP!!!</h1>
    //     \\<p>This is a simple web server written in Zig.</p>
    // ;

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
}

pub fn getEndpoint(self: *Self) *zap.Endpoint {
    return &self.endpoint;
}

fn get(e: *zap.Endpoint, r: zap.Request) void {
    _ = e;

    var buffer: [2048]u8 = undefined;
    const html = std.fmt.bufPrint(&buffer, "{s}{s}{s}", .{ html_template_top_bun, content, html_template_bottom_bun }) catch unreachable;

    r.sendBody(html) catch return;
}
