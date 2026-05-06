# Expected Outcomes – Lab 07

## Scenario 1 – Service Classification Missing

### Assertion Pattern

* reachability: PASS
* route color: FAIL
* transport class: FAIL
* gold paths: FAIL
* transport markers: PASS

---

### Diagnosis

Service classification failure.

The service route is missing the expected color/community, preventing correct transport resolution.

## Scenario 2 – Gold Transport Missing

### Assertion Pattern

- reachability: PASS
- route color: PASS
- transport class: FAIL
- gold paths: FAIL
- gold transport marker: FAIL
- bronze transport marker: PASS

---

### Diagnosis

Transport plane degradation.

Gold transport is unavailable, so the service falls back to available transport while remaining reachable.