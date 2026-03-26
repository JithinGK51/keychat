from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from supabase import create_client, Client
import os

router = APIRouter()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
if not SUPABASE_URL or not SUPABASE_KEY:
    print("WARNING: SUPABASE_URL or SUPABASE_ANON_KEY not set in keys.py")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class KeyCreate(BaseModel):
    user_id: str
    key_name: str
    title: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    links: Optional[List[dict]] = None
    is_favorite: Optional[bool] = False

@router.post("/create-key")
async def create_key(key: KeyCreate):
    try:
        response = supabase.table("keys").insert(key.dict()).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put("/toggle-favorite/{key_id}")
async def toggle_favorite(key_id: str):
    try:
        # Get current state
        key_data = supabase.table("keys").select("is_favorite").eq("id", key_id).single().execute()
        current_state = key_data.data.get("is_favorite", False)
        
        # Toggle
        response = supabase.table("keys").update({"is_favorite": not current_state}).eq("id", key_id).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/get-keys/{user_id}")
async def get_keys(user_id: str):
    try:
        response = supabase.table("keys").select("*").eq("user_id", user_id).order("is_favorite", desc=True).order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/get-favorites/{user_id}")
async def get_favorites(user_id: str):
    try:
        response = supabase.table("keys").select("*").eq("user_id", user_id).eq("is_favorite", True).order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/delete-key/{key_id}")
async def delete_key(key_id: str):
    try:
        response = supabase.table("keys").delete().eq("id", key_id).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
