from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.orm import Session
from models_mysql.user import User, UserResponse, UserUpdate
from utils.mysql_db import get_db
from utils.auth import get_current_user
from typing import List

router = APIRouter()

@router.get("/", response_model=List[UserResponse])
def get_users(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    try:
        # Only admins can view all users
        if current_user.get("role") != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view users"
            )
        
        users = db.query(User).all()
        return users
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/me")
def get_current_user_profile(db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    try:
        user_id = current_user.get("user_id")
        user = db.query(User).filter(User.id == int(user_id)).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return {
            "success": True,
            "data": {
                "_id": str(user.id),
                "full_name": user.full_name,
                "email": user.email,
                "role": user.role.value if hasattr(user.role, 'value') else user.role,
                "status": user.status.value if hasattr(user.status, 'value') else user.status,
                "created_at": user.created_at.isoformat() if user.created_at else None
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
def get_user_by_id(user_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    try:
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return {
            "success": True,
            "data": {
                "_id": str(user.id),
                "full_name": user.full_name,
                "email": user.email,
                "role": user.role.value if hasattr(user.role, 'value') else user.role,
                "status": user.status.value if hasattr(user.status, 'value') else user.status
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.put("/{user_id}")
def update_user(user_id: int, user_update: UserUpdate, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    try:
        # Only admins can update users
        if current_user.get("role") != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update users"
            )
        
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update fields
        if user_update.full_name:
            user.full_name = user_update.full_name
        if user_update.email:
            user.email = user_update.email
        if user_update.role:
            user.role = user_update.role
        if user_update.status:
            user.status = user_update.status
        
        db.commit()
        db.refresh(user)
        
        return {
            "success": True,
            "message": "User updated successfully"
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db), current_user: dict = Depends(get_current_user)):
    try:
        # Only admins can delete users
        if current_user.get("role") != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete users"
            )
        
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        db.delete(user)
        db.commit()
        
        return {
            "success": True,
            "message": "User deleted successfully"
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
