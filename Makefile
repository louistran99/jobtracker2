# Developer entry points. Run `make help` for a summary.

XCODEGEN_VERSION := 2.46.0
XCODEGEN_SHA256  := 4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806
XCODEGEN_DIR     := .tools/xcodegen-$(XCODEGEN_VERSION)
XCODEGEN         := $(XCODEGEN_DIR)/bin/xcodegen

PROJECT     := JobTracker.xcodeproj
SCHEME      := JobTracker
DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro
SWIFT_PATHS := App UITests Packages/JobTrackerKit/Package.swift Packages/JobTrackerKit/Sources Packages/JobTrackerKit/Tests
XCODEBUILD  := set -o pipefail && xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' -quiet
RESULTS     := build/TestResults

# Runs xcodebuild test into a fresh result bundle, then prints its summary.
# Usage: $(call run_tests,<bundle name>,<extra xcodebuild flags>)
define run_tests
	@rm -rf $(RESULTS)/$(1).xcresult
	$(XCODEBUILD) test -resultBundlePath $(RESULTS)/$(1).xcresult $(2) ; status=$$? ; \
	xcrun xcresulttool get test-results summary --path $(RESULTS)/$(1).xcresult --compact \
		| python3 scripts/print-test-summary.py ; \
	exit $$status
endef

.PHONY: help bootstrap generate open format lint build test ui-test check clean

help:
	@echo "bootstrap  Install pinned tools into .tools/"
	@echo "generate   Generate $(PROJECT) from project.yml"
	@echo "open       Generate and open the project in Xcode"
	@echo "format     Format all Swift sources in place"
	@echo "lint       Check formatting and lint rules (fails on any finding)"
	@echo "build      Build the app for the simulator"
	@echo "test       Run unit tests"
	@echo "ui-test    Run UI tests"
	@echo "check      lint + test + ui-test (what CI runs)"
	@echo ""
	@echo "TEST_FLAGS passes extra xcodebuild flags, e.g. to hunt for flaky tests:"
	@echo "  make test TEST_FLAGS='-test-iterations 10 -run-tests-until-failure'"

bootstrap: $(XCODEGEN)

$(XCODEGEN):
	@scripts/install-xcodegen.sh $(XCODEGEN_VERSION) $(XCODEGEN_SHA256) $(XCODEGEN_DIR)

generate: bootstrap
	@$(XCODEGEN) generate --quiet

open: generate
	open $(PROJECT)

format:
	xcrun swift-format format --in-place --recursive --parallel $(SWIFT_PATHS)

lint:
	xcrun swift-format lint --strict --recursive --parallel $(SWIFT_PATHS)

build: generate
	$(XCODEBUILD) build

test: generate
	$(call run_tests,unit,-skip-testing:JobTrackerUITests $(TEST_FLAGS))

ui-test: generate
	$(call run_tests,ui,-only-testing:JobTrackerUITests $(TEST_FLAGS))

check: lint test ui-test

clean:
	rm -rf $(PROJECT) .tools build
