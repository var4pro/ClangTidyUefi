# Clang-Tidy UEFI Static Analysis Plugin

Custom Clang-Tidy module for enforcing UEFI/EDK2 safety rules.

## Included Checks
- `uefi-unchecked-status`: Enforces proper handling of all `EFI_STATUS` returns (supports GNU blocks, function pointers, and casts).
- `uefi-banned-allocator`: Blocks standard UEFI allocators (`AllocatePool`, `AllocatePages`, `FreePool`, `FreePages`) in favor of custom project allocators.
- `uefi-trace-function`: Enforces `TRACE_FUNCTION();` as the first statement in every function.

## Build & Test
```bash
make build       # Compile libUefiTidyModule.so
make test        # Run the test suite against expected outputs
make hook-check  # Full verification (build + self-tidy + unit tests)