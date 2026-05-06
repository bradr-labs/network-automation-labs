# Lab 07 Expected Outcomes

## Scenario 1 — Service Classification Missing

Expected assertion pattern:

- reachability: PASS or FAIL depending on fallback
- route color: FAIL
- transport class: FAIL

Expected diagnosis:

Service classification failure.
The service route is not carrying the expected color/community, so it cannot reliably resolve over gold transport.