const std = @import("std");
const CommandType = enum { C_ARITHMETIC, C_PUSH, C_POP, C_LABEL, C_GOTO, C_IF, C_FUNCTION, C_RETURN, C_CALL };
const ParsingError = error{ ARG1_ERROR, ARG2_ERROR };

pub const Parser = struct {
    file: std.fs.File,
    current_line: []u8 = undefined,
    is_eof: bool = false,
    arg1: []u8 = undefined,
    arg2: i32 = undefined,
    command_type: CommandType = undefined,

    pub fn hasMoreLine(self: Parser) bool {
        return !self.is_eof;
    }
    pub fn advance() void {}
    pub fn get_commandtype(self: Parser) CommandType {
        return self.command_type;
    }
    pub fn get_arg1(self: Parser) ![]u8 {
        if (self.command_type == .C_RETURN) {
            return ParsingError.ARG1_ERROR;
        }
        return self.arg1;
    }
    pub fn get_arg2(self: Parser) !i32 {
        if (self.command_type != .C_PUSH or self.command_type != .C_POP or self.command_type != .C_FUNCTION or self.command_type != .C_CALL) {
            return ParsingError.ARG2_ERROR;
        }
        return self.arg2;
    }
};

// test "parse" {
//     const parser = Parser{};
// }
