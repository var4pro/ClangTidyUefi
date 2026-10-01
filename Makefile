SHELL := /bin/bash

.NOTPARALLEL:
.DELETE_ON_ERROR:

SRC_FILES_V := $(shell find src -type f -name "*.cpp" 2>/dev/null)
PLUGIN_SO   := build/libUefiTidyModule.so
TIDY_RUN_V    := clang-tidy --quiet --load=$(PLUGIN_SO) --config='{CheckOptions: {uefi-trace-function.TargetFiles: ""}}'

.PHONY: all build clean tidy format-do test format-check-all hook-check \
        update-expected generate-flags test-banned test-trace test-unchecked init

all: build

#build
build: $(PLUGIN_SO)

$(PLUGIN_SO): $(SRC_FILES_V) CMakeLists.txt
	@echo "Building Clang Plugin..."
	@cmake -S . -B build
	@cmake --build build
	
#clean
clean:
	rm -rf build
	rm -f tests/cases/compile_flags.txt

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

define tidy_report
$(TIDY_RUN_V) --checks='-*,$(1)' tests/cases/$(2) 2>&1 | sed 's|.*tests/cases/|tests/cases/|g'
endef


test-banned: $(PLUGIN_SO) tests/cases/compile_flags.txt
	@echo "Running Banned Allocators Test..."
	@$(call tidy_report,uefi-banned-allocator,TestBanned.c) \
		| diff -u tests/test_banned_tidy_report_expected.txt -
	@echo "  └─ Banned Allocators Test PASSED"


test-trace: $(PLUGIN_SO) tests/cases/compile_flags.txt
	@echo "Running Trace Function Test..."
	@$(call tidy_report,uefi-trace-function,TestTrace.c) \
		| diff -u tests/test_trace_tidy_report_expected.txt -
	@echo "  └─ Trace Function Test PASSED"

test-unchecked: $(PLUGIN_SO) tests/cases/compile_flags.txt
	@echo "Running Unchecked Status Test..."
	@$(call tidy_report,uefi-unchecked-status,TestUnchecked.c) \
		| diff -u tests/test_unchecked_tidy_report_expected.txt -
	@echo "  └─ Unchecked Status Test PASSED"

test: test-banned test-trace test-unchecked # Run all tests sequentially
	@printf "\n🎉 ALL UEFI STATIC ANALYSIS TESTS PASSED SUCCESSFULLY! 🎉\n"

update-expected: $(PLUGIN_SO) tests/cases/compile_flags.txt
	@echo "Regenerating expected test report baselines..."
	@$(call tidy_report,uefi-banned-allocator,TestBanned.c)    > tests/test_banned_tidy_report_expected.txt
	@$(call tidy_report,uefi-trace-function,TestTrace.c)       > tests/test_trace_tidy_report_expected.txt
	@$(call tidy_report,uefi-unchecked-status,TestUnchecked.c) > tests/test_unchecked_tidy_report_expected.txt
	@echo "Expected reports updated successfully!"

#flags
WORKSPACE_DIR_V ?= 
ifneq ($(strip $(WORKSPACE_DIR_V)),)
override WORKSPACE_DIR_V := $(abspath $(WORKSPACE_DIR_V))
endif
export EDK2_PATH_V := $(WORKSPACE_DIR_V)/edk2

generate-flags: 
	@rm -f tests/cases/compile_flags.txt
	@$(MAKE) tests/cases/compile_flags.txt
	
tests/cases/compile_flags.txt: tests/cases/compile_flags.txt.in
	@if [ -z "$(strip $(WORKSPACE_DIR_V))" ]; then \
		echo "[ERROR] WORKSPACE_DIR_V is not set! Please set it before running."; \
		exit 1; \
	fi
	@echo "Generating tests/cases/compile_flags.txt..."
	@envsubst '$$EDK2_PATH_V' < $< > $@


#Testing everything
format-check-all: format-do hook-check #manually invoke this
hook-check: build tidy test #auto invoking





#tools
print-%:
	@echo '$* = $($*)'

init: generate-flags
	git config core.hooksPath .githooks