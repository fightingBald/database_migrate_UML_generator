# D2 + ELK local validation

Date: 2026-09-10. Implementation and checks were performed in the local working tree; no commit, push or deployment was performed.

## Implemented

- `python -m erd_generator` defaults to D2; `make run` generates D2 source and an ELK SVG.
- Old draw.io entrypoints and Python exports remain available. D2 does not import NetworkX or the draw.io layout/exporter.
- SQL/FK loading returns per-run diagnostics; the historical last-run API remains available separately.
- D2 source generation validates relationships, quotes data, sorts output deterministically and leaves the input Schema unchanged.
- Rendering requires D2 0.7.1/bundled ELK, bounds execution time and publishes only a verified SVG. Failed rendering preserves the previous SVG and returns nonzero.
- D2 self references include field labels. The renderer uses self-loop spacing 100; this improves simple loops but does not prevent all composite-loop label collisions.
- DROP table/column/constraint/index compatibility, schema-qualified index operations, DROP COLUMN CASCADE, complete removal of affected primary-key constraints, numeric migration ordering, ambiguous YAML references and detected parse-error line reporting have regression coverage.
- The legacy comparator now understands qualified FK targets and generated type-suffixed column labels.
- README, Makefile, pinned Python dependencies and GitHub Actions checks are included.
- Four complex business demonstrations and six expected-failure cases run through the public CLI via `make demo`. A discovered stale unique-constraint registration after DROP COLUMN is fixed and covered for single/composite constraints.

## Verification results

Environment: macOS, Python 3.14.0, sqlglot 30.18.0, NetworkX 3.6.1, PyYAML 6.0.3, pydot 4.0.1, D2 0.7.1 with bundled ELK.

| Check | Result |
| --- | --- |
| `make build` | Pass |
| `make test` | 119 passed; 6 integration tests deselected by design |
| `make test-integration` | 6 passed; D2 is required, not silently skipped |
| `make lint` | Ruff checks and scoped formatting pass |
| `make run` | D2 + SVG generated successfully; last measured render 0.648 s |
| Sample schema | 5 tables, 21 columns, 5 FKs, 7 index/unique records |
| Legacy tools | draw.io export, relationship extraction, comparator and documented Graphviz fallback exercised |
| Browser inspection | Sample table/column labels, ordinary FK row connections, labeled self-loop, composite FK pair labels and cyclic connections inspected in Chrome |
| CI configuration | YAML structure checked; official Linux D2 archive downloaded and its SHA-256 verified |
| `make demo` | Four real SVGs and six expected failures verified; local gallery/report generated |

Test coverage includes malformed SQL and YAML, source/target references, explicit/implicit composite FK boundaries, source immutability, deterministic ordering, reserved D2 words, literal substitutions, Unicode, executable/version/layout failures, timeouts, invalid SVGs, write failures and preservation of existing artifacts.

The tiny D2 golden fixture was written from explicit expected schema behavior. Schema correctness tests assert migration outcomes instead of merely comparing two renderers that share the same parser.

## Complex scenario follow-up

The additional suite checks 9 tables / 42 columns / 15 FKs (26 field connectors) for multi-tenant orders; 4 / 15 / 3 for release evolution; 6 / 23 / 10 for cross-system relationships; and 4 / 17 / 3 for Unicode/readability. All four source-only directions and type visibility are exercised. The gallery runner also checks error exit codes, diagnostics, byte-for-byte preservation of prior artifacts and hiding stale images when a requested render fails.

The first local gallery run took 1.132 s, 0.819 s, 0.953 s and 0.839 s respectively per successful CLI invocation, including Python loading and D2 preflight/rendering. These small fictional examples are not production performance evidence; later runs record their own timings in `generated/demos/report.json`.

Browser inspection found overlapping labels in the multi-tenant diagram's composite self references and converging edges. This case passes automated structural/rendering checks but **does not pass a collision-free visual acceptance criterion**; it is labeled accordingly in the gallery and report. The release-evolution and logical-relationship examples are readable; the Unicode, escaped identifiers, long column and appendix were inspected in the standalone SVG. See the [scenario guide](../../examples/README.md).

## Synthetic scale measurements

Reproduction: `make benchmark`. Each case runs in a fresh Python process and writes its SQL, D2, SVG and `metrics.json` beneath `generated/benchmark-N/`.

The graph contains a long parent chain plus owner links. These are synthetic stress inputs, not a sample of the team's production schema. Elapsed time includes the Python CLI, D2 preflight and rendering. RSS is the peak child-process value reported by the OS, converted to MiB; it is not an aggregate concurrent-memory measurement.

| Tables | Columns | FKs | Elapsed | Peak child RSS | SVG bytes | ViewBox width × height |
| --- | --- | --- | --- | --- | --- | --- |
| 50 | 298 | 98 | 6.655 s | 273.9 MiB | 293,056 | 19,439 × 4,486 |
| 200 | 1,198 | 398 | 90.613 s | 1,914.9 MiB | 1,146,540 | 77,089 × 14,814 |

Both completed within the default rendering timeout, but the 200-table case is expensive and visually wide. The measurements do not justify a fast-large-diagram claim. Domain filtering/grouping remains a follow-up once the team's actual schema and diagram boundaries are available.

## Limits and remaining external verification

- GitHub Actions has been configured for Ubuntu/Python 3.11 and 3.14 but has not been run remotely. Python 3.11, Windows and the Linux D2 binary were not executed locally.
- The team's actual migration history has not been supplied or run. The parser remains a documented PostgreSQL subset; no database was used to certify arbitrary SQL execution semantics.
- D2 0.7.1/ELK may anchor a self loop to the table boundary despite column endpoints in the source. Field labels make the relationship explicit, but dense composite self-loop labels can still overlap; ordinary row-level connections were visually verified.
- Omitted composite reference columns are rejected rather than inferred from an unordered primary-key set.
- SVG/browser output is the supported rendered format. PNG/PDF and automatic business-domain splitting are not part of this implementation.
- Source and SVG replacement are separate operations. Consumers must check the exit code before publishing either artifact.

The Linux archive checksum used in CI is `eb172adf59f38d1e5a70ab177591356754ffaf9bebb84e0ca8b767dfb421dad7`, confirmed against the [official D2 0.7.1 release](https://github.com/d2lang/d2/releases/tag/v0.7.1) metadata and the downloaded bytes.
