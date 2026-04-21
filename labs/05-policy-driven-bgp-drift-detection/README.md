# Lab 05 — Policy-Driven BGP with Drift Detection

## Overview

This lab builds a **policy-driven eBGP design** on top of the existing 3-AS Juniper vLabs topology.

Rather than focusing on basic BGP bring-up, this lab introduces:

- **Intent-based policy control**
- **Model-driven configuration rendering**
- **Pre-deployment drift detection**

The goal is to move beyond “pushing config” and toward **controlled, validated network changes**.

---

## Key Outcome

This lab enforces deterministic path selection using BGP policy:

- The same prefixes are learned via both **direct** and **transit** paths
- Transit paths (via AS65333) are preferred using **higher local preference**
- Direct paths remain available as **backup**

Example:

- Transit path: local-pref **250** → selected
- Direct path: local-pref **175** → inactive (Local Preference)

This demonstrates controlled routing behavior driven entirely by policy.

## Topology Context

This lab reuses the existing BGP - Multi-AS topology from Juniper vLabs.

See the topology reference here:
[Juniper vLabs – BGP Multi-AS topology](https://jlabs.juniper.net/vlabs/portal/bgp-multi-as/index.page)


### Roles

- **AS65333 — Transit Core**
  - Single router
  - Central **policy enforcement point**
  - Multiple inter-AS paths exist; AS65333 acts as a policy-controlled transit option influencing route selection and propagation.

- **Edge AS (Left)**
  - Multi-router domain
  - Originates internal prefixes

- **Edge AS (Right)**
  - Smaller domain
  - Originates local prefixes

### Design Intent

All routing between edge domains is controlled by **AS65333**.

This makes the transit router:

- the **policy choke point**
- the **primary automation target**
- the **focus of drift detection**

---

## Objectives

This lab demonstrates:

- Rendering BGP configuration from structured data (no hardcoding)
- Enforcing **explicit import/export policy**
- Detecting **configuration drift before deployment**
- Preventing blind config pushes
- Validating routing behavior after change

---

## Workflow

The lab follows a structured operator workflow:

render → collect → compare → review → deploy → validate → re-collect


### Steps

1. **Render**
   - Generate intended BGP and policy config from templates and data

2. **Collect**
   - Pull current configuration from devices

3. **Compare**
   - Identify differences between intended and actual state
   - Focus only on managed sections:
     - `protocols bgp`
     - `policy-options`
     - `routing-options`

4. **Review**
   - Evaluate drift before making changes

5. **Deploy**
   - Apply candidate configuration

6. **Validate**
   - Confirm BGP sessions and policy behavior

7. **Re-Collect**
   - Pull configuration again after deployment
   - Re-run comparison against intended state
   - Confirm convergence:
     - intended and actual configurations match
     - no unmanaged drift remains within controlled sections

---

## Key Concepts

### Policy-Driven Design

- No implicit route advertisement
- All routing decisions are controlled by defined policy
- Prefix advertisement is explicitly allowed, not assumed

### Transit Enforcement

AS65333 controls:

- which routes are accepted
- which routes are propagated
- which ASes can exchange routes

### Drift Detection

Drift is defined as:

> Any difference between intended and actual configuration within managed sections.

This lab ensures:

- drift is detected before deployment
- changes are reviewed before being applied

---

## Lab Artifacts

This lab introduces the following components:

### Data

- `intent.yml`  
  Defines routing intent and policy behavior

- `policy_matrix.yml`  
  Describes how ASes interact (import/export rules)

### Playbooks

- `lab05_render.yml`
- `lab05_collect.yml`
- `lab05_compare.yml`
- `lab05_deploy.yml`
- `lab05_compare_overlay.yml`

Validation is performed using Junos CLI to confirm routing behavior and policy outcomes.

- `lab05_compare.yml` performs a full pre-deployment comparison between the live configuration and the intended Lab 05 overlay

- `lab05_compare_overlay.yml` performs a post-deployment comparison of only Lab 05–managed configuration (policy and BGP import/export), confirming convergence to the intended state

### Templates

- `lab05_bgp_policy_set.j2`
  - Renders policy-only configuration in `set` format
  - Applies import/export policies to existing BGP groups
  - Does not modify BGP transport or session configuration

The template generates policy overlays only, allowing existing BGP topology and session configuration to remain unchanged.

### Output

- `rendered/lab05/` — intended configurations
- `staging/lab05/` — snapshots, diffs, and reports

---

## Example Scenarios

### Controlled Prefix Advertisement

Add a new prefix to an edge AS and verify:

- it is rendered correctly
- it is advertised only where allowed

### Policy-Based Path Preference

Adjust routing preference and confirm expected path selection.

### Drift Detection

Introduce a manual configuration change and verify:

- drift is detected before deployment
- differences are clearly reported

---

## Success Criteria

The lab is successful when:

- BGP neighbors are generated from data
- Policy is rendered from intent, not hardcoded config
- Drift is detected before deployment
- Changes are applied in a controlled manner
- Post-deployment validation confirms expected routing behavior
- Policy-driven path selection is observable in the routing table:
  - Transit-learned routes are active
  - Direct routes are present but inactive
  - Inactive reason reflects **Local Preference**
- Post-deployment overlay comparison confirms convergence of policy configuration

---

## Verification

Detailed CLI validation, including full command output and path selection proof, is documented here:

`docs/lab-05-verification.md`

## Position in the Series

- **Labs 01–04** focused on configuration generation and deployment mechanics
- **Lab 05** introduces:
  - policy intent
  - drift awareness
  - safe deployment practices

This marks the shift from:

> “Automating configuration”

to

> “Automating network behavior safely”

## How to Run the Lab

### Prerequisites

- Active Juniper vLabs instance (BGP Multi-AS topology)
- Updated `inventory/lab_access.yml` with current host/port mappings
- Python virtual environment with Ansible and `juniper.device` collection

---

### Workflow Execution

Run the lab using the following sequence:

#### 1. Render intended configuration

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/lab05_render.yml
```

### 2. Collect current device state

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/lab05_collect.yml
```

### 3. Compare intended vs actual

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/lab05_compare.yml
```

Review diffs under:

`staging/lab05/diffs/`

**Note:**

Lab 05 uses two comparison modes:

- `lab05_compare.yml` compares the full collected configuration against the rendered overlay  
  → used **before deployment** to understand the complete configuration delta

- `lab05_compare_overlay.yml` compares only Lab 05–managed lines  
  → used **after deployment** to confirm convergence

Because Lab 05 applies a **policy overlay**, the rendered configuration does not include baseline BGP transport.

As a result:

- Pre-deployment diffs show the full configuration delta
- Post-deployment full diffs may still include unchanged baseline lines

For post-deployment validation, focus on:

- `policy-options`
- BGP `import` / `export` statements

These represent the intended state controlled by Lab 05.

### 4. Deploy policy configuration (safe)

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/lab05_deploy.yml
```
- Performs commit check before applying changes
- Applies policy-only configuration


### 5. Validate routing behavior

Run CLI verification steps:

- `show route receive-protocol bgp <neighbor> <prefix> detail`
- `show route <prefix> detail`

Expected:

- transit path selected (higher local preference)
- direct path present but inactive

### 6. Re-collect and confirm convergence

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/lab05_collect.yml
ansible-playbook -i inventory/lab_access.yml playbooks/lab05_compare.yml
```

- Shows full configuration differences (may include baseline lines)

Expected:

 -minimal or no diff between intended and actual state

### 7. Validate overlay convergence

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/lab05_compare_overlay.yml
```

Expected:

- no differences in policy and BGP import/export lines
- overlay matches intended state

---


