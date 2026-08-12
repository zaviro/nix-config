# Revsets and Filesets

Use Change IDs for stable ownership. Use commit IDs only when an exact immutable
version of a rewritten change matters.

## Common revision symbols

| Expression | Meaning |
| --- | --- |
| `@` | Current workspace's working-copy commit |
| `<workspace>@` | Another workspace's working-copy commit |
| `@-` | Parent or parents of `@` |
| `main` | Local `main` bookmark |
| `main@origin` | Last fetched remote `main` |
| `<change-id>` | Visible revision with a stable Change ID |

Quote revsets in the shell.

## Operators

| Expression | Meaning |
| --- | --- |
| `::x` | Ancestors of `x`, inclusive |
| `x::` | Descendants of `x`, inclusive |
| `x::y` | DAG paths from `x` through `y` |
| `x..y` | Ancestors of `y` that are not ancestors of `x` |
| `x & y` | Intersection |
| `x | y` | Union |
| `x ~ y` | Set subtraction |
| `heads(x)` | Heads of the selected set |
| `roots(x)` | Roots of the selected set |

`x::y` and `x..y` are not interchangeable. Print the selection with
`jj log -r '<expression>'` before using it in a mutation.

## Useful selectors

- `conflicts()`: revisions with unresolved file conflicts.
- `divergent()`: visible divergent Change IDs.
- `empty()`: revisions whose tree matches their parents.
- `bookmarks()`: local bookmark targets.
- `remote_bookmarks(exact:main, exact:origin)`: a precise remote bookmark.
- `files("path")`: revisions changing a fileset.
- `description(exact:"subject")`: exact description match.
- `present(x)`: `x` if it exists, otherwise an empty set.

Do not use `mine()` as a substitute for task ownership: multiple agents may
share the same configured author identity.

## Repository recipes

```bash
# Local stack through a candidate
jj log -r 'main..candidate' --reversed

# Scoped conflicts in a candidate publication range
jj log -r 'conflicts() & (main@origin..candidate)'

# Candidate and all descendants that a rewrite may affect
jj log -r 'candidate::'

# Every workspace's working-copy commit
jj log -r 'working_copies()'
```

Replace symbolic `candidate` with the recorded Change ID before mutation.

## Filesets

Plain paths select that path recursively when it is a directory. Prefer quoted,
explicit filesets for non-trivial selection:

| Fileset | Meaning |
| --- | --- |
| `path/to/file.nix` | One path |
| `root:modules/home` | Repository-root-relative subtree |
| `glob:modules/**/*.nix` | Glob pattern |
| `x | y` | Union |
| `x & y` | Intersection |
| `x ~ y` | Subtraction |

Before `split`, `restore`, or path-limited `squash`, compare the fileset
against `jj diff --summary -r <change-id>`. Do not use a path-only split when
two semantic changes touch overlapping lines in the same file.
