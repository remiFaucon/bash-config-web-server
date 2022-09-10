iptables -F
iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -t filter -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t filter -A INPUT -p tcp -dport 22 -j ACCEPT
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -i lo -j ACCEPT
iptables -t filter -A INPUT -p TCP --dport 80 -j ACCEPT
iptables -t filter -A OUTPUT -p TCP --dport 80 -j ACCEPT
iptables -t filter -A INPUT -p TCP --dport 443 -j ACCEPT
iptables -t filter -A OUTPUT -p TCP --dport 443 -j ACCEPT
iptables -t filter -A OUTPUT -p UDP --dport 123 -j ACCEPT