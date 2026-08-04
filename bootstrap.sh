#!/usr/bin/env bash

# ==========================================================
# AgentOS Remote Host Bootstrap
# Gerado automaticamente pelo AgentOS Server
# Host: agentauxiliar
# Workspace: galaxydevegas
# ==========================================================

set -e

##############################################
# Configurações
##############################################

AGENT_DIR="/opt/agentos"
BASE_DIR="/srv/galaxydevegas"
SSH_PORT="22"

##############################################
# Banner
##############################################

echo "=========================================="
echo " AgentOS Remote Host Bootstrap"
echo "=========================================="

##############################################
# Validação de root
##############################################

if [ "$(id -u)" -ne 0 ]; then
    echo "Erro: execute este script como root."
    exit 1
fi

##############################################
# Informações do sistema
##############################################

echo
echo "Sistema:"
uname -a || true
cat /etc/os-release || true

##############################################
# Dependências
##############################################

apt install -y \
    rsync \
    unzip \
    zip \
    git \
    curl \
    wget \
    openssh-client \
    openssh-server \
    ca-certificates \
    jq \
    tree

##############################################
# Docker
##############################################

if true; then
    if command -v docker >/dev/null 2>&1; then
        echo "Docker já instalado: $(docker --version)"
    else
        . /etc/os-release
        if [ "$ID" != "ubuntu" ] && [ "$ID" != "debian" ]; then
            echo "Erro: instalação automática do Docker suporta apenas Ubuntu ou Debian."
            exit 1
        fi
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL "https://download.docker.com/linux/$ID/gpg" -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" > /etc/apt/sources.list.d/docker.list
        apt update
        apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        systemctl enable docker
        systemctl start docker
    fi
    docker --version
    docker compose version
fi

##############################################
# Webmin
##############################################

if true; then
    curl -fsSL -o /tmp/webmin-setup-repo.sh \
        https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repo.sh
    sh /tmp/webmin-setup-repo.sh
    apt update
    apt install -y --install-recommends webmin
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 10000/tcp || true
        ufw reload || true
    fi
    systemctl enable webmin
    systemctl start webmin
fi

##############################################
# Estrutura AgentOS
##############################################

mkdir -p "$AGENT_DIR/scripts"
mkdir -p "$AGENT_DIR/config"
mkdir -p "$AGENT_DIR/logs"
mkdir -p "$AGENT_DIR/tmp"

##############################################
# Workspace
##############################################

mkdir -p "$BASE_DIR/backups"

mkdir -p "$BASE_DIR/code/backend"
mkdir -p "$BASE_DIR/code/frontend"
mkdir -p "$BASE_DIR/code/scripts"

mkdir -p "$BASE_DIR/containers/docker-compose"
mkdir -p "$BASE_DIR/containers/volumes"

mkdir -p "$BASE_DIR/home"
mkdir -p "$BASE_DIR/logs"
mkdir -p "$BASE_DIR/shared"
mkdir -p "$BASE_DIR/tmp"

##############################################
# Permissões
##############################################

if [ -d "$AGENT_DIR" ]; then
    chmod 755 "$AGENT_DIR"
    chmod 700 "$AGENT_DIR/config" "$AGENT_DIR/tmp" 2>/dev/null || true
    chmod 755 "$AGENT_DIR/scripts" "$AGENT_DIR/logs" 2>/dev/null || true
fi
if [ -d "$BASE_DIR" ]; then
    chmod 755 "$BASE_DIR"
    chmod 700 "$BASE_DIR/tmp" 2>/dev/null || true
fi

##############################################
# Validações
##############################################

hostname

hostname -I || true

docker --version
docker compose version

systemctl status webmin --no-pager || true


tree -L 2 "$AGENT_DIR" || true

tree -L 2 "$BASE_DIR" || true

##############################################
# Resumo final
##############################################

HOST_IP="$(hostname -I | awk '{print $1}')"
echo
echo "=========================================="
echo " Bootstrap concluído"
echo "=========================================="
echo
echo "Hostname: $(hostname)"
echo "IP: $HOST_IP"
echo "Usuário SSH: root"
echo "Porta SSH: $SSH_PORT"
echo "Workspace: $BASE_DIR"
echo "AgentOS: $AGENT_DIR"
if true; then
    echo "Webmin: https://$HOST_IP:10000"
fi
echo
echo "Bootstrap finalizado com sucesso."
