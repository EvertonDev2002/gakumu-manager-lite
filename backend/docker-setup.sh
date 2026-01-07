#!/usr/bin/env bash
set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🐳 Gakumu Manager - Docker Setup${NC}"
echo ""

# Verificar se docker-compose está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não encontrado. Por favor, instale o Docker primeiro.${NC}"
    exit 1
fi

# Verificar se arquivo .env existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Arquivo .env não encontrado. Criando a partir de .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ Arquivo .env criado. Edite-o conforme necessário.${NC}"
fi

# Build das imagens
echo -e "${GREEN}📦 Construindo imagens Docker...${NC}"
docker compose build

# Iniciar serviços
echo -e "${GREEN}🚀 Iniciando serviços...${NC}"
docker compose up -d

# Aguardar serviços ficarem prontos
echo -e "${YELLOW}⏳ Aguardando serviços iniciarem...${NC}"
sleep 5

# Verificar status
echo ""
echo -e "${GREEN}📊 Status dos serviços:${NC}"
docker compose ps

echo ""
echo -e "${GREEN}✅ Setup completo!${NC}"
echo ""
echo "Serviços disponíveis:"
echo "  - API: http://localhost:3000"
echo "  - Health Check: http://localhost:3000/health"
echo "  - PostgreSQL: localhost:5432"
echo ""
echo "Comandos úteis:"
echo "  docker compose logs -f app    # Ver logs da aplicação"
echo "  docker compose down           # Parar serviços"
echo "  docker compose down -v        # Parar e remover volumes"
