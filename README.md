Role Name
=========

A brief description of the role goes here.

Requirements
------------

Create network bridge for lxc on fedora

cat ~/lxcbr0.xml
<network>
  <name>lxcbr0</name>
  <bridge name="lxcbr0"/>
  <forward/>
  <ip address="192.168.3.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.3.2" end="192.168.3.254"/>
    </dhcp>
  </ip>
</network>

sudo virsh net-define --file  ~/lxcbr0.xml
sudo virsh net-autostart lxcbr0
sudo virsh net-start lxcbr0

Role Variables
--------------

On fedora, redhat / centos

## ethernet interfaces

```yaml
network_ether:
    - device: enp0s8
      onboot: yes
      bootproto: static
      gw: 172.16.2.1
      prefix: 24
      ip: 172.16.2.150
      ips:
        - ip: 1.1.1.1.
          prefix: 24
        - ip: 2.2.2.2
          prefix: 26
      routes:
        - cidr: 10.247.0.0/16
          gw: 10.0.2.1
        - cidr: 10.247.0.6/16
          gw: 10.0.2.1
```

## bridge

See /usr/share/doc/initscripts-version/ directory for documentation and examples

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

None.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

Felix Archambault
