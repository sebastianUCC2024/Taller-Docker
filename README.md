Markdown
# 🚀 Taller Docker: Infraestructura Web con Nginx Reverse Proxy y Spring Boot

Este repositorio contiene la arquitectura orquestada con **Docker Compose** para desplegar una aplicación web basada en **Spring Boot (Java 17)** protegida y enrutada a través de un proxy inverso **Nginx**.

---

## 🏗️ Arquitectura del Sistema

La solución consta de dos servicios orquestados en una red aislada de tipo `bridge` (`app-network`):

* **`nginx_proxy` (Nginx Alpine):** Actúa como puerta de entrada única (Reverse Proxy) en el puerto `80` del host, reenviando el tráfico hacia el contenedor del backend y aplicando cabeceras de seguridad.
* **`eco_air_active` (Backend Spring Boot):** Microservicio Java 17 aislado dentro de la red privada, ejecutándose en un entorno sin privilegios de usuario (`USER appuser`).

```text
[ Cliente / Navegador ]
         │ (Puerto 80)
         ▼
 ┌───────────────┐
 │  Nginx Proxy  │ (nginx:alpine)
 └───────┬───────┘
         │ (Red interna: app-network)
         ▼
 ┌───────────────┐
 │    Backend    │ (Spring Boot / Java 17)
 └───────────────┘
🛠️ Requisitos Previos
Docker Desktop instalado y en ejecución.

Git para clonar el repositorio.

🚀 Despliegue Rápido
Clonar el repositorio:

Bash
git clone [https://github.com/sebastianUCC2024/Taller-Docker.git](https://github.com/sebastianUCC2024/Taller-Docker.git)
cd Taller-Docker
Construir y levantar la infraestructura:

Bash
docker compose up -d --build
Verificar que los servicios estén activos:

Bash
docker compose ps
Probar el servicio:
Abre tu navegador web e ingresa a http://localhost o ejecuta en la terminal:

Bash
curl http://localhost
📁 Estructura del Proyecto
Plaintext
Taller-Docker/
├── Dockerfile              # Construcción multi-etapa para el Backend Java
├── docker-compose.yml      # Orquestación de servicios Nginx y Backend
├── pom.xml                 # Configuración de dependencias Maven (Spring Boot)
├── .dockerignore           # Exclusión de archivos no requeridos en la imagen
├── nginx/
│   └── nginx.conf          # Configuración del Reverse Proxy Nginx
└── src/                    # Código fuente de la aplicación Spring Boot
📑 Configuración de Archivos Clave
1. Dockerfile (Backend Multi-Stage)
Dockerfile
# Etapa 1: Compilación de la aplicación
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:resolve -B || true

COPY src ./src
RUN mvn package -DskipTests

# Etapa 2: Imagen final de ejecución
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

ENTRYPOINT ["java", "-jar", "app.jar"]
2. nginx/nginx.conf
Nginx
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format main '$remote_addr -$remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log  /var/log/nginx/error.log warn;

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://backend:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Cabeceras de seguridad / Hardening
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-XSS-Protection "1; mode=block" always;
        }
    }
}
3. docker-compose.yml
YAML
networks:
  app-network:
    driver: bridge

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: eco_air_active
    restart: unless-stopped
    environment:
      - SERVER_PORT=8080
    networks:
      - app-network
    deploy:
      resources:
        limits:
          cpus: '0.50'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  nginx:
    image: nginx:alpine
    container_name: nginx_proxy
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - backend
    networks:
      - app-network
    deploy:
      resources:
        limits:
          cpus: '0.25'
          memory: 128M
        reservations:
          cpus: '0.10'
          memory: 64M
📊 Informe de Auditoría Técnica
Fase 1: Seguridad y Privilegios
Principio de Menor Privilegio: Se configuró el contenedor backend con un usuario no privilegiado (USER appuser) mediante la creación previa de appgroup y appuser en el Dockerfile.

Aislamiento de Red: Únicamente el puerto 80 del servicio Nginx está expuesto al host. El backend escucha únicamente en el puerto 8080 de la red privada app-network.

Montajes de Solo Lectura: El archivo nginx.conf se montó con la bandera de lectura estricta (:ro).

Fase 2: Gestión de Recursos y Estabilidad
Límites de RAM y CPU: Se establecieron límites de recursos explícitos (limits y reservations) en docker-compose.yml (512MB de RAM para el backend y 128MB para Nginx) para prevenir ataques de denegación de servicio (DoS) por agotamiento de memoria del host.

Verificación OOMKilled: Confirmado mediante inspección del estado del contenedor (docker inspect), obteniendo OOMKilled: false.

Fase 3: Análisis de Registros y Trazabilidad
Preservación de IP Origen: Nginx transmite la IP real del cliente hacia el backend a través de la cabecera X-Forwarded-For.

Diagnóstico de Inicio: Se analizó el comportamiento de arranque en frío de la máquina virtual de Java (JVM) y Tomcat embebido, asegurando la trazabilidad de peticiones HTTP con respuesta exitosa 200 OK.

Fase 4: Higiene de Imágenes
Imágenes Minimalistas: Se implementaron imágenes basadas en Alpine Linux (nginx:alpine y eclipse-temurin:17-jre-alpine) para reducir la superficie de ataque y optimizar el almacenamiento.

Multi-Stage Build: Implementación de compilación en múltiples etapas en el Dockerfile para excluir Maven y archivos temporales del contenedor final en tiempo de ejecución.
