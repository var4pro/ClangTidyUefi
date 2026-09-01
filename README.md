# Clang-Tidy UEFI Static Analysis Plugin

Custom Clang-Tidy module for enforcing UEFI/EDK2 safety rules.

## Included Checks
- `uefi-unchecked-status`: Enforces proper handling of all `EFI_STATUS` returns by warning about not using return status. (supports GNU blocks, function pointers, and casts).
- `uefi-banned-allocator`: Blocks standard UEFI allocators (`AllocatePool`, `AllocatePages`, `FreePool`, `FreePages`) in favor of custom project allocators.
- `uefi-trace-function`: Enforces `TRACE_FUNCTION();` as the first statement in every function for selected files(use uefi-trace-function.TargetFiles).

## Build & Test(Linux)
```bash
make generate-flags WORKSPACE_DIR_V=/home/var4p/Documents/uefi_workspace/edk2/..  # generate flags for test cases
make build       # Compile libUefiTidyModule.so
make test        # Run the test suite against expected outputs
```

## Development workflow(Linux)
```bash
make generate-flags WORKSPACE_DIR_V=/home/var4p/Documents/uefi_workspace/edk2/..  # generate flags for test cases
make build            # Compile libUefiTidyModule.so
make clean            # Cleans build directory
make tidy             # runs tidy on plugin's code
make format-do        # formats plugin's code
make update-expected  # update *tidy_report* files for tests
make test             # Run the test suite against expected outputs
make format-check-all # run build, and format, and tidy, and tests
```