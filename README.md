# EGZAMIN UBUNTU SERVER – ALAN

## 1. Informacje
- Imię: Alan
- Numer stanowiska: 4
- Użytkownik Samba: `egzamin4`
- Hasło Samba: `1234`
- Strona WWW: `Egzamin Alan`
- Port Apache: `10000`
- Katalog strony: `/egzamin/www`
- Katalog udostępniony Samba: `/pliki_egzaminu`

## 2. Zawartość repozytorium

- `instaluj.sh` – automatyczna instalacja i konfiguracja usług.
- `sprawdz.sh` – sprawdzanie poprawności wykonania zadania.
- `KOMENDY.txt` – najważniejsze komendy do egzaminu.
- `README.md` – instrukcja obsługi.

## 3. Pobranie repozytorium

Zainstaluj Git:

```bash
sudo apt update
sudo apt install git -y
```

Pobierz repozytorium:

```bash
git clone ADRES_REPOZYTORIUM
```

Przejdź do folderu:

```bash
cd egzamin-ubuntu
```

## 4. Instalacja i konfiguracja

Uruchom instalator:

```bash
sudo bash instaluj.sh
```

Skrypt instaluje i konfiguruje:
- SSH
- Apache2
- Stronę WWW
- Port 10000
- Lynx
- Sambę
- Użytkownika egzamin4
- Katalog `/pliki_egzaminu`
- Archiwum strony WWW

## 5. Sprawdzanie zadania

Uruchom:

```bash
sudo bash sprawdz.sh
```

Dodatkowe sprawdzanie strony:

```bash
curl http://localhost:10000
```

Sprawdzanie usług:

```bash
systemctl status ssh
systemctl status apache2
systemctl status smbd
```

Sprawdzanie udziału Samba:

```bash
smbclient -L localhost -U egzamin4
```

Sprawdzanie archiwum:

```bash
ls -l /pliki_egzaminu
```

## 6. Konfiguracja sieci

Sprawdzenie kart sieciowych:

```bash
ip -br link
ip a
ip route
```

Wymagane ustawienia drugiej karty:
- IP: `10.4.0.1/16`
- DNS: `8.8.8.8`
- DNS: `8.8.4.4`
- Brama: `10.4.255.254`

Konfigurację sieci należy wykonać po sprawdzeniu nazw kart i dostępności bramy.

## 7. Pendrive

Sprawdź podłączone dyski:

```bash
lsblk -f
```

Po ustaleniu właściwej partycji USB zamontuj ją i zapisz wynik:

```bash
sudo mkdir -p /mnt/pendrive
sudo mount /dev/sdX1 /mnt/pendrive
ip a | sudo tee /mnt/pendrive/Alan-IP.txt
sync
sudo umount /mnt/pendrive
```

Uwaga: `/dev/sdX1` należy zastąpić rzeczywistą nazwą partycji pendrive'a.

## 8. Ważne

Po wykonaniu konfiguracji należy sprawdzić wszystkie usługi, stronę WWW, udział Samba, archiwum oraz konfigurację sieci.

Nie należy zakładać, że skrypt wykonał poprawnie wszystkie wymagania bez sprawdzenia wyników.
