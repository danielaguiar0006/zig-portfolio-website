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

    const file_path: []const u8 = "imgs/me_256x256.jpg";
    r.sendFile(file_path) catch return;

    std.debug.print("Sending file {s}\n", .{file_path});
}
