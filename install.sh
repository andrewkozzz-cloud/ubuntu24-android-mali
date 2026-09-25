#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=== [1/4] Подготовка окружения Termux ==="
pkg update -y && pkg upgrade -y
pkg install -y proot-distro curl wget tar coreutils

RELEASE_URL="https://github.com/andrewkozzz-cloud/ubuntu24-android-mali/releases/download/v1.0/ubuntu24_droiddesk_arm64.tar.gz"
EXPECTED_SHA="d51afeea93ac1061c7ab5dbcc9ce128762efd72abe1a7d68ed131ab18d75a87a"
TARGET_DIR="$HOME/.local/share/proot-distro/installed-rootfs/ubuntu"
ARCHIVE_PATH="$HOME/rootfs.tar.gz"

echo "=== [2/4] Проверка наличия архива и файлов ==="
mkdir -p "$TARGET_DIR"

if [ -z "$(ls -A $TARGET_DIR 2>/dev/null)" ]; then
    if [ ! -f "$ARCHIVE_PATH" ]; then
        echo "Скачивание архива Ubuntu 24.04 (Mali GPU)..."
        curl -fL -o "$ARCHIVE_PATH" "$RELEASE_URL"
    else
        echo "Найден ранее скачанный архив $ARCHIVE_PATH, скачивание пропущено."
    fi

    echo "Проверка целостности..."
    ACTUAL_SHA=$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')
    echo "Скачанный SHA: $ACTUAL_SHA"

    if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
        echo "Ошибка! Хеш файла не совпал."
        rm -f "$ARCHIVE_PATH"
        exit 1
    fi

    echo "=== [3/4] Распаковка Ubuntu 24.04 (Mali GPU + FreeCAD) ==="
    set +e
    tar -xzvf "$ARCHIVE_PATH" -C "$TARGET_DIR" --exclude='dev/*'
    set -e

    rm -f "$ARCHIVE_PATH"
else
    echo "Система уже распакована в $TARGET_DIR. Распаковка пропущена."
fi

echo "=== [4/4] Создание команды запуска start-ubuntu ==="
cat << 'SCRIPT_EOF' > $PREFIX/bin/start-ubuntu
#!/data/data/com.termux/files/usr/bin/bash
export DISPLAY=:0
export GALLIUM_DRIVER=virpipe

pkill -f termux-x11 || true
am start -n com.termux.x11/com.termux.x11.MainActivity 2>/dev/null || true
termux-x11 :0 -ac &
sleep 2

# Автоматическое выставление крупного шрифта 34 для XFCE
proot-distro login ubuntu --shared-tmp -- bash -c "export DISPLAY=:0; xfconf-query -c xsettings -p /Gtk/FontName -s 'Sans 34' --create -t string 2>/dev/null || true" &

proot-distro login ubuntu --shared-tmp -- env DISPLAY=:0 startxfce4
SCRIPT_EOF

chmod +x $PREFIX/bin/start-ubuntu

echo "================================================="
echo " Готово! Запуск рабочего стола командой: start-ubuntu"
echo "================================================="
