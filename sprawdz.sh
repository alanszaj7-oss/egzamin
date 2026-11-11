
#!/bin/bash

echo "========== TEST EGZAMINU ALAN =========="

echo
echo "1. SSH"
systemctl is-active ssh

echo
echo "2. APACHE"
systemctl is-active apache2

echo
echo "3. SAMBA"
systemctl is-active smbd

echo
echo "4. STRONA WWW"
curl -s http://localhost:10000

echo
echo "5. PORT 10000"
ss -lntp | grep ':10000'

echo
echo "6. WLASCICIEL I UPRAWNIENIA"
stat -c '%A %a %U:%G %n' /egzamin /egzamin/www /egzamin/www/index.html

echo
echo "7. ARCHIWUM"
ls -lh /pliki_egzaminu/

echo
echo "8. UZYTKOWNIK"
id egzamin4

echo
echo "9. ADRESY IP"
ip -br address

echo
echo "10. TRASA SIECIOWA"
ip route

echo
echo "========== KONIEC TESTU =========="
