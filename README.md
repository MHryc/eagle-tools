# eagle-tools.sh

Several small bash scripts that I frequently use on HPCs. Wrapped into a tools
with subcommands and getopts for convinience

```
usage: eagle-tools.sh [-h] {pinfo,cbf} ...

Subcommands:
pinfo   Get information about available partitions (name, nodes, cpus,
        memory/node). Takes no arguments.

cbf     "Compare Big File", computes a md5sum of N initial lines (default is
        1000, can be specified by -s N). Run with -h for help. Gzipped files
        MUST be passed with -g option
```
