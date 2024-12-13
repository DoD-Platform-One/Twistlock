# Twistlock PCC Configuration Files


## Overview

This project stores the Prisma Cloud Compute (PCC) configuration files for the various Big Bang deployments. Combined with backup and restore scripts, it provides a repeatable means for deploying and maintaining PCC configurations as code.


## Project Structure

Each PCC deployment's configurations are stored in a folder respective to the Big Bang cluster:

```
configurations/
configurations/il2
configurations/il2/bb-sil-prod
```

The configurations are currently stored as JSON files generated by the output of [PCC API calls](https://prisma.pan.dev/api/cloud/cwpp).


## Supported Configuration Resources

Supported resources currently include:

- collections
- custom rules
- container runtime policies
- host runtime policies
- alert profiles
  - Note: these have secret tokens that need to be protected

Resources owned by `system` are intentially not backed up.


## Usage (how to backup and restore configurations)

**WIP**

The scripts used to backup and restore the configurations are currently in development, but will be either added to this repository or added upstream to the Big Bang [Twistlock project](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock).


### Resource Dependencies

You can choose to attempt to restore or clear the individual resources, but you then you have to take into account the dependencies yourself.

Runtime policies depend on both collections and custom rules, so you cannot remove a collection or custom rule that is being used. Conversely, you cannot add a runtime policy that depends on a custom rule or collection that does not exist.

Alert profiles depend on runtime policies that they trigger on. Runtime policies can be removed even if an alert profile depends on it, but this will modify the alert trigger. Once all policies that trigger an alert are removed, then the alert is set to trigger on ANY runtime policy.