# Reference Tests

This directory contains small reference regression tests for proof obligation classification.

Each reference test should live directly in a category directory as a pair of files with the same base name:

```text
examples/reference-tests/
  <category>/
    <test-name>.c
    <test-name>.json
```

The intent is to keep these tests:

- small and focused on a single classification edge case,
- easy to compare across analyzers,
- organized by dashboard-facing category rather than by tool-specific wording.

## File Convention

- `<test-name>.c`: the C program for the reference test.
- `<test-name>.json`: the expected checks output for the test.

The JSON file is intended to store expected checks in a structured form that
can later be consumed by tooling.

## Categories

The current category split is intentionally flat:

- `overflow-arithmetic`
- `memsafety`

This can be refined later if the suite grows enough to justify separate
categories for signedness or cast-related overflows.
