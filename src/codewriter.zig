const std = @import("std");
const CommandType = @import("parser.zig").CommandType;
const expect = std.testing.expect;

const CodeWriterError = error{
    FileOpenError,
};
pub const CodeWriter = struct {
    writer: std.io.BufferedWriter(4096, std.fs.File.Writer),

    pub fn init(file: std.fs.File) CodeWriter {
        return CodeWriter{ .writer = std.io.bufferedWriter(file.writer()) };
    }
    pub fn write_arithmetic(self: *CodeWriter, command: []const u8) !void {
        if (std.mem.eql(u8, command, "add")) {
            const str =
                \\@SP
                \\AM=M-1
                \\D=M
                \\A=A-1
                \\M=M+D
                \\
            ;
            try self.writer.writer().print(str, .{});
        } else if (std.mem.eql(u8, command, "sub")) {
            const str =
                \\@SP
                \\AM=M-1
                \\D=M
                \\A=A-1
                \\M=M-D
                \\
            ;
            try self.writer.writer().print(str, .{});
        } else unreachable;
    }
    pub fn write_push_pop(self: *CodeWriter, command_type: CommandType, segment: []const u8, index: i32) !void {
        switch (command_type) {
            .C_PUSH => {
                if (std.mem.eql(u8, segment, "local")) {
                    // do something
                    const str =
                        \\@{d}
                        \\D=A
                        \\@LCL
                        \\A=M+D
                        \\D=M
                        \\@SP
                        \\A=M
                        \\M=D
                        \\@SP
                        \\M=M+1
                        \\
                    ;
                    try self.writer.writer().print(str, .{index});
                } else if (std.mem.eql(u8, segment, "constant")) {
                    const str =
                        \\@{d}
                        \\D=A
                        \\@SP
                        \\A=M
                        \\M=D
                        \\@SP
                        \\M=M+1
                        \\
                    ;
                    try self.writer.writer().print(str, .{index});
                } else if (std.mem.eql(u8, segment, "argument")) {
                    const str =
                        \\@{d}
                        \\D=A
                        \\@ARG
                        \\A=M+D
                        \\D=M
                        \\@SP
                        \\A=M
                        \\M=D
                        \\@SP
                        \\M=M+1
                        \\
                    ;
                    try self.writer.writer().print(str, .{index});
                }
            },
            .C_POP => {
                if (std.mem.eql(u8, segment, "local")) {
                    // do something
                    const str =
                        \\@{d}
                        \\D=A
                        \\@LCL
                        \\D=M+D
                        \\@R13
                        \\M=D
                        \\@SP
                        \\AM=M-1
                        \\D=M
                        \\@R13
                        \\A=M
                        \\M=D
                        \\
                    ;
                    try self.writer.writer().print(str, .{index});
                } else if (std.mem.eql(u8, segment, "argument")) {
                    // do something
                    const str =
                        \\@{d}
                        \\D=A
                        \\@ARG
                        \\D=M+D
                        \\@R13
                        \\M=D
                        \\@SP
                        \\AM=M-1
                        \\D=M
                        \\@R13
                        \\A=M
                        \\M=D
                        \\
                    ;
                    try self.writer.writer().print(str, .{index});
                } else if (std.mem.eql(u8, segment, "static")) {
                    // do something
                } else {
                    return;
                }
            },
            else => unreachable,
        }
    }
};

const Parser = @import("parser.zig").Parser;
test "codewrite" {
    const vm_file_path = "test_push_add.vm";
    const asm_file_path = "test_push_add.asm";

    var vm_file = try std.fs.cwd().createFile(vm_file_path, .{});
    defer vm_file.close();

    const vm_code =
        \\push constant 10
        \\push constant 20
        \\add
        \\
    ;

    try vm_file.writeAll(vm_code);
    vm_file.close();

    var parser = Parser.init(std.fs.cwd().openFile(vm_file_path, .{}) catch return CodeWriterError.FileOpenError);

    var asm_file = try std.fs.cwd().createFile(asm_file_path, .{});
    defer asm_file.close();

    var codewriter = CodeWriter.init(asm_file);

    while (parser.hasMoreLine()) {
        try parser.advance();
        const command_type = parser.get_commandtype();

        switch (command_type) {
            .C_PUSH, .C_POP => {
                const segment = try parser.get_arg1();
                const index = try parser.get_arg2();
                try codewriter.write_push_pop(command_type, segment, index);
            },

            .C_ARITHMETIC => {
                const command = try parser.get_arg1();
                try codewriter.write_arithmetic(command);
            },
            else => {},
        }
    }

    try codewriter.writer.flush();

    const actual_asm = try std.fs.cwd().openFile(asm_file_path, .{});
    defer actual_asm.close();

    const expected_asm =
        \\@10
        \\D=A
        \\@SP
        \\A=M
        \\M=D
        \\@SP
        \\M=M+1
        \\@20
        \\D=A
        \\@SP
        \\A=M
        \\M=D
        \\@SP
        \\M=M+1
        \\@SP
        \\AM=M-1
        \\D=M
        \\A=A-1
        \\M=M+D
        \\
    ;

    var buffer: [expected_asm.len]u8 = undefined;
    const bytes_read = try actual_asm.readAll(&buffer);

    try expect(std.mem.eql(u8, buffer[0..bytes_read], expected_asm));
}
