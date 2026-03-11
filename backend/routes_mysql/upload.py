from fastapi import APIRouter, HTTPException

router = APIRouter()

@router.post("/upload")
async def upload_file():
    return {
        "success": True,
        "message": "Upload endpoint - implement file upload logic",
        "data": {"url": "https://example.com/file.jpg"}
    }
