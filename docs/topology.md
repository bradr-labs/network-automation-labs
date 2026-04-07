# ISIS Multi-Area Lab (JCL-based)

## Device Mapping (JCL → Lab)

| JCL Name | Lab Name |
|----------|----------|
| vmx1     | lab-r1   |
| vmx2     | lab-r2   |
| vmx3     | lab-r3   |
| vmx4     | lab-r4   |
| vmx5     | lab-r5   |
| vmx6     | lab-r6   |

## Roles

- lab-r4, lab-r6 → customer / edge
- lab-r3, lab-r1, lab-r5 → SP transport
- lab-r2 → route reflector

## Design Notes

- Single ISIS Level 2 domain
- "Multi-area" name comes from JCL lab, not protocol design