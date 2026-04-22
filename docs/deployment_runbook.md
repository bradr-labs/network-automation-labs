# ISIS Multi-Area Lab – Building Deployment Runbook

## Overview

This runbook describes how to safely deploy rendered configurations to the Juniper vLabs environment step by step.

IMPORTANT:

* Never use `load: override` unless you intend to fully replace the device config.
* The lab base config contains authentication and access settings.
* Always use `merge` for `.conf` files and `set` for `.set` files.

---

## Config Types

| Type         | Location              | Load Mode |
| ------------ | --------------------- | --------- |
| Base / CE    | `rendered/.../*.conf` | merge     |
| BGP Overlay  | `rendered/.../*.set`  | set       |
| VPN Services | `rendered/.../*.set`  | set       |

---

## Playbooks

| Purpose            | Playbook                            |
| ------------------ | ----------------------------------- |
| Merge full config  | `playbooks/load_rendered_merge.yml` |
| Apply set commands | `playbooks/load_rendered_set.yml`   |

---

## Deployment Order

Deploy in stages to avoid breaking the lab.

### Phase 1 – Customer Edge

```
r4 → r6
```

### Phase 2 – Core Transport

```
r1 → r2
```

### Phase 3 – Provider Edge

```
r3 → r5
```

---

## Commands

### 1. Load CE (example: r4)

ansible-playbook -i inventory/lab_access.yml playbooks/load_rendered_merge.yml --limit r4 -e "cfg_file=../rendered/isis_multi_area/ce/lab-r4.conf"

---

### 2. Load Base (example: r3)

ansible-playbook -i inventory/lab_access.yml playbooks/load_rendered_merge.yml --limit r3 -e "cfg_file=../rendered/isis_multi_area/base/lab-r3.conf"

---

### 3. Load BGP Overlay (example: r3)

ansible-playbook -i inventory/lab_access.yml playbooks/load_rendered_set.yml --limit r3 -e "cfg_file=../rendered/isis_multi_area/bgp/lab-r3.set"

---

### 4. Load VPN Services (example: r3)

ansible-playbook -i inventory/lab_access.yml playbooks/load_rendered_set.yml --limit r3 -e "cfg_file=../rendered/isis_multi_area/vpn/lab-r3.set"

---

## Verification Checklist

### After Base

* Interfaces up
* Management reachable
* ISIS adjacencies up

### After BGP

* `show bgp summary`
* RR/client sessions established

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

### After VPN

* `show route instance`
* `show route table cust-a.inet.0`
* CE routes visible
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

jcluser@lab-r4> ping 192.168.6.6    
PING 192.168.6.6 (192.168.6.6): 56 data bytes
64 bytes from 192.168.6.6: icmp_seq=0 ttl=61 time=5.578 ms
64 bytes from 192.168.6.6: icmp_seq=1 ttl=61 time=2.749 ms
^C
--- 192.168.6.6 ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
round-trip min/avg/max/stddev = 2.749/4.163/5.578/1.415 ms



---

## Golden Rules

1. **Never use override in vLabs**
2. **Always deploy in stages**
3. **One router at a time**
4. **Verify before moving on**
5. **If unsure, stop and check**

---

## Recovery

If something breaks:

* Reload original config (from backup)
* Or respin lab

---

## Notes

* CE routers do NOT run ISIS/MPLS
* VRF name: `cust-a`
* BGP RR: `lab-r2`
* P routers: `lab-r1`
* PE routers: `lab-r3`, `lab-r5`


# One-command SP L3VPN Deployment (ISIS Multi-Area Topology)

## Overview

This deployment builds a full **Service Provider L3VPN network** on top of the Juniper JCL `isis_multi_area` topology.

### Components deployed

* ISIS underlay (transport)
* MPLS / RSVP forwarding
* iBGP Route Reflector (r2)
* Provider Edge routers (r3, r5)
* Customer Edge routers (r4, r6)
* VRF-based L3VPN service (`cust-a`)

---

## Deployment Model

Deployment is performed in **stages**, but executed via a **single orchestrated playbook**.

### Stages

1. **CE layer**

   * r4, r6
   * eBGP to PE
   * customer prefixes

2. **Base layer**

   * r1, r2, r3, r5
   * interfaces, ISIS, MPLS, RSVP

3. **BGP overlay**

   * r2 (RR), r3, r5
   * iBGP + route-reflection
   * global autonomous-system

4. **VPN services**

   * r3, r5
   * VRF (`cust-a`)
   * PE-CE eBGP

---

## Playbooks

| Purpose         | Playbook                                           |
| --------------- | -------------------------------------------------- |
| Full deployment | `playbooks/deploy_sp_l3vpn_on_isis_multi_area.yml` |
| CE stage        | `deploy_sp_l3vpn_on_isis_multi_area__ce.yml`       |
| Base stage      | `deploy_sp_l3vpn_on_isis_multi_area__base.yml`     |
| BGP overlay     | `deploy_sp_l3vpn_on_isis_multi_area__bgp.yml`      |
| VPN services    | `deploy_sp_l3vpn_on_isis_multi_area__vpn.yml`      |

---

## Deployment Command

Run the full deployment with:

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area.yml
```

---

## Important Notes

* Uses **merge** for `.conf` files (safe)
* Uses **set** for `.set` overlays
* Does **NOT** use `override` (prevents lockout)
* Deployment order is enforced by orchestrator

---

## Verification

### End-to-end test

From CE r4:

```bash
ping 192.168.6.6
```

Expected result:

* Successful replies from r6 customer network

---

### Key checks

#### On r3 / r5

```bash
show route table cust-a.inet.0
```

#### On r2

```bash
show bgp summary
```

#### On r4 / r6

```bash
show bgp summary
```

---

## Golden Rules

1. One command deploy — but staged internally
2. Never use override in vLabs
3. If something breaks → stop and verify
4. Always validate CE → CE reachability

---

## Last Verified Working

2026-04-09
End-to-end connectivity confirmed: `lab-r4 → 192.168.6.6`

---

---
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

```
0   VPN services
1   BGP overlay
2   base config
3   older config
```

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

* `rollback 1` may revert too far
* commit history may not match deployment stages

In this case, DO NOT rely on rollback alone.

Use redeploy instead.

---

## Step 3 – Preferred recovery order

### 1. Targeted rollback (best case)

Use when:

* commit history is clear
* you know which layer failed

---

### 2. Redeploy known-good configuration

```bash
ansible-playbook -i inventory/lab_access.yml playbooks/deploy_sp_l3vpn_on_isis_multi_area.yml
```

Use when:

* router state is inconsistent
* commit history is unclear
* multiple changes have been applied

---

### 3. Full reset (last resort)

Use JCL baseline reset only when:

* device is badly broken
* access/config is corrupted
* rollback/redeploy are insufficient

---

## Key Rules

1. Always run `show system commit` first
2. Never assume rollback numbers
3. Prefer **surgical rollback** over full reset
4. If unsure → redeploy instead of guessing

---

## Mental Model

* **Rollback** = undo last change(s)
* **Redeploy** = restore desired state
* **Reset** = wipe to factory baseline

Use the least destructive option first.

---
