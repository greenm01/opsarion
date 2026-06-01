#ifndef OPS_WAYLAND_H
#define OPS_WAYLAND_H

#include <stdbool.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct OpsWaylandDisplay OpsWaylandDisplay;
typedef struct OpsWaylandWindow OpsWaylandWindow;

enum {
  OPS_WAYLAND_MOD_SHIFT = 1u << 0,
  OPS_WAYLAND_MOD_CTRL = 1u << 1,
  OPS_WAYLAND_MOD_ALT = 1u << 2,
  OPS_WAYLAND_MOD_SUPER = 1u << 3,
};

typedef enum {
  OPS_WAYLAND_CURSOR_DEFAULT = 1,
  OPS_WAYLAND_CURSOR_TEXT = 2,
  OPS_WAYLAND_CURSOR_CROSSHAIR = 3,
  OPS_WAYLAND_CURSOR_POINTER = 4,
  OPS_WAYLAND_CURSOR_RESIZE_EW = 5,
  OPS_WAYLAND_CURSOR_RESIZE_NS = 6,
  OPS_WAYLAND_CURSOR_RESIZE_NWSE = 7,
  OPS_WAYLAND_CURSOR_RESIZE_NESW = 8,
  OPS_WAYLAND_CURSOR_RESIZE_ALL = 9,
} OpsWaylandCursorShape;

typedef struct {
  void (*on_close)(void* userdata);
  void (*on_focus)(bool focused, void* userdata);
  void (*on_resize)(uint32_t w, uint32_t h, void* userdata);
  void (*on_key_down)(uint32_t keycode, uint32_t mods, void* userdata);
  void (*on_key_repeat)(uint32_t keycode, uint32_t mods, void* userdata);
  void (*on_key_up)(uint32_t keycode, uint32_t mods, void* userdata);
  void (*on_char)(uint32_t codepoint, void* userdata);
  void (*on_mouse_move)(double x, double y, void* userdata);
  void (*on_mouse_button)(uint32_t btn, bool pressed, void* userdata);
  void (*on_scroll)(double dx, double dy, void* userdata);
  void (*on_scale)(double scale, void* userdata);
  void* userdata;
} OpsWaylandCallbacks;

OpsWaylandDisplay* ops_wayland_init(void);
OpsWaylandWindow* ops_wayland_create_window(
    OpsWaylandDisplay* display, uint32_t w, uint32_t h, const char* title);
void ops_wayland_set_callbacks(
    OpsWaylandWindow* window, const OpsWaylandCallbacks* callbacks);
void ops_wayland_poll_events(OpsWaylandDisplay* display);
void ops_wayland_roundtrip(OpsWaylandDisplay* display);
void* ops_wayland_get_wl_display(OpsWaylandDisplay* display);
void* ops_wayland_get_wl_surface(OpsWaylandWindow* window);
uint32_t ops_wayland_get_width(OpsWaylandWindow* window);
uint32_t ops_wayland_get_height(OpsWaylandWindow* window);
bool ops_wayland_window_should_close(OpsWaylandWindow* window);
bool ops_wayland_window_configured(OpsWaylandWindow* window);
void ops_wayland_set_title(OpsWaylandWindow* window, const char* title);
void ops_wayland_set_app_id(OpsWaylandWindow* window, const char* app_id);
void ops_wayland_set_size(OpsWaylandWindow* window, uint32_t w, uint32_t h);
void ops_wayland_set_size_limits(
    OpsWaylandWindow* window, uint32_t min_w, uint32_t min_h, uint32_t max_w,
    uint32_t max_h);
void ops_wayland_set_cursor_shape(
    OpsWaylandWindow* window, OpsWaylandCursorShape shape);
void ops_wayland_destroy_window(OpsWaylandWindow* window);
void ops_wayland_destroy(OpsWaylandDisplay* display);

#ifdef __cplusplus
}
#endif

#endif
