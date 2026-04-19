# Lab 05 — Policy-Driven BGP with Drift Detection

## Overview

This lab builds a **policy-driven eBGP design** on top of the existing 3-AS Juniper vLabs topology.

Rather than focusing on basic BGP bring-up, this lab introduces:

- **Intent-based policy control**
- **Model-driven configuration rendering**
- **Pre-deployment drift detection**

The goal is to move beyond “pushing config” and toward **controlled, validated network changes**.

---

## Topology Context

This lab reuses the existing BGP - Multi-AS topology from Juniper vLabs.

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

render → collect → compare → review → deploy → validate


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
- `lab05_validate.yml`

### Templates

- `lab05_bgp.j2`
- `lab05_policy.j2`

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

---

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
