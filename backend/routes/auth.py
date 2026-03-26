from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from supabase import create_client, Client
import os
import random
import string
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
from utils.email_utils import send_email_async, send_email_sync, get_otp_html, get_welcome_html

router = APIRouter()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
JWT_SECRET = os.getenv("JWT_SECRET", "super-secret-key")
ALGORITHM = "HS256"

# Public client for standard auth
supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
# Admin client for bucket creation and DB management
supabase_admin: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserAuth(BaseModel):
    email: str
    password: str
    name: str = None

class VerifyRequest(BaseModel):
    email: str
    otp: str

class ResetRequest(BaseModel):
    email: str
    otp: str
    new_password: str

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(days=7)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)
    return encoded_jwt

def generate_otp():
    return ''.join(random.choices(string.digits, k=6))

@router.post("/signup")
async def signup(user: UserAuth):
    try:
        # Check if user already exists
        existing = supabase_admin.table("profiles").select("*").eq("email", user.email).execute()
        if existing.data:
            # If exists but unverified, resend OTP
            if not existing.data[0]["is_verified"]:
                otp = generate_otp()
                supabase_admin.table("profiles").update({"otp_code": otp}).eq("email", user.email).execute()
                send_email_async(user.email, "Your Verification Code", get_otp_html(otp, purpose="verification"))
                return {"message": "Verification code resent", "email": user.email}
            raise HTTPException(status_code=400, detail="User already registered and verified")

        # Hash password
        hashed_password = pwd_context.hash(user.password)
        otp = generate_otp()
        
        # Insert into profiles table
        new_user = {
            "email": user.email,
            "password_hash": hashed_password,
            "name": user.name,
            "otp_code": otp,
            "is_verified": False
        }
        
        supabase_admin.table("profiles").insert(new_user).execute()
        
        # Send OTP email
        send_email_async(user.email, "Verify Your KeyNote Chat Account", get_otp_html(otp, purpose="verification"))
        
        return {"message": "User registered. OTP sent to email.", "email": user.email}
    except Exception as e:
        print(f"Signup error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/verify")
async def verify(req: VerifyRequest):
    try:
        # Fetch user
        res = supabase_admin.table("profiles").select("*").eq("email", req.email).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = res.data[0]
        if user_data["otp_code"] != req.otp:
            raise HTTPException(status_code=400, detail="Invalid OTP code")
        
        # Update verification status
        supabase_admin.table("profiles").update({"is_verified": True, "otp_code": None}).eq("email", req.email).execute()
        
        # Send welcome email
        send_email_async(req.email, "Welcome to KeyNote Chat!", get_welcome_html(user_data["name"]))
        
        # Create bucket (keeping existing logic)
        bucket_id = req.email.replace("@", "-at-").replace(".", "-").lower()
        try:
            supabase_admin.storage.create_bucket(bucket_id, options={"public": True})
        except:
            pass
            
        return {"message": "Email verified successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/login")
async def login(user: UserAuth):
    try:
        # Fetch user from profiles table
        res = supabase_admin.table("profiles").select("*").eq("email", user.email).execute()
        if not res.data:
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        user_data = res.data[0]
        
        # Verify password
        if not pwd_context.verify(user.password, user_data["password_hash"]):
            raise HTTPException(status_code=401, detail="Invalid email or password")
        
        # Check verification
        if not user_data["is_verified"]:
            # Resend OTP
            otp = generate_otp()
            supabase_admin.table("profiles").update({"otp_code": otp}).eq("email", user.email).execute()
            send_email_async(user.email, "Your Verification Code", get_otp_html(otp, purpose="verification"))
            return {"status": "verification_required", "message": "Email not verified. OTP sent."}
        
        # Create token
        access_token = create_access_token(data={"sub": user.email, "name": user_data["name"]})
        
        return {"access_token": access_token, "token_type": "bearer", "user": {"email": user_data["email"], "name": user_data["name"]}}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/forgot-password")
async def forgot_password(user: UserAuth):
    try:
        res = supabase_admin.table("profiles").select("*").eq("email", user.email).execute()
        if not res.data:
            # For security, we might not want to reveal if email exists, 
            # but usually in simple apps we return 200 regardless
            return {"message": "If this email is registered, you will receive a reset code."}
        
        otp = generate_otp()
        supabase_admin.table("profiles").update({"otp_code": otp}).eq("email", user.email).execute()
        
        # Send reset email
        send_email_async(user.email, "Reset Your KeyNote Chat Password", get_otp_html(otp, purpose="reset"))
        
        return {"message": "Password reset OTP sent to email."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/reset-password")
async def reset_password(req: ResetRequest):
    try:
        res = supabase_admin.table("profiles").select("*").eq("email", req.email).execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_data = res.data[0]
        if user_data["otp_code"] != req.otp:
            raise HTTPException(status_code=400, detail="Invalid reset code")
        
        # Update password
        new_hashed = pwd_context.hash(req.new_password)
        supabase_admin.table("profiles").update({"password_hash": new_hashed, "otp_code": None}).eq("email", req.email).execute()
        
        return {"message": "Password updated successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/update-profile")
async def update_profile(req: dict):
    try:
        email = req.get("email")
        if not email:
            raise HTTPException(status_code=400, detail="Email required")
        
        update_data = {}
        if "name" in req and req["name"]:
            update_data["name"] = req["name"]
        if "profile_image" in req:
            update_data["profile_image"] = req["profile_image"] # We should add this column if not exists
            
        if update_data:
            supabase_admin.table("profiles").update(update_data).eq("email", email).execute()
            
        return {"message": "Profile updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/profile/{email}")
async def get_profile(email: str):
    try:
        response = supabase_admin.table("profiles").select("*").eq("email", email).single().execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=404, detail="Profile not found")

@router.get("/test-email")
async def test_email(email: str = None):
    try:
        target = email if email else os.getenv("EMAIL_USER")
        print(f"DEBUG: Manually triggering test email to {target}")
        success = send_email_sync(target, "Diagnostic Test - KeyNote Chat", "<h1>SMTP Configuration is Correct</h1><p>If you see this, the futuristic auth system is working!</p>")
        if success:
            return {"status": "success", "message": f"Test email sent to {target}"}
        else:
            return {"status": "error", "message": "Failed to send test email. Check server logs."}
    except Exception as e:
        print(f"DEBUG: test-email endpoint error: {e}")
        return {"status": "error", "message": str(e)}

@router.post("/ensure-bucket/{email}")
async def ensure_bucket(email: str):
    try:
        bucket_id = email.replace("@", "-at-").replace(".", "-").lower()
        try:
            supabase_admin.storage.get_bucket(bucket_id)
            return {"status": "exists", "bucket_id": bucket_id}
        except Exception:
            try:
                supabase_admin.storage.create_bucket(bucket_id, options={"public": True})
                return {"status": "created", "bucket_id": bucket_id}
            except Exception as b_err:
                raise HTTPException(status_code=500, detail=f"Failed to create bucket: {b_err}")
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/storage-usage/{email}")
async def get_storage_usage(email: str):
    try:
        bucket_id = email.replace("@", "-at-").replace(".", "-").lower()
        files = supabase_admin.storage.from_(bucket_id).list()
        
        total_size = 0
        for file in files:
            metadata = file.get("metadata", {})
            if metadata:
                total_size += metadata.get("size", 0)
        
        limit = 100 * 1024 * 1024 
        return {
            "used_bytes": total_size,
            "total_bytes": limit,
            "percentage": (total_size / limit) * 100 if limit > 0 else 0
        }
    except Exception:
        return {"used_bytes": 0, "total_bytes": 100 * 1024 * 1024, "percentage": 0}
