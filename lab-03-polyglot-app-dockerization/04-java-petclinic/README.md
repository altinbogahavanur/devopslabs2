# LAB-05-04 — Java Spring Boot (PetClinic) Uygulamasını Layered JAR ve JVM Tuning ile Dockerize Etme

| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |
|:---:|:---:|:---:|:---:|
| Orta - İleri | 45 dakika | `maven:3.9-eclipse-temurin-17`, `eclipse-temurin:17-jre-alpine`, `curl` | `8080` |

---

## 1. Uygulama Hakkında

Kurumsal dünyada en yaygın kullanılan mikroservis çatılarından biri **Java Spring Boot**'tur (PetClinic referans mimarisi). 

Java uygulamalarını Dockerize ederken karşılaşılan 3 büyük problem vardır:
1. **Büyük İmaj Boyutu:** Maven ve JDK derleyicisi 800+ MB yer kaplar; oysa çalışma zamanında yalnızca JRE gereklidir.
2. **Önbelleğin Bozulması:** Tek parça `app.jar` dosyası kopyalandığında, 1 satırlık kod değişse bile 60 MB'lık tüm kütüphaneler yeniden yüklenir. Çözüm: **Spring Boot Layered JAR (`layertools`)** ile bağımlılıkları ve uygulama kodunu ayrı katmanlara bölmek.
3. **JVM Bellek Körlüğü (OOM Hatası):** Eski JVM sürümleri konteyner sınırını bilmez ve host makinenin tüm RAM'ini görmeye çalışır. Çözüm: `-XX:+UseContainerSupport` ve `-XX:MaxRAMPercentage=75.0`.

---

## 2. Klasik Linux (Ubuntu) Üzerinde Manuel Derleme ve Çalıştırma

Öğrencinin Dockerfile direktiflerini kurgulayabilmesi için referans Linux akışı:

```bash
# 1. Ubuntu'ya OpenJDK 17 ve Maven kurulması
sudo apt update && sudo apt install -y openjdk-17-jdk maven

# 2. Çalışma dizini ve kodların yerleşimi
mkdir -p /app && cd /app
cp -r /path/to/source/* /app/

# 3. JAR dosyasının derlenmesi
mvn clean package -DskipTests

# 4. DERLEYİCİYE VE MAVEN'A ARTIK İHTİYAÇ YOKTUR!
# Üretim makinesine sadece 'target/petclinic-demo-1.0.0.jar' aktarılır ve JRE ile çalıştırılır:
java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar target/petclinic-demo-1.0.0.jar
```

---

## 3. Zihinsel Eşleştirme Rehberi (Linux ➔ Multi-Stage Dockerfile)

| Klasik Linux Adımı | Karşılık Gelen Dockerfile Direktifi | Kritik En İyi Pratik (Best Practice) |
|:---|:---|:---|
| JDK & Maven Kurulumu | `FROM maven:3.9-eclipse-temurin-17-alpine AS builder` | 1. Aşama: Derleme ve katmanlara ayırma |
| `mvn package` | `RUN mvn clean package -DskipTests` | Üretilen JAR layertools ile 4 katmana parçalanır |
| JRE Kurulumu | `FROM eclipse-temurin:17-jre-alpine` | 2. Aşama: Derleyicisiz, hafif JRE çalışma zamanı |
| Katmanları Kopyalama | `COPY --from=builder /app/dependencies/ ./` | Sık değişmeyen kütüphaneler önbellekte (`CACHED`) kalır |
| Uygulama Katmanı | `COPY --from=builder /app/application/ ./` | Yalnızca birkaç KB'lık kod katmanı kopyalanır |
| JVM Optimizasyonu | `ENV JAVA_OPTS="-XX:+UseContainerSupport ..."` | Bellek sınırının %75'ini heap olarak kullanma |
| Başlatma | `ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]` | Katmanlı JAR başlatıcısı |

---

## 4. Spring Boot Katmanlı JAR (Layered JAR) Mimarisi

```text
+─────────────────────────────────────────────────────────────+
| 1. AŞAMA: maven:3.9-eclipse-temurin-17 AS builder           |
| - pom.xml ve kaynak kodlar derlenir (mvn clean package)     |
| - java -Djarmode=layertools -jar app.jar extract            |
|   1. dependencies/          (Spring, Jackson, Logback vb.)  |
|   2. spring-boot-loader/    (JarLauncher sınıfları)         |
|   3. snapshot-dependencies/ (Dahili kütüphaneler)           |
|   4. application/           (Sizin Controller & Kodlarınız) |
+─────────────────────────────────────────────────────────────+
                               │
            SADECE AYRIŞTIRILMIŞ KATMANLAR AKTARILIR
                               ▼
+─────────────────────────────────────────────────────────────+
| 2. AŞAMA: eclipse-temurin:17-jre-alpine (Non-root)          |
| - Sık değişmeyen 'dependencies' her build'de CACHED kalır!  |
| - Sadece kod değiştiğinde 'application' katmanı yenilenir.  |
| - Boyut: ~600 MB ➔ ~180 MB'a düşer.                         |
+─────────────────────────────────────────────────────────────+
```

---

## 5. Görevler (Tasks)

1. `pom.xml` ve Java kaynak kodlarını inceleyin.
2. 2 aşamalı bir `Dockerfile` oluşturun:
   * **1. Aşama (`builder`):** `pom.xml` kopyalayıp derleyin ve `layertools` ile JAR'ı extract edin.
   * **2. Aşama (`runner`):** `eclipse-temurin:17-jre-alpine` tabanını kullanarak 4 katmanı sırasıyla kopyalayın.
3. JVM için `-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0` ortam değişkenini ekleyin.
4. İmajı `petclinic-demo:v1.0` adıyla derleyin.
5. Konteyneri `--memory=512m` sınırı ile başlatıp `http://localhost:8080/api/pets` adresinden test edin.

---

## 6. İpuçları

<details>
<summary>💡 İpucu 1: -XX:MaxRAMPercentage=75.0 Neden Hayatidir?</summary>

Konteynera örneğin `docker run -m 512m` sınırı verdiğinizde, eğer JVM container-aware değilse host sunucunun (örneğin 16 GB RAM) %25'ini (4 GB) almaya çalışır ve Docker işletim sistemi konteyneri anında `OOMKilled` (Exit 137) ile öldürür. `MaxRAMPercentage=75.0` sayesinde JVM, konteynera tahsis edilen 512 MB'ın %75'ini (384 MB) aşmayacak şekilde heap alanını dinamik ayarlar.
</details>

<details>
<summary>💡 İpucu 2: layertools Extract Komutu</summary>

Spring Boot 3 ile gelen fat-jar yapısını parçalamak için builder aşamasında şu komut çalıştırılır:
`RUN java -Djarmode=layertools -jar target/*.jar extract`
Bu komut kök dizinde 4 ayrı klasör (`dependencies`, `spring-boot-loader`, `snapshot-dependencies`, `application`) oluşturur.
</details>

---

## 7. Referans Çözüm

<details>
<summary>🎯 Referans Multi-Stage Dockerfile</summary>

**`Dockerfile`:**
```dockerfile
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
```

**Derleme ve Çalıştırma:**
```bash
# 1. İmajı derleme
docker build -t petclinic-demo:v1.0 .

# 2. 512 MB RAM sınırı ile konteynerı başlatma
docker run -d --name my-petclinic --memory=512m -p 8080:8080 petclinic-demo:v1.0

# 3. Logları takip etme
docker logs -f my-petclinic

# 4. API endpoint'ini test etme
curl -i http://localhost:8080/api/pets
```
</details>

---

## 8. Doğrulama ve Beklenen Sonuç

```bash
curl -s http://localhost:8080/api/pets
```

* **JSON Çıktısı:**
```json
[
  {"id":1,"name":"Leo","type":"Kedi","owner":"George Franklin"},
  {"id":2,"name":"Basil","type":"Hamster","owner":"Betty Davis"},
  {"id":3,"name":"Rosy","type":"Kopek","owner":"Eduardo Rodriquez"}
]
```
