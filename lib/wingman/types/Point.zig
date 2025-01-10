pub fn Point(comptime I: type) type {
    return struct {
        x: I,
        y: I,
    };
}
