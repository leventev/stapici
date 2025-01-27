const rl = @import("raylib");

const cellSize = 48;
const borderThickness = 20;
const playfieldRows = 20;
const playfieldCols = 10;
const previewCells = 4;

const playfieldX = borderThickness;
const playfieldY = borderThickness;

const previewX = playfieldX + playfieldCols * cellSize + 20;
const previewY = playfieldY;

const screenWidth = 3 * borderThickness + (playfieldCols + previewCells) * cellSize;
const screenHeight = playfieldRows * cellSize + 2 * borderThickness;

const gridColor = rl.Color.init(100, 100, 100, 200);

fn drawGrid(startX: usize, startY: usize, cols: usize, rows: usize) void {
    const width: i32 = @intCast(cols * cellSize);
    const height: i32 = @intCast(rows * cellSize);

    for (0..rows + 1) |row| {
        const x: i32 = @intCast(startX);
        const y: i32 = @intCast(startY + row * cellSize);
        rl.drawLine(x, y, x + width, y, gridColor);
    }

    for (0..cols + 1) |col| {
        const x: i32 = @intCast(startX + col * cellSize);
        const y: i32 = @intCast(startY);
        rl.drawLine(x, y, x, y + height, gridColor);
    }
}

fn draw() void {
    rl.clearBackground(rl.Color.black);
    drawGrid(playfieldX, playfieldY, playfieldCols, playfieldRows);
    drawGrid(previewX, previewY, previewCells, previewCells);
}

pub fn main() !void {
    rl.initWindow(screenWidth, screenHeight, "stapici");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        draw();
    }
}
