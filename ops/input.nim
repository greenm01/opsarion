include input/state
include input/key_state
include input/text_edit
include input/shortcuts
include input/event_queue
include input/platform_runtime
when defined(opsGlfwAdapter) and not defined(waylandBackend):
  include input/glfw_hooks
