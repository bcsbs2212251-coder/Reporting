from fastapi import APIRouter, HTTPException, status, Request
from models.user import UserCreate, UserLogin, UserResponse
from utils.auth import get_password_hash, verify_password, create_access_token
from bson import ObjectId
from datetime import datetime, timezone
from utils.db import get_db

router = APIRouter()

@router.post("/signup")
async def signup(user: UserCreate, request: Request):
    try:
        db = get_db(request)
        
        # Check if user already exists
        existing_user = await db.users.find_one({"email": user.email})
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Create new user
        user_dict = user.model_dump()
        user_dict["password"] = get_password_hash(user.password)
        user_dict["status"] = "active"
        user_dict["created_at"] = datetime.now(timezone.utc)
        user_dict["updated_at"] = datetime.now(timezone.utc)
        
        result = await db.users.insert_one(user_dict)
        
        return {
            "success": True,
            "message": "User created successfully",
            "data": {
                "user_id": str(result.inserted_id)
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"❌ Signup Error: {str(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.post("/login")
async def login(credentials: UserLogin, request: Request):
    try:
        db = get_db(request)
        
        # Find user by email
        user = await db.users.find_one({"email": credentials.email})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Verify password
        if not verify_password(credentials.password, user["password"]):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Create access token
        access_token = create_access_token(
            data={
                "user_id": str(user["_id"]),
                "email": user["email"],
                "role": user["role"]
            }
        )
        
        return {
            "success": True,
            "message": "Login successful",
            "data": {
                "token": access_token,
                "user": {
                    "_id": str(user["_id"]),
                    "full_name": user["full_name"],
                    "email": user["email"],
                    "role": user["role"],
                    "status": user.get("status", "active")
                }
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
async def get_current_user_info(request: Request):
    try:
        # This would normally use authentication middleware
        # For now, returning a placeholder
        return {
            "success": True,
            "data": {
                "message": "User info endpoint"
            }
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
