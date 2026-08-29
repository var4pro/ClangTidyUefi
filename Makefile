SHELL := /bin/bash

SRC_FILES_V := $(shell find src -type f -name "*.cpp" 2>/dev/null)
PLUGIN_SO   := build/libUefiTidyModule.so
TIDY_RUN_V    := clang-tidy --quiet --load=$(PLUGIN_SO) --config='{CheckOptions: {uefi-trace-function.TargetFiles: ""}}'

.PHONY: all build clean tidy format-do test format-check-all hook-check \
        update-expected generate-flags test-banned test-trace test-unchecked

all: build

#default
build: $(PLUGIN_SO)

$(PLUGIN_SO):
	@echo "Building Clang Plugin..."
	@cmake -S . -B build
	@cmake --build build
	
clean:
	rm -rf build

#tidy
tidy:
	clang-tidy $(SRC_FILES_V) -p build/

#format
format-do:
	@echo "Formatting .cpp plugin's code with clang-format..."
	@if [ -n "$(SRC_FILES_V)" ]; then \
		clang-format -i $(SRC_FILES_V); \
		echo "Formatting done!"; \
	else \
		echo "No source files found to format."; \
	fi

# ==============================================================================
# TEST SUITE
# ==============================================================================

test-banned: $(PLUGIN_SO) tests/cases/compile_flags.txt
	@echo "Running Banned Allocators Test..."
	@$(TIDY_RUN_V) --checks='-*,uefi-banned-allocator' tests/cases/TestBanned.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' \
		| diff -u tests/test_banned_tidy_report_expected.txt -
	@echo "  └─ Banned Allocators Test PASSED"

test-trace: $(PLUGIN_SO) tests/cases/compile_flags.txt
	@echo "Running Trace Function Test..."
	@$(TIDY_RUN_V) --checks='-*,uefi-trace-function' tests/cases/TestTrace.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' \
		| diff -u tests/test_trace_tidy_report_expected.txt -
	@echo "  └─ Trace Function Test PASSED"

test-unchecked: $(PLUGIN_SO) tests/cases/compile_flags.txt
	@echo "Running Unchecked Status Test..."
	@$(TIDY_RUN_V) --checks='-*,uefi-unchecked-status' tests/cases/TestUnchecked.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' \
		| diff -u tests/test_unchecked_tidy_report_expected.txt -
	@echo "  └─ Unchecked Status Test PASSED"

# Run all tests sequentially
test: test-banned test-trace test-unchecked
	@echo "\n🎉 ALL UEFI STATIC ANALYSIS TESTS PASSED SUCCESSFULLY! 🎉\n"

update-expected: $(PLUGIN_SO) tests/cases/compile_flags.txt
	@echo "Regenerating expected test report baselines..."
	@$(TIDY_RUN_V) --checks='-*,uefi-banned-allocator' tests/cases/TestBanned.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' > tests/test_banned_tidy_report_expected.txt
	@$(TIDY_RUN_V) --checks='-*,uefi-trace-function' tests/cases/TestTrace.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' > tests/test_trace_tidy_report_expected.txt
	@$(TIDY_RUN_V) --checks='-*,uefi-unchecked-status' tests/cases/TestUnchecked.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' > tests/test_unchecked_tidy_report_expected.txt
	@echo "Expected reports updated successfully!"

#flags
WORKSPACE_DIR_V ?= 
export EDK2_PATH_V := $(WORKSPACE_DIR_V)/edk2

generate-flags: tests/cases/compile_flags.txt
tests/cases/compile_flags.txt: tests/cases/compile_flags.txt.in
	@if [ -z "$(strip $(WORKSPACE_DIR_V))" ]; then \
		echo "[ERROR] WORKSPACE_DIR_V is not set! Please set it before running."; \
		exit 1; \
	fi
	@echo "Generating tests/cases/compile_flags.txt..."
	@envsubst < $< > $@

#manually invoke this
format-check-all: format-do hook-check

#auto invoking
hook-check: build tidy test