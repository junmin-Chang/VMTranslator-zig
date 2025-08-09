const std = @import("std");

pub const CodeWriter = struct {
    file: std.fs.File,

    pub fn write_arithmetic(command: []u8) void {}
    pub fn write_push_pop(command: []u8) void {}
    pub fn close(self: CodeWriter) void {
        self.file.close();
    }
};
