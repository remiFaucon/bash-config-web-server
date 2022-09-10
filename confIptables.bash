iptables -F
iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp -dport 22 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp -dport 80 -j ACCEPT
iptables -A INPUT -p tcp -dport 443 -j ACCEPT
iptables -A OUTPUT -p tcp -dport 443 -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT