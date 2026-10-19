# ==============================================================================
# Trivy Guvenlik Taramasi Testi Icin Kasitli Zafiyetli Imaj (Vulnerable Image)
# ==============================================================================
FROM python:3.7-slim

WORKDIR /app

# Kasitli olarak bilinen kritik CVE zafiyetleri iceren eski paketler yuklenir
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000

CMD ["python", "app.py"]
