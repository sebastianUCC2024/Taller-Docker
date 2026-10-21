FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder

WORKDIR /build

ARG STUDENT_ID
ENV STUDENT_ID=${STUDENT_ID}

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jre-alpine

ARG STUDENT_ID
ENV OPERATOR_ID=${STUDENT_ID}

ENV JAVA_OPTS="-XX:+UseG1GC -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

RUN addgroup -S -g 10001 sensorgroup && \
    adduser -S -u 10001 -G sensorgroup sensor_user

WORKDIR /app

COPY --from=builder /build/target/*.jar app.jar

RUN chown -R sensor_user:sensorgroup /app

USER sensor_user

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]