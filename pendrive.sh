
#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Uruchom: sudo bash pendrive.sh"
    exit 1
fi

echo "=== AUTOMATYCZNY ZAPIS NA PENDRIVE ==="

# Wykrywanie dysków USB
mapfile -t DISKS < <(
    lsblk -dnpo NAME,TRAN,RM |
    awk '$2=="usb" || $3=="1" {print $1}'
)

if [[ ${#DISKS[@]} -eq 0 ]]; then
    echo "Nie wykryto pendrive'a!"
    echo "Podłącz go w VirtualBox: Urządzenia -> USB."
    exit 1
fi

if [[ ${#DISKS[@]} -gt 1 ]]; then
    echo "Wykryto kilka dysków USB:"
    for i in "${!DISKS[@]}"; do
        echo "$i) ${DISKS[$i]}"
    done
    read -r -p "Wybierz numer pendrive'a: " N
    [[ "$N" =~ ^[0-9]+$ ]] && (( N < ${#DISKS[@]} )) || exit 1
    DISK="${DISKS[$N]}"
else
    DISK="${DISKS[0]}"
fi

# Wykrywanie partycji
mapfile -t PARTS < <(
    lsblk -lnpo NAME,TYPE "$DISK" |
    awk '$2=="part" {print $1}'
)

if [[ ${#PARTS[@]} -eq 0 ]]; then
    echo "Pendrive nie ma wykrytej partycji."
    exit 1
fi

if [[ ${#PARTS[@]} -gt 1 ]]; then
    echo "Wykryto kilka partycji:"
    for i in "${!PARTS[@]}"; do
        echo "$i) ${PARTS[$i]}"
    done
    read -r -p "Wybierz partycję: " N
    [[ "$N" =~ ^[0-9]+$ ]] && (( N < ${#PARTS[@]} )) || exit 1
    PART="${PARTS[$N]}"
else
    PART="${PARTS[0]}"
fi

MOUNT="/mnt/egzamin-pendrive"
mkdir -p "$MOUNT"

ALREADY_MOUNTED="$(findmnt -rn -S "$PART" -o TARGET | head -n1 || true)"

if [[ -n "$ALREADY_MOUNTED" ]]; then
    MOUNT="$ALREADY_MOUNTED"
else
    mount "$PART" "$MOUNT"
fi

echo "Zapisuję konfigurację sieci..."
ip address > "$MOUNT/Alan-IP.txt"

sync

if [[ -z "$ALREADY_MOUNTED" ]]; then
    umount "$MOUNT"
fi

echo
echo "GOTOWE! Plik Alan-IP.txt zapisany na pendrive."
