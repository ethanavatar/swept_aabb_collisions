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

test_box := BoundingBox{raylib.Vector2{400, 300}, raylib.Vector2{25, 25}}
cursor_box := BoundingBox{raylib.Vector2{0, 0}, raylib.Vector2{25, 25}}
sum_box := BoundingBox{test_box.position, test_box.half_extents + cursor_box.half_extents}
placed_box := BoundingBox{raylib.Vector2{0, 0}, raylib.Vector2{25, 25}}

BoundingBox :: struct {
    position, half_extents : raylib.Vector2
}

draw_bounds :: proc(aabb : BoundingBox, color : raylib.Color) {
    raylib.DrawCircleV(aabb.position, 2, color)
    raylib.DrawRectangleLines(
        cast(i32)(aabb.position.x - aabb.half_extents.x),
        cast(i32)(aabb.position.y - aabb.half_extents.y),
        cast(i32)(aabb.half_extents.x * 2),
        cast(i32)(aabb.half_extents.y * 2),
        color,
    )
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

        cursor_box.position = raylib.GetMousePosition()

        x := sum_box.position.x - test_box.position.x
        y := sum_box.position.y - test_box.position.y
        size := sum_box.half_extents.x

        if (raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT)) {
            placed_box.position = cursor_box.position
        }

        canvas_center := raylib.Vector2{cast(f32)canvas_width / 2, cast(f32)canvas_height / 2}
        mouse_position := raylib.GetMousePosition()

        raylib.BeginTextureMode(canvas)
            raylib.ClearBackground(raylib.BLACK)
            draw_bounds(test_box, raylib.WHITE)
            draw_bounds(cursor_box, faded_white)
            draw_bounds(placed_box, faded_white)

            raylib.DrawLineV(raylib.Vector2{canvas_center.x + x - size, 0}, raylib.Vector2{canvas_center.x + x - size, 600}, faded_white)
            raylib.DrawLineV(raylib.Vector2{canvas_center.x + x + size, 0}, raylib.Vector2{canvas_center.x + x + size, 600}, faded_white)
            raylib.DrawLineV(raylib.Vector2{0, canvas_center.y + y - size}, raylib.Vector2{800, canvas_center.y + y - size}, faded_white)
            raylib.DrawLineV(raylib.Vector2{0, canvas_center.y + y + size}, raylib.Vector2{800, canvas_center.y + y + size}, faded_white)

            min := sum_box.position - sum_box.half_extents
            max := sum_box.position + sum_box.half_extents

            magnitude := mouse_position - placed_box.position
            
            for dimension := 0; dimension < 2; dimension += 1 {
                if (magnitude[dimension] != 0) {
                    t0 := (min[dimension] - placed_box.position[dimension]) / magnitude[dimension]
                    t1 := (max[dimension] - placed_box.position[dimension]) / magnitude[dimension]

                    if (t0 > t1) {
                        t0, t1 = t1, t0
                    }

                    if (t0 <= 1 && t0 >= 0) {
                        raylib.DrawCircleV(placed_box.position + magnitude * t0, 2, raylib.GREEN)
                    }

                    if (t1 >= 0 && t1 <= 1) {
                        raylib.DrawCircleV(placed_box.position + magnitude * t1, 2, raylib.GREEN)
                    }
                }
            }
            
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
