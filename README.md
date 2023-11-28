# qubes-split-openconnect
A script to connect to a corporate VPN like AnyConnect using OpenConnect and Split GPG to protect your VPN credentials.

A more detailed HowTo setup the script, Split GPG and how the parts fit together will follow.

The idea for this script was heavily inspired by this script https://github.com/sorinipate/vpn-up-for-openconnect/

Quick install note
------------------

1. Setup Split GPG according the Qubes docs https://www.qubes-os.org/doc/split-gpg/
2. Store your passphrase to connect to the VPN Split GPG in the VPN ProxyVM encrypted at /rw/config/vpn-password.gpg
3. Make sure the file can be decrypted via echo `qubes-gpg-client -d /rw/config/vpn-password.gpg 2>/dev/null`
4. Place qubes-split-openconnect.sh at /rw/config
5. Add the following lines to /rw/config/rc.local
```
# Launch qubes-split-openconnect
export QUBES_GPG_DOMAIN=<YOUR-SPLIT-GPG-VM/VAULT-VM>
/rw/config/qubes-split-openconnect.sh start
```
6. Reboot the VPN ProxyVM
7. Try to ping a server on your internal network through the VPN
8. Try the same for an AppVM which is using the VPN ProxyVM as NetVM

If you have any questions or suggestions, feel free to raise an issue.

- One7two99
