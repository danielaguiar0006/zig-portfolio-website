const std = @import("std");
const zap = @import("zap");

pub const Self = @This();

endpoint: zap.Endpoint = undefined,

pub fn init(path: []const u8) Self {
    return .{
        .endpoint = zap.Endpoint.init(.{
            .path = path,
            .get = get,
        }),
    };
}

pub fn getEndpoint(self: *Self) *zap.Endpoint {
    return &self.endpoint;
}

fn get(e: *zap.Endpoint, r: zap.Request) void {
    _ = e;

    const file_path: []const u8 = "assets/css/style.css";
    r.sendFile(file_path) catch |err| {
        std.debug.print("ERROR: {s}\n", .{@errorName(err)});

        r.setStatus(.internal_server_error);
        r.sendBody("Internal Server Error") catch return;
    };

    // r.sendBody( // TODO: This allows me to dynamically send custom css - maybe a dark/light mode?
    //     \\#container {
    //     \\    width: 100%;
    //     \\    height: 100%;
    //     \\    display: flex;
    //     \\    justify-content: center;
    //     \\    align-items: center;
    //     \\    background-color: blue;
    //     \\}
    // ) catch return;

    std.debug.print("Sending file {s}\n", .{file_path});
}
