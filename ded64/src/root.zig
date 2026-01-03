const std = @import("std");
const testing = std.testing;

pub const DefaultTable = Table.init("+/", '=');

pub const Table = struct {
    _table: *const [64]u8,
    _symbols: *const [2]u8,
    _pad: u8,

    pub fn init(symbols: *const [2]u8, pad: u8) Table {
        return Table {
            ._table = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ++
                "abcdefghijklmnopqrstuvwxyz" ++
                "0123456789" ++
                symbols,
            ._symbols = symbols,
            ._pad = pad,
        };
    }
    
    pub fn charOf(self: Table, index: u8) u8 {
        return self._table[index];
    }

    pub fn indexOf(self: Table, char: u8) u8 {
        return switch (char) {
            48...57 => char + 4, // char is a digit
            65...90 => char - 65, // char is a capital letter
            97...122 => char - 71, // char is a small letter
            self.symbols[0] => 62,
            self.symbols[1] => 63,
            self.pad => self.pad // pad has no its special index
        };
    }

    pub fn encode(self: Table, allocator: std.mem.Allocator, input: [] const u8) ! []u8 {
        if (input.len == 0)
            return "";
        
        var output = try allocator.alloc(u8, try encodeLengthFor(input));

        var i: usize = 0;
        var o: usize = 0;
        var tail: usize = input.len - i;
        while (tail >= 3) : (tail = input.len - i) {
            output[o] = input[i] >> 2;
            output[o+1] = ((input[i] & 0b00000011) << 4)
                | ((input[i+1] & 0b11110000) >> 4);
            output[o+2] = ((input[i+1] & 0b00001111) << 2)
                | ((input[i+2] & 0b11000000) >> 6);
            output[o+3] = input[i+2] & 0b00111111;

            i += 3; o += 4;
        }
        
        if (tail == 2) {
            output[o] = input[i] >> 2;
            output[o+1] = ((input[i] & 0b00000011) << 4)
                | ((input[i+1] & 0b11110000) >> 4);
            output[o+2] = ((input[i+1] & 0b00001111) << 2);
            output[o+3] = self._pad;
        }
        else if (tail == 1) {
            output[o] = input[i] >> 2;
            output[o+1] = ((input[i] & 0b00000011) << 4);
            output[o+2] = self._pad;
            output[o+3] = self._pad;
        }

        for (0..output.len) |j| {
            if (output[j] != self._pad) {
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
