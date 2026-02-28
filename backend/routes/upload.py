from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from utils.auth import get_current_user
from utils.cloudinary_utils import upload_file
import shutil
import tempfile
import os

router = APIRouter()

@router.post("/upload")
async def upload_multimedia(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """
    Endpoint to upload a file to Cloudinary.
    Accepts images, audio, and basic documents.
    """
    try:
        # Create a temporary file to store the upload content
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            shutil.copyfileobj(file.file, temp_file)
            temp_path = temp_file.name
        
        # Upload to Cloudinary
        url = upload_file(temp_path)
        
        # Clean up temp file
        os.remove(temp_path)
        
        if not url:
            raise HTTPException(status_code=500, detail="Failed to upload to Cloudinary")
            
        return {
            "success": True,
            "url": url,
            "filename": file.filename,
            "content_type": file.content_type
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload error: {str(e)}")
