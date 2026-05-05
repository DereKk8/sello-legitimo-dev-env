# Sello Legítimo - Entorno de Desarrollo Local

Este repositorio contiene la orquestación de Docker Compose para levantar el entorno de desarrollo local del proyecto **Sello Legítimo**.

## Prerrequisitos

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Git](https://git-scm.com/)

## Repositorios Necesarios

Para levantar el entorno completo, necesitas clonar los siguientes repositorios en la **misma carpeta padre** donde clonarás este repositorio de orquestación:

| Repositorio | Descripción | Característica / Funcionalidad |
|---|---|---|
| `ConfiguracionEleccion-service` | Backend de Configuración de Elecciones (Java + gRPC) | Gestión de elecciones, candidatos, mesas y configuración central del sistema |
| `GestionPreElectoral-service` | Backend de Gestión Pre-Electoral (Java) | Preparación pre-electoral, reportes y tareas previas a la jornada electoral |
| `MockJurados-service` | Backend Mock de Jurados (Java + gRPC) | Simulación del servicio de jurados para pruebas locales |
| `frontend-ConfiguracionElecciones` | Frontend de Configuración de Elecciones | Interfaz web para configurar elecciones, candidatos y mesas |
| `frontend-GestionPreelectoral` | Frontend de Gestión Pre-Electoral | Interfaz web para la gestión pre-electoral y reportes |

> **Nota:** Este repositorio (`sello-legitimo-dev-env`) debe clonarse junto a los anteriores, de modo que los `build.context` de los `docker-compose` resuelvan correctamente las rutas relativas.

## Estructura de Directorios Esperada

```text
sello-legitimo-workspace/
├── sello-legitimo-dev-env/           # Este repositorio
│   ├── docker-compose.local.yml
│   ├── docker-compose.local.gateway.yml
│   └── gateway/
│       └── config/
│           ├── authelia/
│           │   ├── configuration.yml
│           │   ├── users_database.yml
│           │   └── oidc_private_key.pem
│           └── caddy/
│               └── Caddyfile.local
├── ConfiguracionEleccion-service/
├── GestionPreElectoral-service/
├── MockJurados-service/
├── frontend-ConfiguracionElecciones/
└── frontend-GestionPreelectoral/
```

## Configuración del Gateway

Antes de levantar los servicios, asegúrate de contar con los archivos de configuración del gateway dentro de la carpeta `gateway/config/`:

- `gateway/config/authelia/configuration.yml`
- `gateway/config/authelia/users_database.yml`
- `gateway/config/authelia/oidc_private_key.pem`
- `gateway/config/caddy/Caddyfile.local`

> **Importante:** El archivo `oidc_private_key.pem` es un secreto. **No lo subas a Git.** Solicítalo al líder técnico o genera uno nuevo para tu entorno local.

## Cómo Levantar el Entorno

### 1. Clonar los repositorios

```bash
# Crear carpeta de trabajo
mkdir sello-legitimo-workspace
cd sello-legitimo-workspace

# Clonar este repositorio de orquestación
git clone https://github.com/DereKk8/sello-legitimo-dev-env.git
cd sello-legitimo-dev-env

# Clonar los servicios backend y frontend (ajusta las URLs según tu organización)
git clone https://github.com/DereKk8/ConfiguracionEleccion-service.git ../ConfiguracionEleccion-service
git clone https://github.com/DereKk8/GestionPreElectoral-service.git ../GestionPreElectoral-service
git clone https://github.com/DereKk8/MockJurados-service.git ../MockJurados-service
git clone https://github.com/DereKk8/frontend-ConfiguracionElecciones.git ../frontend-ConfiguracionElecciones
git clone https://github.com/DereKk8/frontend-GestionPreelectoral.git ../frontend-GestionPreelectoral
```

> **Nota:** Si los repositorios pertenecen a otra organización o usuario, reemplaza `DereKk8` por el nombre correspondiente.

### 2. Levantar backend y bases de datos

Desde la raíz de `sello-legitimo-dev-env`:

```bash
docker compose -f docker-compose.local.yml up --build -d
```

Esto levanta:
- `configuracion-eleccion-postgres` (PostgreSQL para Configuración Elección) — expuesto en `localhost:5433`
- `gestion-pre-electoral-postgres` (PostgreSQL para Gestión Pre-Electoral) — expuesto en `localhost:5434`
- `configuracion-eleccion` (Backend Configuración Elección) — `localhost:8081` (HTTP), `localhost:9090` (gRPC)
- `gestion-pre-electoral` (Backend Gestión Pre-Electoral) — `localhost:8082`
- `mock-jurados` (Mock Jurados) — `localhost:8083`, `localhost:9091` (gRPC)

### 3. Levantar gateway, Authelia y frontends

Una vez que los servicios backend estén saludables:

```bash
docker compose -f docker-compose.local.gateway.yml up --build -d
```

Esto levanta:
- `authelia` — Servicio de autenticación / SSO
- `gateway` (Caddy) — Reverse proxy en `https://localhost:8091`
- `election-conf-frontend` — Frontend Configuración Elecciones
- `preelectoral-frontend` — Frontend Gestión Pre-Electoral

### 4. Verificar que todo está corriendo

```bash
docker compose -f docker-compose.local.yml ps
docker compose -f docker-compose.local.gateway.yml ps
```

## Acceso a la Aplicación

| Servicio | URL Local |
|---|---|
| Gateway (Caddy) | `https://localhost:8091` |
| Frontend Configuración Elecciones | `https://eleccion.sello-legitimo.site:8091` |
| Frontend Gestión Pre-Electoral | `https://preeleccion.sello-legitimo.site:8091` |
| Authelia | `https://auth.sello-legitimo.site:8091` |
| Backend Configuración Elección | `http://localhost:8081` |
| Backend Gestión Pre-Electoral | `http://localhost:8082` |
| Backend Mock Jurados | `http://localhost:8083` |

> **Nota:** Las URLs con dominio `*.sello-legitimo.site` requieren que tengas configuradas las entradas en tu archivo `hosts` apuntando a `127.0.0.1`, o que uses el puerto `8091` directamente con `localhost`.

## Puertos Expuestos

| Puerto | Servicio |
|---|---|
| `5433` | PostgreSQL — Configuración Elección |
| `5434` | PostgreSQL — Gestión Pre-Electoral |
| `8081` | Backend Configuración Elección (HTTP) |
| `8082` | Backend Gestión Pre-Electoral |
| `8083` | Backend Mock Jurados |
| `9090` | Backend Configuración Elección (gRPC) |
| `8091` | Gateway Caddy (HTTPS) |
| `9091` | Backend Mock Jurados (gRPC) |

## Comandos Útiles

```bash
# Ver logs de todos los servicios backend
docker compose -f docker-compose.local.yml logs -f

# Ver logs del gateway y frontends
docker compose -f docker-compose.local.gateway.yml logs -f

# Detener todos los servicios backend
docker compose -f docker-compose.local.yml down

# Detener gateway y frontends
docker compose -f docker-compose.local.gateway.yml down

# Detener todo y eliminar volúmenes (⚠️ borra datos de PostgreSQL)
docker compose -f docker-compose.local.yml down -v
docker compose -f docker-compose.local.gateway.yml down -v
```

## Notas para el Equipo de Desarrollo

- **Configuración Elección** es el servicio central. Tanto `GestionPreElectoral-service` como `MockJurados-service` dependen de él para la comunicación gRPC.
- Si solo necesitas trabajar en un frontend específico, puedes levantar solo `docker-compose.local.yml` y usar el backend directamente sin pasar por Caddy (según la configuración de cada proyecto).
- Asegúrate de que los `Dockerfile` de cada servicio estén en la raíz de su respectivo repositorio, tal como lo esperan los `docker-compose`.
- Si realizas cambios en el código de algún servicio, reconstruye la imagen con:
  ```bash
  docker compose -f docker-compose.local.yml up --build -d <nombre-del-servicio>
  ```
