# Lab 05 – Verification

## Purpose

This document verifies that policy-driven BGP behavior is functioning as designed.

Specifically:
- AS64544 prefixes are reachable via both direct and transit paths
- policy enforces preference of transit over direct paths
- export policies correctly control advertised prefixes

---

## 1. Verify AS64544 Prefix Advertisement

### vMX5 → AS64522 (direct edge)

```bash
show route advertising-protocol bgp 10.100.25.1
show route advertising-protocol bgp 10.100.35.1
```

Output:
```bash
jcluser@vMX5> show route advertising-protocol bgp 10.100.25.1 

inet.0: 18 destinations, 30 routes (18 active, 0 holddown, 0 hidden)
  Prefix		  Nexthop	       MED     Lclpref    AS path
* 10.100.56.0/24          Self                                    I
* 10.100.100.5/32         Self                                    I
* 10.100.100.6/32         Self                 1                  I
jcluser@vMX5> show route advertising-protocol bgp 10.100.35.1    

inet.0: 18 destinations, 30 routes (18 active, 0 holddown, 0 hidden)
  Prefix		  Nexthop	       MED     Lclpref    AS path
* 10.100.56.0/24          Self                                    I
* 10.100.100.5/32         Self                                    I
* 10.100.100.6/32         Self                 1                  I
```

## 2. Verify Both Paths Are Received on AS64522
Direct path (AS64544 → AS64522)
show route receive-protocol bgp 10.100.25.2 10.100.56.0/24 detail

Output:
```bash
jcluser@vMX2> show route receive-protocol bgp 10.100.25.2 10.100.56.0/24 detail 

inet.0: 19 destinations, 25 routes (19 active, 0 holddown, 0 hidden)
  10.100.56.0/24 (3 entries, 1 announced)
     Accepted
     Nexthop: 10.100.25.2
     AS path: 64544 I 
```

Transit path (AS64544 → AS64533 → AS64522)
show route receive-protocol bgp 10.100.24.2 10.100.56.0/24 detail

Output:
```bash
jcluser@vMX2> show route receive-protocol bgp 10.100.24.2 10.100.56.0/24 detail 

inet.0: 19 destinations, 25 routes (19 active, 0 holddown, 0 hidden)
* 10.100.56.0/24 (3 entries, 1 announced)
     Accepted
     Nexthop: 10.100.24.2
     AS path: 64533 64544 I 
```

Loopback validation (optional but recommended)
show route receive-protocol bgp 10.100.25.2 10.100.100.6/32 detail
show route receive-protocol bgp 10.100.24.2 10.100.100.6/32 detail

Output:
```bash
jcluser@vMX2> show route receive-protocol bgp 10.100.25.2 10.100.100.6/32 detail 

inet.0: 19 destinations, 25 routes (19 active, 0 holddown, 0 hidden)
  10.100.100.6/32 (3 entries, 1 announced)
     Accepted
     Nexthop: 10.100.25.2
     MED: 1
     AS path: 64544 I
jcluser@vMX2> show route receive-protocol bgp 10.100.24.2 10.100.100.6/32 detail 

inet.0: 19 destinations, 25 routes (19 active, 0 holddown, 0 hidden)
* 10.100.100.6/32 (3 entries, 1 announced)
     Accepted
     Nexthop: 10.100.24.2
     AS path: 64533 64544 I
```

## 3. Verify Best Path Selection
show route 10.100.56.0/24 detail

Output:
```bash
jcluser@vMX2> show route 10.100.56.0/24 detail 

inet.0: 19 destinations, 25 routes (19 active, 0 holddown, 0 hidden)
10.100.56.0/24 (3 entries, 1 announced)
        *BGP    Preference: 170/-251
                Next hop type: Router, Next hop index: 595
                Address: 0x8497794
                Next-hop reference count: 6, Next-hop session id: 323
                Kernel Table Id: 0
                Source: 10.100.24.2
                Next hop: 10.100.24.2 via ge-0/0/0.0, selected
                Session Id: 323
                State: <Active Ext>
                Local AS: 64522 Peer AS: 64533
                Age: 30:00 
                Validation State: unverified 
                Task: BGP_64533.10.100.24.2
                Announcement bits (3): 0-KRT 4-BGP_RT_Background 5-Resolve tree 1 
                AS path: 64533 64544 I 
                Accepted
                Localpref: 250
                Router ID: 10.100.100.4
                Thread: junos-main 
         BGP    Preference: 170/-251
                Next hop type: Indirect, Next hop index: 0
                Address: 0x8498894
                Next-hop reference count: 3
                Kernel Table Id: 0
                Source: 10.100.100.3
                Next hop type: Router, Next hop index: 362
                Next hop: 100.123.0.1 via fxp0.0, selected
                Session Id: 0
                Protocol next hop: 10.100.34.2
                Indirect next hop: 0x84de878 - INH Session ID: 0
                Indirect next hop: INH non-key opaque: 0x0 INH key opaque: 0x0
                State: <NotBest Int Ext Changed>
                Inactive reason: Not Best in its group - Interior > Exterior > Exterior via Interior
                Local AS: 64522 Peer AS: 64522
                Age: 30:00 	Metric2: 0 
                Validation State: unverified 
                Task: BGP_64522.10.100.100.3
                AS path: 64533 64544 I 
                Accepted
                Localpref: 250
                Router ID: 10.100.100.3
                Thread: junos-main 
         BGP    Preference: 170/-176
                Next hop type: Router, Next hop index: 596
                Address: 0x8498314
                Next-hop reference count: 3, Next-hop session id: 322
                Kernel Table Id: 0
                Source: 10.100.25.2
                Next hop: 10.100.25.2 via ge-0/0/1.0, selected
                Session Id: 322
                State: <Ext>
                Inactive reason: Local Preference
                Local AS: 64522 Peer AS: 64544
                Age: 30:16 
                Validation State: unverified 
                Task: BGP_64544.10.100.25.2
                AS path: 64544 I 
                Accepted
                Localpref: 175
                Router ID: 10.100.100.5
                Thread: junos-main 
```

show route 10.100.100.6/32 detail
Output:
```bash
jcluser@vMX2> show route 10.100.100.6/32 detail 

inet.0: 19 destinations, 25 routes (19 active, 0 holddown, 0 hidden)
10.100.100.6/32 (3 entries, 1 announced)
        *BGP    Preference: 170/-251
                Next hop type: Router, Next hop index: 595
                Address: 0x8497794
                Next-hop reference count: 6, Next-hop session id: 323
                Kernel Table Id: 0
                Source: 10.100.24.2
                Next hop: 10.100.24.2 via ge-0/0/0.0, selected
                Session Id: 323
                State: <Active Ext>
                Local AS: 64522 Peer AS: 64533
                Age: 31:59 
                Validation State: unverified 
                Task: BGP_64533.10.100.24.2
                Announcement bits (3): 0-KRT 4-BGP_RT_Background 5-Resolve tree 1 
                AS path: 64533 64544 I 
                Accepted
                Localpref: 250
                Router ID: 10.100.100.4
                Thread: junos-main 
         BGP    Preference: 170/-251
                Next hop type: Indirect, Next hop index: 0
                Address: 0x8498894
                Next-hop reference count: 3
                Kernel Table Id: 0
                Source: 10.100.100.3
                Next hop type: Router, Next hop index: 362
                Next hop: 100.123.0.1 via fxp0.0, selected
                Session Id: 0
                Protocol next hop: 10.100.34.2
                Indirect next hop: 0x84de878 - INH Session ID: 0
                Indirect next hop: INH non-key opaque: 0x0 INH key opaque: 0x0
                State: <NotBest Int Ext Changed>
                Inactive reason: Not Best in its group - Interior > Exterior > Exterior via Interior
                Local AS: 64522 Peer AS: 64522
                Age: 31:59 	Metric2: 0 
                Validation State: unverified 
                Task: BGP_64522.10.100.100.3
                AS path: 64533 64544 I 
                Accepted
                Localpref: 250
                Router ID: 10.100.100.3
                Thread: junos-main 
         BGP    Preference: 170/-176
                Next hop type: Router, Next hop index: 596
                Address: 0x8498314
                Next-hop reference count: 3, Next-hop session id: 322
                Kernel Table Id: 0
                Source: 10.100.25.2
                Next hop: 10.100.25.2 via ge-0/0/1.0, selected
                Session Id: 322
                State: <Ext>
                Inactive reason: Local Preference
                Local AS: 64522 Peer AS: 64544
                Age: 32:15 	Metric: 1 
                Validation State: unverified 
                Task: BGP_64544.10.100.25.2
                AS path: 64544 I 
                Accepted
                Localpref: 175
                Router ID: 10.100.100.5
                Thread: junos-main 
```

## 4. Expected Behavior

Verification confirms that:

- AS64544 prefixes are received via both direct and transit paths
- the transit-learned path is selected as best due to higher local preference (250 vs 175)
- the direct path remains present but inactive due to lower local preference

Key attributes:

Path Type	Source	Local Preference	Expected Role
Transit	    AS64533	250	                Preferred
Direct	    AS64544	175	                Backup

## 5. Conclusion

Verification confirms that:

policy correctly influences BGP path selection
transit path is preferred over direct path
direct path remains available as fallback
export policies correctly control prefix advertisement

This validates the Lab 05 policy-driven design.


---

# 🧠 Why this structure works

This is not just “some outputs” — it tells a story:

1. **Are prefixes being advertised?**
2. **Are they received on both paths?**
3. **Which path wins?**
4. **Does that match intent?**

That’s real operator-grade verification.

---