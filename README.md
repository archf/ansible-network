# ansible-network

Configure network devices on a target host.

## Requirements

### Ansible version

Minimum required ansible version is 2.0.

### Other considerations

For real devices, you must know your devices' names beforehand. You also need
to have `python-netaddr` on your control machine.

```bash
sudo pip install python-netaddr
```


## Description


Configure network devices on a target host. This roles aims to provide a seemless
rhel or debian derivatives configuration experience.

### Templates

There are 4 templates.

For FEDORA | RHEL | CENTOS
  * Redhat_routes.j2      -> routes-* configuration files
  * Redhat_device.j2      -> ifcfg-* device files in `/etc/sysconfig/network-scripts/`

For DEBIAN | UBUNTU
  * Debian_interfaces.j2  -> main file `/etc/network/interfaces`
  * Debian_devices.j2     -> device file that goes in `/etc/network/interfaces.d/`

### Configuration table

List of variables to describing a device

```
| variable      | description                                        | value               | type |
|---------------|----------------------------------------------------|---------------------|------|
| device        | device name                                        | <name>              | dict |
| type          | device type                                        | see type table      | dict |
| stp           | on by default, force stp off when device == bridge | on,off              | dict |
| bridge        | specify bridge to attach device to                 | <name>              | dict |
| bootproto     | specify boot protocol                              | static or none,dhcp | dict |
| onboot        | bring up at boot time                              | yes,no              | dict |
| gw            | gateway list of ipv4 and ipv6 cidr                 | <gateway ip>        | dict |
| ips           | list of ipv4 and ipv6 cidr                         | cidr                | list |
| delay         | wait time for bridge to join network               | <seconds>           | dict |
| peerdns       | use dns from option 6 (will overwite resolv.conf   | yes,no              | dict |
| dns           | list of dns to override resolv.conf with           | see example         | list |
| linkdelay     | wait time for ethernet, (stp converence)           | <seconds>           | dict |
| routes        | list of static routes to add                       | see routes table    | list |
| ipv6_init     | enable ipv6                                        | yes,no              | dict |
| ipv6_fatal    | disable device on failure                          | yes,no              | dict |
| ipv4_fatal    | disable device on failure                          | yes,no              | dict |
| ipv6_autoconf | stateless configuration                            | yes,no              | dict |
| ipv6_router   | node is an ipv6 router (enables ipv6 forwarding)   | yes,no              | dict |
```

* type=ovsbridge is supported
* stp is always enabled for bridge devices unless you explicitly turn it off
* `bootproto` defaults to 'dhcp' if ommited
* gw is also used by ip route to set the gateway
* if list contains multiple ips, secondary ips will be add
* if and ipv6 addr is not in cidr notation, will default to a /64 prefix.
* ipv6 is always enabled.

Device types

```
| value     | description                   |
|-----------|-------------------------------|
| Ethernet  | real physical ethernet device |
| Bridge    | built-in linux bridge         |
| ovsbridge | openvswitch bridge            |
| bond      | bond several devices together |
| 6to4      | 6to4 tunnel                   |
```

_Notes_
  * bond support not yet implemented
  * to detrunk a vlan, simply create a device using `<device name>.<vlan_id>` as device name

*Routes*

```
| Variables | description  | value                                       | type |
|-----------|--------------|---------------------------------------------|------|
| to        | route target | cidr ip (or any value accepted by ip route) | dict |
| gw        | gw device    | /32 ip address*                             | dict |
```

Notes:
  * if no specific gw is provided, it will default to the device gateway
  * to avoid duplicate default gateway, routes are defined for each devices based on subnet and subnet mask

### Interesting Tips

¡This sections needs a cleanup!

List all fedora|rhel|centos usable device options.

```bash
cd /etc/sysconfig/network-scripts && grep -r -E -o '\{[a-zA-Z0-9]+\}'  | grep -E -i -I -v 'device|1|2|down|ppp|down' | uniq -u
```

```bash
# quick nating using nftables wip
sudo nft add table nat
sudo nft add chain nat prerouting { type nat hook prerouting priority 0 \; }
sudo nft add rule nat postrouting masquerade
```

*lxc bridge nating*

Replace vars with according to your needs.

```bash
LXC_BRIDGE=lxcbr0
LXC_NETWORK=192.168.0.1
use_iptables_lock="-w"
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables $use_iptables_lock -I INPUT -i ${LXC_BRIDGE} -p udp --dport 67 -j ACCEPT
iptables $use_iptables_lock -I INPUT -i ${LXC_BRIDGE} -p tcp --dport 67 -j ACCEPT
iptables $use_iptables_lock -I INPUT -i ${LXC_BRIDGE} -p udp --dport 53 -j ACCEPT
iptables $use_iptables_lock -I INPUT -i ${LXC_BRIDGE} -p tcp --dport 53 -j ACCEPT
iptables $use_iptables_lock -I FORWARD -i ${LXC_BRIDGE} -j ACCEPT
iptables $use_iptables_lock -I FORWARD -o ${LXC_BRIDGE} -j ACCEPT
iptables $use_iptables_lock -t nat -A POSTROUTING -s ${LXC_NETWORK} ! -d ${LXC_NETWORK} -j MASQUERADE
iptables $use_iptables_lock -t mangle -A POSTROUTING -o ${LXC_BRIDGE} -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill
```

*enable ipv6 forwarding on bridge*

```bash
LXC_BRIDGE=lxcbr0
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
echo 2 > /proc/sys/net/ipv6/conf/all/accept_ra
echo 1 > /proc/sys/net/ipv6/conf/all/accept_ra_from_local
s sysctl -w net.ipv6.conf.all.accept_ra_from_local=1
s sysctl -w net.ipv6.conf.all.accept_ra_defrtr=1

echo 1 > /proc/sys/net/ipv6/conf/${LXC_BRIDGE}/forwarding
echo 2 > /proc/sys/net/ipv6/conf/${LXC_BRIDGE}/accept_ra
s sysctl -w net.ipv6.conf.lxcbr0.accept_ra_from_local=1

echo 0 > /proc/sys/net/ipv6/conf/${LXC_BRIDGE}/autoconf
echo 0 \> /proc/sys/net/ipv6/conf/\${LXC\_BRIDGE}/accept\_dad || true

LXC_BRIDGE=lxcbr0
LXC_IPV6_NETWORK=fd56:db20:4808:25ae::/64
use_iptables_lock="-w"
ip6tables $use_iptables_lock -I INPUT -i ${LXC_BRIDGE} -p udp --dport 67 -j ACCEPT
ip6tables $use_iptables_lock -I INPUT -i ${LXC_BRIDGE} -p tcp --dport 67 -j ACCEPT
ip6tables $use_iptables_lock -I INPUT -i ${LXC_BRIDGE} -p udp --dport 53 -j ACCEPT
ip6tables $use_iptables_lock -I INPUT -i ${LXC_BRIDGE} -p tcp --dport 53 -j ACCEPT
ip6tables $use_iptables_lock -I FORWARD -i ${LXC_BRIDGE} -j ACCEPT
ip6tables $use_iptables_lock -I FORWARD -o ${LXC_BRIDGE} -j ACCEPT
ip6tables $use_iptables_lock -t nat -A POSTROUTING -s ${LXC_IPV6_NETWORK} ! -d ${LXC_IPV6_NETWORK} -j MASQUERADE
```


## Role Variables

### Variables conditionally loaded

Those variables from `vars/*.{yml,json}` are loaded dynamically during task
runtime using the `include_vars` module.

Variables loaded from `vars/main.yml`.

```yaml
# vars file for network

```

Variables loaded from `vars/Debian.yml`.

```yaml
network_pkgs:
  - bridge-utils
  - ifenslave

network_ovs_service: openvswitch-nonetwork.service
network_ovs_pkg: openvswitch-switch

network_conf_path: "/etc/network/interfaces.d"
network_device_file_prefix: ''

```

Variables loaded from `vars/RedHat.yml`.

```yaml
network_pkgs:
  - libselinux-python
  - bridge-utils
  - iputils

network_ovs_service: openvswitch.service
network_ovs_pkg: openvswitch

network_conf_path: "/etc/sysconfig/network-scripts"
network_device_file_prefix: "ifcfg-"

```

### Default vars

Defaults from `defaults/main.yml`.

```yaml
# defaults file for network

network_pkg_state: latest

# device defaults
network_onboot: 'yes'
network_peerdns: 'no'
network_device_type: Ethernet

# ethernet defaults
network_ethernet_linkdelay: 1

# bridge defaults
network_bridge_delay: 1

# ipv4 defaults
network_ipv4_fatal: 'no'

# RHEL ipv6 defaults
network_ipv6_init: 'yes'
network_ipv6_fatal: 'no'
network_ipv6_autoconf: 'no'
network_ipv6_router: 'no'
network_ipv6_forwarding: 'no'

# Debian ifupdown ipv6 defaults
# see http://manpages.ubuntu.com/manpages/wily/en/man5/interfaces.5.html

# accept_ra default value differ according to method
#   dhcp -> 1
#   static -> 2
#   auto -> 2
network_accept_ra: 1        # (0=off, 1=on, 2=on+forwarding)
network_dhcp: 0             # auto method -> use stateless DHCPv6 (0=off, 1=on)

network_autoconf: 0         # Perform stateless autoconfiguration (0=off, 1=on)
network_dad_attempts: 60    # Number of attempts to settle DAD (0 to disable)
network_dad_interval: 0.1   # DAD state polling interval in seconds

# prevent deletion on cleanup
network_unmanaged_devices:
  - lo
  - ovs-system
  - vboxnet0
  - vibr0

```


## Installation

### Install with Ansible Galaxy

```shell
ansible-galaxy install archf.network
```

Basic usage is:

```yaml
- hosts: all
  roles:
    - role: archf.network
```

### Install with git

If you do not want a global installation, clone it into your `roles_path`.

```shell
git clone git@github.com:archf/ansible-network.git /path/to/roles_path
```

But I often add it as a submdule in a given `playbook_dir` repository.

```shell
git submodule add git@github.com:archf/ansible-network.git <playbook_dir>/roles/network
```

As the role is not managed by Ansible Galaxy, you do not have to specify the
github user account.

Basic usage is:

```yaml
- hosts: all
  roles:
  - role: network
```

## Ansible role dependencies

None.

## Todo

  * improve route template (scope & type support)
  * improve device handler -> reconfigure live ip addr with ip commands
  * improve device handler -> reconfigure live routes with ip commands
  * make it work on ubuntu//debian

## License

MIT.

## Author Information

Felix Archambault.

## Role stack

This role was carefully selected to be part an ultimate deck of roles to manage
your infrastructure.

All roles' documentation is wrapped in this [convenient guide](http://127.0.0.1:8000/).


---
This README was generated using ansidoc. This tool is available on pypi!

```shell
pip3 install ansidoc

# validate by running a dry-run (will output result to stdout)
ansidoc --dry-run <rolepath>

# generate you role readme file
ansidoc <rolepath>
```

You can even use it programatically from sphinx. Check it out.