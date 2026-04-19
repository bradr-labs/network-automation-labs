## Lab 05 — Policy-Driven BGP with Drift Detection

Design Definition
## 1. Lab Overview

Lab 05 builds a policy-driven eBGP design on top of the existing 3-AS Juniper vLabs topology, using a model-driven approach to render configuration and a pre-deployment comparison workflow to detect drift before changes are applied.

The lab introduces intent-based routing policy and safe deployment practices, extending the configuration rendering workflows developed in Labs 01–04.

## 2. Topology Roles

The lab uses the existing 3-AS Juniper vLabs topology with clearly defined roles and multiple inter-AS path options.

### Autonomous Systems

- **AS65333**  
  Single-router transit AS acting as the central policy control point.

- **AS65222**  
  Left-side edge AS with one internal router and multiple border routers.

- **AS65444**  
  Right-side edge AS with multiple externally connected routers.

### Path Characteristics

Multiple valid inter-AS paths exist between AS65222 and AS65444:

- Direct edge adjacencies between the two ASes  
- A transit path via AS65333  

The lab does not remove this complexity. Instead, it uses policy to:

- control route advertisement  
- influence preferred path selection  
- maintain alternate paths for resilience  

AS65333 remains the primary **policy enforcement point**, but it is not the only available path.

## 3. Lab Objectives

The lab demonstrates the following capabilities:

1. Model-Driven Configuration
BGP neighbors generated from topology data
Policy generated from structured intent (not hardcoded CLI)
Reuse of rendering patterns from Labs 01–04
2. Policy-Controlled Routing
Explicit import/export behavior
No default “permit all” routing
Prefix advertisement restricted by policy objects
3. Drift Detection Before Deployment
Uses collected live configuration as the baseline for comparison
4. Safe Deployment Workflow
Render → Compare → Review → Deploy → Validate
Deployment gated by drift status

## 4. Policy Design Principles

Policy in this lab is intentionally simple, explicit, and focused on controlling behavior across multiple available paths.

### 1. Explicit Route Advertisement

Each AS advertises only approved prefixes.

- Prefixes are defined centrally and referenced by policy
- No implicit or blanket advertisement is permitted
- Export policy strictly controls what leaves each AS

This ensures that route propagation is deliberate and predictable.

---

### 2. Explicit Route Acceptance

Routers do not accept all received routes by default.

- Import policy defines exactly which prefixes are accepted
- All other routes are rejected by default
- This prevents unintended route propagation and limits blast radius

---

### 3. Policy-Controlled Path Selection

Multiple valid inter-AS paths exist between AS65222 and AS65444:

- Direct edge adjacencies  
- Transit path via AS65333  

Policy is used to control which path is preferred.

- Selected remote prefixes are preferred via the transit path
- Direct edge paths remain available as backup
- Local Preference is used as the primary decision mechanism

This demonstrates how routing behavior can be shaped without modifying topology.

---

### 4. Transit Enforcement

AS65333 acts as the central policy enforcement point.

- Only approved prefixes are accepted into transit
- Only approved prefixes are re-advertised between edge ASes
- Uncontrolled transit is explicitly prevented

This ensures that AS65333 does not become a blind route-forwarding point.

---

### 5. Deterministic Behavior

All routing outcomes are designed to be:

- predictable  
- explainable  
- reproducible  

For any given prefix:

- the preferred path is defined by policy  
- alternate paths are intentionally retained  
- behavior remains consistent across all border routers  

This allows drift and misconfiguration to be clearly identified.

---

### 6. Drift Sensitivity

Policy is designed so that small changes have visible impact.

Examples include:

- changing local preference values  
- modifying import/export policy assignments  
- altering allowed prefix sets  

These changes can affect best-path selection or route visibility, making drift detection meaningful and observable.

## 5. Managed Configuration Scope

Automation in this lab controls only specific parts of the device configuration:

protocols bgp
policy-options
routing-options autonomous-system

All drift detection and comparisons are scoped to these sections.

This avoids noise and keeps the lab focused.

## 6. Definition of Drift

For this lab:

Drift = Any difference between intended rendered configuration and actual device configuration within managed sections.

Drift includes:

manual config changes on devices
missing policy statements
mismatched BGP neighbor definitions

Drift excludes:

unrelated system config
interface-level config outside BGP scope

## 7. Workflow Model

The operator workflow for Lab 05 is:

1. Render intended configuration from data
2. Collect current device configuration (managed sections only)
3. Compare intended vs actual configuration
4. Review drift report
5. Deploy policy configuration (controlled change)
6. Validate routing behavior and policy outcomes
7. Re-collect and verify that intended state matches actual state

### Key Behavior

Deployment should not proceed blindly.

Drift must be:
- resolved, or
- explicitly accepted

After deployment:
- intended and actual configuration should converge
- no unmanaged drift should remain within the controlled scope

## 8. Data Model Strategy

The lab uses a model-driven approach, separating routing intent from device-specific configuration.

Rather than defining configuration directly in playbooks or templates, the lab uses structured data to describe desired network behavior.

### 1. Intent Model (`intent.yml`)

This is the primary source of truth for the lab.

It defines:

- router roles and AS membership  
- BGP session relationships  
- prefix definitions  
- policy definitions (import/export behavior)  
- path preference goals  

The intent model is designed to describe **what the network should do**, not how configuration is written.

---

### 2. Policy Matrix (`policy_matrix.yml`)

This file provides a human-readable view of the intended design.

It describes:

- relationships between routers and ASes  
- import and export policy assignments  
- preferred vs backup path behavior  
- allowed prefix advertisement and acceptance  

The policy matrix is used to:

- validate that intent is correctly defined  
- make the design easy to understand and review  
- provide a clear reference during troubleshooting  

---

### 3. Derived Configuration

Device configuration is not stored statically.

Instead:

- templates consume structured intent data  
- playbooks render configuration dynamically  
- resulting configs are written to the `rendered/` directory  

This ensures that configuration is:

- consistent  
- repeatable  
- derived from a single source of truth  

---

### 4. Minimal Device-Specific Overrides

Per-device customization is intentionally limited.

Overrides are used only where necessary, such as:

- router ID assignment  
- minor per-device adjustments  

The design avoids embedding logic in individual devices and instead derives behavior from shared intent.

---

### Design Principle

The key principle of the data model is:

> Define intent once, reuse it everywhere, and derive configuration automatically.

This allows the lab to scale cleanly and supports reliable drift detection and validation workflows.
The lab separates facts, intent, and rendered output.

## 9. Expected Outputs

The lab produces artifacts that reflect real operational workflows, using the existing repository structure.

### Rendered Configuration

Intended configuration is generated from structured data and templates:

- `rendered/lab05/`  
  Contains rendered BGP and policy configuration for each device

### Staging and Working Data

Intermediate data used during execution is stored under:

- `staging/lab05/`

This includes:

- collected device configuration snapshots
- intended vs actual comparison outputs
- drift and diff reports

### Operational Outputs

The lab produces human-readable outputs that demonstrate:

- configuration differences (intended vs actual)
- drift detection results
- validation results after deployment

These outputs are generated during playbook execution and stored under the lab05 staging area.

### Purpose

These artifacts provide:

- visibility into intended vs actual state
- evidence of controlled deployment
- traceability of configuration changes

They represent the transition from simple configuration automation to **observable and verifiable network behavior**.

## 10. Example Scenarios

The lab supports practical scenarios such as:

Scenario 1 — Controlled Prefix Advertisement

Add a new internal prefix to an edge AS and verify:

it is rendered correctly
it is advertised only where allowed
Scenario 2 — Policy-Based Path Preference

Modify preference toward one path via transit AS65333 and validate route selection.

Scenario 3 — Drift Detection

Introduce a manual config change on a router and verify:

drift is detected before deployment
report highlights differences clearly

## 11. Key Design Insight

The most important concept in this lab is:

The transit AS (65333) is not just a router — it is the policy control plane.

Everything in the lab should reinforce that:

policy is enforced there
drift is most critical there
correctness is validated through it

## 12. Position in the Lab Series

Lab 05 represents a transition:

Labs 01–04: configuration generation and deployment mechanics
Lab 05: intent, policy, and safe change validation

It introduces the idea that:

Automation is not just about pushing config — it is about controlling outcomes and preventing mistakes.