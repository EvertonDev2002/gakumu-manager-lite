# 📚 GakumuManager Lite

> Um gerenciador acadêmico simples e eficiente para instituições de ensino.

**Projeto Final da Disciplina Desenvolvimento Web**

---

## 📖 Sobre o Projeto

O **GakumuManager Lite** é um sistema de gerenciamento acadêmico desenvolvido para facilitar a administração de alunos, professores, cursos, disciplinas, turmas e matrículas em instituições de ensino. Com uma interface simples e intuitiva, o sistema oferece todas as funcionalidades essenciais para o gerenciamento acadêmico.

### 🏷️ Significado do Nome

- **Gakumu (学務)**: Termo japonês que significa "assuntos acadêmicos" ou "serviços acadêmicos"
- **Manager**: Palavra em inglês que significa "gerenciador" ou "administrador"
- **Lite**: Sufixo em inglês usado para versões mais leves ou simplificadas de um produto

---

## 🚀 Tecnologias

### Backend

- **NestJS** - Framework Node.js progressivo
- **TypeScript** - Linguagem de programação
- **Docker** - Containerização
- **PostgreSQL** - Banco de dados (via Docker)

### Frontend

- Em desenvolvimento

---

## 📋 Requisitos Funcionais

### 👥 Gestão de Alunos

- ✅ Cadastrar alunos
- ✅ Listar alunos cadastrados
- ✅ Editar informações de alunos
- ✅ Excluir alunos
- ✅ Consultar informações cadastrais dos alunos

### 👨‍🏫 Gestão de Professores

- ✅ Cadastrar professores
- ✅ Listar professores cadastrados
- ✅ Editar informações de professores
- ✅ Excluir professores
- ✅ Consultar informações cadastrais
- ✅ Atribuir turmas e disciplinas aos professores

### 📚 Gestão de Cursos e Disciplinas

- ✅ Cadastrar cursos
- ✅ Manter e atualizar cursos
- ✅ Cadastrar disciplinas
- ✅ Manter e atualizar disciplinas

### 🎓 Gestão de Turmas

- ✅ Cadastrar turmas
- ✅ Manter e atualizar turmas

### 📝 Gestão de Matrículas

- ✅ Inscrever alunos em disciplinas
- ✅ Cancelar matrículas
- ✅ Listar alunos por turma

---

## 🗂️ Estrutura do Projeto

```
gakumu-manager-lite/
├── backend/               # API Backend (NestJS)
│   ├── src/              # Código fonte
│   ├── test/             # Testes
│   ├── docker-compose.yml
│   └── package.json
├── docs/                 # Documentação
├── frontend/             # Interface Frontend (Em desenvolvimento)
├── README.md
└── LICENSE
```

---

## ⚙️ Configuração e Instalação

### Pré-requisitos

- Node.js (v18 ou superior)
- pnpm
- Docker e Docker Compose

### Backend

1. **Navegue até a pasta do backend:**

   ```bash
   cd backend
   ```

2. **Instale as dependências:**

   ```bash
   pnpm install
   ```

3. **Configure o ambiente de desenvolvimento:**

   ```bash
   chmod +x docker-setup.sh
   ./docker-setup.sh
   ```

4. **Inicie os serviços com Docker:**

   ```bash
   docker-compose -f docker-compose.dev.yml up -d
   ```

5. **Execute o servidor de desenvolvimento:**
   ```bash
   pnpm run start:dev
   ```

O servidor estará disponível em `http://localhost:3000`

---

## 🧪 Testes

```bash
# Testes unitários
pnpm run test

# Testes e2e
pnpm run test:e2e

# Cobertura de testes
pnpm run test:cov
```

---

## 📝 API Documentation

Após iniciar o servidor, a documentação da API estará disponível em:

- Swagger UI: `http://localhost:3000/api`

---

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença especificada no arquivo [LICENSE](LICENSE).

---

## 👨‍💻 Autor

Desenvolvido como Projeto Final da Disciplina Desenvolvimento Web
