# Lab 03 - Controlled OSPF to ISIS Migration

A staged, idempotent workflow for migrating a live underlay from OSPF to ISIS using Ansible.

## Objective

Migrate a multi-area OSPF underlay to ISIS using a controlled, staged automation workflow.

This lab introduces:
- protocol migration without full configuration replacement
- data-driven rendering from topology variables
- staged deployment and verification
- idempotent playbook design

---

## Lab environment

This lab is based on the Juniper Cloud Labs (JCL) OSPF Multi-Area topology.

It uses two inventory sources:

- `inventory/ospf_multi_area.yml`
- `inventory/lab_access.yml`


## Roles of each inventory

- `inventory/ospf_multi_area.yml` — topology and per-device data  
- `inventory/lab_access.yml` — JCL IP/port access model

This lab assumes:

- a working OSPF multi-area topology
- NETCONF enabled
- valid credentials
- a working Ansible environment

## What this lab shows

This lab is about controlled protocol migration using staged rendered configuration.

You will:
- render base and transition configuration from topology data
- standardize router state where needed
- check whether OSPF is currently configured
- explicitly remove OSPF
- merge the ISIS transition configuration
- verify the router state after migration

Each router is migrated individually to maintain control and visibility.

## Staged configuration model

This lab uses a two-stage configuration model:

- Base configuration  
  Defines the intended baseline state of the router

- Transition configuration  
  Defines the protocol migration (OSPF → ISIS)

This separation ensures:
- predictable starting state
- safer migration workflow
- clearer configuration intent

## Topology data model

Topology and device data are defined in:

- `inventory/ospf_multi_area.yml`

This includes values such as:

- hostname
- loopback IP
- management IP
- default route next hop
- ISO address
- underlay interface addressing

### Example

```yaml
r1:
  hostname: lab-r1
  loopback_ip: 10.100.100.1
  fxp0_ip: 100.123.1.0/16
  default_route_next_hop: 100.123.0.1
  iso_address: 49.0002.1010.0100.0001.00

  underlay_interfaces:
    - name: ge-0/0/0
      address: 10.100.12.1/24
    - name: ge-0/0/1
      address: 10.100.14.1/24
```

This keeps topology intent separate from the migration logic.

## Templates used

This workflow uses:

- `templates/ospf_multi_area_base.j2`
- `templates/ospf_multi_area_with_isis.j2`

The rendered transition configuration is built from topology data and written locally before deployment.

## Files used

- `playbooks/render_ospf_multi_area_with_isis.yml`
- `playbooks/ospf_multi_area_to_isis.yml`
- `playbooks/test_connectivity.yml`
- `inventory/ospf_multi_area.yml`
- `inventory/lab_access.yml`
- `templates/ospf_multi_area_with_isis.j2`
- `rendered/ospf_multi_area/transition/`

## Rendering model

Rendered configurations are separated by stage:

```text
rendered/ospf_multi_area/base/
rendered/ospf_multi_area/transition/
```

This separates:

- baseline router configuration
- migration-specific transition state

The migration workflow does not treat the device as a blank target.
Instead, it builds toward the ISIS underlay in controlled stages.

## Key design decisions

### No `load: override`

Unlike Lab 02, this workflow avoids full configuration replacement.

It does not use:

```text
load: override
```

This reduces the risk of:

- losing management access
- wiping required system configuration
- making the migration harder to recover

## Explicit OSPF removal

The migration workflow does not assume protocol state will sort itself out.

Instead, it:

- checks whether OSPF is present
- removes OSPF explicitly
- then merges the rendered ISIS target configuration

This keeps the migration predictable and rerunnable.

## Merge-based deployment

The final rendered configuration is applied using:

```text
load: merge
```

This allows:

- incremental change
- preservation of non-migration config
- safer reruns

## Idempotent workflow

The migration workflow is designed to be rerunnable:

- OSPF removal is conditional
- final ISIS config is merged safely
- repeated runs do not break the target state

## Workflow

### 1. Activate environment

```bash
source .venv/bin/activate
```

### 2. Verify connectivity

```bash
ansible-playbook \
-i inventory/ospf_multi_area.yml \
-i inventory/lab_access.yml \
playbooks/test_connectivity.yml \
--limit r1
```

### 3. Render base configuration

```bash
ansible-playbook \
-i inventory/ospf_multi_area.yml \
-i inventory/lab_access.yml \
playbooks/render_base.yml \
--limit r1
```

### 4. Apply base configuration

```bash
ansible-playbook \
-i inventory/ospf_multi_area.yml \
-i inventory/lab_access.yml \
playbooks/load_ospf_multi_area_base.yml \
--limit r1
```

This step ensures the router is in a known baseline state before migration.

### 5. Render transition configuration (OSPF → ISIS)

```bash
ansible-playbook \
-i inventory/ospf_multi_area.yml \
-i inventory/lab_access.yml \
playbooks/render_ospf_multi_area_with_isis.yml \
--limit r1
```

### 6. Perform protocol migration

```bash
ansible-playbook \
-i inventory/ospf_multi_area.yml \
-i inventory/lab_access.yml \
playbooks/ospf_multi_area_to_isis.yml \
--limit r1
```

This step:

- removes OSPF (if present)
- merges ISIS configuration
- verifies the result

### 7. Repeat per router

```bash
--limit r2
--limit r3
...
```

Migrate one router at a time to maintain control.

## Validation

After each migration step, validate that:

- the router is still reachable
- ISIS configuration is present
- adjacency forms correctly
- expected routes are available

Useful checks include:

```bash
show isis adjacency
show route
show configuration protocols isis
ping <remote loopback>
```

The migration playbook also includes immediate post-change checks such as:

```bash
show version
show configuration protocols isis
```

## Notes
Authentication is intentionally excluded from templates
Lab access is managed separately through `inventory/lab_access.yml`
This workflow is designed for controlled lab migration, not production rollout
Migrate one router at a time to keep the change observable and recoverable

## Why this matters

This lab moves beyond basic configuration management into protocol migration engineering.

It demonstrates how to:

- transition an active underlay from one protocol to another
- separate topology data from execution logic
- render before deploying
- avoid destructive full configuration replacement
- build safe, repeatable change workflows

This is much closer to real network change execution than one-off config pushes.

