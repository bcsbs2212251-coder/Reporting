from fastapi import APIRouter, HTTPException, status, Request
from models.password_reset import PasswordResetRequest, PasswordResetVerify, PasswordResetToken
from utils.email_service import email_service
from utils.auth import get_password_hash
from datetime import datetime, timedelta, timezone
from bson import ObjectId
from utils.db import get_db

router = APIRouter()

@router.post("/forgot-password")
async def forgot_password(request_data: PasswordResetRequest, request: Request):
    """Send password reset email"""
    try:
        db = get_db(request)
        
        # Check if user exists
        user = await db.users.find_one({"email": request_data.email})
        if not user:
            # Don't reveal if email exists or not for security
            return {"message": "If the email exists, a reset token has been sent"}
        
        # Generate reset token
        reset_token = email_service.generate_reset_token()
        expires_at = datetime.now(timezone.utc) + timedelta(hours=1)  # Token expires in 1 hour
        
        # Store reset token in database
        reset_data = PasswordResetToken(
            email=request_data.email,
            token=reset_token,
            expires_at=expires_at.isoformat()
        )
        
        # Remove any existing reset tokens for this email
        await db.password_resets.delete_many({"email": request_data.email})
        
        # Insert new reset token
        await db.password_resets.insert_one(reset_data.dict())
        
        # Send email
        email_sent = email_service.send_password_reset_email(
            to_email=request_data.email,
            user_name=user.get('full_name', 'User'),
            reset_token=reset_token
        )
        
        if not email_sent:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send reset email"
            )
        
        return {"message": "If the email exists, a reset token has been sent"}
        
    except Exception as e:
        print(f"Error in forgot_password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )

@router.post("/reset-password")
async def reset_password(reset_data: PasswordResetVerify, request: Request):
    """Reset password using token"""
    try:
        db = get_db(request)
        
        # Find reset token
        token_doc = await db.password_resets.find_one({
            "email": reset_data.email,
            "token": reset_data.reset_token
        })
        
        if not token_doc:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired reset token"
            )
        
        # Check if token is expired
        expires_at = datetime.fromisoformat(token_doc['expires_at'])
        if datetime.now(timezone.utc) > expires_at:
            # Remove expired token
            await db.password_resets.delete_one({"_id": token_doc["_id"]})
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Reset token has expired"
            )
        
        # Find user
        user = await db.users.find_one({"email": reset_data.email})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update password
        hashed_password = get_password_hash(reset_data.new_password)
        await db.users.update_one(
            {"_id": user["_id"]},
            {
                "$set": {
                    "password": hashed_password,
                    "updated_at": datetime.now(timezone.utc)
                }
            }
        )
        
        # Remove used reset token
        await db.password_resets.delete_one({"_id": token_doc["_id"]})
        
        # Send confirmation email
        email_service.send_password_change_confirmation(
            to_email=reset_data.email,
            user_name=user.get('full_name', 'User')
        )
        
        return {"message": "Password reset successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in reset_password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )

@router.post("/verify-reset-token")
async def verify_reset_token(email: str, token: str, request: Request):
    """Verify if reset token is valid"""
    try:
        db = get_db(request)
        
        token_doc = await db.password_resets.find_one({
            "email": email,
            "token": token
        })
        
        if not token_doc:
            return {"valid": False, "message": "Invalid reset token"}
        
        # Check if token is expired
        expires_at = datetime.fromisoformat(token_doc['expires_at'])
        if datetime.now(timezone.utc) > expires_at:
            # Remove expired token
            await db.password_resets.delete_one({"_id": token_doc["_id"]})
            return {"valid": False, "message": "Reset token has expired"}
        
        return {"valid": True, "message": "Token is valid"}
        
    except Exception as e:
        print(f"Error in verify_reset_token: {e}")
        return {"valid": False, "message": "Error verifying token"}

@router.delete("/cleanup-expired-tokens")
async def cleanup_expired_tokens(request: Request):
    """Clean up expired reset tokens (can be called by a cron job)"""
    try:
        db = request.app.database
        
        current_time = datetime.now(timezone.utc).isoformat()
        result = await db.password_resets.delete_many({
            "expires_at": {"$lt": current_time}
        })
        
        return {"message": f"Cleaned up {result.deleted_count} expired tokens"}
        
    except Exception as e:
        print(f"Error in cleanup_expired_tokens: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error cleaning up tokens"
        )