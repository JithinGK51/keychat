from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from supabase import create_client, Client
import os

router = APIRouter()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
if not SUPABASE_URL or not SUPABASE_KEY:
    print("WARNING: SUPABASE_URL or SUPABASE_ANON_KEY not set in notes.py")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class NoteCreate(BaseModel):
    user_id: str
    title: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None
    links: Optional[List[dict]] = None
    is_pinned: bool = False
    conversation_id: Optional[str] = None

@router.post("/create-note")
async def create_note(note: NoteCreate):
    try:
        response = supabase.table("notes").insert(note.dict()).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/get-notes/{user_id}")
async def get_notes(user_id: str, conversation_id: Optional[str] = None):
    try:
        query = supabase.table("notes").select("*").eq("user_id", user_id)
        if conversation_id:
            query = query.eq("conversation_id", conversation_id)
        else:
            query = query.is_("conversation_id", "null")
            
        response = query.order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/search-notes")
async def search_notes(user_id: str, query: str, conversation_id: Optional[str] = None):
    try:
        query = supabase.table("notes").select("*").eq("user_id", user_id).ilike("description", f"%{query}%")
        if conversation_id:
            query = query.eq("conversation_id", conversation_id)
            
        response = query.execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
