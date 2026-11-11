
#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Uruchom skrypt przez sudo."
    exit 1
fi

echo "=== EGZAMIN UBUNTU - KONFIGURACJA ==="

read -rsp "Wpisz haslo dla uzytkownika egzamin4 (1234): " HASLO
echo
if [ -z "$HASLO" ]; then
    echo "Haslo nie moze byc puste."
    exit 1
fi

echo "[1/8] Aktualizacja i instalacja programow..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
    openssh-server apache2 lynx samba smbclient

echo "[2/8] Konfiguracja SSH..."
systemctl enable --now ssh

echo "[3/8] Tworzenie strony internetowej..."
mkdir -p /egzamin/www
echo "Egzamin Alan" > /egzamin/www/index.html
chown -R www-data:www-data /egzamin
chmod 754 /egzamin
find /egzamin/www -type d -exec chmod 754 {} +
find /egzamin/www -type f -exec chmod 754 {} +

echo "[4/8] Konfiguracja portu Apache 10000..."
if ! grep -Eq '^[[:space:]]*Listen[[:space:]]+10000([[:space:]]|$)' /etc/apache2/ports.conf; then
    echo "Listen 10000" >> /etc/apache2/ports.conf
fi

cat > /etc/apache2/sites-available/egzamin.conf <<'APACHE'
<VirtualHost *:10000>
    DocumentRoot /egzamin/www

    <Directory /egzamin/www>
        Options -Indexes
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/egzamin_error.log
    CustomLog ${APACHE_LOG_DIR}/egzamin_access.log combined
</VirtualHost>
APACHE

a2ensite egzamin.conf
apache2ctl configtest
systemctl enable --now apache2
systemctl restart apache2

echo "[5/8] Tworzenie uzytkownika egzamin4..."
if ! id egzamin4 >/dev/null 2>&1; then
    useradd -m -s /bin/bash egzamin4
fi
echo "egzamin4:$HASLO" | chpasswd

echo "[6/8] Konfiguracja katalogu Samba..."
mkdir -p /pliki_egzaminu
chown egzamin4:egzamin4 /pliki_egzaminu
chmod 755 /pliki_egzaminu

if pdbedit -L 2>/dev/null | cut -d: -f1 | grep -qx egzamin4; then
    printf '%s\n%s\n' "$HASLO" "$HASLO" | smbpasswd -s egzamin4
else
    printf '%s\n%s\n' "$HASLO" "$HASLO" | smbpasswd -s -a egzamin4
fi
smbpasswd -e egzamin4

if ! grep -q '^\[pliki_egzaminu\]' /etc/samba/smb.conf; then
    cat >> /etc/samba/smb.conf <<'SAMBA'

[pliki_egzaminu]
   path = /pliki_egzaminu
   browseable = yes
   read only = no
   writable = yes
   valid users = egzamin4
   create mask = 0755
   directory mask = 0755
SAMBA
fi

testparm -s
systemctl enable --now smbd
systemctl restart smbd

echo "[7/8] Tworzenie archiwum strony..."
tar -czf /pliki_egzaminu/strona_egzamin.tar.gz -C /egzamin www
chown egzamin4:egzamin4 /pliki_egzaminu/strona_egzamin.tar.gz

echo "[8/8] Sprawdzanie wynikow..."
echo
echo "=== STRONA WWW ==="
curl -s http://localhost:10000 || true
echo
echo "=== LYNX ==="
lynx -dump http://localhost:10000 || true
echo
echo "=== STATUS USLUG ==="
systemctl is-active ssh
systemctl is-active apache2
systemctl is-active smbd
echo
echo "=== KARTY SIECIOWE ==="
ip -br address
echo
echo "=== UDZIAL SAMBA ==="
smbclient -L localhost -U egzamin4 -c quit
echo
echo "=== PLIKI W UDZIALE ==="
ls -l /pliki_egzaminu
echo
echo "GOTOWE. Siec i pendrive wymagaja osobnej konfiguracji."
