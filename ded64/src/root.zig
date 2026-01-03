const std = @import("std");
const testing = std.testing;

pub const Table = struct {
    _table: *const [64]u8,

    pub fn init() Table {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const digits = "0123456789";
        const symbols = "+/";

        return Table {
            ._table = upper ++ lower ++ digits ++ symbols,
        };
    }

    pub fn charOf(self: Table, index: u8) u8 {
        return self._table[index];
    }

    pub fn encode(self: Table, allocator: std.mem.Allocator, input: [] const u8) ! []u8 {
        if (input.len == 0)
            return "";
        
        var output = try allocator.alloc(u8, try encodeLengthFor(input));

        var i: usize = 0;
        var o: usize = 0;
        var tail: usize = input.len - i;
        while (tail >= 3) {
            output[o] = input[i] >> 2;
            output[o+1] = ((input[i] & 0b00000011) << 4)
                | ((input[i+1] & 0b11110000) >> 4);
            output[o+2] = ((input[i+1] & 0b00001111) << 2)
                | ((input[i+2] & 0b11000000) >> 6);
            output[o+3] = input[i+2] & 0b00111111;

            i += 3; o += 4;
            tail = input.len - i;
        }
        
        if (tail == 2) {
            output[o] = input[i] >> 2;
            output[o+1] = ((input[i] & 0b00000011) << 4)
                | ((input[i+1] & 0b11110000) >> 4);
            output[o+2] = ((input[i+1] & 0b00001111) << 2);
            output[o+3] = '=';
        }
        else if (tail == 1) {
            output[o] = input[i] >> 2;
            output[o+1] = ((input[i] & 0b00000011) << 4);
            output[o+2] = '=';
            output[o+3] = '=';
        }

        for (0..output.len) |j| {
            if (output[j] != '=') {
                output[j] = self.charOf(output[j]);
            }
        }

        return output;
    }
};

pub fn encodeLengthFor(buffer: [] const u8) !usize {
    if (buffer.len < 3)
        return 4;
    return try std.math.divCeil(usize, buffer.len, 3) * 4;
}

test "encodeLengthFor == 4 when buffer.len = 2" {
    const len = try encodeLengthFor("ab");
    try testing.expect(len == 4);
}

test "encodeLengthFor == 8 when buffer.len == 4" {
    const len = try encodeLengthFor("abcd");
    try testing.expect(len == 8);
}

fn countIgnoredTail(buffer: [] const u8) usize {
    var i: usize = buffer.len - 1;
    while (buffer[i] == '=') : (i -= 1) {}
    return buffer.len - i - 1;
}

test "countIgnoredTail == 0 when buffer is empty" {
    const tail = countIgnoredTail("abc");
    try testing.expect(tail == 0);
}

test "countIgnoredTail == 0 when buffer has no tail" {
    const tail = countIgnoredTail("abc");
    try testing.expect(tail == 0);
}

test "countIgnoredTail == 1 when buffers tail == 1" {
    const tail = countIgnoredTail("abc=");
    try testing.expect(tail == 1);
}

test "countIgnoredTail == 2  when buffers tail == 2" {
    const tail = countIgnoredTail("abc==");
    try testing.expect(tail == 2);
}

test "countIgnoredTail ignores inner `=`" {
    const tail = countIgnoredTail("=a=bc==");
    try testing.expect(tail == 2);
}

pub fn decodedBufferLength(buffer: [] const u8) !usize {
    if (buffer.len < 4)
        return 3;

    return try std.math.divFloor(usize, buffer.len, 4) * 3 - countIgnoredTail(buffer);
}

test "decodedBufferLength == 2 when buffer.len == 4 and no tail" {
    const len = try decodedBufferLength("abcd");
    try testing.expect(len == 3);
}

test "decodedBufferLength == 4 when buffer.len == 8 and tail == 2" {
    const len = try decodedBufferLength("abcdab==");
    try testing.expect(len == 4);
}
