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

The labs progress from simple configuration tasks to a full **Service Provider L3VPN deployment** built using a layered model and then into **policy-driven routing control with drift-aware operations**.

The goal is simple:
build something that looks closer to real operations than “run this playbook and hope”.

---

## What this project is

This is not a collection of random playbooks.

It is a structured progression showing how to move from:
- simple device changes  
to  
- controlled service deployment  

It demonstrates:

- **model-driven configuration rendering** (data → templates → device configs)  
- **separation of underlay and overlay** responsibilities  
- **staged deployment workflows** (render → deploy)  
- **safe configuration strategies** (`merge` and `set`, no destructive overrides)  
- **idempotent automation design**  
- **failure isolation and recovery strategy**
- **drift-aware operational workflow** (render → collect → compare → deploy → verify)  

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

Start at Lab 01 if you are new to this.  
Jump to Lab 04 if you want the full service deployment.  
Jump to Lab 05 if you want the most operations-focused workflow in the repo.

---

## What gets built (final lab)

The final lab automates a full service provider L3VPN stack:

- ISIS multi-area underlay  
- MPLS + RSVP  
- iBGP with route reflector  
- PE–CE connectivity  
- VRF service (cust-a)  

All configuration is generated from structured data and deployed in stages.

End-to-end validation is included (CE to CE reachability confirmed).

---

## Deployment is staged

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

## Latest Lab

### Lab 05 – Policy-Driven BGP with Drift Detection

Lab 05 extends the series from service deployment into **policy-driven network behavior**.

It demonstrates:

- multi-AS BGP policy control across direct and transit paths
- render → collect → compare workflow before deployment
- safe policy deployment onto existing BGP topology
- CLI validation of routing outcomes after change
- post-deployment convergence checking for Lab 05-managed configuration

This is the first lab in the series focused not just on generating configuration, but on **controlling and verifying routing behavior safely**.

## Future Labs

This repository is designed as an evolving series.

Planned extensions include:

### Lab 06 – BGP-Based Transport Modeling
- Classful / segmented transport design
- Route propagation boundaries
- Service reachability across constrained domains
- Overlay behavior on non-uniform underlay

These labs extend the progression from single-domain automation toward multi-domain and policy-driven network design.

## Author

Network engineer focused on service provider technologies and automation.

Background includes:

- SP routing (ISIS, BGP, MPLS, L3VPN, L2VPN, SRv6)
- Multi-vendor environments
- Automation using Python and Ansible
- Contributor to technical content including Cisco Press and engineering blogs.