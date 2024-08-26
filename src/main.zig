const std = @import("std");

const InputBuffer = struct {
    buffer: []u8,
    buffer_length: usize,
    input_length: usize,

    pub fn init(allocator: *const std.mem.Allocator) !InputBuffer {
        const buffer = try allocator.alloc(u8, 1024);
        return InputBuffer{
            .buffer = buffer,
            .buffer_length = 0,
            .input_length = 0,
        };
    }

    pub fn read_line(self: *InputBuffer) ![]u8 {
        const stdin = std.io.getStdIn().reader();

        const line = try stdin.readUntilDelimiterOrEof(self.buffer, '\n');

        if (line) |l| {
            self.input_length = l.len;
            self.buffer_length = l.len;
            return l;
        } else {
            return error.EndOfStream;
        }
    }
};

pub fn main() !void {

    const allocator = std.heap.page_allocator;
    var input_buffer = try InputBuffer.init(&allocator);
    defer allocator.free(input_buffer.buffer);

    while (true) {
        std.debug.print("db > ", .{});
        const line = try input_buffer.read_line();
        
        if (std.mem.eql(u8, std.mem.trim(u8, line, &std.ascii.whitespace), "exit") or
            std.mem.eql(u8, std.mem.trim(u8, line, &std.ascii.whitespace), "quit")) {
            std.debug.print("Exiting...\n", .{});
            break;
        }
        
        std.debug.print("{s}\n", .{line});
    }

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    //const stdout_file = std.io.getStdOut().writer();
    //var bw = std.io.bufferedWriter(stdout_file);
    //const stdout = bw.writer();

    //try stdout.print("Run `zig build test` to run the tests.\n", .{});

    //try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
