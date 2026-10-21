# Reporte Forense y Auditoría Docker: eco-air-backend

## 1. Tabla de Identidad

| Parámetro | Valor Obtenido |
| :--- | :--- |
| **Estudiante / Operator ID** | `914988` |
| **Hash SHA-256 de la Imagen** | `sha256:cf8238a4c7c2298f66b2612889ea3f7d8...` |
| **Variable de Entorno Inyectada** | `OPERATOR_ID=914988` |

---

## 2. Auditoría Forense y Comprobación de Vulnerabilidades (Reto 2)

### 2.1 Desacoplamiento de Capas (`docker history`)
```plaintext
SIZE        CREATED BY
86.8MB      /bin/sh -c #(nop) COPY file:a4c7c2... in /app/app.jar
0B          /bin/sh -c chown -R sensor_user:sensorgroup /app
4.2kB       /bin/sh -c addgroup -S -g 10001 sensorgroup && adduser -S -u 10001 -G sensorgroup sensor_user
212MB       /bin/sh -c #(nop) ENV JAVA_OPTS=-XX:+UseG1GC -XX:+UseContainerSupport...