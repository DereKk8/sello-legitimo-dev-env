# Sello Legitimo - Entorno de Desarrollo Local

Este repositorio contiene la orquestacion de Docker Compose para levantar el entorno de desarrollo local del proyecto **Sello Legitimo**.

> **Nota importante:** Este repo es **independiente** del repositorio del Gateway de produccion. Toda la configuracion necesaria de Caddy y Authelia para desarrollo local esta incluida aqui, de modo que no necesitas clonar ni tocar el repo del gateway (cuya configuracion remota puede estar desactualizada).

## Prerrequisitos

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Git](https://git-scm.com/)
- `openssl` (para generar la clave privada OIDC)
- `python3` (para ejecutar el script de configuracion inicial del gateway)

## Repositorios Necesarios

Para levantar el entorno completo, clona los siguientes repositorios en la **misma carpeta padre** donde clonaras este repositorio de orquestacion:

| Repositorio | Descripcion | Caracteristica / Funcionalidad |
|---|---|---|
| `ConfiguracionEleccion-service` | Backend de Configuracion de Elecciones (Java + gRPC) | Gestion de elecciones, candidatos, mesas y configuracion central del sistema |
| `GestionPreElectoral-service` | Backend de Gestion Pre-Electoral (Java) | Preparacion pre-electoral, reportes y tareas previas a la jornada electoral |
| `MockJurados-service` | Backend Mock de Jurados (Java + gRPC) | Simulacion del servicio de jurados para pruebas locales |
| `frontend-ConfiguracionElecciones` | Frontend de Configuracion de Elecciones | Interfaz web para configurar elecciones, candidatos y mesas |
| `frontend-GestionPreelectoral` | Frontend de Gestion Pre-Electoral | Interfaz web para la gestion pre-electoral y reportes |

> **No necesitas clonar el repositorio del Gateway.** La configuracion de Caddy y Authelia para desarrollo local ya esta incluida en este repo.

## Estructura de Directorios Esperada

```text
sello-legitimo-workspace/
├── sello-legitimo-dev-env/           # Este repositorio
│   ├── docker-compose.local.yml
│   ├── docker-compose.local.gateway.yml
│   ├── setup-gateway.sh
│   └── gateway/
│       └── config/
│           ├── authelia/
│           │   ├── configuration.yml.template
│           │   ├── users_database.yml
│           │   ├── configuration.yml   # Generado por setup-gateway.sh
│           │   └── oidc_private_key.pem  # Generado por setup-gateway.sh
│           └── caddy/
│               └── Caddyfile.local
├── ConfiguracionEleccion-service/
├── GestionPreElectoral-service/
├── MockJurados-service/
├── frontend-ConfiguracionElecciones/
└── frontend-GestionPreelectoral/
```

## Configuracion Inicial del Gateway

Antes de levantar el gateway por primera vez, ejecuta el script de configuracion desde la raiz de este repositorio:

```bash
chmod +x setup-gateway.sh
./setup-gateway.sh
```

Este script hace lo siguiente:
1. Genera la clave privada RSA para OIDC (`gateway/config/authelia/oidc_private_key.pem`).
2. Genera secrets aleatorios para Authelia (session, encryption, JWT, HMAC).
3. Crea el archivo `gateway/config/authelia/configuration.yml` a partir de la plantilla incluida.

> **No subas los archivos generados a Git.** Estan protegidos por `.gitignore` por defecto.

## Credenciales de Prueba

Authelia viene preconfigurado con los siguientes usuarios de prueba (definidos en `users_database.yml`):

| Usuario | Contrasena | Roles |
|---|---|---|
| `registraduria` | `12345` | frontend-configuracion, frontend-gestion-pre, admin |
| `superadmin` | `12345` | frontend-configuracion, frontend-gestion-pre, admin |

## Como Levantar el Entorno

### 1. Clonar los repositorios

```bash
# Crear carpeta de trabajo
mkdir sello-legitimo-workspace
cd sello-legitimo-workspace

# Clonar este repositorio de orquestacion
git clone https://github.com/DereKk8/sello-legitimo-dev-env.git
cd sello-legitimo-dev-env

# Ejecutar la configuracion inicial del gateway
chmod +x setup-gateway.sh
./setup-gateway.sh

# Clonar los servicios backend y frontend (ajusta las URLs segun tu organizacion)
git clone https://github.com/DereKk8/ConfiguracionEleccion-service.git ../ConfiguracionEleccion-service
git clone https://github.com/DereKk8/GestionPreElectoral-service.git ../GestionPreElectoral-service
git clone https://github.com/DereKk8/MockJurados-service.git ../MockJurados-service
git clone https://github.com/DereKk8/frontend-ConfiguracionElecciones.git ../frontend-ConfiguracionElecciones
git clone https://github.com/DereKk8/frontend-GestionPreelectoral.git ../frontend-GestionPreelectoral
```

> **Nota:** Si los repositorios pertenecen a otra organizacion o usuario, reemplaza `DereKk8` por el nombre correspondiente.

### 2. Levantar backend y bases de datos

Desde la raiz de `sello-legitimo-dev-env`:

```bash
docker compose -f docker-compose.local.yml up --build -d
```

Esto levanta:
- `configuracion-eleccion-postgres` (PostgreSQL para Configuracion Eleccion) — expuesto en `localhost:5433`
- `gestion-pre-electoral-postgres` (PostgreSQL para Gestion Pre-Electoral) — expuesto en `localhost:5434`
- `configuracion-eleccion` (Backend Configuracion Eleccion) — `localhost:8081` (HTTP), `localhost:9090` (gRPC)
- `gestion-pre-electoral` (Backend Gestion Pre-Electoral) — `localhost:8082`
- `mock-jurados` (Mock Jurados) — `localhost:8083`, `localhost:9091` (gRPC)

### 3. Levantar gateway, Authelia y frontends

Una vez que los servicios backend esten saludables:

```bash
docker compose -f docker-compose.local.gateway.yml up --build -d
```

Esto levanta:
- `authelia` — Servicio de autenticacion / SSO
- `gateway` (Caddy) — Reverse proxy en `https://localhost:8091`
- `election-conf-frontend` — Frontend Configuracion Elecciones
- `preelectoral-frontend` — Frontend Gestion Pre-Electoral

### 4. Verificar que todo esta corriendo

```bash
docker compose -f docker-compose.local.yml ps
docker compose -f docker-compose.local.gateway.yml ps
```

## Acceso a la Aplicacion

| Servicio | URL Local |
|---|---|
| Gateway (Caddy) | `https://localhost:8091` |
| Frontend Configuracion Elecciones | `https://eleccion.sello-legitimo.site:8091` |
| Frontend Gestion Pre-Electoral | `https://preeleccion.sello-legitimo.site:8091` |
| Authelia | `https://auth.sello-legitimo.site:8091` |
| Backend Configuracion Eleccion | `http://localhost:8081` |
| Backend Gestion Pre-Electoral | `http://localhost:8082` |
| Backend Mock Jurados | `http://localhost:8083` |

> **Nota:** Las URLs con dominio `*.sello-legitimo.site` requieren que tengas configuradas las entradas en tu archivo `hosts` apuntando a `127.0.0.1`, o que uses el puerto `8091` directamente con `localhost`.

### Entradas recomendadas en /etc/hosts

Para poder usar los dominios locales con HTTPS, anade estas lineas a tu archivo `hosts`:

```
127.0.0.1  auth.sello-legitimo.site
127.0.0.1  eleccion.sello-legitimo.site
127.0.0.1  preeleccion.sello-legitimo.site
```

## Puertos Expuestos

| Puerto | Servicio |
|---|---|
| `5433` | PostgreSQL — Configuracion Eleccion |
| `5434` | PostgreSQL — Gestion Pre-Electoral |
| `8081` | Backend Configuracion Eleccion (HTTP) |
| `8082` | Backend Gestion Pre-Electoral |
| `8083` | Backend Mock Jurados |
| `9090` | Backend Configuracion Eleccion (gRPC) |
| `8091` | Gateway Caddy (HTTPS) |
| `9091` | Backend Mock Jurados (gRPC) |

## Comandos Utiles

```bash
# Ver logs de todos los servicios backend
docker compose -f docker-compose.local.yml logs -f

# Ver logs del gateway y frontends
docker compose -f docker-compose.local.gateway.yml logs -f

# Detener todos los servicios backend
docker compose -f docker-compose.local.yml down

# Detener gateway y frontends
docker compose -f docker-compose.local.gateway.yml down

# Detener todo y eliminar volumenes (⚠️ borra datos de PostgreSQL)
docker compose -f docker-compose.local.yml down -v
docker compose -f docker-compose.local.gateway.yml down -v

# Re-generar la configuracion del gateway (si cambia la plantilla)
./setup-gateway.sh
```

## Notas para el Equipo de Desarrollo

- **Configuracion Eleccion** es el servicio central. Tanto `GestionPreElectoral-service` como `MockJurados-service` dependen de el para la comunicacion gRPC.
- Si solo necesitas trabajar en un frontend especifico, puedes levantar solo `docker-compose.local.yml` y usar el backend directamente sin pasar por Caddy (segun la configuracion de cada proyecto).
- Asegurate de que los `Dockerfile` de cada servicio esten en la raiz de su respectivo repositorio, tal como lo esperan los `docker-compose`.
- Si realizas cambios en el codigo de algun servicio, reconstruye la imagen con:
  ```bash
  docker compose -f docker-compose.local.yml up --build -d <nombre-del-servicio>
  ```
- La configuracion del gateway (`Caddyfile.local`, plantilla de Authelia, etc.) se mantiene **en este repo**. Si necesitas ajustar algo del gateway para desarrollo local, hazlo aqui y no en el repositorio del gateway de produccion.
