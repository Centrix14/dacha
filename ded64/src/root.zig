const std = @import("std");

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
    
    fn chr(self: Table, index: u8) u8 {
        if (index == 64) {
            return self._pad;
        }
        else {
            return self._table[index];
        }
    }

    fn idx(self: Table, char: u8) u8 {
        if (char == self._symbols[0]) return 62;
        if (char == self._symbols[1]) return 63;
        if (char == self._pad) return 64;
        return switch (char) {
            48...57 => char + 4, // char is a digit
            65...90 => char - 65, // char is a capital letter
            97...122 => char - 71, // char is a small letter
            else => unreachable
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
            output[o+1] = ((input[i] & 0x03) << 4)
                | ((input[i+1] & 0xf0) >> 4);
            output[o+2] = ((input[i+1] & 0x0f) << 2)
                | ((input[i+2] & 0xc0) >> 6);
            output[o+3] = input[i+2] & 0x3f;

            i += 3; o += 4;
        }

        switch (tail) {
            2 => {
                output[o] = input[i] >> 2;
                output[o+1] = ((input[i] & 0x03) << 4)
                    | ((input[i+1] & 0xf0) >> 4);
                output[o+2] = ((input[i+1] & 0x0f) << 2);
                output[o+3] = 64;
            },
            
            1 => {
                output[o] = input[i] >> 2;
                output[o+1] = ((input[i] & 0x03) << 4);
                output[o+2] = 64;
                output[o+3] = 64;
            },

            else => unreachable
        }

        for (0..output.len) |j|
            output[j] = self.chr(output[j]);

        return output;
    }

    pub fn decode(self: Table, allocator: std.mem.Allocator, input: [] const u8) ! []u8 {
        const to_ignore = countCharFromEnd(input, self._pad);
        const useful_length = input.len - to_ignore;
        if (useful_length == 0)
            return "";

        var output = try allocator.alloc(u8, try decodeLengthFor(input) - to_ignore);

        var i: usize = 0;
        var o: usize = 0;
        var tail: usize = useful_length - i;
        while (tail >= 4) : (tail = useful_length - i) {
            const source = [4]u8{
                self.idx(input[i]), self.idx(input[i+1]),
                self.idx(input[i+2]), self.idx(input[i+3])
            };
            
            output[o] = (source[0] << 2) | ((source[1] & 0x30) >> 4);
            output[o+1] = (source[1] << 4) | (source[2] >> 2);
            output[o+2] = (source[2] << 6) | source[3];

            i += 4; o += 3;
        }

        switch (tail) {
            3 => {
                const source = [3]u8{
                    self.idx(input[i]), self.idx(input[i+1]),
                    self.idx(input[i+2])
                };

                output[o] = (source[0] << 2) | ((source[1] & 0x30) >> 4);
                output[o+1] = (source[1] << 4) | (source[2] >> 2);
            },

            2 => {
                const source = [2]u8{
                    self.idx(input[i]), self.idx(input[i+1])
                };

                output[o] = (source[0] << 2) | ((source[1] & 0x30) >> 4);
                output[o+1] = (source[1] << 4);
            },

            else => unreachable
        }

        return output;
    }
};

fn countCharFromEnd(buffer: [] const u8, char: u8) usize {
    var i: usize = buffer.len - 1;
    while (buffer[i] == char) : (i -= 1) {}
    return buffer.len - i - 1;
}

pub fn encodeLengthFor(buffer: [] const u8) !usize {
    if (buffer.len < 3)
        return 4;
    return try std.math.divCeil(usize, buffer.len, 3) * 4;
}

pub fn decodeLengthFor(buffer: [] const u8) !usize {
    if (buffer.len < 4)
        return 3;

    return try std.math.divFloor(usize, buffer.len, 4) * 3;
}
