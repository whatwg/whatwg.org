#!/bin/sh

./convert-policy.py ../sg/SG\ Policy.md policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/sg-policy
./convert-policy.py ../sg/Workstream\ Policy.md policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/workstream-policy
./convert-policy.py ../sg/SG\ Agreement.md policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/sg-agreement
./convert-policy.py ../sg/Principles.md policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/principles
./convert-policy.py ../sg/IPR\ Policy.md policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/ipr-policy

