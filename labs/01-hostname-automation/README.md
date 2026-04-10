# Lab 01 - Hostname Automation

## Objective

Automate hostname configuration on multiple Juniper devices using Ansible.

This is the starting point of the project and introduces:
- inventory structure
- basic config deployment
- commit workflow
- simple validation

---

## Lab environment

You can run this lab against any compatible Junos environment.

For this walkthrough, I used Juniper Cloud Labs (JCL), specifically the OSPF Multi-Area topology:

`https://jlabs.juniper.net/vlabs/portal/ospf-multi-area/index.page`

If you already have access to other Junos routers, that is fine too. This lab only needs:
- reachable devices
- NETCONF access
- valid credentials

---

## What this lab shows

This lab is intentionally simple.

You will:
- connect to multiple routers
- apply a hostname based on the inventory name
- commit the change
- verify the result

No templates, no staging, no complexity — just the core workflow.

---

## Prerequisites

- Python 3.10+
- Ansible installed via `requirements.txt`
- Access to Juniper devices
- NETCONF enabled on devices

---

## Files used

- `playbooks/set_hostname.yml`
- `inventory/lab_access.yml`

---

## Inventory (JCL lab access)

This lab uses a dynamic inventory file based on Juniper Cloud Labs (JCL).

JCL environments provide:

- a shared IP address
- a unique port per device

When the lab respins, both the IP address and ports change.

## Inventory file

- `inventory/lab_access.yml`

```yaml
Example

all:
  children:
    junos:
      hosts:
        r1:
          ansible_host: 66.129.235.201
          ansible_port: 47009
        r2:
          ansible_host: 66.129.235.201
          ansible_port: 47012
        r3:
          ansible_host: 66.129.235.201
          ansible_port: 47015
        r4:
          ansible_host: 66.129.235.201
          ansible_port: 47018
        r5:
          ansible_host: 66.129.235.201
          ansible_port: 47021
        r6:
          ansible_host: 66.129.235.201
          ansible_port: 47024
```

You must update this file before running any playbooks.

The port pattern is often sequential, but always verify the active IP/port assignments from the JCL portal.

## Host naming model

In this lab, the hostname is derived directly from the inventory host name.

Examples:

r1 → r1
r2 → r2
r3 → r3

This keeps the first lab simple and avoids introducing extra per-device data before it is needed.

More structured per-device data is introduced in later labs.

## Playbook flow

The playbook:

- connects to the device using NETCONF
- applies the hostname configuration
- commits the change
- verifies the result

## How to run it

### 1. Activate the environment

```bash
source .venv/bin/activate
```

### 2. Update the inventory

Edit `inventory/lab_access.yml` with the current IP address and ports from your JCL lab.

### 3. Test NETCONF access

Before running the playbook, verify that the router accepts a NETCONF session.

Example for r1:

```bash
ssh -p 47009 jcluser@66.129.235.201 -s netconf
```

If this works, you should see the NETCONF <hello> output.

### 4. (Optional): Inventory sanity check

You can verify that Ansible is reading the inventory correctly:

```bash
ansible all -i inventory/lab_access.yml -m ping
```

### 5. Run the playbook

This lab uses an interactive password prompt at runtime.

When the playbook starts, enter the device password from your JCL lab email.

Test one router first:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/set_hostname.yml --limit r1
```

Then run the full group:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/set_hostname.yml
```

## Expected result

Each router will have its hostname updated.

Example verification on the device:

```bash
show configuration system host-name
```

Example output:

```bash
system {
    host-name r1;
}
```

## Validation

The playbook includes a verification step and prints the resulting hostname configuration.

Example output:

```bash
set system host-name r1
```

You can also log into the router and confirm the hostname manually.

## Notes

- Uses NETCONF (no CLI scraping)
- Applies configuration using load: set
- Focuses on a single change to keep the workflow clear
- Inventory is based on the JCL IP + port model
- Lab respins require manual inventory updates

## Why this matters

This is the foundation for everything that follows.

Later labs build on the same ideas to:

- generate configs from templates
- deploy routing protocols
- orchestrate multi-stage changes
- validate intended outcomes

---



