//! JSON shapes for the JSONPlaceholder API.

pub const Todo = struct {
    userId: u32,
    id: u32,
    title: []const u8,
    completed: bool,
};

pub const Post = struct {
    title: []const u8,
};
