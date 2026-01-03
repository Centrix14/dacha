const std = @import("std");
const ded64 = @import("ded64");

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    
    const table = ded64.DefaultTable;
    
    const message = "Man is distinguished\n";
    const encode = try table.encode(allocator, message);
    defer allocator.free(encode);

    try stdout.print("{s}\n", .{encode});
    try stdout.flush();
}
