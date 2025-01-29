const rl = @import("raylib");
const std = @import("std");

const cellSize = 48;
const borderThickness = 20;
const playfieldRows = 40;
const playfieldVisibleStart = 20;
const playfieldCols = 10;
const tetrominoCells = 4;

const playfieldX = borderThickness;
const playfieldY = borderThickness + 2 * cellSize;

const previewX = playfieldX + playfieldCols * cellSize + 20;
const previewY = playfieldY;

const screenWidth = 3 * borderThickness + (playfieldCols + tetrominoCells) * cellSize;
const screenHeight = (playfieldRows - playfieldVisibleStart + 2) * cellSize + 2 * borderThickness;

const gridColor = rl.Color.init(180, 180, 180, 130);
const borderColor = rl.Color.init(25, 25, 25, 255);
const shadowColor = rl.Color.init(100, 100, 100, 80);

const Pos = struct {
    x: isize,
    y: isize,
};

const Tetromino = struct {
    shape: []const Pos,
    color: rl.Color,

    const Iterator = struct {
        anchor: Pos,
        inner: []const Pos,
        idx: usize,

        fn next(self: *Iterator) ?Pos {
            if (self.inner.len == self.idx) return null;

            const pos = self.inner[self.idx];
            self.idx += 1;

            return Pos{
                .x = self.anchor.x + pos.x,
                .y = self.anchor.y + pos.y,
            };
        }
    };

    fn positionsIterator(self: Tetromino, anchor: Pos) Iterator {
        return Iterator{
            .inner = self.shape,
            .anchor = anchor,
            .idx = 0,
        };
    }
};

const Cell = union(enum) {
    empty: void,
    filled: rl.Color,
};

const TetrominoType = enum { I, O, S, Z, L, J, T };

fn tetrominoColor(t: TetrominoType) rl.Color {
    switch (t) {
        .I => return rl.Color.init(0, 255, 255, 255),
        .O => return rl.Color.init(255, 255, 0, 255),
        .S => return rl.Color.init(0, 255, 0, 255),
        .Z => return rl.Color.init(255, 0, 0, 255),
        .L => return rl.Color.init(255, 160, 0, 255),
        .J => return rl.Color.init(0, 0, 255, 255),
        .T => return rl.Color.init(128, 0, 128, 255),
    }
}

fn tetrominoShape(t: TetrominoType, rot: u2) []const Pos {
    switch (t) {
        .I => {
            switch (rot) {
                0, 2 => {
                    return &[_]Pos{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 2, .y = 0 } };
                },
                1, 3 => {
                    return &[_]Pos{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 2 } };
                },
            }
        },
        .O => {
            return &[_]Pos{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } };
        },
        .S => {
            switch (rot) {
                0 => {
                    return &[_]Pos{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 1, .y = -1 } };
                },
                1 => {
                    return &[_]Pos{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = 1 } };
                },
                2 => {
                    return &[_]Pos{ .{ .x = -1, .y = 1 }, .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 } };
                },
                3 => {
                    return &[_]Pos{ .{ .x = -1, .y = -1 }, .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 } };
                },
            }
        },
        .Z => {
            switch (rot) {
                0 => {
                    return &[_]Pos{ .{ .x = -1, .y = -1 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 } };
                },
                1 => {
                    return &[_]Pos{ .{ .x = 1, .y = -1 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 } };
                },
                2 => {
                    return &[_]Pos{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } };
                },
                3 => {
                    return &[_]Pos{ .{ .x = -1, .y = 1 }, .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 } };
                },
            }
        },
        .L => {
            switch (rot) {
                0 => {
                    return &[_]Pos{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 1, .y = -1 } };
                },
                1 => {
                    return &[_]Pos{ .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 1 } };
                },
                2 => {
                    return &[_]Pos{ .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = -1, .y = 1 } };
                },
                3 => {
                    return &[_]Pos{ .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = -1, .y = -1 } };
                },
            }
        },
        .J => {
            switch (rot) {
                0 => {
                    return &[_]Pos{ .{ .x = -1, .y = -1 }, .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 } };
                },
                1 => {
                    return &[_]Pos{ .{ .x = 1, .y = -1 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 } };
                },
                2 => {
                    return &[_]Pos{ .{ .x = 1, .y = 1 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 } };
                },
                3 => {
                    return &[_]Pos{ .{ .x = -1, .y = 1 }, .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 } };
                },
            }
        },
        .T => {
            switch (rot) {
                0 => {
                    return &[_]Pos{ .{ .x = -1, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 } };
                },
                1 => {
                    return &[_]Pos{ .{ .x = 0, .y = -1 }, .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 } };
                },
                2 => {
                    return &[_]Pos{ .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 } };
                },
                3 => {
                    return &[_]Pos{ .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 0 }, .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 } };
                },
            }
        },
    }
}

const GameState = struct {
    playfield: [playfieldRows][playfieldCols]Cell = .{[_]Cell{.empty} ** playfieldCols} ** playfieldRows,
    currentTetrominoType: TetrominoType,
    anchor: Pos,
    rotation: u2,
    lockDelay: usize,
    rand: std.Random.DefaultPrng,
    horizontallyMoved: bool,
    nextTetrominos: [4]TetrominoType,
    heldType: ?TetrominoType,
    alreadySwapped: bool,

    fn currentTetromino(self: GameState) Tetromino {
        return Tetromino{
            .color = tetrominoColor(self.currentTetrominoType),
            .shape = tetrominoShape(self.currentTetrominoType, self.rotation),
        };
    }
};

var gameState = GameState{
    .rotation = 0,
    .lockDelay = 1,
    .rand = undefined,
    .horizontallyMoved = false,
    .nextTetrominos = undefined,
    .currentTetrominoType = undefined,
    .anchor = undefined,
    .heldType = null,
    .alreadySwapped = false,
};

fn drawGrid(startX: usize, startY: usize, cols: usize, rows: usize) void {
    const width: i32 = @intCast(cols * cellSize);
    const height: i32 = @intCast(rows * cellSize);

    for (0..rows + 1) |row| {
        const x: i32 = @intCast(startX);
        const y: i32 = @intCast(startY + row * cellSize);
        rl.drawLine(x, y, x + width, y + 1, gridColor);
    }

    for (0..cols + 1) |col| {
        const x: i32 = @intCast(startX + col * cellSize);
        const y: i32 = @intCast(startY);
        rl.drawLine(x, y, x + 1, y + height, gridColor);
    }
}

fn drawCurrentTetromino() void {
    const currentTetromino = gameState.currentTetromino();
    const color = currentTetromino.color;
    var it = currentTetromino.positionsIterator(gameState.anchor);

    while (it.next()) |pos| {
        const x: i32 = @intCast(playfieldX + pos.x * cellSize);
        const y: i32 = @intCast(playfieldY + (pos.y - playfieldVisibleStart) * cellSize);
        rl.drawRectangle(x + 1, y + 1, cellSize - 1, cellSize - 1, color);

        rl.drawRectangleLines(x, y, cellSize + 1, cellSize + 1, borderColor);
        rl.drawRectangleLines(x + 1, y + 1, cellSize - 1, cellSize - 1, borderColor);
    }
}

fn drawTetrominoShadow() void {
    const shadowRow = getShadowRow();

    const currentTetromino = gameState.currentTetromino();
    var it = currentTetromino.positionsIterator(Pos{
        .x = gameState.anchor.x,
        .y = shadowRow,
    });

    while (it.next()) |pos| {
        const x: i32 = @intCast(playfieldX + pos.x * cellSize);
        const y: i32 = @intCast(playfieldY + (pos.y - playfieldVisibleStart) * cellSize);

        rl.drawRectangle(x + 1, y + 1, cellSize - 1, cellSize - 1, shadowColor);
        rl.drawRectangleLines(x, y, cellSize + 1, cellSize + 1, borderColor);
        rl.drawRectangleLines(x + 1, y + 1, cellSize - 1, cellSize - 1, borderColor);
    }
}

fn drawPlayfield() void {
    for (playfieldVisibleStart..playfieldRows) |row| {
        for (0..playfieldCols) |col| {
            if (gameState.playfield[row][col] == .empty) continue;

            const color = gameState.playfield[row][col].filled;
            const x: i32 = @intCast(playfieldX + col * cellSize);
            const y: i32 = @intCast(playfieldY + (row - playfieldVisibleStart) * cellSize);
            rl.drawRectangle(x + 1, y + 1, cellSize - 1, cellSize - 1, color);
        }
    }
}

fn canMove(newPos: Pos) bool {
    const currentTetromino = gameState.currentTetromino();
    var it = currentTetromino.positionsIterator(newPos);

    while (it.next()) |pos| {
        if (pos.x < 0 or pos.y > playfieldRows - 1 or pos.x > playfieldCols - 1) return false;
        const col: usize = @as(usize, @intCast(pos.x));
        const row: usize = @as(usize, @intCast(pos.y));

        if (gameState.playfield[row][col] != .empty) return false;
    }

    return true;
}

fn getShadowRow() isize {
    const startY = gameState.anchor.y;
    var last = startY;
    var row = startY + 1;
    while (row < playfieldRows + 1) : (row += 1) {
        const newPos = Pos{
            .x = gameState.anchor.x,
            .y = row,
        };

        if (!canMove(newPos))
            return last;

        last = row;
    }

    @panic("unreachable");
}

fn drawPreview() void {
    for (0..gameState.nextTetrominos.len) |i| {
        const origy: isize = @intCast(previewY + 20 + cellSize + (i + 1) * (4 * cellSize));
        const origx: isize = @intCast(previewX + cellSize);

        const color = tetrominoColor(gameState.nextTetrominos[i]);
        const shape = tetrominoShape(gameState.nextTetrominos[i], 0);
        for (shape) |pos| {
            const x: i32 = @intCast(origx + pos.x * cellSize);
            const y: i32 = @intCast(origy + pos.y * cellSize);

            rl.drawRectangle(x + 1, y + 1, cellSize - 1, cellSize - 1, color);

            rl.drawRectangleLines(x, y, cellSize + 1, cellSize + 1, borderColor);
            rl.drawRectangleLines(x + 1, y + 1, cellSize - 1, cellSize - 1, borderColor);
        }
    }
}

fn drawHeld() void {
    if (gameState.heldType) |held| {
        const origy: isize = @intCast(previewY + cellSize);
        const origx: isize = @intCast(previewX + cellSize);

        const color = tetrominoColor(held);
        const shape = tetrominoShape(held, 0);
        for (shape) |pos| {
            const x: i32 = @intCast(origx + pos.x * cellSize);
            const y: i32 = @intCast(origy + (pos.y + 1) * cellSize);

            rl.drawRectangle(x + 1, y + 1, cellSize - 1, cellSize - 1, color);

            rl.drawRectangleLines(x, y, cellSize + 1, cellSize + 1, borderColor);
            rl.drawRectangleLines(x + 1, y + 1, cellSize - 1, cellSize - 1, borderColor);
        }
    }
}

fn draw() void {
    rl.clearBackground(rl.Color.init(30, 30, 30, 255));
    drawGrid(playfieldX, playfieldY, playfieldCols, playfieldRows - playfieldVisibleStart);
    drawGrid(previewX, previewY, tetrominoCells, tetrominoCells);
    drawPlayfield();
    drawCurrentTetromino();
    drawTetrominoShadow();
    drawHeld();
    drawPreview();
}

fn getNextType() TetrominoType {
    const random = gameState.rand.random();
    const r = random.intRangeAtMost(usize, 0, 6);
    return @enumFromInt(r);
}

fn eliminateLine(row: isize) void {
    var r = row;
    while (r > playfieldVisibleStart) : (r -= 1) {
        const r2 = @as(usize, @intCast(r));
        for (0..playfieldCols) |col| {
            gameState.playfield[r2][col] = gameState.playfield[r2 - 1][col];
        }
    }

    for (0..playfieldCols) |col| {
        gameState.playfield[playfieldVisibleStart][col] = .empty;
    }
}

fn checkForFullLine() void {
    var row: isize = playfieldRows - 1;
    blk: while (row > playfieldVisibleStart) : (row -= 1) {
        for (0..playfieldCols) |col| {
            if (gameState.playfield[@as(usize, @intCast(row))][col] == .empty) continue :blk;
        }

        eliminateLine(row);
        row += 1;
        continue;
    }
}

fn place(drop: bool) void {
    const currentTetromino = gameState.currentTetromino();
    const placePos = Pos{
        .x = gameState.anchor.x,
        .y = if (drop) getShadowRow() else gameState.anchor.y,
    };
    var it = currentTetromino.positionsIterator(placePos);

    while (it.next()) |pos| {
        const col: usize = @as(usize, @intCast(pos.x));
        const row: usize = @as(usize, @intCast(pos.y));

        std.debug.assert(gameState.playfield[row][col] == .empty);
        gameState.playfield[row][col] = Cell{ .filled = currentTetromino.color };
    }

    checkForFullLine();

    resetAnchor();
    gameState.currentTetrominoType = getNextAndShift();
    gameState.alreadySwapped = false;
}

fn update(moveDown: bool, gravity: bool) void {
    if (moveDown) {
        const newPos = Pos{
            .x = gameState.anchor.x,
            .y = gameState.anchor.y + 1,
        };

        if (canMove(newPos)) {
            gameState.anchor.y += 1;
        } else {
            if (gravity) {
                if (gameState.lockDelay == 0) {
                    place(false);
                    gameState.lockDelay = 1;
                } else {
                    gameState.lockDelay -= 1;
                }
            } else if (!gameState.horizontallyMoved) {
                place(false);
            }
        }
        gameState.horizontallyMoved = false;
    } else {
        gameState.horizontallyMoved = true;
    }
}

fn canRotate(next: u2) bool {
    const shape = tetrominoShape(gameState.currentTetrominoType, next);
    for (shape) |pos| {
        const x = gameState.anchor.x + pos.x;
        const y = gameState.anchor.y + pos.y;

        if (x < 0 or y > playfieldRows - 1 or x > playfieldCols - 1) return false;
        const col: usize = @as(usize, @intCast(x));
        const row: usize = @as(usize, @intCast(y));

        if (gameState.playfield[row][col] != .empty) return false;
    }

    return true;
}

fn nextRotation(rot: u2) u2 {
    return if (rot < 3)
        rot + 1
    else
        0;
}

fn rotate() void {
    var rot = nextRotation(gameState.rotation);

    while (!canRotate(rot)) {
        rot = nextRotation(rot);
    }

    gameState.rotation = rot;
}

fn resetAnchor() void {
    gameState.anchor.x = 4;
    gameState.anchor.y = playfieldVisibleStart - 1;
    gameState.rotation = 0;
}

fn getNextAndShift() TetrominoType {
    const next = gameState.nextTetrominos[0];
    for (0..gameState.nextTetrominos.len - 1) |i| {
        gameState.nextTetrominos[i] = gameState.nextTetrominos[i + 1];
    }
    gameState.nextTetrominos[gameState.nextTetrominos.len - 1] = getNextType();
    return next;
}

fn hold() void {
    if (gameState.alreadySwapped) return;
    gameState.alreadySwapped = true;
    if (gameState.heldType) |held| {
        const tmp = gameState.currentTetrominoType;
        gameState.currentTetrominoType = held;
        gameState.heldType = tmp;
    } else {
        gameState.heldType = gameState.currentTetrominoType;
        gameState.currentTetrominoType = getNextAndShift();
    }
    resetAnchor();
}

pub fn main() !void {
    gameState.rand = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    for (0..gameState.nextTetrominos.len) |i| {
        gameState.nextTetrominos[i] = getNextType();
    }

    gameState.currentTetrominoType = getNextType();
    resetAnchor();

    rl.initWindow(screenWidth, screenHeight, "stapici");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    const timeBetweenFall: f64 = 0.5;
    const timeBetweenMoveVertical: f64 = 0.1;
    const timeBetweenMoveHorizontal: f64 = 0.1;

    var now = rl.getTime();
    var gravity_last = now;
    var down_last = now;
    var left_last = now;
    var right_last = now;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        now = rl.getTime();

        const gravity_delta = now - gravity_last;
        const down_delta = now - down_last;
        const left_delta = now - left_last;
        const right_delta = now - right_last;

        if (rl.isKeyPressed(rl.KeyboardKey.left_shift)) {
            hold();
        }

        if (rl.isKeyPressed(rl.KeyboardKey.space)) {
            place(true);
        }

        if (rl.isKeyPressed(rl.KeyboardKey.up)) {
            rotate();
        }

        if (gravity_delta >= timeBetweenFall) {
            gravity_last = now;
            update(true, true);
        }

        if (left_delta >= timeBetweenMoveHorizontal and rl.isKeyDown(rl.KeyboardKey.left)) {
            if (gameState.anchor.x > 0 and canMove(Pos{ .x = gameState.anchor.x - 1, .y = gameState.anchor.y })) {
                gameState.anchor.x -= 1;
            }
            left_last = now;
            update(false, false);
        }

        if (right_delta >= timeBetweenMoveHorizontal and rl.isKeyDown(rl.KeyboardKey.right)) {
            if (gameState.anchor.x < playfieldCols - 1 and canMove(Pos{ .x = gameState.anchor.x + 1, .y = gameState.anchor.y })) {
                gameState.anchor.x += 1;
            }
            right_last = now;
            update(false, false);
        }

        if (down_delta >= timeBetweenMoveVertical and rl.isKeyDown(rl.KeyboardKey.down)) {
            gravity_last = now;
            down_last = now;
            update(true, false);
        }

        draw();
    }
}
