
#!/bin/bash

# ============================================================
# Script: config_hostname.sh
# Version: 1.0.1 (Compatible con Bash antiguo)
# Descripción: Configura el hostname de forma automática y persistente
# Uso: ./config_hostname.sh [nombre_host]
# ============================================================

echo 
echo "configura el nombre del hostname en Linux local"
echo "Uso: sh hostname.sh nombre_hostame"
echo

# Colores para output (opcional, si no soporta usar sin ellos)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

# Función para mostrar mensajes
print_msg() {
    echo "[+] $1"
}

print_error() {
    echo "${RED}[!] $1${NC}" 2>&1
}

print_success() {
    echo "${GREEN}[✓] $1${NC}"
}

print_warning() {
    echo "${YELLOW}[*] $1${NC}"
}

# Función para verificar si se tiene permisos de root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_error "Este script debe ejecutarse como root"
        echo "Usa: sudo $0 [nombre_host]"
        exit 1
    fi
}

# Función para validar el nombre del host
validate_hostname() {
    local hostname="$1"
    
    # Verificar longitud (máximo 63 caracteres)
    if [ ${#hostname} -gt 63 ]; then
        print_error "El nombre de host es demasiado largo (máximo 63 caracteres)"
        return 1
    fi
    
    # Verificar caracteres válidos (solo letras, números y guiones)
    if ! echo "$hostname" | grep -Eq '^[a-zA-Z0-9][a-zA-Z0-9-]*$'; then
        print_error "Nombre inválido. Usa solo letras, números y guiones"
        print_error "Debe comenzar con una letra o número"
        return 1
    fi
    
    # Verificar que no termine en guión
    if echo "$hostname" | grep -q '\-$'; then
        print_error "El nombre no puede terminar en guión"
        return 1
    fi
    
    return 0
}

# Función para configurar /etc/hosts
configure_etc_hosts() {
    local hostname="$1"
    local old_hostname="$2"
    local hosts_file="/etc/hosts"
    local temp_file="/tmp/hosts.tmp.$$"
    
    print_msg "Configurando /etc/hosts..."
    
    # Buscar líneas con el hostname antiguo y reemplazarlas
    if [ -f "$hosts_file" ]; then
        # Crear backup
        cp "$hosts_file" "${hosts_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Eliminar líneas que contienen el hostname antiguo (solo las de 127.0.0.1 y 127.0.1.1)
        sed -e "/127\.0\.0\.1[[:space:]]*$old_hostname/d" \
            -e "/127\.0\.1\.1[[:space:]]*$old_hostname/d" \
            "$hosts_file" > "$temp_file"
        
        # Añadir el nuevo hostname
        echo "127.0.0.1    localhost" >> "$temp_file"
        echo "127.0.1.1    $hostname" >> "$temp_file"
        
        # Reemplazar archivo
        mv "$temp_file" "$hosts_file"
        
        print_success "Archivo /etc/hosts actualizado"
    else
        # Crear /etc/hosts si no existe
        cat > "$hosts_file" << EOF
127.0.0.1    localhost
127.0.1.1    $hostname

# The following lines are desirable for IPv6 capable hosts
::1          localhost ip6-localhost ip6-loopback
ff02::1      ip6-allnodes
ff02::2      ip6-allrouters
EOF
        print_success "Archivo /etc/hosts creado"
    fi
}

# Función principal
main() {
    local new_hostname="$1"
    local current_hostname=""
    local hostname_file="/etc/hostname"
    
    # Verificar root
    check_root
    
    # Obtener hostname actual
    if [ -f "$hostname_file" ]; then
        current_hostname=$(cat "$hostname_file" 2>/dev/null | head -n1)
    fi
    if [ -z "$current_hostname" ]; then
        current_hostname="localhost"
    fi
    
    print_msg "Hostname actual: $current_hostname"
    
    # Si no se pasó argumento, intentar generarlo automáticamente
    if [ -z "$new_hostname" ]; then
        print_warning "No se especificó nombre de host"
        
        # Generar nombre basado en la IP o usar un nombre por defecto
        # Intentar obtener IP con métodos antiguos
        local ip_address=""
        if command -v hostname >/dev/null 2>&1; then
            ip_address=$(hostname -I 2>/dev/null | awk '{print $1}')
        fi
        
        if [ -n "$ip_address" ] && [ "$ip_address" != "127.0.0.1" ]; then
            # Generar nombre basado en IP
            new_hostname="host-$(echo "$ip_address" | sed 's/\./-/g')"
            print_msg "Generando hostname basado en IP: $new_hostname"
        else
            # Usar nombre por defecto
            new_hostname="linux-server-$(date +%Y%m%d)"
            print_msg "Usando hostname por defecto: $new_hostname"
        fi
    fi
    
    # Validar el nuevo hostname
    print_msg "Validando nombre: $new_hostname"
    if ! validate_hostname "$new_hostname"; then
        exit 1
    fi
    
    # Si el nombre es igual al actual, no hacer nada
    if [ "$new_hostname" = "$current_hostname" ]; then
        print_warning "El hostname ya está configurado como: $new_hostname"
        exit 0
    fi
    
    print_msg "Configurando nuevo hostname: $new_hostname"
    
    # 1. Configurar /etc/hostname (persistente en reinicios)
    echo "$new_hostname" > "$hostname_file"
    if [ $? -eq 0 ]; then
        print_success "Archivo /etc/hostname actualizado"
    else
        print_error "Error al escribir /etc/hostname"
        exit 1
    fi
    
    # 2. Configurar /etc/hosts
    configure_etc_hosts "$new_hostname" "$current_hostname"
    
    # 3. Cambiar hostname en tiempo real (método antiguo)
    if command -v hostname >/dev/null 2>&1; then
        hostname "$new_hostname"
        if [ $? -eq 0 ]; then
            print_success "Hostname cambiado en tiempo real"
        else
            print_warning "No se pudo cambiar el hostname en tiempo real"
        fi
    fi
    
    # 4. Actualizar /etc/mailname si existe (para sistemas con mail)
    if [ -f "/etc/mailname" ]; then
        echo "$new_hostname" > "/etc/mailname"
        print_msg "Actualizado /etc/mailname"
    fi
    
    # 5. Actualizar /etc/hosts con localhost completamente
    # Esto ya lo hace configure_etc_hosts
    
    # Mostrar resumen
    echo ""
    echo "=========================================="
    print_success "Hostname configurado exitosamente"
    echo "=========================================="
    echo "  Nuevo hostname: $new_hostname"
    echo "  Hostname actual: $(hostname 2>/dev/null || echo 'desconocido')"
    echo "  Persistente en: /etc/hostname"
    echo "  Hosts en: /etc/hosts"
    echo "=========================================="
    echo ""
    print_warning "Si estás en una red, es posible que necesites reiniciar"
    print_warning "la sesión o ejecutar: exec bash"
    echo ""
    
    # Verificar configuración
    print_msg "Verificando configuración..."
    if command -v hostname >/dev/null 2>&1; then
        local verify_hostname=$(hostname 2>/dev/null)
        if [ "$verify_hostname" = "$new_hostname" ]; then
            print_success "Verificación: OK"
        else
            print_warning "Verificación: Hostname en tiempo real ($verify_hostname) no coincide"
            print_warning "Reinicia la sesión para aplicar todos los cambios"
        fi
    fi
}

# Manejar señales
trap 'echo ""; print_warning "Script interrumpido"; exit 1' INT TERM

# Mostrar ayuda
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Uso: $0 [nombre_host]"
    echo ""
    echo "Si no se especifica nombre, se genera automáticamente:"
    echo "  - Basado en la IP de la máquina"
    echo "  - O usando: linux-server-YYYYMMDD"
    echo ""
    echo "Requisitos:"
    echo "  - Ejecutar como root o con sudo"
    echo "  - El nombre debe tener solo letras, números y guiones"
    echo "  - Máximo 63 caracteres"
    echo ""
    echo "Ejemplos:"
    echo "  $0 mi-servidor"
    echo "  $0 web-prod-01"
    echo "  $0  # Genera automáticamente"
    exit 0
fi

# Ejecutar función principal
main "$@"

exit 0
