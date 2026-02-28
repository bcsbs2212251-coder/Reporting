from fastapi import APIRouter, Depends, HTTPException, status, Request
from typing import List, Optional
from datetime import datetime, timezone
from bson import ObjectId
from models.leave import Leave, LeaveUpdate
from utils.auth import get_current_user
from utils.db import get_db

router = APIRouter()

# Create leave request
@router.post("/leaves")
async def create_leave(leave: Leave, request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db(request)
    leave_dict = leave.dict()
    leave_dict["user_id"] = current_user["_id"]
    leave_dict["user_name"] = current_user["full_name"]
    leave_dict["user_email"] = current_user["email"]
    
    result = await db.leaves.insert_one(leave_dict)
    leave_dict["_id"] = str(result.inserted_id)
    return leave_dict

# Get all leaves (admin)
@router.get("/leaves")
async def get_all_leaves(
    request: Request,
    status: Optional[str] = None,
    month: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db(request)
    query = {}
    if status:
        query["status"] = status
    if month:
        # Filter by month (format: YYYY-MM)
        query["start_date"] = {"$regex": f"^{month}"}
    
    leaves = await db.leaves.find(query).sort("created_at", -1).to_list(length=None)
    for leave in leaves:
        leave["_id"] = str(leave["_id"])
    return leaves

# Get user's own leaves
@router.get("/leaves/my")
async def get_my_leaves(request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db(request)
    leaves = await db.leaves.find({"user_id": current_user["_id"]}).sort("created_at", -1).to_list(length=None)
    for leave in leaves:
        leave["_id"] = str(leave["_id"])
    return leaves

# Get leave by ID
@router.get("/leaves/{leave_id}")
async def get_leave(leave_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db(request)
    if not ObjectId.is_valid(leave_id):
        raise HTTPException(status_code=400, detail="Invalid leave ID")
    
    leave = await db.leaves.find_one({"_id": ObjectId(leave_id)})
    if not leave:
        raise HTTPException(status_code=404, detail="Leave not found")
    
    # Check if user has access
    if current_user["role"] != "admin" and leave["user_id"] != current_user["_id"]:
        raise HTTPException(status_code=403, detail="Access denied")
    
    leave["_id"] = str(leave["_id"])
    return leave

# Update leave status (admin only)
@router.put("/leaves/{leave_id}")
async def update_leave(
    leave_id: str,
    leave_update: LeaveUpdate,
    request: Request,
    current_user: dict = Depends(get_current_user)
):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db(request)
    if not ObjectId.is_valid(leave_id):
        raise HTTPException(status_code=400, detail="Invalid leave ID")
    
    update_data = {k: v for k, v in leave_update.dict().items() if v is not None}
    update_data["updated_at"] = datetime.now(timezone.utc).isoformat()
    
    result = await db.leaves.update_one(
        {"_id": ObjectId(leave_id)},
        {"$set": update_data}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Leave not found")
    
    return {"message": "Leave updated successfully"}

# Delete leave (user can delete their own pending leaves)
@router.delete("/leaves/{leave_id}")
async def delete_leave(leave_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    db = get_db(request)
    if not ObjectId.is_valid(leave_id):
        raise HTTPException(status_code=400, detail="Invalid leave ID")
    
    leave = await db.leaves.find_one({"_id": ObjectId(leave_id)})
    if not leave:
        raise HTTPException(status_code=404, detail="Leave not found")
    
    # Only allow deletion of own pending leaves or admin can delete any
    if current_user["role"] != "admin":
        if leave["user_id"] != current_user["_id"] or leave["status"] != "pending":
            raise HTTPException(status_code=403, detail="Cannot delete this leave")
    
    await db.leaves.delete_one({"_id": ObjectId(leave_id)})
    return {"message": "Leave deleted successfully"}

# Get leave statistics (admin)
@router.get("/leaves/stats/summary")
async def get_leave_stats(request: Request, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db(request)
    total = await db.leaves.count_documents({})
    pending = await db.leaves.count_documents({"status": "pending"})
    approved = await db.leaves.count_documents({"status": "approved"})
    rejected = await db.leaves.count_documents({"status": "rejected"})
    
    return {
        "total": total,
        "pending": pending,
        "approved": approved,
        "rejected": rejected
    }
