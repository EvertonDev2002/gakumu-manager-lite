# Gakumu Manager Lite - Backend

Backend da aplicação Gakumu Manager Lite, construído com NestJS, TypeORM e PostgreSQL.

## 📋 Índice

- [Stack Tecnológico](#-stack-tecnológico)
- [Pré-requisitos](#-pré-requisitos)
- [Setup do Projeto](#-setup-do-projeto)
- [Docker](#-docker)
- [Desenvolvimento Local](#-desenvolvimento-local)
- [Testes](#-testes)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Tecnologias Detalhadas](#-tecnologias-detalhadas)

## 🛠 Stack Tecnológico

- **Framework**: [NestJS](https://nestjs.com/) 11.x
- **Linguagem**: TypeScript 5.x
- **Runtime**: Node.js 20.x (gerenciado via mise)
- **ORM**: TypeORM 0.3.x
- **Banco de dados**: PostgreSQL 16
- **Gerenciador de pacotes**: pnpm
- **Containerização**: Docker + Docker Compose

## 📦 Pré-requisitos

### Opção 1: Usando Docker (Recomendado)

- Docker 20.10+
- Docker Compose 2.0+

### Opção 2: Desenvolvimento Local

- [mise](https://mise.jdx.dev/) - Gerenciador de versões
- PostgreSQL 16 (ou via Docker)

## 🚀 Setup do Projeto

### Instalação de Dependências

```bash
# Instalar ferramentas via mise
mise install

# Instalar dependências do projeto
pnpm install
```

### Configuração de Ambiente

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar variáveis conforme necessário
```

Variáveis principais:

```env
NODE_ENV=development
PORT=3000
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=gakumu_db
```

## 🐳 Docker

### Setup Rápido

Execute o script automático:

```bash
./docker-setup.sh
```

### Setup Manual

#### Produção

```bash
# Build e iniciar
docker compose up -d

# Ver logs
docker compose logs -f app

# Parar
docker compose down
```

#### Desenvolvimento (Hot Reload)

```bash
# Iniciar em modo desenvolvimento
docker compose -f docker-compose.dev.yml up

# Em segundo plano
docker compose -f docker-compose.dev.yml up -d

# Ver logs
docker compose -f docker-compose.dev.yml logs -f app

# Parar
docker compose -f docker-compose.dev.yml down
```

### Comandos Úteis Docker

```bash
# Parar e remover volumes (limpa banco de dados)
docker compose down -v

# Rebuild da aplicação
docker compose build app
docker compose up -d

# Executar comandos no container
docker compose exec app sh

# Ver status dos containers
docker compose ps
```

### Acessar Aplicação

- **API**: http://localhost:3000
- **Health Check**: http://localhost:3000/health
- **PostgreSQL**: localhost:5432

## 💻 Desenvolvimento Local

### Compilar e Executar

```bash
# Modo desenvolvimento (watch mode)
pnpm run start:dev

# Modo produção
pnpm run build
pnpm run start:prod

# Modo debug
pnpm run start:debug
```

### Formatação e Linting

```bash
# Formatar código
pnpm run format

# Lint e auto-fix
pnpm run lint
```

## 🧪 Testes

```bash
# Testes unitários
pnpm run test

# Testes unitários em watch mode
pnpm run test:watch

# Testes E2E
pnpm run test:e2e

# Cobertura de testes
pnpm run test:cov
```

## 📁 Estrutura do Projeto

```
backend/
├── src/
│   ├── app.controller.ts      # Controller principal
│   ├── app.service.ts          # Service principal
│   ├── app.module.ts           # Módulo raiz
│   └── main.ts                 # Ponto de entrada
├── test/                       # Testes E2E
├── docker-compose.yml          # Compose produção
├── docker-compose.dev.yml      # Compose desenvolvimento
├── Dockerfile                  # Multi-stage build
├── .dockerignore               # Exclusões Docker
├── mise.toml                   # Configuração mise
├── tsconfig.json               # Config TypeScript
└── package.json                # Dependências e scripts
```

## 📚 Tecnologias Detalhadas

### NestJS

NestJS é um framework Node.js progressivo para construir aplicações server-side eficientes e escaláveis. Inspirado no Angular, utiliza TypeScript e aplica princípios de arquitetura sólida.

**Principais recursos:**

- **Dependency Injection**: Inversão de controle built-in
- **Modular**: Organize código em módulos reutilizáveis
- **Decorators**: Metadata e rotas declarativas (@Controller, @Get, etc)
- **Middleware/Guards/Interceptors**: Pipeline de request/response
- **TypeScript First**: Type safety completo
- **Testável**: Jest integrado, mocking facilitado

**Estrutura básica:**

```typescript
// Module - organização
@Module({
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}

// Controller - rotas
@Controller()
export class AppController {
  @Get()
  getHello(): string {
    return 'Hello World!';
  }
}

// Service - lógica de negócio
@Injectable()
export class AppService {
  getHello(): string {
    return 'Hello World!';
  }
}
```

**Documentação**: https://docs.nestjs.com/

### TypeORM

TypeORM é um ORM (Object-Relational Mapping) para TypeScript e JavaScript que suporta múltiplos bancos de dados relacionais e NoSQL.

**Principais recursos:**

- **Type-safe**: Define modelos com classes TypeScript
- **Migrations**: Controle de versão do schema
- **Repositories**: Abstração para operações de dados
- **Relations**: OneToMany, ManyToOne, ManyToMany
- **Query Builder**: Construa queries complexas type-safe
- **Transactions**: Suporte completo a transações

**Exemplo de Entity:**

```typescript
import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column({ unique: true })
  email: string;

  @Column()
  age: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
```

**Uso em Service:**

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async findAll(): Promise<User[]> {
    return this.userRepository.find();
  }

  async findOne(id: number): Promise<User> {
    return this.userRepository.findOneBy({ id });
  }

  async create(userData: Partial<User>): Promise<User> {
    const user = this.userRepository.create(userData);
    return this.userRepository.save(user);
  }

  async remove(id: number): Promise<void> {
    await this.userRepository.delete(id);
  }
}
```

**Configuração no AppModule:**

```typescript
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DATABASE_HOST,
      port: parseInt(process.env.DATABASE_PORT),
      username: process.env.DATABASE_USER,
      password: process.env.DATABASE_PASSWORD,
      database: process.env.DATABASE_NAME,
      entities: [User],
      synchronize: process.env.NODE_ENV === 'development',
    }),
    TypeOrmModule.forFeature([User]),
  ],
})
export class AppModule {}
```

**⚠️ Importante**:

- `synchronize: true` apenas em desenvolvimento
- Use migrations em produção
- Sempre defina indexes em colunas de busca frequente

**Documentação**: https://typeorm.io/

### mise

mise (anteriormente rtx) é um gerenciador de versões de ferramentas de desenvolvimento moderno e rápido, escrito em Rust. Substitui ferramentas como nvm, pyenv, rbenv, etc.

**Por que usar mise?**

- **Múltiplas linguagens**: Node.js, Python, Go, Rust, Java, etc
- **Reprodutível**: Versões definidas em `mise.toml`
- **Rápido**: Escrito em Rust, muito mais rápido que alternativas
- **Simples**: Um único comando para instalar tudo
- **Ambientes isolados**: Cada projeto usa suas próprias versões

**Configuração (`mise.toml`):**

```toml
[tools]
node = "20"              # Node.js 20.x (latest)
# python = "3.13"        # Python se necessário
# pnpm = "latest"        # pnpm global
```

**Comandos principais:**

```bash
# Instalar todas as ferramentas definidas
mise install

# Verificar versões instaladas
mise ls

# Usar versão específica
mise use node@20.10.0

# Executar comando com mise
mise exec -- node --version

# Ativar mise no shell (adicione ao ~/.config/fish/config.fish)
mise activate fish | source
```

**Workflow do projeto:**

1. Clone o repositório
2. Execute `mise install`
3. Todas as ferramentas na versão correta são instaladas automaticamente
4. Execute `pnpm install`

**Documentação**: https://mise.jdx.dev/

### Docker

Docker containeriza a aplicação e suas dependências, garantindo consistência entre ambientes.

**Arquitetura do projeto:**

```
┌─────────────────────────────────────┐
│  Dockerfile (Multi-stage)           │
│  ┌───────────────────────────────┐  │
│  │ Stage 1: Builder              │  │
│  │ - node:20-alpine              │  │
│  │ - Instala dependências        │  │
│  │ - Build TypeScript → JS       │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │ Stage 2: Runtime              │  │
│  │ - node:20-alpine              │  │
│  │ - Copia apenas dist/          │  │
│  │ - Dependências produção       │  │
│  │ - Non-root user (appuser)     │  │
│  │ - Health check configurado    │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘

docker-compose.yml (Produção)
├── app (NestJS)
│   ├── Build otimizado
│   └── Port 3000
└── db (PostgreSQL 16)
    ├── Volume persistente
    ├── Health check
    └── Port 5432

docker-compose.dev.yml (Desenvolvimento)
├── app (NestJS)
│   ├── Volume de código fonte
│   ├── Hot reload (watch mode)
│   └── Port 3000
└── db (PostgreSQL 16)
    └── Volume separado (dev)
```

**Boas práticas implementadas:**

1. **Multi-stage build**: Reduz tamanho da imagem final (~400MB → ~150MB)
2. **Alpine Linux**: Base mínima e segura
3. **Non-root user**: Executa como `appuser` (UID 1000)
4. **Layer caching**: COPY ordenado para maximizar cache
5. **Health checks**: Monitora saúde da aplicação
6. **.dockerignore**: Exclui arquivos desnecessários
7. **Production deps only**: Imagem final sem devDependencies

**Exemplo de Dockerfile otimizado:**

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
RUN corepack enable pnpm
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src/ ./src/
RUN pnpm build

# Runtime stage
FROM node:20-alpine
WORKDIR /app
RUN corepack enable pnpm
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod && pnpm store prune
COPY --from=builder /app/dist ./dist

# Segurança
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser && \
    chown -R appuser:appuser /app
USER appuser

EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider \
      http://localhost:3000/health || exit 1

CMD ["node", "dist/main.js"]
```

**Networks e Volumes:**

- **Network `app-network`**: Isolamento e comunicação entre containers
- **Volume `postgres_data`**: Persistência dos dados do banco
- **Volumes de desenvolvimento**: Monta código fonte para hot reload

**Documentação**:

- Docker: https://docs.docker.com/
- Compose: https://docs.docker.com/compose/

## 📖 Recursos Adicionais

### NestJS

- [Documentação Oficial](https://docs.nestjs.com/)
- [Guias](https://docs.nestjs.com/first-steps)
- [Recipes](https://docs.nestjs.com/recipes/crud-generator)

### TypeORM

- [Documentação](https://typeorm.io/)
- [Migrations](https://typeorm.io/migrations)
- [Relations](https://typeorm.io/relations)

### Docker

- [Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage builds](https://docs.docker.com/build/building/multi-stage/)
- [Security](https://docs.docker.com/engine/security/)

## 👥 Autores

Projeto desenvolvido para a faculdade.
