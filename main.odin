package main
import "core:fmt"
import "vendor:raylib"

should_close := false
canvas : raylib.RenderTexture2D
window : raylib.RenderTexture2D

canvas_width, canvas_height := 800, 600
window_width, window_height := 800, 600

canvas_rect := raylib.Rectangle{0, 0, cast(f32)canvas_width, -cast(f32)canvas_height}
window_rect := raylib.Rectangle{0, 0, cast(f32)window_width,  cast(f32)window_height}

faded_white := raylib.Color{255, 255, 255, 85}

draw_canvas :: proc() {
    raylib.ClearBackground(raylib.RAYWHITE)

    text : cstring = "Hello, Sailor!"
    text_width := raylib.MeasureText(text, 20)
    raylib.DrawText(text, 400 - text_width / 2, 200, 20, raylib.GRAY)
}

main :: proc() {
    raylib.InitWindow(800, 600, "Swept AABB Collision")
    defer raylib.CloseWindow()

    raylib.SetTargetFPS(60)

    canvas = raylib.LoadRenderTexture(800, 600)
    defer raylib.UnloadRenderTexture(canvas)

    window = raylib.LoadRenderTexture(800, 600)
    defer raylib.UnloadRenderTexture(window)

    for (!should_close && !raylib.WindowShouldClose()) {
        defer free_all(context.temp_allocator)

        raylib.BeginTextureMode(canvas)
        draw_canvas()
        raylib.EndTextureMode()

        raylib.BeginDrawing()
        raylib.ClearBackground(raylib.RAYWHITE)
        raylib.DrawTexturePro(
            canvas.texture,
            canvas_rect, window_rect,
            raylib.Vector2{0, 0}, 0,
            raylib.WHITE,
        )
        raylib.EndDrawing()
    }

    free_all(context.allocator)
}
