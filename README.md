# Junos Automation Lab (Ansible)

## Overview
This project automates configuration and validation of Juniper vMX routers using Ansible.

The lab supports full configuration deployment, configuration backup, and basic validation workflows.

---

## Features

- Push full configurations to multiple routers
- Pull running configurations from devices
- Automate hostname changes
- Support multi-device orchestration using inventory
- Uses NETCONF (no CLI scraping)

---

## Project Structure
ansible-lab/
├── inventory/ # device definitions and variables
├── group_vars/ # shared variables
├── playbooks/ # automation tasks
├── backups/ # pulled configs (ignored by git)
├── rendered/ # generated configs (ignored by git)
└── .venv/ # python environment (ignored)

---

## Requirements

- Python 3.11
- Ansible (>=10 recommended)
- Juniper Ansible collections
- NETCONF enabled on devices

---

## Usage

### Activate environment
source .venv/bin/activate

### Push full config
ansible-playbook -i inventory/hosts.yml playbooks/load_full_config.yml

### Pull configs
ansible-playbook -i inventory/hosts.yml playbooks/pull_full_config.yml

### Change hostnames
ansible-playbook -i inventory/hosts.yml playbooks/set_hostname.yml

---

## Notes

- Uses per-device ports for lab access
- Credentials are currently stored in playbooks (lab only)
- `.venv/`, `backups/`, and generated files are excluded from Git

---

## Future Improvements

- Jinja2 templates for config generation
- Data-driven topology definitions
- Config validation and drift detection

## Authentication
- Authentication is intentionally excluded from rendered lab templates because reapplying local auth blocks breaks new logins in the JCL environment

## Lab Workflows
OSPF Multi-area → ISIS Conversion

This workflow converts a Juniper OSPF Multi-area starter lab into an ISIS underlay using templated configuration and Ansible orchestration.

Key Concepts
- Topology data is defined in:
  - inventory/ospf_multi_area_hosts.yml
- Lab access (IP/port) is defined in:
  - inventory/lab_access.yml (changes per lab respin)
- Authentication is NOT templated (lab-managed)

Templates
- templates/ospf_multi_area_base.j2
- templates/ospf_multi_area_with_isis.j2

Playbooks
- playbooks/render_ospf_multi_area_with_isis.yml
- playbooks/ospf_multi_area_to_isis.yml

Workflow Steps
1. Activate environment
source .venv/bin/activate
2. Verify connectivity
ansible-playbook \
-i inventory/ospf_multi_area_hosts.yml \
-i inventory/lab_access.yml \
playbooks/test_connectivity.yml \
--limit r1
3. Render final configuration
ansible-playbook \
-i inventory/ospf_multi_area_hosts.yml \
-i inventory/lab_access.yml \
playbooks/render_ospf_multi_area_with_isis.yml \
--limit r1
4. Convert router from OSPF to ISIS
ansible-playbook \
-i inventory/ospf_multi_area_hosts.yml \
-i inventory/lab_access.yml \
playbooks/ospf_multi_area_to_isis.yml \
--limit r1
5. Repeat for additional routers
--limit r2
--limit r3

Safety Notes
- load override is avoided due to access issues in the lab environment

Workflow uses:
- explicit removal of OSPF
- merge of final config
- immediate verification
- Authentication config is intentionally excluded from templates
