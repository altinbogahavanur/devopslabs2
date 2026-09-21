# ==========================================
# 1. AŞAMA: DERLEME VE KATMANLARA AYIRMA (BUILDER)
# ==========================================
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /build

# Bağımlılıkları önbelleğe almak için önce sadece pom.xml kopyalanır
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Kaynak kodlar kopyalanıp paketlenir
COPY src ./src
RUN mvn clean package -DskipTests

# Spring Boot katmanlı JAR'ı parçalama
WORKDIR /build/extracted
RUN java -Djarmode=layertools -jar /build/target/*.jar extract

# ==========================================
# 2. AŞAMA: ÇALIŞMA ZAMANI (RUNTIME - JRE)
# ==========================================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Güvenlik: Non-root kullanıcı oluşturma
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Katmanları sırayla kopyalama (En az değişenden en sık değişene doğru)
COPY --from=builder /build/extracted/dependencies/ ./
COPY --from=builder /build/extracted/spring-boot-loader/ ./
COPY --from=builder /build/extracted/snapshot-dependencies/ ./
COPY --from=builder /build/extracted/application/ ./

RUN chown -R appuser:appgroup /app
USER appuser

# JVM Container optimizasyonları
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
