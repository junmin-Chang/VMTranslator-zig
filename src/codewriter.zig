const std = @import("std");
const Parser = @import("parser.zig").Parser;

pub const CodeWriter = struct {
    writer: std.io.BufferedWriter(4096, std.fs.File.Writer),

    pub fn init(self: CodeWriter) CodeWriter {
        return CodeWriter{ .writer = std.io.bufferedWriter(self.writer.writer()) };
    }
    pub fn write_arithmetic(self: *CodeWriter, parser: *Parser) void {
        switch (parser.get_commandtype()) {
            .C_ARITHMETIC => {
                const arg1 = parser.get_arg1();
                if (std.mem.eql(u8, arg1, "add")) {
                    const str =
                        \\@SP
                        \\AM=M-1
                        \\D=M
                        \\M=0
                        \\A=A-1
                        \\M=M+D
                        \\
                    ;
                    try self.writer.writer().print(str, .{});
                } else if (std.mem.eql(u8, arg1, "sub")) {
                    const str =
                        \\@SP
                        \\AM=M-1
                        \\D=M
                        \\M=0
                        \\A=A-1
                        \\M=M-D
                        \\
                    ;
                    try self.writer.writer().print(str, .{});
                }
            },
            else => unreachable,
        }
    }
    pub fn write_push_pop(command: []u8, segment: []u8, index: i32) void {}
    pub fn close(self: CodeWriter) void {
        self.file.close();
    }
};
