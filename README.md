# Network Automation Lab Series  
### Model-Driven Infrastructure Deployment with Ansible (Junos)

---

## Overview

A hands-on network automation project built on Juniper vLabs.

Rather than treating devices as individual configuration targets, this project builds networks as **systems**, using:

- structured topology data  
- configuration rendering  
- staged deployment workflows  
- safe, repeatable change execution  

The labs progress from simple configuration tasks to a full **Service Provider L3VPN deployment** built using a layered model and then into **policy-driven routing control with drift-aware operations and transport-aware validation**.

The goal is simple:
build something that looks closer to real operations than “run this playbook and hope”.

---

## What this project is

This is not a collection of random playbooks.

It is a structured progression showing how to move from:
- simple device changes  
to  
- controlled service deployment
to  
- validated forwarding behavior  

It demonstrates:

- model-driven configuration rendering (data → templates → device configs)  
- separation of underlay and overlay responsibilities  
- staged deployment workflows (render → deploy)  
- safe configuration strategies (`merge` and `set`, no destructive overrides)  
- idempotent automation design  
- failure isolation and recovery strategy
- drift-aware operational workflow (render → collect → compare → deploy → verify) 
- transport-aware validation of service forwarding behavior 

## Why this exists

Most automation examples stop at:
“push config to device”

Real networks don’t work like that.

## Platform choice

This project uses Juniper vLabs for hands-on access.

The focus is not on the vendor CLI, but on:

- automation patterns
- data modelling
- deployment workflow

The same approach can be applied to other platforms.

## Lab progression

Each lab builds on the previous one and introduces a new layer of operational thinking.

| Lab | Focus                                  | What it shows                                                                 |
|-----|----------------------------------------|-------------------------------------------------------------------------------|
| 01  | Hostname automation                    | Basic inventory, NETCONF access, and first config push                        |
| 02  | Config backup and controlled restore   | State capture, lab rebuilds, and controlled config replacement                |
| 03  | Controlled OSPF to ISIS migration      | Staged rendering, explicit protocol removal, and idempotent migration         |
| 04  | Full SP L3VPN deployment               | Full underlay + overlay + service automation                                  |
| 05  | Policy-driven BGP with drift detection | Intent-based policy control, pre-deployment diffing, and safe deployment      |
| 06  | Transport-aware service validation     | Service → transport dependency validation and forwarding-path observability   |
| 07  | Intent validation under failure        | Failure classification, multi-plane fault isolation, and diagnostic workflows |

Start at Lab 01 if you are new to this.  
Jump to Lab 04 if you want the full service deployment.  
Jump to Lab 05 if you want policy control and drift-aware operations.  
Jump to Lab 06 if you want to understand how services are actually forwarded in the network.

---

## What gets built (core deployment)

Lab 04 remains the central build in this series and automates a full service provider L3VPN stack:

- ISIS multi-area underlay  
- MPLS + RSVP  
- iBGP with route reflector  
- PE–CE connectivity  
- VRF service (cust-a)  

All configuration is generated from structured data and deployed in stages.

End-to-end validation is included (CE to CE reachability confirmed).

---

## What comes after deployment

Labs 05 and 06 build on this foundation by focusing on **how the network behaves after it is built**:

- Lab 05 introduces policy control and drift-aware operations  
- Lab 06 validates how services are actually forwarded across transport classes  

Together, these extend the project from:

- building networks  

into:

- controlling and verifying real operational behavior

---

## Core Deployment (Lab04) is staged

Changes are applied in controlled phases:

CE → Core → BGP → VPN

This avoids:

- broken adjacencies
- partial control-plane state
- service deployment without transport

## Safe execution model

This project intentionally avoids:

```bash
load: override
```

Instead it uses:

- merge for structured configs
- set for incremental changes

This preserves access and reduces risk during deployment.

## How to run (fast path)

See the topology reference for this specific core deployment Lab04 here:
[Juniper vLabs – IS-IS - Multi-level/area](https://jlabs.juniper.net/vlabs/portal/is-is-multi-level-area/)

### 1. Full deployment (Lab 04)

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area.yml
```

### 2. Staged deployment (recommended for learning/debugging)

Render configs:

```bash
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__ce.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__base.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__bgp.yml
ansible-playbook -i inventory/isis_multi_area.yml playbooks/render_isis_multi_area__vpn.yml
```

Deploy in order:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__ce.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__base.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__bgp.yml
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area__vpn.yml
```

## Verification

End-to-end connectivity is validated across the L3VPN service.

Example:

- `ping 192.168.6.6`

Expected:

successful CE-to-CE communication across the provider network

## Getting started

Setup the environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Update your inventory with device IPs and credentials, then run the playbooks from the relevant lab.

## Lab environment (no hardware needed)

This lab was built and tested using Juniper Cloud Labs (JCL).
If you don’t have access to physical routers, no problem — JCL provides free, browser-based access to Juniper lab environments.
You can spin up a topology, get device IP/port access, and run this lab exactly as shown here.
- JCL environments use shared access (IP + port per device)
- Labs can expire or reset, so inventory may need to be updated
- Authentication is handled by the lab environment (not templated here)

### Get access

1. Go to : Juniper Cloud Labs (JCL) 
2. Sign up for an account  
3. Launch a lab (for example: `vMX` or `isis_multi_area`)  
4. Use the provided IP/port details in your Ansible inventory  


### Lab 05 – Policy-Driven BGP with Drift Detection

Lab 05 extends the series from service deployment into policy-driven network behavior.

It demonstrates:

- multi-AS BGP policy control across direct and transit paths
- render → collect → compare workflow before deployment
- safe policy deployment onto existing BGP topology
- CLI validation of routing outcomes after change
- post-deployment convergence checking for Lab 05-managed configuration

This is the first lab in the series focused not just on generating configuration, but on **controlling and verifying routing behavior safely**.

## Current Focus Labs

### Lab 06 – Transport-Aware Service Reachability

Lab 06 extends the series from policy control into **transport-aware service validation**.

This labs demonstrates:

- how customer-facing services are resolved over specific transport classes (gold / bronze)
- how service intent (color) drives transport selection at the PE
- how transport paths exist independently of the service plane
- end-to-end validation of service → transport dependency (CE → PE → boundary)
- controlled failure testing by removing service classification at the source

Lab 06 introduces a validation workflow that proves not only that a service is reachable, but **how it is forwarded and why**.

It also shows how operators can verify these behaviors across different states (for example, with and without service classification), rather than relying on static control-plane inspection.

This marks the transition from:

- configuration and deployment (Labs 01–04)  
- policy control and drift detection (Lab 05)  

into:

- **intent-driven forwarding validation and multi-plane observability (Lab 06)**
- **failure classification and operator-focused diagnosis workflows (Lab 07)**

---

## Latest Lab

### Lab 07 – Intent Validation Under Failure

Lab 07 extends the series from transport-aware validation into operator-focused failure diagnosis.

It demonstrates:

- controlled failure injection across service and transport layers
- classification of assertion failures into operational diagnoses
- distinction between service-plane and transport-plane faults
- handling of mixed or ambiguous failure conditions
- reusable PASS/FAIL validation workflows for operational testing

The lab focuses on explaining *why* forwarding intent is violated, not simply detecting that a mismatch exists.

This marks the transition from:

- service-aware forwarding validation (Lab 06)

into:

- **intent classification, fault isolation, and operational diagnosis workflows (Lab 07)**

## Future Planned Lab

### Lab 08 – Multi-Service / Multi-Class Validation
- validating multiple services across different transport classes
- scaling the model beyond single-route verification
- SLA-aware service grouping and validation

These labs extend the progression toward **real-world operational validation**, where engineers must verify not only that the network works, but that it behaves as intended under change.

## Author

Network engineer focused on service provider technologies and automation.

Background includes:

- SP routing (ISIS, BGP, MPLS, L3VPN, L2VPN, SRv6)
- Multi-vendor environments
- Automation using Python and Ansible
- Contributor to technical content including Cisco Press and engineering blogs.