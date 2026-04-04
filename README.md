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