const std = @import("std");
const api = @import("api.zig");
const models = @import("models.zig");

pub fn main(init: std.process.Init) !void {
    const gpa = init.gpa;

    var client: api.Api = .init(gpa, init.io);
    defer client.deinit();

    const get = try client.send(.{
        .location = .{ .url = api.base_url ++ "/todos/1" },
    });
    std.debug.print("GET status: {d}\n", .{@backingInt(get)});
    if (get != .ok) return error.UnexpectedStatus;

    var parsed = try std.json.parseFromSlice(models.Todo, gpa, client.bodyText(), .{});
    std.debug.print("Todo: {s} (completed: {})\n", .{
        parsed.value.title,
        parsed.value.completed,
    });
    parsed.deinit();

    const filtered = try client.send(.{
        .location = .{ .url = api.base_url ++ "/posts?userId=1" },
        .extra_headers = &.{
            .{ .name = "accept", .value = "application/json" },
        },
    });
    if (filtered != .ok) return error.UnexpectedStatus;

    var posts = try std.json.parseFromSlice([]models.Post, gpa, client.bodyText(), .{
        .ignore_unknown_fields = true,
    });
    std.debug.print("Found {d} posts for user 1\n", .{posts.value.len});
    if (posts.value.len > 0) {
        std.debug.print("First post: {s}\n", .{posts.value[0].title});
    }
    posts.deinit();

    const missing = try client.send(.{
        .location = .{ .url = api.base_url ++ "/todos/999999" },
    });
    std.debug.print("Missing todo status: {d}\n", .{@backingInt(missing)});
    if (missing != .not_found) return error.UnexpectedStatus;

    const new_post = .{
        .title = "Hello from Zig",
        .body = "My first API call",
        .userId = 1,
    };
    const payload = try std.json.Stringify.valueAlloc(gpa, new_post, .{});
    defer gpa.free(payload);

    const post = try client.send(.{
        .location = .{ .url = api.base_url ++ "/posts" },
        .method = .POST,
        .payload = payload,
        .headers = .{ .content_type = .{ .override = "application/json" } },
    });
    std.debug.print("POST status: {d}\n{s}\n", .{ @backingInt(post), client.bodyText() });
    if (post != .created) return error.UnexpectedStatus;

    const replacement = .{
        .id = 1,
        .userId = 1,
        .title = "A replacement title",
        .body = "A replacement body",
    };
    const replacement_json = try std.json.Stringify.valueAlloc(gpa, replacement, .{});
    defer gpa.free(replacement_json);

    const put = try client.send(.{
        .location = .{ .url = api.base_url ++ "/posts/1" },
        .method = .PUT,
        .payload = replacement_json,
        .headers = .{ .content_type = .{ .override = "application/json" } },
    });
    std.debug.print("PUT status: {d}\n{s}\n", .{ @backingInt(put), client.bodyText() });
    if (put != .ok) return error.UnexpectedStatus;

    const patch = try client.send(.{
        .location = .{ .url = api.base_url ++ "/posts/1" },
        .method = .PATCH,
        .payload = "{\"title\":\"A patched title\"}",
        .headers = .{ .content_type = .{ .override = "application/json" } },
    });
    std.debug.print("PATCH status: {d}\n{s}\n", .{ @backingInt(patch), client.bodyText() });
    if (patch != .ok) return error.UnexpectedStatus;

    const delete = try client.send(.{
        .location = .{ .url = api.base_url ++ "/posts/1" },
        .method = .DELETE,
    });
    std.debug.print("DELETE status: {d}\n{s}\n", .{ @backingInt(delete), client.bodyText() });
    if (delete != .ok) return error.UnexpectedStatus;
}
