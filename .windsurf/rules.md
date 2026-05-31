## engram-lite workspace binding

At the start of every session, call mem_use_workspace with the current workspace
path before invoking any other engram tool.

Example:
  mem_use_workspace(workspace_path: "/path/to/your/project")

This scopes all memory operations to the correct workspace.
