---
name: simplify
description: Simplify recently modified code for clarity, consistency, and maintainability without changing its behavior. Use after writing or modifying code when a cleanup pass is useful.
disable-model-invocation: true
---

# Simplify

Review recently modified code and make it clearer, simpler, and easier to maintain without changing its behavior.

Preserve all existing functionality, outputs, side effects, error handling, evaluation order, and resource lifetimes.

Only review and modify code that is part of the current task. Do not expand the scope into unrelated cleanup or refactoring.

## Workflow

1. Inspect the current working tree and identify the changes relevant to the task.
2. Read the modified code and enough surrounding code to understand its context and existing conventions.
3. Look for:
   - unnecessary complexity or nesting
   - duplicated logic
   - unclear names
   - redundant state or computation
   - unnecessary abstractions
   - inconsistent patterns
   - comments that only restate obvious code
   - avoidable allocations, I/O, or repeated work when the improvement is clear and behavior-preserving
4. Check whether existing project utilities, helpers, or patterns can simplify the changed code.
5. Apply only changes that provide a clear improvement.
6. Review the final diff to ensure the changes remain within scope and preserve behavior.
7. Run the most relevant project checks.

## Principles

- Readability matters more than reducing line count.
- Prefer explicit code over clever or overly compact solutions.
- Prefer existing project patterns over introducing new abstractions.
- Keep useful abstractions and boundaries.
- Avoid nested ternaries when normal conditionals are clearer.
- Do not refactor merely because something could be written differently.
- Do not optimize speculatively.
- Do not modify unrelated code.
- Do not change behavior just to make the implementation look cleaner.
- Do not remove validation, error handling, security checks, accessibility behavior, or tests.
- Do not add comments unless they explain genuinely non-obvious behavior.

## Additional Focus

If the user provides additional instructions after `/simplify`, treat them as additional review criteria while still following the core requirements above.

Examples:

/simplify

/simplify focus on performance and memory usage

/simplify pay extra attention to React re-renders

## Completion

If worthwhile refinements exist, apply them and verify the result.

If the code is already clear and no meaningful refinement is justified, leave it unchanged and say so.

Report the relevant refinements and validation performed. Keep the response concise.
