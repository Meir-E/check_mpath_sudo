# check_mpath_sudo
cutom script based https://git.fws.fr/fws/zabbix-agent-addons/src/branch/master/zabbix_scripts/check_mpath_sudo
# Install on linux
```
curl --ssl-no-revoke -L https://github.com/Meir-E/check_mpath_sudo/archive/refs/heads/main.zip > myfile.zip
unzip -jo myfile.zip && chmod +x check_mpath_sudo.pl && rm myfile.zip README.md
```
# Run Example
```
./check_mpath_sudo.pl --mpath ssvm2./check_mpath_sudo --mpath ssvm2  --pretty
```
# Run Example for Testing
```
./check_mpath_sudo.pl --mpath ssvm2./check_mpath_sudo --mpath ssvm2  --pretty --t yes
```
