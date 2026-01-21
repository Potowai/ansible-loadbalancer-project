#!/bin/bash

# Script de déploiement automatisé
# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Déploiement Load Balancer + Web    ${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Fonction pour afficher les messages
function info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

function success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

function error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Vérifier qu'Ansible est installé
info "Vérification de l'installation d'Ansible..."
if ! command -v ansible &> /dev/null; then
    error "Ansible n'est pas installé. Installation..."
    sudo apt update && sudo apt install ansible -y
fi
success "Ansible est installé ($(ansible --version | head -n1))"

# Vérifier la connectivité
info "Test de connectivité avec les serveurs..."
if ansible all -m ping &> /dev/null; then
    success "Tous les serveurs sont accessibles"
else
    error "Impossible de joindre certains serveurs"
    echo ""
    warning "Assurez-vous que:"
    echo "  1. Les adresses IP dans inventory/hosts.ini sont correctes"
    echo "  2. Vous avez configuré les clés SSH (ssh-copy-id)"
    echo "  3. Les serveurs sont allumés et accessibles"
    echo ""
    read -p "Voulez-vous continuer quand même ? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Menu de déploiement
echo ""
echo -e "${YELLOW}Que voulez-vous déployer ?${NC}"
echo "1) Tout (Load Balancer + Serveurs Web)"
echo "2) Seulement les serveurs web"
echo "3) Seulement le load balancer"
echo "4) Mode dry-run (test sans modification)"
echo "5) Quitter"
echo ""
read -p "Votre choix (1-5): " choice

case $choice in
    1)
        info "Déploiement complet..."
        ansible-playbook playbook.yml
        ;;
    2)
        info "Déploiement des serveurs web..."
        ansible-playbook playbook.yml --tags webservers
        ;;
    3)
        info "Déploiement du load balancer..."
        ansible-playbook playbook.yml --tags loadbalancer
        ;;
    4)
        info "Mode dry-run activé..."
        ansible-playbook playbook.yml --check
        ;;
    5)
        info "Annulation du déploiement"
        exit 0
        ;;
    *)
        error "Choix invalide"
        exit 1
        ;;
esac

# Vérification post-déploiement
if [ $? -eq 0 ]; then
    echo ""
    success "Déploiement réussi !"
    echo ""
    info "Tests de vérification..."
    
    # Récupérer l'IP du load balancer
    LB_IP=$(grep -A1 "\[loadbalancer\]" inventory/hosts.ini | grep ansible_host | awk -F'=' '{print $2}' | awk '{print $1}')
    
    if [ ! -z "$LB_IP" ]; then
        echo ""
        echo -e "${GREEN}Testez votre infrastructure:${NC}"
        echo "  Load Balancer: http://$LB_IP"
        echo "  Health Check: http://$LB_IP/health"
        echo ""
        
        # Test rapide
        if command -v curl &> /dev/null; then
            info "Test du load balancer..."
            if curl -s -o /dev/null -w "%{http_code}" http://$LB_IP | grep -q "200"; then
                success "Le load balancer répond correctement !"
            else
                warning "Le load balancer ne répond pas encore (peut prendre quelques secondes)"
            fi
        fi
    fi
else
    error "Le déploiement a échoué. Consultez les logs ci-dessus."
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}      Déploiement terminé !            ${NC}"
echo -e "${BLUE}========================================${NC}"
