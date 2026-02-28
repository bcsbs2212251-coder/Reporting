from fastapi import APIRouter, HTTPException, status, Request, Depends
from models.report import ReportCreate, ReportUpdate
from utils.auth import get_current_user
from utils.db import get_db
from bson import ObjectId
from datetime import datetime, timezone

router = APIRouter()

@router.post("/")
async def create_report(report: ReportCreate, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # Get user info
        user = await db.users.find_one({"_id": ObjectId(current_user["user_id"])})
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Create report
        report_dict = report.model_dump()
        report_dict["user_id"] = str(user["_id"])
        report_dict["user_name"] = user["full_name"]
        report_dict["status"] = "pending"
        report_dict["created_at"] = datetime.now(timezone.utc)
        report_dict["updated_at"] = datetime.now(timezone.utc)
        
        result = await db.reports.insert_one(report_dict)
        
        return {
            "success": True,
            "message": "Report created successfully",
            "data": {
                "report_id": str(result.inserted_id)
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
async def get_reports(request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # If employee, show only their reports; if admin, show all
        query = {}
        if current_user.get("role") != "admin":
            query["user_id"] = current_user["user_id"]
        
        reports = []
        async for report in db.reports.find(query).sort("created_at", -1):
            reports.append({
                "_id": str(report["_id"]),
                "user_id": report["user_id"],
                "user_name": report["user_name"],
                "title": report["title"],
                "description": report["description"],
                "priority": report["priority"],
                "status": report["status"],
                "category": report.get("category", "general"),
                "attachments": report.get("attachments", []),
                "voice_notes": report.get("voice_notes", []),
                "created_at": report.get("created_at").isoformat() if report.get("created_at") else None,
                "updated_at": report.get("updated_at").isoformat() if report.get("updated_at") else None
            })
        
        return {
            "success": True,
            "data": {
                "reports": reports
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.get("/{report_id}")
async def get_report_by_id(report_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        report = await db.reports.find_one({"_id": ObjectId(report_id)})
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        # Check authorization
        if current_user.get("role") != "admin" and report["user_id"] != current_user["user_id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to view this report"
            )
        
        return {
            "success": True,
            "data": {
                "_id": str(report["_id"]),
                "user_id": report["user_id"],
                "user_name": report["user_name"],
                "title": report["title"],
                "description": report["description"],
                "priority": report["priority"],
                "status": report["status"],
                "category": report.get("category", "general"),
                "attachments": report.get("attachments", []),
                "voice_notes": report.get("voice_notes", []),
                "created_at": report.get("created_at").isoformat() if report.get("created_at") else None,
                "updated_at": report.get("updated_at").isoformat() if report.get("updated_at") else None
            }
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.put("/{report_id}")
async def update_report(report_id: str, report_update: ReportUpdate, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # Check if report exists
        existing_report = await db.reports.find_one({"_id": ObjectId(report_id)})
        if not existing_report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        # Check authorization
        if current_user.get("role") != "admin" and existing_report["user_id"] != current_user["user_id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this report"
            )
        
        # Update report
        update_data = {k: v for k, v in report_update.model_dump().items() if v is not None}
        update_data["updated_at"] = datetime.now(timezone.utc)
        
        await db.reports.update_one(
            {"_id": ObjectId(report_id)},
            {"$set": update_data}
        )
        
        return {
            "success": True,
            "message": "Report updated successfully"
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )

@router.delete("/{report_id}")
async def delete_report(report_id: str, request: Request, current_user: dict = Depends(get_current_user)):
    try:
        db = get_db(request)
        
        # Check if report exists
        existing_report = await db.reports.find_one({"_id": ObjectId(report_id)})
        if not existing_report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found"
            )
        
        # Check authorization (only admin or report owner)
        if current_user.get("role") != "admin" and existing_report["user_id"] != current_user["user_id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this report"
            )
        
        await db.reports.delete_one({"_id": ObjectId(report_id)})
        
        return {
            "success": True,
            "message": "Report deleted successfully"
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=str(e)
        )
