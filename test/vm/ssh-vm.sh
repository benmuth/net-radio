#!/bin/bash
# SSH into the VM
exec ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222 user@localhost "$@"
