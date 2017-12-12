#!/bin/sh

./whatwg.org/convert-policy.py ../sg/SG\ Policy.md whatwg.org/policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/sg-policy
./whatwg.org/convert-policy.py ../sg/Workstream\ Policy.md whatwg.org/policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/workstream-policy
./whatwg.org/convert-policy.py ../sg/SG\ Agreement.md whatwg.org/policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/sg-agreement
./whatwg.org/convert-policy.py ../sg/Principles.md whatwg.org/policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/principles
./whatwg.org/convert-policy.py ../sg/IPR\ Policy.md whatwg.org/policy-template.html ../sg/policy-link-mapping.txt  > whatwg.org/ipr-policy

