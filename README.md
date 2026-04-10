# SP L3VPN Automation Lab (Juniper vLabs)

A hands-on network automation project built on Juniper vLabs.

This repo walks through a progression from basic Ansible tasks to a full service provider L3VPN deployment using structured data, templating, and staged rollout.

The goal is simple:
build something that looks closer to real operations than “run this playbook and hope”.

---

## What this project is

This is not a collection of random playbooks.

It is a structured progression showing how to move from:
- simple device changes  
to  
- controlled service deployment  

Each lab builds on the previous one and introduces a new layer of operational thinking.

| Lab | Focus                               | What it shows                                                         |
|-----|-------------------------------------|-----------------------------------------------------------------------|
| 01 | Hostname automation                  | Basic inventory, NETCONF access, and first config push                |
| 02 | Config backup and controlled restore | State capture, lab rebuilds, and controlled config replacement        |
| 03 | Controlled OSPF to ISIS migration    | Staged rendering, explicit protocol removal, and idempotent migration |
---

## Lab progression

| Lab | Focus | What it shows |
|-----|------|----------------|
| 01 | Hostname automation | Basic inventory, variables, and first config push |
| 02 | Config backup / restore | Operational safety and state capture |
| 03 | OSPF → ISIS migration | Controlled change and staged rollout |
| 04 | SP L3VPN deployment | Full underlay + overlay + service automation |

Start at Lab 01 if you are new to this.  
Jump to Lab 04 if you just want the full build.

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

## How it works

This project is built around a few key ideas:

### 1. Data first

Device configs are generated from structured data (`host_vars`, `group_vars`), not hardcoded CLI.

### 2. Templates, not copy/paste

Jinja templates are used to render:
- base config
- BGP overlay
- VPN services

### 3. Staged deployment

The network is not pushed in one go.

Typical flow:
1. Base / CE prep  
2. Underlay readiness  
3. BGP overlay  
4. VPN services  
5. Validation  

### 4. Operational awareness

- Configs are rendered before deployment  
- Merge vs set workflows are both supported  
- Rollback is commit-aware (not blind rollback 1)  
- Redeploy is used as a recovery strategy when needed  

---

## Repository structure

labs/
  01-hostname-automation/
  02-config-backup-and-restore/
  03-ospf-to-isis-migration/
  04-sp-l3vpn-on-isis-multi-area/

inventory/
host_vars/
group_vars/
templates/
roles/
playbooks/
docs/

Each lab contains its own README with exact steps and expected results.

## Getting started

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Update your inventory with device IPs and credentials, then run the playbooks from the relevant lab.

## Platform choice

This project uses Juniper vLabs for hands-on access.

The focus is not on the vendor CLI, but on:

- automation patterns
- data modelling
- deployment workflow

The same approach can be applied to other platforms.

## Why this exists

Most automation examples stop at:
“push config to device”

Real networks don’t work like that.

## This project is about:

- building configs from data
- deploying in stages
- validating outcomes
- having a recovery approach

## Author

Network engineer focused on service provider technologies and automation.

Background includes:

- SP routing (ISIS, BGP, MPLS, L3VPN, L2VPN, SRv6)
- Multi-vendor environments
- Automation using Python and Ansible
- Contributor to technical content including Cisco Press and engineering blogs.

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

## Future work
- automated validation checks
- CI linting / testing
- additional labs, services and VRFs
- deeper abstraction into reusable roles