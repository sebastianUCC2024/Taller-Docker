# Etapa 1: Compilación (Build)
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /app

# Copiar configuración de dependencias
COPY pom.xml .
RUN mvn dependency:resolve -B || true

# Copiar código fuente y compilar omitiendo pruebas para velocidad
COPY src ./src
RUN mvn package -DskipTests

# Etapa 2: Imagen final liviana de ejecución
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Copiar el ejecutable generado
COPY --from=builder /app/target/*.jar app.jar

# Exponer el puerto del backend (8080)
EXPOSE 8080

# Ejecutar con un usuario sin privilegios por seguridad
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

ENTRYPOINT ["java", "-jar", "app.jar"]