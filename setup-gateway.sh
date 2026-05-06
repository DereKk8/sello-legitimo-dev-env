#!/usr/bin/env bash
#
# Script de configuracion inicial para el Gateway (Authelia + Caddy).
# Genera la clave privada OIDC y los secrets de Authelia a partir de la plantilla.
# Solo es necesario ejecutarlo una vez antes de levantar el entorno por primera vez.
#

set -e

CONFIG_DIR="gateway/config/authelia"

echo "========================================"
echo "  Configuracion inicial del Gateway"
echo "========================================"
echo ""

mkdir -p "$CONFIG_DIR"

if ! command -v openssl &> /dev/null; then
    echo "Error: openssl no esta instalado. Instalalo e intenta de nuevo."
    exit 1
fi

if [ ! -f "$CONFIG_DIR/oidc_private_key.pem" ]; then
    echo "Generando clave privada OIDC ($CONFIG_DIR/oidc_private_key.pem)..."
    openssl genrsa -out "$CONFIG_DIR/oidc_private_key.pem" 4096
    echo "Clave privada generada."
else
    echo "La clave privada ya existe. Omitiendo generacion."
fi

if [ ! -f "$CONFIG_DIR/configuration.yml.template" ]; then
    echo "Error: No se encontro $CONFIG_DIR/configuration.yml.template"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "Error: python3 es necesario para generar la configuracion. Instalalo e intenta de nuevo."
    exit 1
fi

echo "Generando secrets aleatorios para Authelia..."

python3 << PYEOF
import secrets
import pathlib

config_dir = pathlib.Path("gateway/config/authelia")
pem_file = config_dir / "oidc_private_key.pem"
template_file = config_dir / "configuration.yml.template"
output_file = config_dir / "configuration.yml"

private_key = pem_file.read_text()
# Indentar cada linea con 8 espacios para el bloque YAML
indented_key = "\n".join("        " + line for line in private_key.strip().split("\n"))

template = template_file.read_text()
template = template.replace("{{SESSION_SECRET}}", secrets.token_hex(64))
template = template.replace("{{STORAGE_ENCRYPTION_KEY}}", secrets.token_hex(32))
template = template.replace("{{JWT_SECRET}}", secrets.token_hex(64))
template = template.replace("{{OIDC_HMAC_SECRET}}", secrets.token_hex(32))
template = template.replace("{{OIDC_PRIVATE_KEY}}", indented_key)

output_file.write_text(template)
print("configuration.yml generado exitosamente.")
PYEOF

echo ""
echo "========================================"
echo "  Listo"
echo "========================================"
echo "Archivos generados/verificados:"
echo "  - $CONFIG_DIR/configuration.yml"
echo "  - $CONFIG_DIR/oidc_private_key.pem"
echo ""
echo "Puedes levantar el entorno con:"
echo "  docker compose -f docker-compose.local.gateway.yml up --build -d"
