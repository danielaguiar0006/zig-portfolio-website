// TODO: Go throughout the whole codebase and actually handle errors instead of just doing "catch unreachable"
// TODO: Add a default 404 endpoint

const std = @import("std");
const zap = @import("zap");

const StyleEndpoint = @import("endpoints/StyleEndpoint.zig");
const IconEndpoint = @import("endpoints/IconEndpoint.zig");
const HomePageEndpoint = @import("endpoints/HomePageEndpoint.zig");

const HOMEPAGE_URI = "/home";

fn on_request(r: zap.Request) void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});

        // REDIRECT TO HOMEPAGE
        if (std.mem.eql(u8, the_path, "/") or std.mem.startsWith(u8, the_path, "/index")) {
            r.redirectTo(HOMEPAGE_URI, .moved_permanently) catch |err| {
                r.setStatus(.internal_server_error);
                r.sendBody("Internal Server Error") catch return;

                std.debug.print("ERROR: {s}\n", .{@errorName(err)});
                return;
            };

            std.debug.print("REDIRECTING TO {s}\n", .{HOMEPAGE_URI});
        }
    }

    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }

    if (r.body) |the_body| {
        std.debug.print("BODY: {s}\n", .{the_body});
    }
}

pub fn main() !void {
    // INIT ALLOCATOR - NOTE: using GPA to detect memory leaks
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
        .safety = true,
    }){};
    defer { // DEINIT ALLOCATOR
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) {
            std.debug.print("Memory leak detected!\n", .{});
        }
    }
    const allocator = gpa.allocator();

    // CREATE LISTENER
    var endpoint_listener = zap.Endpoint.Listener.init(allocator, .{
        .port = 8080,
        .on_request = on_request,
        .log = true,
        // TODO: .public_folder = "html/",
        .max_clients = 10000,
        .max_body_size = 1024 * 1024 * 10,
    });
    defer endpoint_listener.deinit();

    // INIT ENDPOINTS - NOTE: Watch out! Some might need to be deinited
    var style_endpoint = StyleEndpoint.init("/style.css");
    var icon_endpoint = IconEndpoint.init("/icon.jpg");
    var home_endpoint = HomePageEndpoint.init(allocator, HOMEPAGE_URI);
    defer home_endpoint.deinit();

    // REGISTER ENDPOINTS TO LISTENER
    try endpoint_listener.register(style_endpoint.getEndpoint());
    try endpoint_listener.register(icon_endpoint.getEndpoint());
    try endpoint_listener.register(home_endpoint.getEndpoint());

    // LISTEN
    try endpoint_listener.listen();
    std.debug.print("Listening on 0.0.0.0:8080\n", .{});

    // START ZAP
    zap.start(.{
        .threads = 2,
        .workers = 1, // 1 worker enables sharing state between threads
    });
}
