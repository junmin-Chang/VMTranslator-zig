const std = @import("std");
const expect = std.testing.expect;
pub const CommandType = enum { C_ARITHMETIC, C_PUSH, C_POP, C_LABEL, C_GOTO, C_IF, C_FUNCTION, C_RETURN, C_CALL, NONE };
const ParsingError = error{ ARG1_ERROR, ARG2_ERROR, PARSE_INT_ERROR };

pub const Parser = struct {
    reader: std.io.BufferedReader(4096, std.fs.File.Reader),
    current_line: [4096]u8 = undefined,
    line_len: usize = 0,
    is_eof: bool = false,
    arg1: []const u8 = undefined,
    arg2: i32 = undefined,
    command_type: CommandType = undefined,

    pub fn init(file: std.fs.File) Parser {
        return Parser{
            .reader = std.io.bufferedReader(file.reader()),
        };
    }

    pub fn hasMoreLine(self: Parser) bool {
        return !self.is_eof;
    }
    pub fn advance(self: *Parser) !void {
        while (true) {
            if (try self.reader.reader().readUntilDelimiterOrEof(self.current_line[0..], '\n')) |line| {
                self.line_len = line.len;
            } else {
                self.is_eof = true;
                self.command_type = .NONE;
                return;
            }

            var line: []const u8 = self.current_line[0..self.line_len];
            if (std.mem.indexOf(u8, line, "//")) |idx| {
                line = line[0..idx];
            }

            line = std.mem.trim(u8, line, " \t\r\n");

            if (line.len == 0) continue;

            var tokenizer = std.mem.tokenizeAny(u8, line, " ");

            if (tokenizer.next()) |cmd| {
                self.arg1 = cmd;
                if (std.mem.eql(u8, cmd, "push")) {
                    self.command_type = .C_PUSH;
                    self.arg1 = tokenizer.next() orelse return ParsingError.ARG1_ERROR;
                    self.arg2 = try std.fmt.parseInt(i32, tokenizer.next() orelse return ParsingError.PARSE_INT_ERROR, 10);
                } else if (std.mem.eql(u8, cmd, "pop")) {
                    self.command_type = .C_POP;
                    self.arg1 = tokenizer.next() orelse return ParsingError.ARG1_ERROR;
                    self.arg2 = try std.fmt.parseInt(i32, tokenizer.next() orelse return ParsingError.PARSE_INT_ERROR, 10);
                } else {
                    self.command_type = .C_ARITHMETIC;
                    self.arg1 = cmd;
                }
            }
            break;
        }
    }
    pub fn get_commandtype(self: Parser) CommandType {
        return self.command_type;
    }
    pub fn get_arg1(self: Parser) ![]const u8 {
        if (self.command_type == .C_RETURN) {
            return ParsingError.ARG1_ERROR;
        }
        return self.arg1;
    }
    pub fn get_arg2(self: Parser) !i32 {
        switch (self.command_type) {
            .C_PUSH, .C_POP, .C_FUNCTION, .C_CALL => return self.arg2,
            else => return ParsingError.ARG2_ERROR,
        }
    }
};

test "parse" {
    const cwd = std.fs.cwd();
    const file: std.fs.File = try cwd.openFile("test.vm", .{});
    defer file.close();
    var parser = Parser.init(file);
    try parser.advance();
    try expect(parser.command_type == .C_PUSH);
    try expect(std.mem.eql(u8, parser.arg1, "local"));
    try expect(parser.arg2 == 0);

    try parser.advance();
    try expect(parser.command_type == .C_ARITHMETIC);
    try expect(std.mem.eql(u8, parser.arg1, "add"));
}
