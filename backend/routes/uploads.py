from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from supabase import create_client, Client
import os
import uuid

router = APIRouter()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
supabase_admin: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

@router.post("/upload-image")
async def upload_image(email: str = Form(...), file: UploadFile = File(...)):
    try:
        # Sanitize email for bucket name
        bucket_id = email.replace("@", "-at-").replace(".", "-").lower()
        
        file_ext = file.filename.split(".")[-1]
        file_name = f"{uuid.uuid4()}.{file_ext}"
        
        # Read file content
        content = await file.read()
        
        # Upload to Supabase
        res = supabase_admin.storage.from_(bucket_id).upload(
            path=file_name,
            file=content,
            file_options={"content-type": file.content_type}
        )
        
        # Get public URL
        url = supabase_admin.storage.from_(bucket_id).get_public_url(file_name)
        
        return {"image_url": url, "file_name": file_name, "bucket": bucket_id}
    except Exception as e:
        print(f"Upload error for {email}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
