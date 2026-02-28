from fastapi import APIRouter, HTTPException, status, Request, Depends
from models.task import TaskCreate, TaskUpdate
from utils.auth import get_current_user
from utils.db import get_db
from bson import ObjectId
from datetime import datetime, timezone

router = APIRouter()

@router.post("/")
async def create_task(task: TaskCreate, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # Only admins can create tasks
        if current_user.get("role") != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can create tasks"
            )
        
        # Create task
        task_dict = task.model_dump()
        task_dict["assigned_by"] = current_user["user_id"]
        task_dict["status"] = "pending"
        task_dict["created_at"] = datetime.now(timezone.utc)
        task_dict["updated_at"] = datetime.now(timezone.utc)
        
        result = await db.tasks.insert_one(task_dict)
        
        return {
            "success": True,
            "message": "Task created successfully",
            "data": {
                "task_id": str(result.inserted_id)
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/")
async def get_tasks(request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # If employee, show only their tasks; if admin, show all
        query = {}
        if current_user.get("role") != "admin":
            query["user_id"] = current_user["user_id"]
        
        tasks = []
        async for task in db.tasks.find(query).sort("created_at", -1):
            tasks.append({
                "_id": str(task["_id"]),
                "user_id": task["user_id"],
                "assigned_by": task.get("assigned_by"),
                "title": task["title"],
                "description": task.get("description", ""),
                "priority": task["priority"],
                "status": task["status"],
                "due_date": task.get("due_date").isoformat() if task.get("due_date") else None,
                "created_at": task.get("created_at").isoformat() if task.get("created_at") else None,
                "updated_at": task.get("updated_at").isoformat() if task.get("updated_at") else None
            })
        
        return {
            "success": True,
            "data": {
                "tasks": tasks
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{task_id}")
async def get_task_by_id(task_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        task = await db.tasks.find_one({"_id": ObjectId(task_id)})
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        # Check authorization
        if current_user.get("role") != "admin" and task["user_id"] != current_user["user_id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view this task"
            )
        
        return {
            "success": True,
            "data": {
                "_id": str(task["_id"]),
                "user_id": task["user_id"],
                "assigned_by": task.get("assigned_by"),
                "title": task["title"],
                "description": task.get("description", ""),
                "priority": task["priority"],
                "status": task["status"],
                "due_date": task.get("due_date").isoformat() if task.get("due_date") else None,
                "created_at": task.get("created_at").isoformat() if task.get("created_at") else None,
                "updated_at": task.get("updated_at").isoformat() if task.get("updated_at") else None
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.put("/{task_id}")
async def update_task(task_id: str, task_update: TaskUpdate, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # Check if task exists
        existing_task = await db.tasks.find_one({"_id": ObjectId(task_id)})
        if not existing_task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        # Check authorization
        if current_user.get("role") != "admin" and existing_task["user_id"] != current_user["user_id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this task"
            )
        
        # Update task
        update_data = {k: v for k, v in task_update.model_dump().items() if v is not None}
        update_data["updated_at"] = datetime.now(timezone.utc)
        
        await db.tasks.update_one(
            {"_id": ObjectId(task_id)},
            {"$set": update_data}
        )
        
        return {
            "success": True,
            "message": "Task updated successfully"
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/{task_id}")
async def delete_task(task_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # Only admins can delete tasks
        if current_user.get("role") != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can delete tasks"
            )
        
        # Check if task exists
        existing_task = await db.tasks.find_one({"_id": ObjectId(task_id)})
        if not existing_task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        await db.tasks.delete_one({"_id": ObjectId(task_id)})
        
        return {
            "success": True,
            "message": "Task deleted successfully"
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
