# NestJS — Instruções para o LLM

Contexto: APIs backend com NestJS (framework Node.js com TypeScript).

## Objetivo do assistant

- Gerar controllers, providers, modules e DTOs seguindo arquitetura NestJS.
- Garantir dependency injection, validação, exception handling e testes.
- Aplicar princípios SOLID e Clean Architecture.

## Estrutura esperada

### Module (Organização)

```typescript
// cats/cats.module.ts
import { Module } from '@nestjs/common';
import { CatsController } from './cats.controller';
import { CatsService } from './cats.service';

@Module({
  controllers: [CatsController],
  providers: [CatsService],
  exports: [CatsService], // Export se usado em outros módulos
})
export class CatsModule {}
```

### DTO com validação (class-validator)

```typescript
// cats/dto/create-cat.dto.ts
import {
  IsString,
  IsInt,
  IsNotEmpty,
  Min,
  Max,
  IsOptional,
  IsEnum,
} from 'class-validator';

export enum CatBreed {
  PERSIAN = 'persian',
  SIAMESE = 'siamese',
  MAINE_COON = 'maine_coon',
}

export class CreateCatDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsInt()
  @Min(0)
  @Max(30)
  age: number;

  @IsEnum(CatBreed)
  breed: CatBreed;

  @IsString()
  @IsOptional()
  description?: string;
}
```

### Controller (Rotas e Validação)

```typescript
// cats/cats.controller.ts
import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  HttpCode,
  HttpStatus,
  ParseIntPipe,
  ValidationPipe,
} from '@nestjs/common';
import { CatsService } from './cats.service';
import { CreateCatDto } from './dto/create-cat.dto';
import { UpdateCatDto } from './dto/update-cat.dto';
import { Cat } from './interfaces/cat.interface';

@Controller('cats')
export class CatsController {
  constructor(private readonly catsService: CatsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createCatDto: CreateCatDto): Promise<Cat> {
    return this.catsService.create(createCatDto);
  }

  @Get()
  async findAll(@Query('limit', ParseIntPipe) limit?: number): Promise<Cat[]> {
    return this.catsService.findAll(limit);
  }

  @Get(':id')
  async findOne(@Param('id', ParseIntPipe) id: number): Promise<Cat> {
    return this.catsService.findOne(id);
  }

  @Put(':id')
  async update(
    @Param('id', ParseIntPipe) id: number,
    @Body() updateCatDto: UpdateCatDto
  ): Promise<Cat> {
    return this.catsService.update(id, updateCatDto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id', ParseIntPipe) id: number): Promise<void> {
    await this.catsService.remove(id);
  }

  @Get('health')
  @HttpCode(HttpStatus.OK)
  healthCheck(): { status: string } {
    return { status: 'healthy' };
  }
}
```

### Service (Lógica de negócio)

```typescript
// cats/cats.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateCatDto } from './dto/create-cat.dto';
import { UpdateCatDto } from './dto/update-cat.dto';
import { Cat } from './interfaces/cat.interface';

@Injectable()
export class CatsService {
  private cats: Cat[] = [];
  private idCounter = 1;

  create(createCatDto: CreateCatDto): Cat {
    const cat: Cat = {
      id: this.idCounter++,
      ...createCatDto,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.cats.push(cat);
    return cat;
  }

  findAll(limit?: number): Cat[] {
    return limit ? this.cats.slice(0, limit) : this.cats;
  }

  findOne(id: number): Cat {
    const cat = this.cats.find((c) => c.id === id);
    if (!cat) {
      throw new NotFoundException(`Cat with ID ${id} not found`);
    }
    return cat;
  }

  update(id: number, updateCatDto: UpdateCatDto): Cat {
    const cat = this.findOne(id);
    Object.assign(cat, updateCatDto, { updatedAt: new Date() });
    return cat;
  }

  remove(id: number): void {
    const index = this.cats.findIndex((c) => c.id === id);
    if (index === -1) {
      throw new NotFoundException(`Cat with ID ${id} not found`);
    }
    this.cats.splice(index, 1);
  }
}
```

### Interface

```typescript
// cats/interfaces/cat.interface.ts
export interface Cat {
  id: number;
  name: string;
  age: number;
  breed: string;
  description?: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### Exception Filters (Tratamento de erros)

```typescript
// common/filters/http-exception.filter.ts
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.message
        : 'Internal server error';

    response.status(status).json({
      statusCode: status,
      message,
      timestamp: new Date().toISOString(),
    });
  }
}
```

### Guards (Autenticação/Autorização)

```typescript
// common/guards/auth.guard.ts
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { Observable } from 'rxjs';

@Injectable()
export class AuthGuard implements CanActivate {
  canActivate(
    context: ExecutionContext
  ): boolean | Promise<boolean> | Observable<boolean> {
    const request = context.switchToHttp().getRequest();
    const token = request.headers.authorization?.split(' ')[1];

    if (!token) {
      throw new UnauthorizedException('No token provided');
    }

    // Validação do token aqui
    return true;
  }
}

// Uso no controller:
// @UseGuards(AuthGuard)
// @Get()
// async findAll() { ... }
```

### Interceptors (Logging/Transformação)

```typescript
// common/interceptors/logging.interceptor.ts
import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url } = request;
    const now = Date.now();

    return next.handle().pipe(
      tap(() => {
        const duration = Date.now() - now;
        this.logger.log(`${method} ${url} - ${duration}ms`);
      })
    );
  }
}
```

### Pipes (Validação customizada)

```typescript
// common/pipes/parse-positive-int.pipe.ts
import {
  PipeTransform,
  Injectable,
  ArgumentMetadata,
  BadRequestException,
} from '@nestjs/common';

@Injectable()
export class ParsePositiveIntPipe implements PipeTransform<string, number> {
  transform(value: string, metadata: ArgumentMetadata): number {
    const val = parseInt(value, 10);
    if (isNaN(val) || val <= 0) {
      throw new BadRequestException(
        `${metadata.data} must be a positive integer`
      );
    }
    return val;
  }
}

// Uso:
// @Get(':id')
// findOne(@Param('id', ParsePositiveIntPipe) id: number) { ... }
```

### Testes (Jest)

```typescript
// cats/cats.controller.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { CatsController } from './cats.controller';
import { CatsService } from './cats.service';
import { CreateCatDto } from './dto/create-cat.dto';
import { NotFoundException } from '@nestjs/common';

describe('CatsController', () => {
  let controller: CatsController;
  let service: CatsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [CatsController],
      providers: [CatsService],
    }).compile();

    controller = module.get<CatsController>(CatsController);
    service = module.get<CatsService>(CatsService);
  });

  describe('create', () => {
    it('should create a cat', async () => {
      const createCatDto: CreateCatDto = {
        name: 'Fluffy',
        age: 2,
        breed: 'persian',
      };

      const result = await controller.create(createCatDto);

      expect(result).toMatchObject(createCatDto);
      expect(result.id).toBeDefined();
      expect(result.createdAt).toBeInstanceOf(Date);
    });
  });

  describe('findOne', () => {
    it('should throw NotFoundException for invalid id', async () => {
      await expect(controller.findOne(999)).rejects.toThrow(NotFoundException);
    });

    it('should return a cat by id', async () => {
      const createCatDto: CreateCatDto = {
        name: 'Whiskers',
        age: 3,
        breed: 'siamese',
      };

      const created = await controller.create(createCatDto);
      const found = await controller.findOne(created.id);

      expect(found).toEqual(created);
    });
  });
});
```

### Config Module (Variáveis de ambiente)

```typescript
// config/configuration.ts
export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  database: {
    host: process.env.DATABASE_HOST || 'localhost',
    port: parseInt(process.env.DATABASE_PORT, 10) || 5432,
    username: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '1d',
  },
});

// app.module.ts
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration';

@Module({
  imports: [
    ConfigModule.forRoot({
      load: [configuration],
      isGlobal: true,
      envFilePath: '.env',
    }),
  ],
})
export class AppModule {}
```

### Main.ts (Bootstrap)

```typescript
// main.ts
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Global pipes
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Remove propriedades não definidas no DTO
      forbidNonWhitelisted: true, // Lança erro se houver propriedades extras
      transform: true, // Transforma payloads em instâncias de DTO
    })
  );

  // Global filters
  app.useGlobalFilters(new AllExceptionsFilter());

  // Global interceptors
  app.useGlobalInterceptors(new LoggingInterceptor());

  // CORS
  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    credentials: true,
  });

  // Prefixo global
  app.setGlobalPrefix('api/v1');

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
```

## Boas práticas

### Arquitetura

- **Módulos por feature**: organize código por domínio (users/, cats/, auth/)
- **Dependency Injection**: sempre injete dependências via constructor
- **Single Responsibility**: cada service tem uma responsabilidade única
- **DTOs separados**: CreateDto, UpdateDto, ResponseDto
- **Interfaces/Types**: defina contratos claros

### Validação

- **class-validator**: use decorators nos DTOs (@IsString, @IsEmail, etc)
- **ValidationPipe global**: valide todos os inputs automaticamente
- **transform: true**: converta tipos automaticamente (string → number)
- **whitelist: true**: remova propriedades não definidas
- **forbidNonWhitelisted**: rejeite payloads com propriedades extras

### Error Handling

- **HttpException**: use exceções específicas (NotFoundException, BadRequestException)
- **Exception Filters**: centralize tratamento de erros
- **Mensagens claras**: sempre forneça contexto nos erros
- **Status codes corretos**: 200, 201, 204, 400, 401, 404, 500

### Segurança

- **Guards**: proteja rotas com autenticação/autorização
- **CORS**: configure origens permitidas
- **Helmet**: adicione headers de segurança (`app.use(helmet())`)
- **Rate limiting**: previna abuso com throttler
- **Validação de entrada**: nunca confie em dados do cliente

### Performance

- **Async/await**: use em operações I/O
- **Streaming**: use streams para grandes volumes de dados
- **Caching**: implemente cache com `@nestjs/cache-manager`
- **Compression**: habilite gzip (`app.use(compression())`)

### Testes

- **Unit tests**: teste services isoladamente
- **Integration tests**: teste controllers com TestingModule
- **E2E tests**: teste fluxos completos com supertest
- **Coverage**: mantenha > 80% de cobertura
- **Mocks**: use jest.mock() para dependências externas

### Documentação

- **OpenAPI/Swagger**: documente API automaticamente
- **JSDoc**: documente métodos públicos
- **README**: explique setup e arquitetura
- **Changelog**: mantenha histórico de mudanças

## CLI útil

```bash
# Criar novo projeto
nest new project-name

# Gerar recursos
nest g module cats          # Módulo
nest g controller cats      # Controller
nest g service cats         # Service
nest g resource cats        # CRUD completo (module + controller + service + DTO)

# Testes
pnpm test                  # Unit tests
pnpm test:e2e              # E2E tests
pnpm test:cov              # Coverage

# Build e execução
pnpm build
pnpm start                 # Produção
pnpm start:dev             # Dev com watch mode
pnpm start:debug           # Debug mode
```

## ORMs e Databases

NestJS suporta múltiplos ORMs e bibliotecas de banco de dados:

### TypeORM (Mais popular)

```bash
pnpm add @nestjs/typeorm typeorm mysql2
# ou para PostgreSQL: pnpm add @nestjs/typeorm typeorm pg
```

```typescript
// app.module.ts
import { TypeOrmModule } from '@nestjs/typeorm';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: 'localhost',
      port: 5432,
      username: 'user',
      password: 'password',
      database: 'database',
      entities: [Cat],
      synchronize: true, // APENAS em desenvolvimento
    }),
    TypeOrmModule.forFeature([Cat]),
  ],
})
export class AppModule {}

// cat.entity.ts
import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity()
export class Cat {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column()
  age: number;

  @Column()
  breed: string;
}

// cats.service.ts
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

@Injectable()
export class CatsService {
  constructor(
    @InjectRepository(Cat)
    private catsRepository: Repository<Cat>
  ) {}

  async findAll(): Promise<Cat[]> {
    return this.catsRepository.find();
  }

  async findOne(id: number): Promise<Cat> {
    return this.catsRepository.findOneBy({ id });
  }

  async create(createCatDto: CreateCatDto): Promise<Cat> {
    const cat = this.catsRepository.create(createCatDto);
    return this.catsRepository.save(cat);
  }
}
```

**Referências TypeORM:**

- [NestJS + TypeORM](https://docs.nestjs.com/techniques/database)
- [TypeORM Documentation](https://typeorm.io/)

### Prisma (Moderno e Type-Safe)

```bash
pnpm add @prisma/client
pnpm add -D prisma
pnpx prisma init
```

```typescript
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model Cat {
  id          Int      @id @default(autoincrement())
  name        String
  age         Int
  breed       String
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

// prisma.service.ts
import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect();
  }
}

// cats.service.ts
@Injectable()
export class CatsService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.cat.findMany();
  }

  async create(createCatDto: CreateCatDto) {
    return this.prisma.cat.create({
      data: createCatDto,
    });
  }
}
```

**Referências Prisma:**

- [NestJS + Prisma](https://docs.nestjs.com/recipes/prisma)
- [Prisma Documentation](https://www.prisma.io/docs)

### Mongoose (MongoDB)

```bash
pnpm add @nestjs/mongoose mongoose
```

```typescript
// app.module.ts
import { MongooseModule } from '@nestjs/mongoose';

@Module({
  imports: [
    MongooseModule.forRoot('mongodb://localhost/nest'),
    MongooseModule.forFeature([{ name: Cat.name, schema: CatSchema }]),
  ],
})
export class AppModule {}

// cat.schema.ts
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Cat {
  @Prop({ required: true })
  name: string;

  @Prop()
  age: number;

  @Prop()
  breed: string;
}

export type CatDocument = Cat & Document;
export const CatSchema = SchemaFactory.createForClass(Cat);

// cats.service.ts
import { Model } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';

@Injectable()
export class CatsService {
  constructor(@InjectModel(Cat.name) private catModel: Model<CatDocument>) {}

  async findAll(): Promise<Cat[]> {
    return this.catModel.find().exec();
  }

  async create(createCatDto: CreateCatDto): Promise<Cat> {
    const cat = new this.catModel(createCatDto);
    return cat.save();
  }
}
```

**Referências Mongoose:**

- [NestJS + Mongoose](https://docs.nestjs.com/techniques/mongodb)
- [Mongoose Documentation](https://mongoosejs.com/)

### Sequelize (Tradicional)

```bash
pnpm add @nestjs/sequelize sequelize sequelize-typescript mysql2
```

```typescript
// app.module.ts
import { SequelizeModule } from '@nestjs/sequelize';

@Module({
  imports: [
    SequelizeModule.forRoot({
      dialect: 'mysql',
      host: 'localhost',
      port: 3306,
      username: 'root',
      password: 'root',
      database: 'test',
      models: [Cat],
    }),
    SequelizeModule.forFeature([Cat]),
  ],
})
export class AppModule {}

// cat.model.ts
import { Column, Model, Table } from 'sequelize-typescript';

@Table
export class Cat extends Model {
  @Column
  name: string;

  @Column
  age: number;

  @Column
  breed: string;
}
```

**Referências Sequelize:**

- [NestJS + Sequelize](https://docs.nestjs.com/techniques/database#sequelize-integration)
- [Sequelize Documentation](https://sequelize.org/)

### MikroORM (Alternativa Moderna)

```bash
pnpm add @mikro-orm/core @mikro-orm/nestjs @mikro-orm/postgresql
```

**Referências MikroORM:**

- [NestJS + MikroORM](https://docs.nestjs.com/recipes/mikroorm)
- [MikroORM Documentation](https://mikro-orm.io/)

### Comparação de ORMs

| ORM           | Vantagens                                                      | Desvantagens                                 | Melhor para                                       |
| ------------- | -------------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------- |
| **TypeORM**   | Maduro, decorators, migrations, grande comunidade              | Pode ser lento, Active Record vs Data Mapper | Projetos enterprise, familiaridade com TypeScript |
| **Prisma**    | Type-safe, schema-first, migrations automáticas, Prisma Studio | Menos flexível, arquivo schema separado      | Projetos modernos, DX excepcional                 |
| **Mongoose**  | ODM para MongoDB, schemas flexíveis                            | Apenas MongoDB, menos type-safe              | Apps NoSQL, dados não estruturados                |
| **Sequelize** | Maduro, suporta múltiplos DBs                                  | JavaScript puro, menos type-safe             | Migração de projetos Node.js legados              |
| **MikroORM**  | Unit of Work pattern, type-safe                                | Menor comunidade                             | Projetos que precisam de patterns DDD             |

**Recomendação:** Use **Prisma** para projetos novos (melhor DX) ou **TypeORM** para enterprise (maturidade).

## Dependências essenciais

```json
{
  "dependencies": {
    "@nestjs/common": "^10.0.0",
    "@nestjs/core": "^10.0.0",
    "@nestjs/platform-express": "^10.0.0",
    "@nestjs/config": "^3.0.0",
    "class-validator": "^0.14.0",
    "class-transformer": "^0.5.1",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.1"
  },
  "devDependencies": {
    "@nestjs/cli": "^10.0.0",
    "@nestjs/testing": "^10.0.0",
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "jest": "^29.0.0",
    "supertest": "^6.3.0"
  }
}
```

## Referências

### Core

- [Documentação Oficial](https://docs.nestjs.com/)
- [Dependency Injection](https://docs.nestjs.com/fundamentals/dependency-injection)
- [Guards](https://docs.nestjs.com/guards)
- [Interceptors](https://docs.nestjs.com/interceptors)
- [Pipes](https://docs.nestjs.com/pipes)
- [Exception Filters](https://docs.nestjs.com/exception-filters)
- [Validation](https://docs.nestjs.com/techniques/validation)
- [Testing](https://docs.nestjs.com/fundamentals/testing)

### Databases e ORMs

- [Database (TypeORM)](https://docs.nestjs.com/techniques/database)
- [Prisma](https://docs.nestjs.com/recipes/prisma)
- [MongoDB (Mongoose)](https://docs.nestjs.com/techniques/mongodb)
- [Sequelize](https://docs.nestjs.com/techniques/database#sequelize-integration)
- [MikroORM](https://docs.nestjs.com/recipes/mikroorm)
- [SQL (TypeORM)](https://docs.nestjs.com/recipes/sql-typeorm)

### Segurança e Autenticação

- [Authentication](https://docs.nestjs.com/security/authentication)
- [Authorization](https://docs.nestjs.com/security/authorization)
- [Encryption and Hashing](https://docs.nestjs.com/security/encryption-and-hashing)
- [Helmet](https://docs.nestjs.com/security/helmet)
- [CORS](https://docs.nestjs.com/security/cors)
- [Rate Limiting](https://docs.nestjs.com/security/rate-limiting)

### Técnicas Avançadas

- [Caching](https://docs.nestjs.com/techniques/caching)
- [Task Scheduling](https://docs.nestjs.com/techniques/task-scheduling)
- [Queues](https://docs.nestjs.com/techniques/queues)
- [Events](https://docs.nestjs.com/techniques/events)
- [Compression](https://docs.nestjs.com/techniques/compression)
- [File Upload](https://docs.nestjs.com/techniques/file-upload)

---

# Docker — Instruções para o LLM

Contexto: Dockerfiles otimizados, multi-stage builds, segurança.

## Objetivo do assistant

- Gerar Dockerfiles multi-stage, seguros (non-root), com health checks.
- Minimizar tamanho de imagem final.

## Estrutura esperada

### Python/FastAPI Multi-stage

```dockerfile
# Builder stage
FROM python:3.12-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      gcc \
      libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Runtime stage
FROM python:3.12-slim

WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libpq5 \
      curl && \
    rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY src/ ./src/

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

# Update PATH for non-root user
ENV PATH=/root/.local/bin:$PATH

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Node.js/TypeScript Multi-stage

```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && \
    pnpm install --frozen-lockfile

# Copy source and build
COPY tsconfig.json ./
COPY src/ ./src/
RUN pnpm build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Install production dependencies only
COPY package.json pnpm-lock.yaml ./
RUN corepack enable pnpm && \
    pnpm install --frozen-lockfile --prod && \
    pnpm store prune

# Copy built application
COPY --from=builder /app/dist ./dist

# Create non-root user
RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/main.js"]
```

### .dockerignore

```
# Version control
.git
.gitignore

# Dependencies
node_modules
__pycache__
*.pyc
.venv
venv

# IDE
.vscode
.idea
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Build outputs
dist
build
*.log

# Tests
tests
*.test.ts
*.test.js
coverage

# Documentation
README.md
docs
```

### Docker Compose (dev)

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - '8000:8000'
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
      - LOG_LEVEL=debug
    volumes:
      - ./src:/app/src
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    ports:
      - '5432:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U user']
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

## Restrições

- **Multi-stage**: SEMPRE use para separar build de runtime
- **Base images**: prefira `-alpine` ou `-slim`
- **Non-root**: NUNCA rode como root, use `USER`
- **HEALTHCHECK**: sempre defina para produção
- **.dockerignore**: crie para excluir desnecessários
- **Layer caching**: ordene comandos do menos mutável ao mais
- **apt cleanup**: sempre `rm -rf /var/lib/apt/lists/*`
- **pip cache**: use `--no-cache-dir`
- **npm/pnpm**: use `--frozen-lockfile` ou `ci`

## Comandos

```bash
# Build
docker build -t myapp:latest .

# Build com cache otimizado
docker build --target builder -t myapp:builder .
docker build -t myapp:latest .

# Run com health check
docker run --rm -p 8000:8000 --name myapp myapp:latest

# Check health
docker inspect --format='{{.State.Health.Status}}' myapp

# Compose
docker compose up -d
docker compose logs -f app
docker compose down -v
```

## Saída esperada

1. Dockerfile multi-stage com builder + runtime
2. .dockerignore com exclusões apropriadas
3. HEALTHCHECK definido
4. USER non-root configurado
5. Comandos de build e run

---

# TypeScript Core — Instruções para o LLM

Contexto: typing, validation, error handling em TypeScript puro.

## Objetivo do assistant

- Gerar código type-safe com Zod validation e error handling robusto.
- Usar recursos modernos (satisfies, as const, type narrowing).

## Estrutura esperada

### Validation com Zod

```typescript
// config/env.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'production', 'test'])
    .default('development'),
  PORT: z.string().transform(Number).pipe(z.number().min(1).max(65535)),
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z
    .string()
    .regex(/^\d+[smhd]$/)
    .default('1d'),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
});

export const env = envSchema.parse(process.env);

export type Env = z.infer<typeof envSchema>;
```

### Custom Error Classes

```typescript
// errors/AppError.ts
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
    public readonly isOperational = true,
    public readonly context?: Record<string, unknown>
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  constructor(message: string, context?: Record<string, unknown>) {
    super(400, message, true, context);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string | number) {
    super(404, `${resource} with id ${id} not found`, true, { resource, id });
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(401, message, true);
  }
}
```

### Type narrowing com satisfies

```typescript
// types/user.ts
export type UserRole = 'admin' | 'user' | 'guest';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  metadata: Record<string, unknown>;
}

// Using satisfies for type checking while preserving literal types
export const DEFAULT_PERMISSIONS = {
  admin: ['read', 'write', 'delete'],
  user: ['read', 'write'],
  guest: ['read'],
} as const satisfies Record<UserRole, readonly string[]>;

// Type is inferred as:
// { readonly admin: readonly ['read', 'write', 'delete'], ... }
```

### Result type pattern

```typescript
// types/result.ts
export type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };

export function success<T>(value: T): Result<T, never> {
  return { ok: true, value };
}

export function failure<E>(error: E): Result<never, E> {
  return { ok: false, error };
}

// Usage example
import type { User } from './user';

async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      return failure(new NotFoundError('User', id));
    }
    const user = await response.json();
    return success(user);
  } catch (error) {
    return failure(error as Error);
  }
}

// Consuming
const result = await fetchUser('123');
if (result.ok) {
  console.log(result.value.name); // Type-safe access
} else {
  console.error(result.error.message);
}
```

### Type guards

```typescript
// utils/guards.ts
export function isString(value: unknown): value is string {
  return typeof value === 'string';
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function hasProperty<K extends string>(
  obj: unknown,
  key: K
): obj is Record<K, unknown> {
  return isRecord(obj) && key in obj;
}

// Usage
function processData(data: unknown) {
  if (!isRecord(data)) {
    throw new ValidationError('Data must be an object');
  }

  if (!hasProperty(data, 'id') || !isString(data.id)) {
    throw new ValidationError('Data must have a string id');
  }

  // Now data.id is type-safe (string)
  console.log(data.id.toUpperCase());
}
```

### tsconfig.json (strict)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "lib": ["ES2022"],
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowImportingTsExtensions": true,
    "isolatedModules": true,
    "noEmit": true,

    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noImplicitOverride": true,

    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

## Restrições

- **Strict mode**: sempre habilitado
- **any**: proibido, use `unknown` e narrowing
- **Type assertions**: evite, prefira type guards
- **Enums**: prefira union types ou `as const`
- **noUncheckedIndexedAccess**: sempre habilitado
- **Indentação**: 2 espaços

## Comandos

```bash
# Type check
pnpm exec tsc --noEmit

# Run with type checking
pnpm exec tsx src/main.ts
```

## Saída esperada

1. Zod schemas para validation
2. Custom error classes estendendo Error
3. Type guards para runtime checks
4. satisfies para preservar literal types
5. tsconfig.json strict configurado

---

# Instruções Base — Foco LLM

Objetivo: instruções concisas que o LLM necessita para gerar código e mudanças seguras no repositório.

## Regras gerais

- Responda em **português brasileiro**; gere **código em inglês**.
- Formato da resposta:
  - 1. Código (marcado).
  - 2. Testes mínimos (quando aplicável).
  - 3. Explicação em até 2 linhas.
- Priorize: **tests**, **type hints**, **segurança** (validação/escaping), **reprodutibilidade** (seeds, envs).
- Não use emojis; use ícones (Nerd Font) apenas se solicitado explicitamente.

## Ambiente do desenvolvedor (VS Code)

**Formatação e estilo:**

- Line length: **79 caracteres** (Python, geral)
- Indentação: **2 espaços** (JS/TS/JSON/YAML), **4 espaços** (Python)
- Formatadores: Ruff (Python), Prettier (JS/TS/JSON/CSS)
- Linters: Ruff (Python), ESLint (JS/TS), Flake8 (Python)

**Ferramentas configuradas:**

- Python: `ruff format`, `ruff check`, `pytest`, `mypy`/`pyright` (type checking desabilitado por padrão)
- JavaScript/TypeScript: `prettier`, `eslint` (run on save)
- Shell: Bash IDE formatter
- Java: RedHat formatter

**Executores de código (code-runner):**

- Python: `clear ; python -u`
- JavaScript: `clear ; node`
- TypeScript: `ts-node`
- Java: `clear ; cd $dir && javac $fileName && java $fileNameWithoutExt`

**Boas práticas esperadas:**

- Format on save ativado (gere código já formatado)
- Organize imports automaticamente
- Use type hints (Python) e strict typing (TypeScript)
- Testes com `pytest` (Python) ou `vitest` (JS/TS)

## Exemplo de prompt ideal

"Implemente `function` X com typing, adicione `pytest` unit tests e explique em 1 linha como executar os testes."

## Do / Don't

- Do: oferecer snippets minimalistas testáveis e comandos para executar.
- Don't: fornecer longas explicações, guias de instalação passo-a-passo ou opiniões não solicitadas.

Use este arquivo em conjunto com templates específicos (`python-core.md`, `fastapi.md`, `docker.md`, etc.).

## Qualidade de Código

### Princípios Fundamentais

**SEMPRE aplique estes princípios ao criar ou modificar código:**

- **DRY (Don't Repeat Yourself)**: nunca duplique código

  - Extraia código repetido em funções reutilizáveis
  - Crie bibliotecas compartilhadas para lógica comum
  - Use herança, composição ou mixins quando apropriado

- **KISS (Keep It Simple, Stupid)**: prefira simplicidade sobre complexidade

  - Escolha a solução mais simples que funciona
  - Evite otimizações prematuras
  - Código simples é mais fácil de entender e manter

- **SRP (Single Responsibility Principle)**: cada unidade tem uma única responsabilidade
  - Uma função faz uma coisa e faz bem
  - Uma classe/módulo tem um único motivo para mudar
  - Separe lógica de negócio de lógica de apresentação

### Detecção de Code Smells

**Identifique e refatore estes problemas:**

- **Funções longas**: > 20-30 linhas indica necessidade de decomposição
- **Classes gigantes**: muitas responsabilidades, divida em classes menores
- **Código duplicado**: violação do DRY, extraia para função comum
- **Muitos parâmetros**: > 3-4 parâmetros, considere objeto de configuração
- **Comentários excessivos**: código deve ser autoexplicativo
- **Nomes vagos**: `data`, `temp`, `x` - use nomes descritivos
- **Condicionais aninhadas**: > 2 níveis, extraia em funções
- **Magic numbers**: use constantes nomeadas
- **God objects**: objetos que fazem tudo, refatore em objetos menores

### Princípios de Código Limpo

- **Nomenclatura**: use nomes descritivos e significativos

  - **Siga as convenções da comunidade de cada linguagem/framework**:
    - Python: `snake_case` para funções/variáveis, `PascalCase` para classes
    - JavaScript/TypeScript: `camelCase` para funções/variáveis, `PascalCase` para classes/componentes
    - Java: `camelCase` para métodos/variáveis, `PascalCase` para classes
    - Bash: `snake_case` ou `lowercase` para funções/variáveis
    - CSS/HTML: `kebab-case` para classes e IDs
    - Constantes: `UPPER_SNAKE_CASE` na maioria das linguagens
  - Funções: verbos (`calculate_total`, `send_email`, `handleClick`)
  - Classes: substantivos (`User`, `OrderProcessor`, `UserProfile`)
  - Booleanos: predicados (`is_valid`, `has_permission`, `canEdit`)
  - **Prefixo `handle` para event handlers**: `handleSubmit`, `handleClick`, `handleChange`
  - **Prefixo `on` para callbacks/props**: `onClick`, `onSubmit`, `onError` (comum em React/frameworks)
  - Use nomes do domínio do problema, não da implementação

- **Funções pequenas**: cada função deve fazer apenas uma coisa e fazê-la bem

  - Máximo 20-30 linhas
  - Um único nível de abstração
  - Sem efeitos colaterais escondidos

- **Comentários**: use para explicar "por quê", não "o quê"

  - Código deve ser autoexplicativo
  - Docstrings para APIs públicas
  - TODO/FIXME com contexto e data

- **Formatação consistente**: mantenha indentação e estilo uniformes

  - Use formatadores automáticos (black, prettier, etc.)
  - Siga guias de estilo da linguagem

- **Tratamento de erros**: sempre valide inputs e trate erros explicitamente
  - Fail fast: valide no início da função
  - Use exceções específicas, não genéricas
  - Nunca ignore erros silenciosamente

### Arquitetura de Software

#### Para Scripts Shell

- **Separação de responsabilidades**: divida scripts grandes em módulos menores
- **Biblioteca de funções comuns**: centralize funcionalidades reutilizáveis em `scripts/lib/`
- **Configuração separada**: mantenha configurações em arquivos separados (variáveis, constantes)
- **Single Responsibility**: cada script deve ter um propósito claro e único

#### Para Projetos Python

- **Clean Architecture**: organize código em camadas (domain, application, infrastructure)
- **Dependency Injection**: prefira passar dependências via parâmetros
- **SOLID Principles**: aplique quando apropriado ao contexto
  - Single Responsibility: uma classe/módulo, uma responsabilidade
  - Open/Closed: aberto para extensão, fechado para modificação
  - Liskov Substitution: subtipos devem ser substituíveis por seus tipos base
  - Interface Segregation: interfaces específicas são melhores que genéricas
  - Dependency Inversion: dependa de abstrações, não de implementações concretas
- **Estrutura de pastas**: organize por funcionalidade, não por tipo de arquivo

#### Boas Práticas Gerais

- **Modularidade**: código modular é mais fácil de testar e manter
- **Testabilidade**: escreva código que seja fácil de testar
- **Baixo acoplamento**: minimize dependências entre módulos
- **Alta coesão**: mantenha funcionalidades relacionadas juntas
- **Princípio KISS**: Keep It Simple, Stupid - prefira simplicidade

---

## DevOps & Infraestrutura

### Princípios Fundamentais

- **Idempotência**: Todo script ou comando de configuração deve ser seguro para rodar múltiplas vezes
- **Observabilidade**: Sempre inclua logs estruturados e health checks para serviços backend
- **Segurança (POLP)**: Princípio do Menor Privilégio - evite `sudo`/`root` a menos que necessário
- **Reprodutibilidade**: Use versionamento de dependências e lock files
- **Modern Linux Tooling**: Use ferramentas modernas (`eza`, `bat`, `fd`, `rg`) em contextos interativos, POSIX em scripts de automação para portabilidade

### Docker

- **Multi-stage builds**: SEMPRE use para reduzir tamanho de imagens
- **Imagens base leves**: Prefira `alpine`, `-slim` ou `distroless`
- **Non-root user**: NUNCA rode como root, use instrução `USER`
- **Health checks**: Defina `HEALTHCHECK` em produção
- **.dockerignore**: Sempre crie para excluir arquivos desnecessários

Exemplo:

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .

RUN useradd -m appuser
USER appuser

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8000/health || exit 1
```

### Kubernetes

- **Resource limits**: SEMPRE defina requests e limits
- **Probes**: Configure liveness e readiness probes
- **Namespaces**: Use para isolamento lógico
- **Labels**: Padronize labels para service discovery
- **Secrets**: Use ConfigMaps e Secrets, nunca hardcode configurações

### Infrastructure as Code

**Terraform/OpenTofu:**

- Mantenha estado remoto (Remote State)
- Use módulos para recursos repetitivos
- Siga convenção: `resource_type.name_of_resource`
- Sempre use variáveis para valores configuráveis

**Ansible:**

- Use roles para organização
- Sempre use tags para seletividade
- Handlers para restart de serviços
- Idempotência é essencial

### Systemd (Linux)

- **Unit Files**: Sempre defina `Restart=on-failure`
- **Sandboxing**: Use `ProtectSystem=full`, `PrivateTmp=true`, `NoNewPrivileges=true`
- **Validação**: Use `systemd-analyze security` para validar configurações
- **Logs**: Centralize com `journalctl`

### Networking (Linux)

- Use `iproute2` (`ip`) ao invés de `net-tools` (`ifconfig`)
- Prefira `nftables` sobre `iptables`
- Para DNS: use `systemd-resolved` ou `resolvectl`

### Segurança

**Desenvolvimento:**

- Validação de inputs (OWASP Top 10)
- Secrets em variáveis de ambiente (nunca em código)
- Dependências atualizadas (Dependabot, Renovate)
- Sanitize user input antes de processar
- Use prepared statements/parametrized queries

**Sistema:**

- Permissões mínimas: `chmod 600` para arquivos sensíveis
- Firewall configurado (ufw/nftables)
- SSH hardening: chaves, disable root, fail2ban
- Logs de auditoria habilitados

**Containers:**

- Scan de imagens (trivy, grype)
- Non-root user obrigatório
- Read-only filesystem quando possível
- Secrets via Docker secrets ou volumes criptografados

### Performance e Otimização

**Shell Scripts:**

- Evite subshells desnecessários: `$(cmd)` vs `` `cmd` ``
- Use built-ins ao invés de comandos externos quando possível
- Prefira `[[` ao invés de `[` em bash

**Python:**

- Use comprehensions ao invés de loops quando apropriado
- Considere `asyncio` para operações I/O intensivas
- Profile com `cProfile` antes de otimizar
- Use `polars` ou `numpy` para processamento pesado

**Java:**

- Virtual Threads (Java 21+) para I/O intensivo
- Lazy evaluation com Streams
- StringBuilder para concatenação de strings em loops
- Evite reflection em código crítico

**TypeScript/Node.js:**

- Entenda o Event Loop: não bloqueie com sync operations
- Use async/await patterns corretamente
- Bundling e tree-shaking para reduzir tamanho
- Worker threads para processamento CPU intensivo

**Docker:**

- Layer caching: ordene COPY de menos mutável para mais
- Multi-stage builds para imagens enxutas
- Use `.dockerignore` para excluir desnecessários
- BuildKit para builds paralelos e cache avançado

---

## Ferramentas e Ambiente

### Gerenciamento de Versões e Ambientes

**SEMPRE use `mise` para instalar e gerenciar ferramentas:**

- **Linguagens de programação**: Python, Node.js, Go, Rust, Java, etc.
- **Ferramentas de desenvolvimento**: shellcheck, shfmt, ruff, yamllint, jq, bats, etc.
- **Gerenciadores de pacotes**: uv (Python), pnpm (Node.js)
- **Configure versões no `mise.toml`** para reprodutibilidade
- **Evite usar gerenciadores de pacotes do sistema** (pacman/yay/apt) para ferramentas de desenvolvimento

**Padrão obrigatório:**

```toml
# mise.toml
[tools]
# Linguagens de programação
python = "3.13"
node = "20"

# Ferramentas de desenvolvimento
uv = "latest"              # Gerenciador Python
shellcheck = "latest"      # Linter shell
ruff = "latest"            # Linter/formatter Python
yamllint = "latest"        # Linter YAML
jq = "latest"              # Processador JSON
bats = "latest"            # Framework de testes Bash
```

**Workflow:**

```bash
# Instalar todas as ferramentas definidas em mise.toml
mise install

# Executar comandos com mise (usa versões do mise.toml)
mise exec -- python --version
mise exec -- shellcheck script.sh
mise exec -- ruff check .

# Ou ativar mise no shell (opcional)
eval "$(mise activate bash)"
python --version  # Usa versão do mise automaticamente
```

**CI/CD:**

```yaml
# .gitlab-ci.yml template
.install-mise: &install-mise
  - curl https://mise.run | sh
  - export PATH="$HOME/.local/bin:$PATH"
  - mise install

job-name:
  before_script:
    - *install-mise
  script:
    - mise exec -- command
```

### Configuração de Ferramentas

**pyproject.toml (Python):**

- Configure ruff, black, pytest
- Use `uv init` para começar novos projetos

**mise.toml:**

- Pin versões específicas para reprodutibilidade
- Use plugins oficiais quando disponível

**.editorconfig:**

- Mantenha consistência entre editores
- Defina charset, indentação, fim de linha

### Ambiente de Desenvolvimento (VS Code)

**Ferramentas:**

- **ShellCheck Extension**: análise estática de shell scripts em tempo real
  - Detecta erros comuns e sugere boas práticas durante a escrita
  - Integrado ao editor para feedback instantâneo
  - Configurado para severity `warning` ou superior

**Shell e Aliases:**

O ambiente usa Fish shell interativo com aliases modernos. **SEMPRE considere estes aliases ao sugerir ou executar comandos:**

**Nota sobre uso:**

- **Em scripts**: use comandos nativos POSIX para portabilidade
- **Interativamente**: mencione versões com alias quando executar
- **Exemplos**: "Execute `ls -la`" (script) vs "Vejo pelo `ll` que..." (interativo)

**Utilitários Modernos:**

- `cp` → `rsync -ah --progress`
- `ls` → `eza --icons --classify --group-directories-first`
- `ll` → `eza -l --icons --group-directories-first --time-style=relative --git`
- `cat` → `bat --style=auto --paging=auto`
- `lt` → `eza --tree --level=2 --icons`
- `find` → `fd --hidden --follow --exclude .git`
- `grep` → `rg --smart-case --hidden --follow --glob '!.git'`
- `pn` → `pnpm`

**Gerenciamento de Pacotes:**

- `add-arch` → `yay -S --needed --noconfirm`
- `remove-arch` → `yay -Rns`
- `update-arch` → `flatpak update -y; and yay -Syu --noconfirm; and yay -Ycc`
- `flatpak-search` → `flatpak search --columns=name,application`

---

## Workflows de Desenvolvimento

### Testes e Validação

**Shell Scripts:**

- Validação com `shellcheck --severity=warning` (via extensão do VS Code para análise em tempo real)
- Teste com `bash -n script.sh` (dry-run)
- Use `bats` para testes automatizados quando apropriado
- A extensão ShellCheck do VS Code fornece feedback instantâneo sobre boas práticas durante a escrita

**Python:**

- Use `pytest` para testes
- Cobertura mínima: funções críticas devem ter testes
- Mock de comandos do sistema com `unittest.mock`

### Debugging e Troubleshooting

- Use `set -x` para debug de shell scripts
- Para Python: use `logging` ao invés de `print`
- Logs estruturados: inclua timestamp, nível, contexto
- Teste em ambiente isolado: containers ou VMs quando possível

### Commits e Versionamento

**Tipos de Conventional Commits:**

- `feat:` - nova funcionalidade para o usuário
- `fix:` - correção de bug
- `docs:` - apenas mudanças na documentação
- `style:` - formatação, ponto e vírgula, etc (sem mudança de código)
- `refactor:` - refatoração sem alterar funcionalidade
- `perf:` - melhorias de performance
- `test:` - adição ou correção de testes
- `chore:` - tarefas de manutenção (deps, config, build)
- `ci:` - mudanças em CI/CD
- `build:` - mudanças no sistema de build

**Boas Práticas:**

- Mensagens em português: `feat: adiciona suporte ao River`
- Commits atômicos: uma mudança lógica por commit
- Use `git commit --amend` para correções pequenas
- Primeira linha: máximo 72 caracteres
- Corpo opcional: explique "por quê", não "o quê"
- **Sugira commits frequentemente**: ao finalizar ciclos, sprints ou modificações significativas
  - Evite acumular múltiplas mudanças em um único commit
  - Facilita rollback e rastreamento de mudanças
  - Mantenha histórico limpo e semântico

### Checklist Antes de Finalizar

**Scripts (Shell):**

- [ ] Testado com shellcheck
- [ ] Executável (`chmod +x`)
- [ ] Testado em ambiente limpo
- [ ] Backup criado se modifica sistema
- [ ] Shebang correto (`#!/usr/bin/env bash`)
- [ ] `set -e` no início

**Python:**

- [ ] Type hints completos
- [ ] Docstrings presentes
- [ ] Formatado com ruff/black
- [ ] Imports organizados
- [ ] Sem warnings do mypy/pyright
- [ ] Testes passando

**TypeScript/React:**

- [ ] Types corretos (sem `any` desnecessário)
- [ ] Componentes testados
- [ ] Props documentadas (JSDoc)
- [ ] Formatado com prettier
- [ ] Sem warnings do ESLint
- [ ] Build produção funcional

**Java/Spring:**

- [ ] Records usados para DTOs
- [ ] Exceptions específicas
- [ ] Testes unitários presentes
- [ ] JavaDoc em APIs públicas
- [ ] Sem warnings do compilador
- [ ] Constructor injection usado

### Padrões de Resposta

### Pesquisa e Validação

- **SEMPRE** consulte documentações oficiais e recentes antes de sugerir mudanças
- **SEMPRE** verifique boas práticas validadas pela comunidade (GitHub, Arch Wiki, fóruns oficiais)
- Priorize soluções comprovadas e bem documentadas
- Verifique compatibilidade de versões e dependências
- Consulte issues e discussions de projetos para problemas conhecidos
- Use fontes confiáveis: documentação oficial > Arch Wiki > fóruns oficiais > Stack Overflow

### Ao Criar/Modificar Código

1. Pesquise boas práticas atuais para a tecnologia específica
2. Explique brevemente o que será feito
3. Implemente a solução seguindo padrões da comunidade
4. Destaque pontos importantes apenas se necessário
5. Seja direto e objetivo

### Ao Corrigir Erros

- Identifique a causa raiz
- Consulte documentação e issues relacionadas
- Explique o problema de forma clara
- Forneça a correção baseada em práticas validadas
- Sugira como evitar no futuro apenas se relevante

### Ao Sugerir Melhorias

- Pesquise soluções já existentes e bem estabelecidas
- Foque em melhorias práticas e aplicáveis
- Priorize legibilidade e manutenibilidade
- Considere o contexto do projeto (dotfiles pessoais)
- Verifique se a sugestão é amplamente recomendada pela comunidade

### Ao Finalizar Tarefas

- Sugira commit com mensagem apropriada
- Use tipo correto de Conventional Commit
- Mantenha mensagem descritiva mas concisa
- Separe mudanças lógicas em commits diferentes
- Inclua contexto relevante no corpo do commit quando necessário

---

## Linters e Formatadores

### Shell/Bash

- **Análise estática**: ShellCheck (via extensão VS Code)
- **Formatação**: shfmt
- **Stack mínimo**: ShellCheck + shfmt

### Python

- **Linter + Formatter**: Ruff (all-in-one, baseado em Rust)
- **Type checking**: mypy ou pyright
- **Stack atual**: UV + Ruff (já ideal)

### Java

- **IDE**: IntelliJ IDEA (linter integrado)
- **Formatter**: Spotless (apenas para projetos em equipe)
- **Evite**: Checkstyle/PMD para projetos pessoais

### TypeScript/Node.js

- **Linter**: ESLint + @typescript-eslint
- **Formatter**: Prettier
- **Stack atual**: já configurado (nada a adicionar)

### PHP (futuro)

- **Verificação**: PHP_CodeSniffer
- **Correção**: PHP-CS-Fixer

### Princípios para Escolha de Linters

**Adicione ferramentas apenas se**:

- 󰄬 Resolver problema real no workflow
- 󰄬 Não sobrepor funcionalidade existente
- 󰄬 Ter comunidade ativa e manutenção regular
- 󰄬 Integrar bem com stack atual

**Evite**:

- 󰅙 Redundância (Bashate vs ShellCheck)
- 󰅙 Forks inativos (shellcheck-ng)
- 󰅙 Overkill para projetos pessoais (Checkstyle/PMD em Java)
- 󰅙 Ferramentas opinativas demais para contexto genérico

---

## Referências Úteis

### Shell & Scripting

- [Fish Shell Documentation](https://fishshell.com/docs/current/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck Wiki](https://www.shellcheck.net/wiki/)

### Ferramentas de Desenvolvimento

- [UV Documentation](https://docs.astral.sh/uv/)
- [PNPM Documentation](https://pnpm.io/)
- [Mise Documentation](https://mise.jdx.dev/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)

### Backend & Frameworks

- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [React Documentation](https://react.dev/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

### DevOps & Infrastructure

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Conventional Commits](https://www.conventionalcommits.org/)

### Segurança

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

### Design & Tipografia

- [Nerd Fonts Cheat Sheet](https://www.nerdfonts.com/cheat-sheet)
