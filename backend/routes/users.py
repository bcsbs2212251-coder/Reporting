from fastapi import APIRouter, HTTPException, status, Request, Depends
from utils.auth import get_current_user
from utils.db import get_db
from bson import ObjectId

router = APIRouter()

@router.get("/")
async def get_users(request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # Only admins can view all users
        if current_user.get("role") != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view users"
            )
        
        users = []
        async for user in db.users.find():
            users.append({
                "_id": str(user["_id"]),
                "full_name": user["full_name"],
                "email": user["email"],
                "role": user["role"],
                "status": user.get("status", "active"),
                "created_at": user.get("created_at")
            })
        
        return {
            "success": True,
            "data": {
                "users": users
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/me")
async def get_current_user_profile(request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        user = await db.users.find_one({"_id": ObjectId(current_user["user_id"])})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return {
            "success": True,
            "data": {
                "_id": str(user["_id"]),
                "full_name": user["full_name"],
                "email": user["email"],
                "role": user["role"],
                "status": user.get("status", "active"),
                "created_at": user.get("created_at")
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{user_id}")
async def get_user_by_id(user_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        user = await db.users.find_one({"_id": ObjectId(user_id)})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return {
            "success": True,
            "data": {
                "_id": str(user["_id"]),
                "full_name": user["full_name"],
                "email": user["email"],
                "role": user["role"],
                "status": user.get("status", "active"),
                "created_at": user.get("created_at")
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
