# Lab 07 – Intent Validation Under Failure

## Goal

Extend Lab 06 by adding a diagnosis layer to interpret validation failures.

Instead of only detecting mismatches (PASS/FAIL), this lab classifies and explains why intent is violated.

---

## What this lab adds

* Reuse of Lab 06 validation workflow
* Interpretation of assertion failures
* Mapping failure patterns to root cause and impact

---

## Scenario 1 – Service Classification Missing

### Description

The service route is no longer tagged with the expected color/community (`map2gold`).

This simulates loss of service classification at ingress.

---

### Failure Injection

On CE31:

```bash
delete policy-options policy-statement vpn term 1 then community add map2gold
commit
```

---

### Expected Behavior

* Service remains reachable
* Route color assertion fails
* Transport class assertion fails
* Gold path assertions fail
* Transport markers remain present

---

### Diagnosis

```text
Service classification failure
Cause: missing service color/community
Impact: service cannot map to gold transport, fallback likely
```

---

## How to Run

```bash
./scripts/validate_lab07_failure.sh <service-ip>
```

Example:

```bash
./scripts/validate_lab07_failure.sh 172.16.3.32
```

---

## Output Format

```text
ASSERT ...
RESULT: PASS/FAIL

DIAGNOSIS:
- ...
```

---

## Notes

* This lab does not introduce new validation checks
* It adds interpretation on top of Lab 06 results
* Focus is on operator-level understanding of failures

## Scenario 2 – Gold Transport Missing

This scenario simulates loss of the intended gold transport class while service classification remains intact.

Expected result:

- service remains reachable (fallback transport used)
- service route still carries the expected color/community
- gold transport resolution fails
- bronze/default transport remains available

Diagnosis:

Transport plane degradation.

### Sample Output (FAIL)

```text
ASSERT reachability -> PASS
ASSERT route color -> PASS
ASSERT transport class -> PASS
ASSERT gold path ABR23 -> FAIL
ASSERT gold path ABR24 -> PASS
ASSERT gold transport marker -> FAIL
ASSERT bronze transport marker -> PASS

RESULT: FAIL

DIAGNOSIS:

Partial gold transport path degradation
Cause: ABR23 gold transport marker/path is missing
Impact: service still resolves over gold, but transport resiliency is reduced
```

## Scenario Runbook

### Baseline Validation

Run this before and after each failure scenario.

```bash
./scripts/validate_lab07_failure.sh 172.16.3.32
```

Expected result:

RESULT: PASS

### Scenario 1 – Service Classification Missing

Inject Failure

On CE31:

```bash
configure
delete policy-options policy-statement vpn term 1 then community add map2gold
commit
```

Verify
```bash
./scripts/validate_lab07_failure.sh 172.16.3.32
```

Expected diagnosis:

DIAGNOSIS:
- Service classification failure
- Cause: service route is missing expected color/community
- Impact: cannot map to gold transport, fallback likely

Restore

On CE31:

```bash
configure
set policy-options policy-statement vpn term 1 then community add map2gold
commit
```

Confirm Restore
```bash
./scripts/validate_lab07_failure.sh 172.16.3.32
```

Expected result:

RESULT: PASS

### Scenario 2 – Partial Gold Transport Path Degradation
Inject Failure

On ABR23:

```bash
configure
delete protocols mpls label-switched-path toPE25-gold transport-class gold
delete protocols mpls label-switched-path toASBR22-gold transport-class gold
commit
```

Verify

```bash
./scripts/validate_lab07_failure.sh 172.16.3.32
```

Expected diagnosis:

```text
DIAGNOSIS:
- Partial gold transport path degradation
- Cause: ABR23 gold transport marker/path is missing
- Impact: service still resolves over gold, but transport resiliency is reduced
```

Restore

On ABR23:

```bash
configure
set protocols mpls label-switched-path toPE25-gold transport-class gold
set protocols mpls label-switched-path toASBR22-gold transport-class gold
commit
```

Confirm Restore

```bash
./scripts/validate_lab07_failure.sh 172.16.3.32
```

Expected result:

RESULT: PASS

