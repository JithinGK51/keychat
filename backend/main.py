from dotenv import load_dotenv
import os
import uvicorn

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import notes, keys, auth, uploads, conversations
from fastapi.staticfiles import StaticFiles

app = FastAPI(title="KeyNote Chat API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(notes.router, prefix="/notes", tags=["Notes"])
app.include_router(keys.router, prefix="/keys", tags=["Keys"])
app.include_router(uploads.router, prefix="/uploads", tags=["Uploads"])
app.include_router(conversations.router, prefix="/conversations", tags=["Conversations"])

app.mount("/static", StaticFiles(directory="uploads"), name="static")

@app.get("/")
async def root():
    return {"message": "KeyNote Chat API is online and futuristic"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
