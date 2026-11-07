"""Prints a one-line summary (and any failures) from `xcresulttool get test-results summary` JSON on stdin."""

import json
import sys

summary = json.load(sys.stdin)
print(
    f"{summary.get('result', 'Unknown')}: "
    f"{summary.get('passedTests', 0)} passed, "
    f"{summary.get('failedTests', 0)} failed, "
    f"{summary.get('skippedTests', 0)} skipped "
    f"(of {summary.get('totalTestCount', 0)})"
)
for failure in summary.get("testFailures", []):
    print(f"  FAILED {failure.get('testIdentifierString')}: {failure.get('failureText')}")
