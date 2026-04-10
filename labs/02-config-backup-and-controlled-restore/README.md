# Lab 02 - Config Backup and Controlled Restore

## Objective

Back up the current configuration from Junos devices and then load a different known configuration set in a controlled lab workflow.

This lab introduces:
- configuration capture
- local backup storage
- controlled full-config replacement
- basic recovery and lab state management

---

## Lab environment

You can run this lab against any compatible Junos environment.

For this walkthrough, I used Juniper Cloud Labs (JCL). The same JCL IP + port inventory model from Lab 01 is used here.

This lab assumes:
- reachable Junos devices
- NETCONF enabled
- valid login credentials
- a prepared configuration file for each target device

---

## What this lab shows

This lab is about operational discipline.

You will:
- pull the current running configuration from each router
- save it locally per device
- load a different known config onto the router
- commit the new state

This makes it possible to preserve the current lab state before moving into another topology or workflow.

---

## Prerequisites

- Python 3.10+
- Ansible installed via `requirements.txt`
- Access to Juniper devices
- NETCONF enabled on devices
- A valid `inventory/lab_access.yml`
- Prepared replacement config files for the restore phase

---

## Files used

- `playbooks/pull_full_config.yml`
- `playbooks/restore_known_config.yml`
- `inventory/lab_access.yml`
- `backups/`
- `staging/`

---

## Inventory model

This lab uses the same JCL inventory model as Lab 01.

### Example

```yaml
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
```

### JCL uses:

- one shared IP
- a unique port per device

When the lab respins, update the inventory file before running any playbooks.

## Backup workflow

The backup workflow:

- connects to each router using NETCONF
- runs show configuration
- saves the output locally as a per-device .conf file

```text
Example output
backups/r1.conf
backups/r2.conf
backups/r3.conf
```

## Run backup

Test one router first:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/pull_full_config.yml --limit r1
```

Then run the full group:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/pull_full_config.yml
```

You will be prompted for the device password at runtime.

## Controlled restore workflow

The restore workflow loads a different known configuration file onto the router to move the lab into another prepared state.

This is useful when:

- moving into another lab state
- rebuilding a topology quickly
- loading a prepared configuration set for the next exercise

## Important

This workflow uses:

```text
load: override
```

That means the active configuration is fully replaced by the target file.

This is intentionally destructive and should be treated as a lab-only workflow.

### Restore config mapping

Each router must define a cfg_file value pointing to the configuration file that should be loaded.

In this project, cfg_file is defined directly in:

`inventory/lab_access.yml`

```yaml
Example
r1:
  ansible_host: 66.129.235.201
  ansible_port: 47009
  cfg_file: "../staging/vMX1-juniper.conf"
```

### How it works

- Each device defines its own cfg_file
- The restore playbook reads this variable
- The specified file is loaded onto that device

This allows per-router control of what configuration is applied.

### Staging configs

For this lab, staging configs are pre-saved from a previous lab state.

Example files
- `staging/vMX1-juniper.conf`
- `staging/vMX2-juniper.conf`
...

These files represent a known working topology and are used to quickly move between lab states.

### Notes

- cfg_file is required for each router when using the restore workflow
- File paths are resolved relative to the playbook location (playbooks/)
- This is why paths use ../staging/...
- Missing or incorrect paths will cause the playbook to fail before making changes

### Restore workflow

Test one router first:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/restore_known_config.yml --limit r1
```

Then run the full group:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/restore_known_config.yml
```

You will be prompted for the device password at runtime.

## Expected result
After backup:

The current running configuration is saved locally.

After restore:

The router is committed into the new target configuration state.

## Validation
Backup

Confirm that .conf files exist in:

`backups/`

## Restore

Verify on the device:

```markdown
```bash
show configuration system host-name
```

Or compare changes:

```markdown
```bash
show configuration | compare rollback 1
```

## Notes

- Uses NETCONF only
- Backup is non-destructive
- Restore uses full configuration replacement
- Test with --limit r1 before running against all devices
- Designed for lab use, not production workflows

## Why this matters

This lab moves beyond simple config pushes.

It shows how to:

preserve current state before change
move a lab into another known state
treat configuration as an operational artifact

This is closer to real-world automation than one-off task execution.