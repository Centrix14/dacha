const std = @import("std");
const ded64 = @import("ded64");

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    
    const table = ded64.DefaultTable;

    const message = "Man is distinguished, not only by his reason, but by this singular passion from other animals, which is a lust of the mind, that by a perseverance of delight in the continued and indefatigable generation of knowledge, exceeds the short vehemence of any carnal pleasure.";
    
    const encode = try table.encode(allocator, message);
    defer allocator.free(encode);

    const decode = try table.decode(allocator, encode);
    defer allocator.free(decode);

    try stdout.print("{any}\n", .{std.mem.eql(u8, message, decode)});

    try stdout.flush();
}
