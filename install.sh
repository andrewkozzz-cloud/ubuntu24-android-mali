#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== [1/4] Подготовка окружения Termux ==="
pkg update -y && pkg upgrade -y
pkg install -y proot-distro curl wget tar coreutils

RELEASE_URL="https://github.com/andrewkozzz-cloud/ubuntu24-android-mali/releases/download/v1.0/ubuntu24_droiddesk_arm64.tar.gz"
EXPECTED_SHA="d51afeea93ac1061c7ab5dbcc9ce128762efd72abe1a7d68ed131ab18d75a87a"
TARGET_DIR="$HOME/.local/share/proot-distro/installed-rootfs/ubuntu24-mali"
ARCHIVE_PATH="$HOME/rootfs.tar.gz"

echo "=== [2/4] Скачивание и проверка архива ==="
mkdir -p "$TARGET_DIR"

if [ ! -f "$ARCHIVE_PATH" ]; then
    curl -fL -o "$ARCHIVE_PATH" "$RELEASE_URL"
fi

echo "Проверка целостности..."
ACTUAL_SHA=$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')
echo "Скачанный SHA: $ACTUAL_SHA"

if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
    echo "Ошибка! Хеш файла не совпал."
    rm -f "$ARCHIVE_PATH"
    exit 1
fi

echo "=== [3/4] Распаковка Ubuntu 24.04 (FreeCAD + Mali GPU) ==="
set +e
tar -xzvf "$ARCHIVE_PATH" -C "$TARGET_DIR" --exclude='dev/*'
set -e

rm -f "$ARCHIVE_PATH"

# Регистрируем дистрибутив в proot-distro
mkdir -p $PREFIX/etc/proot-distro
cat << 'SCRIPT_EOF' > $PREFIX/etc/proot-distro/ubuntu24-mali.sh
DISTRO_NAME="Ubuntu 24.04 ARM64 (Mali GPU + FreeCAD)"
DISTRO_TARBALL=""
SCRIPT_EOF

echo "=== [4/4] Создание команды запуска start-ubuntu ==="
cat << 'SCRIPT_EOF' > $PREFIX/bin/start-ubuntu
#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
export GALLIUM_DRIVER=virpipe

pkill -f termux-x11 || true
am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true
termux-x11 :0 -ac &
sleep 2

proot-distro login ubuntu24-mali --user andrew --shared-tmp -- env DISPLAY=:0 startxfce4
SCRIPT_EOF

chmod +x $PREFIX/bin/start-ubuntu

echo "================================================="
echo " Готово! Запуск рабочего стола командой: start-ubuntu"
echo "================================================="
