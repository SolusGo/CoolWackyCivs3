# The Salt Road Compact testing

Automated evidence lives in `../tools/Validation.json`, `../tools/validate_archived.py` and `../tools/tests/archived.lua`. The suite executes this production Lua context, rather than a reimplementation of the mechanic. It checks clean/supplementary pristine and mutated SQL baselines, all 172 approved unit/building companions, exact yield deltas including duplicate inherited records, localization and human-only registration.

Lua51 scenarios exercise bootstrap/reload, foreign/free controller cleanup, capture/liberation, idempotence and the mechanic-specific cases in the [pack matrix](../docs/ArchivedDailyTesting.md). Each of Quick/Standard/Epic/Marathon runs with 4 and 34 occupied mock major slots, 25+ cities per civilization, 100 trade routes and 1,000+ units. Map work is bounded; a global unit scan fails the test.

Native acceptance is **NOT RUN**. In a new BNW + standalone CP151 game, use the [exact guide](README.md) and [native matrix](../docs/ArchivedDailyTesting.md) to verify real payouts, relevant callbacks, city capture/razing/liberation, ordinary save/reload, unit upgrades/combat previews and the native art fallbacks. Repeat on Marathon with 25+ owned cities where practical. Record saves and Database.log/Lua.log; do not infer a pass from a mock.

Post-economy owner-turn reconciliation affects the next payout. Direct callbacks change controller state when delivered; UI dispatch synchrony and native economic timing still require observation. SQL/sample fixtures are not a reconstruction of final clean CP gameplay data.
