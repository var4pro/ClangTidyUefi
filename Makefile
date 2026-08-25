SHELL := /bin/bash

BUILD_DIR_V   := build
SRC_DIR_V     := src
TESTS_DIR_V   := tests
PLUGIN_SO_V   := $(BUILD_DIR_V)/libUefiTidyModule.so
SRC_FILES_V := $(shell find src -type f -name "*.cpp" 2>/dev/null)

TIDY_RUN_V    := clang-tidy --quiet --load=$(PLUGIN_SO_V)

.PHONY: all build clean tidy format-do test format-check-all hook-check update-expected

all: build

#default
build:
	@echo "Building Clang Plugin..."
	@cmake -S . -B build
	@cmake --build build
	
clean:
	rm -rf build

#tidy
tidy:
	clang-tidy src/*.cpp -p build/

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

test-banned: build
	@echo "Running Banned Allocators Test..."
	@$(TIDY_RUN_V) --checks='-*,uefi-banned-allocator' $(TESTS_DIR_V)/cases/TestBanned.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' \
		| diff -u $(TESTS_DIR_V)/test_banned_tidy_report_expected.txt -
	@echo "  └─ Banned Allocators Test PASSED"

test-trace: build
	@echo "Running Trace Function Test..."
	@$(TIDY_RUN_V) --checks='-*,uefi-trace-function' $(TESTS_DIR_V)/cases/TestTrace.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' \
		| diff -u $(TESTS_DIR_V)/test_trace_tidy_report_expected.txt -
	@echo "  └─ Trace Function Test PASSED"

test-unchecked: build
	@echo "Running Unchecked Status Test..."
	@$(TIDY_RUN_V) --checks='-*,uefi-unchecked-status' $(TESTS_DIR_V)/cases/TestUnchecked.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' \
		| diff -u $(TESTS_DIR_V)/test_unchecked_tidy_report_expected.txt -
	@echo "  └─ Unchecked Status Test PASSED"

# Run all tests sequentially
test: test-banned test-trace test-unchecked
	@echo "\n🎉 ALL UEFI STATIC ANALYSIS TESTS PASSED SUCCESSFULLY! 🎉\n"

update-expected: build
	@echo "🔄 Regenerating expected test report baselines..."
	@$(TIDY_RUN_V) --checks='-*,uefi-banned-allocator' $(TESTS_DIR_V)/cases/TestBanned.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' > $(TESTS_DIR_V)/test_banned_tidy_report_expected.txt
	@$(TIDY_RUN_V) --checks='-*,uefi-trace-function' $(TESTS_DIR_V)/cases/TestTrace.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' > $(TESTS_DIR_V)/test_trace_tidy_report_expected.txt
	@$(TIDY_RUN_V) --checks='-*,uefi-unchecked-status' $(TESTS_DIR_V)/cases/TestUnchecked.c 2>&1 \
		| sed 's|.*tests/cases/|tests/cases/|g' > $(TESTS_DIR_V)/test_unchecked_tidy_report_expected.txt
	@echo "✅ Expected reports updated successfully!"

#manually invoke this
format-check-all: format-do hook-check

#auto invoking
hook-check: build tidy test