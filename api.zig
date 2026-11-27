//! A thin wrapper around std.http.Client that owns the response buffer.

const std = @import("std");

pub const base_url = "https://jsonplaceholder.typicode.com";

pub const Api = struct {
    client: std.http.Client,
    body: std.Io.Writer.Allocating,

    pub fn init(gpa: std.mem.Allocator, io: std.Io) Api {
        return .{
            .client = .{ .allocator = gpa, .io = io },
            .body = .init(gpa),
        };
    }

    pub fn deinit(self: *Api) void {
        self.body.deinit();
        self.client.deinit();
    }

    /// Sends a request, replacing the previous response body with the new one.
    /// `options.response_writer` is set for you; read the result with `bodyText`.
    pub fn send(self: *Api, options: std.http.Client.FetchOptions) !std.http.Status {
        self.body.clearRetainingCapacity();
        var opts = options;
        opts.response_writer = &self.body.writer;
        const result = try self.client.fetch(opts);
        return result.status;
    }

    pub fn bodyText(self: *Api) []const u8 {
        return self.body.written();
    }
};
