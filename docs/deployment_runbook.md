# ISIS Multi-Area Lab – Deployment Runbook

## Overview

This runbook describes how to safely deploy rendered configurations to the Juniper vLabs environment.

⚠️ IMPORTANT:

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

---
