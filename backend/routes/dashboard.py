from fastapi import APIRouter, HTTPException, status, Request, Depends
from utils.auth import get_current_user
from utils.db import get_db
from bson import ObjectId

router = APIRouter()

@router.get("/stats")
async def get_dashboard_stats(request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        if current_user.get("role") == "admin":
            # Admin stats
            total_users = await db.users.count_documents({})
            total_reports = await db.reports.count_documents({})
            total_tasks = await db.tasks.count_documents({})
            pending_reports = await db.reports.count_documents({"status": "pending"})
            
            return {
                "success": True,
                "data": {
                    "total_users": total_users,
                    "total_reports": total_reports,
                    "total_tasks": total_tasks,
                    "pending_reports": pending_reports
                }
            }
        else:
            # Employee stats
            user_id = current_user["user_id"]
            my_reports = await db.reports.count_documents({"user_id": user_id})
            my_tasks = await db.tasks.count_documents({"user_id": user_id})
            pending_tasks = await db.tasks.count_documents({
                "user_id": user_id,
                "status": "pending"
            })
            
            return {
                "success": True,
                "data": {
                    "my_reports": my_reports,
                    "my_tasks": my_tasks,
                    "pending_tasks": pending_tasks
                }
            }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/analytics")
async def get_analytics(request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # Build query based on role
        query = {}
        if current_user.get("role") != "admin":
            query["user_id"] = current_user["user_id"]
        
        # Get report statistics by status
        report_stats = {
            "total": await db.reports.count_documents(query),
            "pending": await db.reports.count_documents({**query, "status": "pending"}),
            "approved": await db.reports.count_documents({**query, "status": "approved"}),
            "rejected": await db.reports.count_documents({**query, "status": "rejected"}),
            "completed": await db.reports.count_documents({**query, "status": "completed"})
        }
        
        # Get task statistics by status
        task_stats = {
            "total": await db.tasks.count_documents(query),
            "pending": await db.tasks.count_documents({**query, "status": "pending"}),
            "in_progress": await db.tasks.count_documents({**query, "status": "in_progress"}),
            "completed": await db.tasks.count_documents({**query, "status": "completed"}),
            "cancelled": await db.tasks.count_documents({**query, "status": "cancelled"})
        }
        
        return {
            "success": True,
            "data": {
                "reports": report_stats,
                "tasks": task_stats
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
