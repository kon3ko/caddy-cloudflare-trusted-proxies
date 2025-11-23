#!/usr/bin/env sh
set -euo pipefail

dest=/out/trusted_proxies/cloudflare
destdir="$(dirname "$dest")"
ipv4="https://www.cloudflare.com/ips-v4"
ipv6="https://www.cloudflare.com/ips-v6"

# create dest dir if not exists
mkdir -p "$destdir"

# create a temp file
tmp="$(mktemp "$destdir"/trusted_proxies_cloudflare.XXXXXX)"

# ensure temp file is removed on exit
trap 'rm -f "$tmp"' EXIT

# download and format the IPs (combined IPv4 + IPv6 in one line)
{
  printf '# Cloudflare IPv4 + IPv6\n'
  printf 'trusted_proxies static '

  # IPv4 → แปลงเป็นบรรทัดเดียว
  curl -fsS "$ipv4" | sed '/^\s*$/d' | tr '\n' ' '

  printf ' '

  # IPv6 → แปลงเป็นบรรทัดเดียว
  curl -fsS "$ipv6" | sed '/^\s*$/d' | tr '\n' ' '

  printf '\n'
} > "$tmp"

# extract candidate network strings
netlines="$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?|[A-Fa-f0-9:]+(/[0-9]{1,3})?' "$tmp" || true)"

# validate networks using sipcalc; abort if any invalid
if ! echo "$netlines" | while IFS= read -r n; do
  [ -z "$n" ] && continue
  sipcalc "$n" >/dev/null 2>&1 || {
    echo "Invalid network: $n" >&2
    exit 2
  }
done
then
  echo "validation failed" >&2
  exit 2
fi

# Check if the content has changed; if not, skip reload
if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
  echo "no change in cloudflare IPs, skip reload"
  exit 0
fi

# move temp file to destination (atomic update) with retries
chmod 0644 "$tmp"
mv -f "$tmp" "$dest"
trap - EXIT
echo "updated \`$dest\`"

# format Caddyfile into a temp file BEFORE load
fmt_tmp="$(mktemp)"

# NOTE: caddy fmt exits with code 1 if it makes changes, even though it prints formatted output.
# With set -e, we must ignore that exit code.
caddy fmt /watch/Caddyfile > "$fmt_tmp" 2>/dev/null || true

# Notify Caddy to reload the *formatted* Caddyfile
curl -fsS --unix-socket /run/caddy-admin.sock \
  -X POST http://localhost/load \
  -H 'Content-Type: text/caddyfile' \
  -H 'Cache-Control: must-revalidate' \
  --data-binary @"$fmt_tmp"

rm -f "$fmt_tmp"
echo "caddy reloaded"
