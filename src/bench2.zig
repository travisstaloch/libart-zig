const std = @import("std");
const art = @import("art");
const Art = art.Art;
const art_test = @import("test_art.zig");

const bench_log = if (std.debug.runtime_safety) std.debug.print else std.log.info;

fn bench(a: std.mem.Allocator, container: anytype, comptime appen_fn: anytype, comptime get_fn: anytype, comptime del_fn: anytype) !void {
    const filename = "./testdata/words.txt";
    var lines = std.ArrayList([:0]const u8).init(a);
    defer lines.deinit();
    defer {
        for (lines.items) |line| {
            a.free(line);
        }
    }

    {
        const f = try std.fs.cwd().openFile(filename, .{ .mode = .read_only });
        defer f.close();
        const reader = &f.reader();
        while (try reader.readUntilDelimiterOrEofAlloc(a, '\n', 512)) |line| {
            defer a.free(line);
            try lines.append(try a.dupeZ(u8, line));
        }
    }

    const doInsert_ = struct {
        fn func(line: [:0]const u8, linei: usize, _container: anytype, _: anytype, comptime U: type) anyerror!void {
            _ = U;
            _ = try appen_fn(_container, line, linei);
        }
    }.func;
    var timer = try std.time.Timer.start();
    for (0.., lines.items) |i, line| {
        try doInsert_(line, i, container, null, usize);
    }
    const t1 = timer.read();

    const doSearch = struct {
        fn func(line: [:0]const u8, linei: usize, _container: anytype, _: anytype, comptime U: type) anyerror!void {
            _ = U;
            _ = linei;
            if (@TypeOf(_container) == *Art(usize)) {
                const result = get_fn(_container, line);
                try std.testing.expect(result == .found);
            } else {
                const result = get_fn(_container.*, line);
                try std.testing.expect(result != null);
            }
        }
    }.func;

    timer.reset();
    for (0.., lines.items) |i, line| {
        try doSearch(line, i, container, null, usize);
    }
    const t2 = timer.read();

    const doDelete = struct {
        fn func(line: [:0]const u8, linei: usize, _container: anytype, _: anytype, comptime U: type) anyerror!void {
            _ = U;
            _ = linei;
            if (@TypeOf(_container) == *Art(usize)) {
                const result = try del_fn(_container, line);
                try std.testing.expect(result == .found);
            } else {
                const result = del_fn(_container, line);
                try std.testing.expect(result);
            }
        }
    }.func;
    timer.reset();
    for (0.., lines.items) |i, line| {
        try doDelete(line, i, container, null, usize);
    }
    const t3 = timer.read();

    std.debug.print("insert {}ms, search {}ms, delete {}ms, combined {}ms\n", .{ t1 / 1000000, t2 / 1000000, t3 / 1000000, (t1 + t2 + t3) / 1000000 });
    try art_test.free_keys(container);
}

/// bench against StringHashMap
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const aa = arena.allocator();
        const Map = std.StringHashMap(usize);
        var map = Map.init(aa);
        std.debug.print("\nStringHashMap\n", .{});
        try bench(allocator, &map, Map.put, Map.get, Map.remove);
    }
    {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();
        const aa = arena.allocator();
        const T = Art(usize);
        var t = T.init(&aa);
        defer t.deinit();
        std.debug.print("\nArt\n", .{});
        try bench(allocator, &t, T.insert, T.search, T.delete);
    }
}
