const std = @import("std");
const Socket = std.Io.net.Socket;
const Protocol = std.Io.net.Protocol;

pub const Server = struct {
    host: []const u8,
    port: u16,
    addr: std.Io.net.IpAddress,
    io: std.Io,

    pub fn init(host: []const u8, port: u16, io: std.Io) !Server {
        const addr = try std.Io.net.IpAddress.parse(host, port);

        return Server {
            .host = host, .port = port, .addr = addr, .io = io
        };
    }

    pub fn listen(self: Server) !std.Io.net.Server {
        return try self.addr.listen(self.io, .{
            .mode = Socket.Mode.stream,
            .protocol = Protocol.tcp
        });
    }
};
