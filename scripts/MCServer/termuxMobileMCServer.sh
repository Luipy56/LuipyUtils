#!/bin/bash
# Script: setup_papermc.sh
# Automatiza la instalación y ejecución de un servidor PaperMC

show_help() {
    cat << EOF
Uso: $0 [opción] [parámetro] [-h]

Opciones:
  -i [VERSION]     Instalar / descargar PaperMC (default: latest)
  -s [RAM]         Ejecutar el servidor con la RAM indicada (ej: 2G, default: 2G)
  -h, --help       Muestra esta ayuda

Ejemplo:
$0 -i 1.20.1    # Descarga e instala PaperMC 1.20.1
$0 -s 2G        # Ejecuta el servidor con 2G RAM
EOF
    exit 0
}

# --- Comprobar argumentos ---
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

ACTION="$1"
PARAM="${2:-}"

check_command() {
    command -v "$1" >/dev/null 2>&1
}

install_java() {
    if ! check_command java; then
        echo "Java no encontrado. Instalando..."
        if check_command pkg; then
            pkg install openjdk-17 -y
        elif check_command apt; then
            sudo apt update
            sudo apt install openjdk-17-jdk -y
        else
            echo "Instala Java manualmente"
            exit 1
        fi
    fi
}

install_tools() {
    for cmd in wget curl; do
        if ! check_command $cmd; then
            echo "Instalando $cmd..."
            if check_command pkg; then
                pkg install $cmd -y
            elif check_command apt; then
                sudo apt install $cmd -y
            else
                echo "Instala $cmd manualmente"
                exit 1
            fi
        fi
    done
}

prepare_folder() {
    SERVER_DIR="$HOME/minecraft_paper_test_server"
    mkdir -p "$SERVER_DIR"
    cd "$SERVER_DIR" || exit
    if pgrep -f "paper.*.jar" > /dev/null; then
        echo "Deteniendo servidor existente..."
        pkill -f "paper.*.jar"
    fi
}


download_paper() {
    PAPER_VERSION="${PARAM:-latest}"
    PAPER_JAR="paper.jar"

    echo "Obteniendo último build de PaperMC versión $PAPER_VERSION..."

    # Obtener JSON de la API
    JSON=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION")
    if [[ -z "$JSON" ]]; then
        echo "Error: No se pudo acceder a la API de PaperMC."
        exit 1
    fi

    # Extraer el último build
    BUILD=$(echo "$JSON" | grep -oP '"builds":\[\K[0-9,]+' | tr ',' '\n' | tail -1)

    if [[ -z "$BUILD" ]]; then
        echo "Error: No se pudo obtener el número de build para la versión $PAPER_VERSION"
        exit 1
    fi

    DOWNLOAD_URL="https://api.papermc.io/v2/projects/paper/versions/$PAPER_VERSION/builds/$BUILD/downloads/paper-$PAPER_VERSION-$BUILD.jar"
    echo "Descargando PaperMC versión $PAPER_VERSION, build $BUILD..."

    # Descargar usando curl con -L para seguir redirecciones
    if ! curl -L -o "$PAPER_JAR" "$DOWNLOAD_URL"; then
        echo "Error: No se pudo descargar PaperMC."
        exit 1
    fi

    echo "Aceptando EULA..."
    echo "eula=true" > eula.txt
    echo "PaperMC descargado correctamente en $PAPER_JAR"
}


run_server() {
    RAM="${PARAM:-2G}"
    SERVER_DIR="$HOME/minecraft_paper_test_server"
    PAPER_JAR="$SERVER_DIR/paper.jar"

    if [[ ! -f "$PAPER_JAR" ]]; then
        echo "Error: paper.jar no encontrado en $SERVER_DIR. Ejecuta -i primero."
        exit 1
    fi

    cd "$SERVER_DIR" || exit
    echo "Ejecutando servidor PaperMC con $RAM RAM..."
    java -Xmx$RAM -Xms$RAM -jar paper.jar nogui
}

# --- Acción principal ---
case "$ACTION" in
    -i)
        install_java
        install_tools
        prepare_folder
        download_paper
        ;;
    -s)
        run_server
        ;;
    *)
        echo "Opción no reconocida: $ACTION"
        show_help
        ;;
esac
