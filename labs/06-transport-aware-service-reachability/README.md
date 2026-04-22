# Lab 06 — Transport-Aware Service Reachability

## Summary

This lab traces how a customer-facing service route is resolved for forwarding within the Juniper vLabs BGP-CT inter-domain topology.

Rather than modifying policy or rebuilding the control plane, the focus is on observing how a service is mapped onto the transport layer, identifying the transport class selected, and understanding how multiple transport paths (gold and bronze) are represented in the control plane.

The lab then demonstrates how removing the service classification at the source changes the transport outcome without breaking reachability, highlighting the dependency between service intent and transport selection.

Finally, the workflow provides a repeatable way for an operator to validate these behaviors across different states (for example, with and without service classification), rather than relying on manual static control-plane inspection or assumptions about forwarding behavior.

This lab focuses on understanding forwarding behavior, not just route presence.

## Background — vLabs BGP-CT inter-domain topology

This lab uses the Juniper vLabs BGP Classful Transport (BGP-CT) inter-domain topology.

See the topology reference here:
[Juniper vLabs – BGP Classful Transport Planes – Inter-Domain topology](https://jlabs.juniper.net/vlabs/portal/bgp-ct-inter-domain/)

At a high level, the topology models a multi-AS service provider network where:

- Customer services are advertised using standard BGP
- Transport paths are carried in a separate control plane (BGP transport families)
- Different transport classes (for example, *gold* and *bronze*) are exposed independently of the service routes

The design separates two concerns:

1. Service plane
   - Customer-facing routes (for example, `172.16.3.32/32`)
   - Standard BGP reachability and VPN routing
   - Service attributes such as `target` and `color`

2. Transport plane
   - Label-switched paths (LSPs) and transport reachability
   - Multiple transport classes (gold, bronze)
   - Carried in transport-specific RIBs (for example, `bgp.transport.3`, `junos-rti-tc-*`)

A key behavior of this topology is that:

- A service route can carry a color (for example, `color:0:100`)
- That color is used by the receiving PE to select a transport class
- The actual forwarding path is then resolved using the corresponding transport RIB

This allows the network to support:

- policy-driven path selection
- differentiated transport (premium vs best-effort)
- service-level intent without changing the underlying transport fabric

In other words, the topology demonstrates how:

> **Service intent is mapped to transport behavior, rather than being hardcoded into the forwarding plane.**

##  What this lab proves

This lab demonstrates how service intent drives transport selection in a modern network.

We can prove that:

- A service marked with a color (intent) is resolved over a specific transport class
- Removing that intent does NOT break connectivity
- But it does change how the network forwards traffic

---

##  Key takeaway

> Transport path selection is driven by service classification at the source — not by transport availability.

---

##  Why this matters

This is EXACTLY what modern networks are becoming - SR-TE mindset capable, intent-based routing based,  SLA transport aware and multi-plane forwarding. In real networks, this applies to:

- premium / low-latency traffic  
- financial systems  
- voice / video services  
- differentiated customer SLAs  

If intent is wrong, traffic still flows — but not as designed.

---

##  Lab topology (simplified)

```text
CE31 (AS64503)
↓ (service + color)
AS64501
↓
AS64502 (transport domain)
↓ (gold / bronze)
PE25
↓
CE41 (AS64504)
```

---

## Behavior demonstrated

### Baseline (gold service)

```text
Service: color:0:100
↓
Resolution scheme
↓
Gold transport selected
↓
Traffic uses gold LSPs
```

---

### Failure scenario (intent removed)

```text
Service: no color
↓
No mapping
↓
No gold transport selection
↓
Traffic still flows (but no SLA guarantee)
```

---
## How to run the lab

Run the validation playbook:

```bash
ansible-playbook playbooks/verify_lab06_transport_resolution.yml
```
You will be prompted for the device password used in the vLabs environment.

The playbook performs the following checks:


CE41
- Service reachability (ping)
- Customer-facing route attributes

PE25
- Service route resolution
- Transport class selection
- Presence of gold transport paths

ABR23
- Transport-plane visibility
- Gold and bronze transport class mapping

The output provides PASS/FAIL assertions for each stage, allowing you to quickly understand both service state and transport behavior.

## Customizing verification inputs

The playbook uses `labs/06-transport-aware-service-reachability/verification.yml` to define which devices and service to validate. You can adapt the lab to a different topology (when you launch your own vLab) by modifying this file.

### Service definition

```yaml
service:
  destination_ip: 172.16.3.32
  source_ip: 172.16.4.42
```
- destination_ip — the service being validated
- source_ip — the CE source used for reachability testing

### CE checks

```yaml
ce_checks:
  - device_name: CE41
    host: <host>
    port: <port>
```

Defines the CE used to validate:

- service reachability
- customer-facing route attributes

### PE checks

```yaml
pe_checks:
  - device_name: PE25
    host: <host>
    port: <port>
```

Defines the PE used to validate:

- transport-class resolution
- forwarding path selection

### Boundary checks

```yaml
boundary_checks:
  - device_name: ABR23
    host: <host>
    port: <port>
```

Defines the transport visibility point used to validate:

- presence of transport classes (gold / bronze)
- transport-plane state

### Notes

Device access details (host/port) depend on the vLabs instance and may change between sessions.
The structure of this file is intentionally simple to allow quick reuse across different labs or environments.

---

## Validation approach

This Ansible validation playbook checks:

- CE reachability
- Service route attributes (color)
- PE transport resolution
- Presence of gold paths
- Transport-plane state (ABR view)

---

## Example output

### Before (expected)

```text
ASSERT reachability -> PASS
ASSERT route color -> PASS
ASSERT transport class -> PASS
ASSERT gold path ABR23 -> PASS
ASSERT gold path ABR24 -> PASS
```

---

### After removing intent

```text
ASSERT reachability -> PASS
ASSERT route color -> FAIL
ASSERT transport class -> FAIL
ASSERT gold path ABR23 -> FAIL
ASSERT gold path ABR24 -> FAIL
ASSERT gold transport marker -> PASS
ASSERT bronze transport marker -> PASS
```

---

## What this proves

- The network is still operational
- Transport (gold/bronze) still exists
- Only the service classification changed

Therefore:

> The service no longer uses gold transport because the intent signal was removed at the source.

---

## ⚙️ How I triggered failure

On the service-originating device (CE31, AS64503 on the far right):

```bash
configure
delete policy-options policy-statement vpn term 1 then community add map2gold
commit
```
This removed:

color:0:100

## Engineering insight

This lab shows a critical real-world failure mode:

- Networks don’t always fail loudly
- They degrade silently when intent is missing

Validation must check:

what traffic is doing, not just if traffic works

## Structure

```text
playbooks/
  verify_lab06_transport_resolution.yml

inventory/
  lab_access.yml

docs/
  lab-06-notes.md
```

