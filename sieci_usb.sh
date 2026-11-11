
#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Uruchom skrypt przez sudo."
    exit 1
fi

echo "=== KONFIGURACJA SIECI EGZAMINACYJNEJ ==="

mapfile -t IFACES < <(
    ip -o link show | awk -F': ' '{print $2}' |
    sed 's/@.*//' | grep -vE '^(lo|docker|veth|virbr)' 
)

if [[ ${#IFACES[@]} -lt 2 ]]; then
    echo "Nie wykryto dwóch kart sieciowych."
    echo "W VirtualBox włącz drugą kartę sieciową."
    exit 1
fi

echo "Wykryte karty:"
for i in "${!IFACES[@]}"; do
    echo "$i) ${IFACES[$i]}"
done

echo
echo "Wybierz numer DRUGIEJ karty (zwykle 1):"
read -r NR

if ! [[ "$NR" =~ ^[0-9]+$ ]] || (( NR >= ${#IFACES[@]} )); then
    echo "Nieprawidłowy wybór."
    exit 1
fi

NIC="${IFACES[$NR]}"

echo "Wybrana karta: $NIC"
echo "Adres: 10.4.0.1/16"
echo "DNS: 8.8.8.8 oraz 8.8.4.4"
echo "Brama: 10.4.255.254 (trasa zapasowa)"
echo
read -r -p "Czy kontynuować? (tak/nie): " OK
[[ "$OK" == "tak" ]] || exit 0

mkdir -p /root/netplan-backup
cp -a /etc/netplan/. /root/netplan-backup/

cat > /etc/netplan/99-egzamin-siec.yaml <<EOF
network:
  version: 2
  ethernets:
    $NIC:
      dhcp4: false
      addresses:
        - 10.4.0.1/16
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
      routes:
        - to: default
          via: 10.4.255.254
          metric: 200
EOF

chmod 600 /etc/netplan/99-egzamin-siec.yaml

netplan generate

echo
echo "Konfiguracja przygotowana."
echo "Za chwilę sprawdzimy ją przez netplan try."
echo "Jeśli połączenie działa poprawnie, zaakceptuj zmiany."
netplan try --timeout 60

echo
echo "=== AKTUALNE ADRESY ==="
ip address

echo
echo "=== WYKRYWANIE PENDRIVE ==="
lsblk -o NAME,TRAN,RM,SIZE,FSTYPE,LABEL,MOUNTPOINTS

echo
echo "Jeśli pendrive nie jest widoczny, podłącz go w VirtualBox"
echo "przez Urządzenia -> USB i uruchom skrypt ponownie."
echo

mapfile -t USB_PARTS < <(
    lsblk -rpno NAME,TYPE,TRAN,RM |
    awk '$2=="part" && ($3=="usb" || $4=="1") {print $1}'
)

if [[ ${#USB_PARTS[@]} -eq 0 ]]; then
    echo "Nie wykryto partycji pendrive."
    echo "Konfiguracja sieci została wykonana."
    exit 0
fi

echo "Wykryte partycje USB:"
for i in "${!USB_PARTS[@]}"; do
    echo "$i) ${USB_PARTS[$i]}"
done

read -r -p "Wybierz numer pendrive: " USB_NR

if ! [[ "$USB_NR" =~ ^[0-9]+$ ]] || (( USB_NR >= ${#USB_PARTS[@]} )); then
    echo "Nieprawidłowy wybór."
    exit 1
fi

PART="${USB_PARTS[$USB_NR]}"
MOUNT="/mnt/egzamin-usb"

mkdir -p "$MOUNT"

if ! findmnt -rn -S "$PART" >/dev/null; then
    mount "$PART" "$MOUNT"
else
    MOUNT="$(findmnt -rn -S "$PART" -o TARGET | head -n1)"
fi

ip address > "$MOUNT/Alan-IP.txt"
sync

echo "Zapisano plik: $MOUNT/Alan-IP.txt"

umount "$MOUNT"

echo "Pendrive bezpiecznie odmontowany."
echo "GOTOWE!"
