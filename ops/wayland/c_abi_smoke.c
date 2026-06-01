#include "ops_wayland.h"

static void on_close(void* userdata) {
  (void)userdata;
}

static void on_focus(bool focused, void* userdata) {
  (void)focused;
  (void)userdata;
}

static void on_key_repeat(uint32_t keycode, uint32_t mods, void* userdata) {
  (void)keycode;
  (void)mods;
  (void)userdata;
}

int main(void) {
  if ((OPS_WAYLAND_MOD_SHIFT | OPS_WAYLAND_MOD_CTRL |
       OPS_WAYLAND_MOD_ALT | OPS_WAYLAND_MOD_SUPER) != 15u) {
    return 1;
  }
  if (OPS_WAYLAND_CURSOR_DEFAULT == OPS_WAYLAND_CURSOR_TEXT) {
    return 1;
  }

  OpsWaylandCallbacks callbacks = {0};
  callbacks.on_close = on_close;
  callbacks.on_focus = on_focus;
  callbacks.on_key_repeat = on_key_repeat;
  ops_wayland_set_callbacks(0, &callbacks);

  OpsWaylandDisplay* display = ops_wayland_init();
  if (display == 0) {
    return 0;
  }

  ops_wayland_poll_events(display);
  ops_wayland_roundtrip(display);
  (void)ops_wayland_get_wl_display(display);

  OpsWaylandWindow* window =
      ops_wayland_create_window(display, 320, 240, "Ops Wayland ABI Smoke");
  if (window != 0) {
    ops_wayland_set_callbacks(window, &callbacks);
    ops_wayland_set_title(window, "Ops Wayland ABI Smoke");
    ops_wayland_set_size(window, 320, 240);
    ops_wayland_set_cursor_shape(window, OPS_WAYLAND_CURSOR_DEFAULT);
    (void)ops_wayland_window_should_close(window);
    (void)ops_wayland_get_wl_surface(window);
    if (ops_wayland_get_width(window) == 0 ||
        ops_wayland_get_height(window) == 0) {
      ops_wayland_destroy_window(window);
      ops_wayland_destroy(display);
      return 1;
    }
    ops_wayland_destroy_window(window);
  }

  ops_wayland_destroy(display);
  return 0;
}
