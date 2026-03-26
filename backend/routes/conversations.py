from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from supabase import create_client, Client
import os
import uuid
from typing import List, Optional

router = APIRouter()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_ANON_KEY")
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

class ConversationCreate(BaseModel):
    user_id: str
    title: Optional[str] = "New Chat"

class ConversationUpdate(BaseModel):
    title: str

@router.get("/{user_id}")
async def get_conversations(user_id: str):
    try:
        response = supabase.table("conversations").select("*").eq("user_id", user_id).order("created_at", descending=True).execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/")
async def create_conversation(conv: ConversationCreate):
    try:
        data = {
            "user_id": conv.user_id,
            "title": conv.title
        }
        response = supabase.table("conversations").insert(data).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/{conversation_id}")
async def delete_conversation(conversation_id: str):
    try:
        response = supabase.table("conversations").delete().eq("id", conversation_id).execute()
        return {"status": "deleted"}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/clear/default")
async def clear_default_chat(user_id: str):
    try:
        response = supabase.table("notes").delete().eq("user_id", user_id).is_("conversation_id", None).execute()
        return {"status": "cleared", "deleted_count": len(response.data)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/clear/{conversation_id}")
async def clear_chat(conversation_id: str):
    try:
        # Delete all notes associated with this conversation
        response = supabase.table("notes").delete().eq("conversation_id", conversation_id).execute()
        return {"status": "cleared", "deleted_count": len(response.data)}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
@router.put("/{conversation_id}")
async def update_conversation(conversation_id: str, conv: ConversationUpdate):
    try:
        response = supabase.table("conversations").update({"title": conv.title}).eq("id", conversation_id).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
