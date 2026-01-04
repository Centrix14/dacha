const std = @import("std");
const dws = @import("dws");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var threaded = std.Io.Threaded.init(allocator, .{});
    const io = threaded.io();
    defer threaded.deinit();

    const server = try dws.Server.init("127.0.0.1", 1234, io);
    var listening = try server.listen();
    const connection = try listening.accept(io);
    defer connection.close(io);
}
