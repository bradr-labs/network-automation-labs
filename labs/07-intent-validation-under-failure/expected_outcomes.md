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