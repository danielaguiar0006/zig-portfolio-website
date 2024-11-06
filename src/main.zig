const std = @import("std");
const zap = @import("zap");

var gpa = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
    .safety = true,
}){};
const allocator = gpa.allocator();

var html_template_top_bun: []const u8 = undefined;
var html_template_bottom_bun: []const u8 = undefined;
var content: []const u8 = undefined;

fn on_request(r: zap.Request) void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
    }

    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }

    const html = std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ html_template_top_bun, content, html_template_bottom_bun }) catch unreachable;
    defer allocator.free(html);

    r.sendBody(html) catch return;
}

pub fn main() !void {
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }

    const html_template = std.fs.cwd().readFileAlloc(allocator, "src/index.html.template", std.math.maxInt(usize)) catch unreachable;
    defer allocator.free(html_template);

    var html_template_stream = std.io.fixedBufferStream(html_template);
    const html_template_reader = html_template_stream.reader();

    // GET THE TWO HALVES OF THE TEMPLATE
    html_template_top_bun = html_template_reader.readUntilDelimiterAlloc(allocator, '~', std.math.maxInt(usize)) catch unreachable;
    html_template_bottom_bun = html_template_reader.readAllAlloc(allocator, std.math.maxInt(usize)) catch unreachable;
    defer allocator.free(html_template_top_bun);
    defer allocator.free(html_template_bottom_bun);

    content =
        \\<h1>Hello from Zig and ZAP!!!</h1>
        \\  <p>This is a simple web server written in Zig.</p>
    ;

    var listener = zap.HttpListener.init(.{
        .port = 9090,
        .on_request = on_request,
        .log = true,
        .max_clients = 10000,
    });
    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:9090\n", .{});

    zap.start(.{
        .threads = 2,
        .workers = 1, // 1 worker enables sharing state between threads
    });
}
