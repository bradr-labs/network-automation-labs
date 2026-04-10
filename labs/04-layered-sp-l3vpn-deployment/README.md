# Lab 04 - Layered SP L3VPN Deployment with Structured Rendering

## Objective

Build a Service Provider L3VPN network using a structured, model-driven approach with layered configuration rendering and controlled deployment.

This lab moves beyond individual configuration tasks and introduces a repeatable deployment model based on:

- separation of underlay and overlay responsibilities
- structured topology-driven configuration rendering
- staged service deployment across network roles
- safe, non-destructive configuration loading
- orchestration of multi-phase network changes

---

## Overview

This lab demonstrates how to construct a complete SP-style network by combining:

- a transport underlay (ISIS-based topology from JCL)
- a service overlay (BGP + VRF-based L3VPN)

Rather than treating devices as isolated targets, the network is built as a **layered system**, where:

- the underlay provides reachability and transport
- the overlay delivers services and customer connectivity

Configuration is not written manually per device.
Instead, it is:

1. defined through structured topology data
2. rendered into device-specific configuration files
3. deployed in controlled stages

---

## Key Idea

This lab introduces a fundamental shift:

> from pushing configs → to building networks from a model

Each layer is rendered and deployed independently, allowing:

- predictable outcomes
- safer changes
- repeatable workflows
- easier troubleshooting

---

## What this lab shows

You will:

- render underlay and overlay configurations from structured data
- deploy configurations in staged layers (CE → core → PE → VPN)
- use different load strategies for different configuration types
- orchestrate a full SP L3VPN deployment with a single command
- validate end-to-end customer connectivity across the network

---

## Why this matters

This approach reflects how real networks are engineered:

- infrastructure is treated as a system, not individual devices
- configuration is generated from intent, not written ad hoc
- changes are staged, validated, and reversible

This reflects a model-driven approach to network automation, where desired state is defined first and rendered into device configuration.

## Authentication

Lab 04 does not store device credentials in the repository.

Deployment playbooks prompt for the device password at runtime.  
This keeps authentication separate from the rendered model and avoids publishing lab credentials.
A blank SSH config file `/tmp/blank_ssh_config` is used to avoid local SSH key or agent interference on the control node in some environments.

## Architecture Model

This lab separates network state into two layers:

### Underlay (Transport)

- ISIS-based underlay (JCL topology)
- MPLS / RSVP forwarding
- Core connectivity

Rendered as:
- bracket-style configuration (`.conf`)
- applied using `merge`

---

### Overlay (Services)

- iBGP (RR + PE sessions)
- VRF-based L3VPN services
- CE–PE routing

Rendered as:
- set-style configuration (`.set`)
- applied using `set`

## Rendering Model

All rendered configurations are stored under:

rendered/

Structure varies by lab and deployment phase.

### Lab 04 structure:

rendered/
  isis_multi_area/
    base/
    ce/
    bgp/
    vpn/

### Rules/Config types

- Underlay/core → `.conf` (bracket style)
- Overlay/services → `.set` (set style)

| Type         | Location              | Load Mode |
| ------------ | --------------------- | --------- |
| Base / CE    | `rendered/.../*.conf` | merge     |
| BGP Overlay  | `rendered/.../*.set`  | set       |
| VPN Services | `rendered/.../*.set`  | set       |

This ensures:

- clean separation of concerns
- predictable deployment behavior
- safer incremental changes

---

## Design Decisions 

This lab intentionally avoids full configuration replacement (`load: override`).

Instead, it uses:

- `merge` for structured base configuration
- `set` for incremental service overlays

This approach was chosen to:

- preserve existing access and system configuration
- reduce risk of management lockout
- allow partial deployment and rollback by layer
- support iterative changes without resetting device state

The deployment model reflects real operational constraints, where full replacement is often unsafe or impractical.

## Deployment Model

This lab uses two layers of playbooks:

- High-level playbooks (`deploy_*`) orchestrate rollout by stage
- Low-level playbooks (`load_*`) handle direct device interaction

For normal use, run the `deploy_*` playbooks only.
Low-level device interaction (`load_*` playbooks) is intentionally abstracted and not part of the primary user interface.

---

## Multi-Stage Deployment

This runbook describes how to safely deploy rendered configurations to the Juniper vLabs environment step by step.

Use this when:
- learning the system
- debugging issues
- validating each stage manually

And:
- never use `load: override` unless you intend to fully replace the device config.
- the lab base config contains authentication and access settings.
- always use `merge` for `.conf` files and `set` for `.set` files.


## Deployment Logic

The deployment is ordered to respect dependencies between network roles.

- Customer Edge is deployed first to establish service endpoints  
- Core transport is deployed next to provide reachability  
- Provider Edge is configured after transport is stable  
- VPN services are applied last, once control-plane connectivity exists  

Each stage builds on the previous one.

This prevents:

- routing adjacency failures  
- incomplete control-plane formation  
- service configuration without transport reachability  

## Deployment Stages

1. CE layer (r4, r6) - eBGP to PE, customer prefixes
2. Base Layer (r1, r2, r3, r5) - interfaces, ISIS, MPLS, RSVP
3. BGP Overlay (r2(RR), r3, r5) - iBGP + route-reflection, global autonomous system
4. VPN services (r3, r5) - VRF (`cust-a`), PE-CE eBGP

## Notes

- CE routers do NOT run ISIS/MPLS
- VRF name: `cust-a`
- BGP RR: `lab-r2`
- P routers: `lab-r1`
- PE routers: `lab-r3`, `lab-r5`


## Playbooks used

| Purpose         | Playbook                                           |
| --------------- | -------------------------------------------------- |
| CE stage        | `deploy_sp_l3vpn_on_isis_multi_area__ce.yml`       |
| Base stage      | `deploy_sp_l3vpn_on_isis_multi_area__base.yml`     |
| BGP overlay     | `deploy_sp_l3vpn_on_isis_multi_area__bgp.yml`      |
| VPN services    | `deploy_sp_l3vpn_on_isis_multi_area__vpn.yml`      |


## Phases

The staged workflow has two phases:

1. Render all configurations
2. Deploy them in order

### 1. Render all configurations

```bash
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__ce.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__base.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__bgp.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__vpn.yml
```
### Render output

CE render creates:
- `rendered/isis_multi_area/ce/`
For:
- `lab-r4.conf`
- `lab-r6.conf`

Base render creates:
- `rendered/isis_multi_area/base/`
For:
- `lab-r1.conf`
- `lab-r2.conf`
- `lab-r3.conf`
- `lab-r5.conf`

BGP render creates:
- `rendered/isis_multi_area/bgp/`
For:
- `lab-r2.set`
- `lab-r3.set`
- `lab-r5.set`

VPN render creates:
- `rendered/isis_multi_area/vpn/`
For:
- `lab-r3.set`
- `lab-r5.set`

### 2. Deploy them in order

After rendering, run:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__ce.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__base.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__bgp.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__vpn.yml
```

### Full multi-stage sequence (for reference and brevity)

```bash
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__ce.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__base.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__bgp.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__vpn.yml

ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__ce.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__base.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__bgp.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__vpn.yml
```

## Orchestrated Deployment (Single Command)

A full deployment can be executed using a single orchestrator playbook.

This playbook enforces the correct deployment order internally.

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area.yml
```

| Purpose         | Playbook                                           |
| --------------- | -------------------------------------------------- |
| Full            | `deploy_sp_l3vpn_on_isis_multi_area.yml`           |

## Verification

### After Base

- Interfaces up
- Management reachable
- ISIS adjacencies up

### After BGP

- `show bgp summary`
- RR/client sessions established

```bash
jcluser@lab-r3> show bgp summary 
Threading mode: BGP I/O
Default eBGP mode: advertise - accept, receive - accept
Groups: 2 Peers: 2 Down peers: 0
Table          Tot Paths  Act Paths Suppressed    History Damp State    Pending
bgp.l3vpn.0          
                       3          3          0          0          0          0
Peer                     AS      InPkt     OutPkt    OutQ   Flaps Last Up/Dwn State|#Active/Received/Accepted/Damped...
10.100.34.2           65004         56         56       0       0       23:41 Establ
  cust-a.inet.0: 3/4/4/0
10.100.100.2          65000         14         14       0       0        4:53 Establ
  bgp.l3vpn.0: 3/3/3/0
  cust-a.inet.0: 2/3/3/0
```

### After VPN routing

- `show route instance`
- `show route table cust-a.inet.0`
- CE routes visible

```bash
jcluser@lab-r3> show route instance cust-a 
Instance             Type
         Primary RIB                                     Active/holddown/hidden
cust-a               vrf            
         cust-a.inet.0                                   7/0/0
         cust-a.inet6.0                                  1/0/0

jcluser@lab-r3> show route table cust-a.inet.0 

cust-a.inet.0: 7 destinations, 9 routes (7 active, 0 holddown, 0 hidden)
+ = Active Route, - = Last Active, * = Both

10.100.34.0/24     *[Direct/0] 00:21:37
                    >  via ge-0/0/2.0
                    [BGP/170] 00:21:35, localpref 100
                      AS path: 65004 I, validation-state: unverified
                    >  to 10.100.34.2 via ge-0/0/2.0
10.100.34.1/32     *[Local/0] 00:21:37
                       Local via ge-0/0/2.0
10.100.56.0/24     *[BGP/170] 00:02:42, localpref 100, from 10.100.100.2
                      AS path: I, validation-state: unverified
                    >  to 10.100.13.1 via ge-0/0/0.0, label-switched-path R3-TO-R5
10.100.100.4/32    *[BGP/170] 00:21:35, localpref 100
                      AS path: 65004 I, validation-state: unverified
                    >  to 10.100.34.2 via ge-0/0/2.0
100.123.0.0/16     *[BGP/170] 00:21:35, localpref 100
                      AS path: 65004 I, validation-state: unverified
                    >  to 10.100.34.2 via ge-0/0/2.0
                    [BGP/170] 00:02:42, localpref 100, from 10.100.100.2
                      AS path: 65006 I, validation-state: unverified
                    >  to 10.100.13.1 via ge-0/0/0.0, label-switched-path R3-TO-R5
192.168.4.0/24     *[BGP/170] 00:21:35, localpref 100
                      AS path: 65004 I, validation-state: unverified
                    >  to 10.100.34.2 via ge-0/0/2.0
192.168.6.0/24     *[BGP/170] 00:02:42, localpref 100, from 10.100.100.2
                      AS path: 65006 I, validation-state: unverified
                    >  to 10.100.13.1 via ge-0/0/0.0, label-switched-path R3-TO-R5
```

### End-to-end connectivity

From r4:

- `ping 192.168.6.6`

```bash
jcluser@lab-r4> ping 192.168.6.6    
PING 192.168.6.6 (192.168.6.6): 56 data bytes
64 bytes from 192.168.6.6: icmp_seq=0 ttl=61 time=5.578 ms
64 bytes from 192.168.6.6: icmp_seq=1 ttl=61 time=2.749 ms
^C
--- 192.168.6.6 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 2.749/4.163/5.578/1.415 ms
```

## Golden Rules

1. Never use override in vLabs
2. Always deploy in stages
3. One router at a time (when testing)
4. Verify after each phase
5. If unsure, stop and check

## Failure Model

Failures in this workflow typically occur in one of three areas:

- transport layer (ISIS/MPLS not converged)
- control plane (BGP sessions not established)
- service layer (VRF or CE routing incomplete)

The staged deployment model helps isolate failures to a specific layer.

Verification steps are aligned to each stage to detect issues early before progressing.

## Recovery Strategy (Commit-Aware)

Recovery must account for how many commits exist on each router.

Do NOT blindly use `rollback 1`.

---

## Step 1 – Inspect commit history

On the affected router:

```bash
show system commit
```

Example:

0   VPN services
1   BGP overlay
2   base config
3   older config

---

## Step 2 – Choose the correct rollback target

### Case A – Multi-stage routers (e.g. r3, r5)

Use rollback selectively by layer:

| Goal                | Command      |
| ------------------- | ------------ |
| Remove VPN only     | `rollback 1` |
| Remove VPN + BGP    | `rollback 2` |
| Return to base only | `rollback 3` |

Example:

```bash
configure
rollback 1
commit
```

---

### Case B – Single-commit routers (e.g. r1)

If only one meaningful commit exists:

- `rollback 1` may revert too far
- commit history may not match deployment stages

👉 In this case, DO NOT rely on rollback alone.

Use redeploy instead.

---

## Step 3 – Preferred recovery order

### 1. Targeted rollback (best case)

Use when:

- commit history is clear
- you know which layer failed

---

### 2. Redeploy known-good configuration

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area.yml
```

Use when:

- router state is inconsistent
- commit history is unclear
- multiple changes have been applied

---

### 3. Full reset (last resort)

Use JCL baseline reset only when:

- device is badly broken
- access/config is corrupted
- rollback/redeploy are insufficient

---

## Key Rules

1. Always run `show system commit` first
2. Never assume rollback numbers
3. Prefer **surgical rollback** over full reset
4. If unsure → redeploy instead of guessing

---

## Mental Model

- **Rollback** = undo last change(s)
- **Redeploy** = restore desired state
- **Reset** = wipe to factory baseline

Use the least destructive option first.

---