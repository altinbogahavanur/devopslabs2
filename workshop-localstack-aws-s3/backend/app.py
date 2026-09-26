import os
import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException, Form
from contextlib import asynccontextmanager

AWS_ENDPOINT_URL = os.getenv("AWS_ENDPOINT_URL", "http://localstack:4566")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
AWS_ACCESS_KEY_ID = os.getenv("AWS_ACCESS_KEY_ID", "test")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY", "test")
S3_BUCKET = os.getenv("S3_BUCKET", "devops-training-bucket")

def get_s3_client():
    return boto3.client(
        "s3",
        endpoint_url=AWS_ENDPOINT_URL,
        region_name=AWS_REGION,
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY
    )

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Uygulama baslarken varsayilan bucket'i kontrol et veya olustur
    s3 = get_s3_client()
    try:
        s3.head_bucket(Bucket=S3_BUCKET)
        print(f"[INIT] S3 Bucket '{S3_BUCKET}' zaten mevcut.")
    except ClientError:
        try:
            s3.create_bucket(Bucket=S3_BUCKET)
            print(f"[INIT] S3 Bucket '{S3_BUCKET}' basariyla olusturuldu.")
        except Exception as e:
            print(f"[INIT HATA] Bucket olusturulamadi: {e}")
    yield

app = FastAPI(
    title="DevOps LocalStack S3 Storage API",
    description="LocalStack S3 Integration Microservice for DevOps Training",
    version="1.0.0",
    lifespan=lifespan
)

@app.get("/")
def read_root():
    return {
        "status": "success",
        "service": "DevOps S3 Storage API",
        "s3_endpoint": AWS_ENDPOINT_URL,
        "default_bucket": S3_BUCKET,
        "docs_url": "/docs"
    }

@app.get("/health")
def health_check():
    s3 = get_s3_client()
    try:
        s3.list_buckets()
        return {"status": "healthy", "s3_connection": "connected"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"S3 baglanti hatasi: {str(e)}")

@app.get("/buckets")
def list_buckets():
    s3 = get_s3_client()
    try:
        res = s3.list_buckets()
        return {"buckets": [b["Name"] for b in res.get("Buckets", [])]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Bucket listeleme hatasi: {str(e)}")

@app.get("/files")
def list_files(bucket: str = S3_BUCKET):
    s3 = get_s3_client()
    try:
        res = s3.list_objects_v2(Bucket=bucket)
        files = []
        if "Contents" in res:
            for item in res["Contents"]:
                files.append({
                    "key": item["Key"],
                    "size_bytes": item["Size"],
                    "last_modified": item["LastModified"].isoformat()
                })
        return {"bucket": bucket, "count": len(files), "files": files}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Dosya listeleme hatasi: {str(e)}")

@app.post("/upload-text")
def upload_text(filename: str = Form(...), content: str = Form(...), bucket: str = S3_BUCKET):
    s3 = get_s3_client()
    try:
        s3.put_object(
            Bucket=bucket,
            Key=filename,
            Body=content.encode("utf-8"),
            ContentType="text/plain"
        )
        return {
            "status": "success",
            "message": f"'{filename}' basariyla '{bucket}' bucketina yuklendi.",
            "filename": filename,
            "size_bytes": len(content.encode("utf-8"))
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"S3 yukleme hatasi: {str(e)}")

@app.get("/files/{filename}")
def get_file_content(filename: str, bucket: str = S3_BUCKET):
    s3 = get_s3_client()
    try:
        obj = s3.get_object(Bucket=bucket, Key=filename)
        body = obj["Body"].read().decode("utf-8")
        return {
            "status": "success",
            "bucket": bucket,
            "filename": filename,
            "content": body
        }
    except ClientError as e:
        if e.response["Error"]["Code"] == "NoSuchKey":
            raise HTTPException(status_code=404, detail="Dosya S3 uzerinde bulunamadi.")
        raise HTTPException(status_code=500, detail=str(e))
