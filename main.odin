package main
import "core:fmt"
import "vendor:raylib"
import "core:math"

should_close := false
canvas : raylib.RenderTexture2D
window : raylib.RenderTexture2D

canvas_width, canvas_height : i32 = 800, 600
window_width, window_height : i32 = canvas_width * 2, canvas_height * 2

canvas_rect := raylib.Rectangle{0, 0, cast(f32)canvas_width, -cast(f32)canvas_height}
window_rect := raylib.Rectangle{0, 0, cast(f32)window_width,  cast(f32)window_height}

faded_white := raylib.Color{255, 255, 255, 85}

test_box := BoundingBox{raylib.Vector2{400, 300}, raylib.Vector2{25, 25}}
cursor_box := BoundingBox{raylib.Vector2{0, 0}, raylib.Vector2{25, 25}}
sum_box := BoundingBox{test_box.position, test_box.half_extents + cursor_box.half_extents}
placed_box := BoundingBox{raylib.Vector2{0, 0}, raylib.Vector2{25, 25}}

BoundingBox :: struct {
    position, half_extents : raylib.Vector2,
}

Hit :: struct {
    is_hit : bool,
    time : f32,
    position : raylib.Vector2,
}

ray_intersect_bounds :: proc(position : raylib.Vector2, magnitude : raylib.Vector2, bounds : BoundingBox) -> Hit {
    hit := Hit{}
    min := bounds.position - bounds.half_extents
    max := bounds.position + bounds.half_extents

    last_entry : f32 = -math.F32_MAX
    first_exit : f32 = math.F32_MAX

    for dimension := 0; dimension < 2; dimension += 1 {
        if (magnitude[dimension] != 0) {
            t0 := (min[dimension] - position[dimension]) / magnitude[dimension]
            t1 := (max[dimension] - position[dimension]) / magnitude[dimension]

            last_entry = math.max(last_entry, math.min(t0, t1)) 
            first_exit = math.min(first_exit, math.max(t0, t1))
        } else if (position[dimension] < min[dimension] || position[dimension] > max[dimension]) {
            return hit
        }
    }

    if (last_entry < first_exit && last_entry >= 0 && last_entry <= 1) {
        hit.is_hit = true
        hit.time = last_entry
        hit.position = position + magnitude * last_entry
    }

    return hit
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

ensure_aspect_ratio :: proc(width, height : ^i32, target_width, target_height : i32) {
    target_aspect_ratio := cast(f32)target_width / cast(f32)target_height
    new_height := cast(f32)width^ / target_aspect_ratio
    height^ = cast(i32)new_height
}



window_to_canvas_position :: proc(window_position : raylib.Vector2) -> raylib.Vector2 {
    return raylib.Vector2{
        window_position.x / cast(f32)window_width * cast(f32)canvas_width,
        window_position.y / cast(f32)window_height * cast(f32)canvas_height,
    }
}

get_canvas_mouse_position :: proc() -> raylib.Vector2 {
    return window_to_canvas_position(raylib.GetMousePosition())
}

main :: proc() {
    raylib.SetConfigFlags({.WINDOW_RESIZABLE})
    raylib.InitWindow(window_width, window_height, "Swept AABB Collision")
    defer raylib.CloseWindow()

    raylib.SetTargetFPS(60)

    canvas = raylib.LoadRenderTexture(canvas_width, canvas_height)
    defer raylib.UnloadRenderTexture(canvas)

    window = raylib.LoadRenderTexture(window_width, window_height)
    defer raylib.UnloadRenderTexture(window)

    for (!should_close && !raylib.WindowShouldClose()) {
        defer free_all(context.temp_allocator)

        if (raylib.IsWindowResized()) {
            width := raylib.GetScreenWidth()
            height := raylib.GetScreenHeight()
            ensure_aspect_ratio(&width, &height, 800, 600)
            raylib.SetWindowSize(width, height)
            window_rect.width = cast(f32)width
            window_rect.height = cast(f32)height
        }

        mouse_position := get_canvas_mouse_position()
        cursor_box.position = mouse_position

        x := sum_box.position.x - test_box.position.x
        y := sum_box.position.y - test_box.position.y
        size := sum_box.half_extents.x

        canvas_center := raylib.Vector2{cast(f32)canvas_width / 2, cast(f32)canvas_height / 2}

        raylib.BeginTextureMode(canvas)
            raylib.ClearBackground(raylib.BLACK)
            draw_bounds(test_box, raylib.WHITE)
            draw_bounds(cursor_box, faded_white)
            draw_bounds(placed_box, faded_white)

            raylib.DrawLineV(placed_box.position, cursor_box.position, faded_white)

            raylib.DrawLineV(raylib.Vector2{canvas_center.x + x - size, 0}, raylib.Vector2{canvas_center.x + x - size, 600}, faded_white)
            raylib.DrawLineV(raylib.Vector2{canvas_center.x + x + size, 0}, raylib.Vector2{canvas_center.x + x + size, 600}, faded_white)
            raylib.DrawLineV(raylib.Vector2{0, canvas_center.y + y - size}, raylib.Vector2{800, canvas_center.y + y - size}, faded_white)
            raylib.DrawLineV(raylib.Vector2{0, canvas_center.y + y + size}, raylib.Vector2{800, canvas_center.y + y + size}, faded_white)

            magnitude := mouse_position - placed_box.position
            hit := ray_intersect_bounds(placed_box.position, magnitude, sum_box)
            
            if (hit.is_hit) {
                swept_box := BoundingBox{hit.position, placed_box.half_extents}
                draw_bounds(swept_box, raylib.RED)
            }

            if (raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT)) {
                placed_box.position = mouse_position
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
