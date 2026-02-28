import cloudinary
import cloudinary.uploader
import os
from dotenv import load_dotenv

load_dotenv()

# Cloudinary configuration
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET"),
    secure=True
)

def upload_file(file, folder="workflow_pro"):
    """
    Uploads a file to Cloudinary.
    'file' can be a path, a file-like object, or a binary stream.
    """
    try:
        response = cloudinary.uploader.upload(
            file,
            folder=folder,
            resource_type="auto"  # Automatically detect image, video, raw, etc.
        )
        return response.get("secure_url")
    except Exception as e:
        print(f"Cloudinary upload error: {e}")
        return None
