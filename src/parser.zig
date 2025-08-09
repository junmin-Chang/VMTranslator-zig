const std = @import("std");
const CommandType = enum { C_ARITHMETIC, C_PUSH, C_POP, C_LABEL, C_GOTO, C_IF, C_FUNCTION, C_RETURN, C_CALL };

pub const Parser = struct {
    arg1: []u8,
    arg2: i32,
    command_type: CommandType,

    pub fn hasMoreLine() bool {}
    pub fn advance() void {}
    pub fn get_commandtype(self: Parser) CommandType {
        return self.command_type;
    }
    pub fn get_arg1(self: Parser) []u8 {
        return self.arg1;
    }
    pub fn get_arg2(self: Parser) i32 {
        return self.arg2;
    }
};
