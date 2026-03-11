#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
# Remove ufw first — conflicts with direct iptables management
apt-get remove -y ufw || true
apt-get install -y netfilter-persistent iptables-persistent haproxy awscli

# =============================================================================
# NAT instance setup
# source_dest_check is disabled at the Terraform resource level.
# =============================================================================

# Enable IP forwarding permanently via sysctl.d (survives sysctl.conf rewrites)
cat > /etc/sysctl.d/99-ip-forward.conf << 'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
SYSCTL
sysctl --system

# Primary network interface
PRIMARY_IF=$(ip route get 8.8.8.8 | awk '{print $5; exit}')

# Masquerade outbound traffic from private subnets
iptables -t nat -A POSTROUTING \
  -s "${vpc_cidr}" ! -d "${vpc_cidr}" \
  -o "$PRIMARY_IF" -j MASQUERADE

iptables -A FORWARD \
  -i "$PRIMARY_IF" -o "$PRIMARY_IF" \
  -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A FORWARD -s "${vpc_cidr}" -j ACCEPT

# Persist rules across reboots
netfilter-persistent save

# =============================================================================
# Dynamic HAProxy configuration
# Discovers k3s masters via EC2 tags and (re)generates haproxy.cfg.
# Runs at boot and every 5 minutes via a systemd timer.
# =============================================================================

cat > /usr/local/bin/configure-haproxy.sh << 'HAPROXY_EOF'
#!/bin/bash
set -euo pipefail

AWS_REGION="${aws_region}"
ENVIRONMENT="${environment}"
TMP=$(mktemp)

# Discover running k3s master IPs by tag
MASTER_IPS=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters \
    "Name=tag:Role,Values=k3s-master" \
    "Name=tag:environment,Values=$ENVIRONMENT" \
    "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].PrivateIpAddress" \
  --output text 2>/dev/null || true)

if [[ -z "$MASTER_IPS" ]]; then
  echo "[haproxy-refresh] No k3s masters found yet — skipping."
  exit 0
fi

cat > "$TMP" << CFG
global
    log /dev/log local0
    log /dev/log local1 notice
    maxconn 4096

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5s
    timeout client  50s
    timeout server  50s

#----------------------------------------------------------------------
# k3s API — Kubernetes control plane
#----------------------------------------------------------------------
frontend k3s-api
    bind *:6443
    default_backend k3s-masters

backend k3s-masters
    balance roundrobin
    option tcp-check
CFG

for ip in $MASTER_IPS; do
  echo "    server master-$${ip//./-} $ip:6443 check" >> "$TMP"
done

cat >> "$TMP" << CFG

#----------------------------------------------------------------------
# Ingress — HTTP / HTTPS (k3s nodes run the ingress controller)
#----------------------------------------------------------------------
frontend ingress-http
    bind *:80
    default_backend ingress-http

frontend ingress-https
    bind *:443
    default_backend ingress-https

backend ingress-http
    balance roundrobin
    option tcp-check
CFG

for ip in $MASTER_IPS; do
  echo "    server node-$${ip//./-} $ip:80 check" >> "$TMP"
done

echo "" >> "$TMP"
echo "backend ingress-https" >> "$TMP"
echo "    balance roundrobin" >> "$TMP"
echo "    option tcp-check" >> "$TMP"

for ip in $MASTER_IPS; do
  echo "    server node-$${ip//./-} $ip:443 check" >> "$TMP"
done

# Atomic update: validate then swap
if haproxy -c -f "$TMP" &>/dev/null; then
  cp "$TMP" /etc/haproxy/haproxy.cfg
  systemctl reload haproxy 2>/dev/null || systemctl start haproxy
  echo "[haproxy-refresh] Config updated (masters: $MASTER_IPS)"
else
  echo "[haproxy-refresh] Config validation failed — keeping current config."
  rm -f "$TMP"
  exit 1
fi

rm -f "$TMP"
HAPROXY_EOF

chmod +x /usr/local/bin/configure-haproxy.sh

# Systemd service
cat > /etc/systemd/system/haproxy-refresh.service << 'SVC'
[Unit]
Description=Refresh HAProxy config from EC2 instance tags
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/configure-haproxy.sh
SVC

# Systemd timer — runs 1 min after boot, then every 5 min
cat > /etc/systemd/system/haproxy-refresh.timer << 'TIMER'
[Unit]
Description=Refresh HAProxy config every 5 minutes
After=network-online.target

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=haproxy-refresh.service

[Install]
WantedBy=timers.target
TIMER

systemctl daemon-reload
systemctl enable haproxy-refresh.timer
systemctl start haproxy-refresh.timer

# Initial run — no-op if masters aren't up yet
/usr/local/bin/configure-haproxy.sh || true

echo "Bastion bootstrap complete."
