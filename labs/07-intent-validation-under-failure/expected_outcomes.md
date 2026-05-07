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


## Scenario 2 – Partial Gold Transport Path Degradation

### Assertion Pattern

- reachability: PASS
- route color: PASS
- transport class: PASS
- gold path ABR23: FAIL
- gold path ABR24: PASS
- gold transport marker: FAIL
- bronze transport marker: PASS

---

### Diagnosis

Partial gold transport path degradation.

The service remains correctly classified and still resolves over gold transport, but one gold path/marker is missing, reducing transport resiliency.

## Scenario 3 – Mixed / Multiple Intent Failure

### Assertion Pattern

- reachability: PASS
- route color: FAIL
- transport class: FAIL
- gold path ABR23: FAIL
- gold path ABR24: FAIL
- gold transport marker: FAIL
- bronze transport marker: PASS

---

### Diagnosis

Multiple or unknown intent failure.

The assertion pattern does not match a single known scenario, so the validator avoids overconfident diagnosis and directs the operator to review the failed assertions and full report.
