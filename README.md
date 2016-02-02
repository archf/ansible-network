Role Name
=========

Configure network devices on a target host. This roles aims to provide a seemless
rhel or debian derivatives configuration experience. Templates are meant to
be modular and reusable.

Requirements
------------

For Ethernet devices, you must know your devices' names beforehand.

Role Variables
--------------

## Device variables

List of variables to describing a device:

| variable      | description                                      | value               | type |
|---------------|--------------------------------------------------|---------------------|------|
| device        | device name                                      | <name>              | dict |
| type          | device type                                      | <device type>       | dict |
| stp           | to force stp off when device == bridge           | on,off              | dict |
| bootproto     | specify boot protocol                            | static or none,dhcp | dict |
| onboot        | bring up at boot time                            | yes,no              | dict |
| gw            | gateway to use, also used by routes a default    | <gateway ip>        | dict |
| ips           | list of ips and prefix to use                    | see ips table       | list |
| prefix        | rules over undefined prefix in ips               | see ips             | dict |
| delay         | wait time for bridge to join network             | <seconds>           | dict |
| peerdns       | use dns from option 6 (will overwite resolv.conf | yes,no              | dict |
| dns           | list of dns to override resolv.conf with         | see example         | list |
| linkdelay     | wait time for ethernet, (stp converence)         | <seconds>           | dict |
| routes        | list of static routes to add                     | see routes table    | list |
| ipv6_init     | enable ipv6                                      | yes,no              | dict |
| ipv6_fatal    | disable device on failure                        | yes,no              | dict |
| ipv4_fatal    | disable device on failure                        | yes,no              | dict |
| ip6           | static ipv6 address to configure                 | <ipv6 cidr>         | list |
| ipv6_autoconf | stateless configuration                          | yes,no              | dict |
| ipv6_router   | node is an ipv6 router (enables ipv6 forwarding) | yes,no              | dict |

* stp is always enabled for bridge devices unless you explicitly turn it off
* `bootproto` defaults to 'dhcp' if ommited
* ipv6 is always enabled.
* see other defaults below

Variables `ips`:

| Variables | description    | value                 | type |
|-----------|----------------|-----------------------|------|
| ip        | <ipv4 address> | quad dotted ip        | dict |
| prefix    | subnet prefix  | integer in range 0-32 | dict |

If list contains multiple elements, aliases will be created

Variables `ip6`:

| Variables | description                        |
|-----------|------------------------------------|
| n/a       | ipv6 address list in cidr notation |

* Note: if addr not in cidr notation, will default to a /64 prefix.

routes:

| Variables | description  | value                                       | type |
|-----------|--------------|---------------------------------------------|------|
| to        | route target | cidr ip (or any value accepted by ip route) | dict |
| gw        | gw device    | /32 ip address*                             | dict |

* Note: if no gw is provided, it will default to the device gateway

## Defaults

Interface template is designed to minimise typing. Here are the defaults.

```yaml
# device defaults
network_onboot: 'yes'
network_peerdns: 'no'
network_device_type: Ethernet

# ethernet defaults
network_ethernet_linkdelay: 1

network_bridge_delay: 1

# ipv4 defaults
network_ipv4_fatal: 'no'

# ipv6 defaults
network_ipv6_init: 'yes'
network_ipv6_fatal: 'no'
network_ipv6_autoconf: 'no'
network_ipv6_router: 'no'
network_ipv6_forwarding: 'no'
```

You can map those variables to the matching unprefixed variable inside a device.

Dependencies
------------

python-netaddr.

Example Playbook
----------------

## Device configuration

You must define a network variable wich contain a list of devices.

For example:

And invoke your play as usual:

```yaml
- hosts: servers
  roles:
      - { role: archf.network }
```

Todo
------

* improve route template
  * scope support
  * type support
* make use of cidr notation everywhere and use python module netaddr
* improve device handler -> reconfigure a live ip interface with ip commands
* make it work on ubuntu//debian
* ovs support
* enable ipv6 nating on linux bridges
  * ipv6/conf/all/forwarding=1
  * /net/ipv6/conf/${BRIDGE}/autoconf=0
  * ip6tables -w -t nat -A POSTROUTING -s ${IPV6_NETWORK} ! -d ${IPV6_NETWORK} -j

PR welcomed !!!

License
-------

MIT

Author Information
------------------

Felix Archambault
