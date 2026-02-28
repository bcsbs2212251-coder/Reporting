from fastapi import APIRouter, Depends, HTTPException, Request, Query
from fastapi.responses import StreamingResponse
from utils.auth import get_current_user
from utils.db import get_db
from utils import pdf_generator
import csv
import io
from datetime import datetime

router = APIRouter()

@router.get("/export/reports")
async def export_reports(
    request: Request, 
    format: str = Query("csv", enum=["csv", "pdf"]),
    current_user: dict = Depends(get_current_user)
):
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db(request)
    reports = await db.reports.find().sort("created_at", -1).to_list(length=None)
    
    filename = f"reports_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    if format == "pdf":
        pdf_bytes = pdf_generator.generate_reports_pdf(reports)
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}.pdf"}
        )
    
    # Default CSV
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "User", "Title", "Category", "Priority", "Status", "Date"])
    
    for r in reports:
        date_str = r.get("created_at").strftime("%Y-%m-%d %H:%M") if isinstance(r.get("created_at"), datetime) else str(r.get("created_at", ""))
        writer.writerow([
            str(r["_id"]),
            r.get("user_name", ""),
            r.get("title", ""),
            r.get("category", "general"),
            r.get("priority", "medium"),
            r.get("status", "pending"),
            date_str
        ])
    
    output.seek(0)
    return StreamingResponse(
        io.BytesIO(output.getvalue().encode()),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
    )

@router.get("/export/leaves")
async def export_leaves(
    request: Request, 
    format: str = Query("csv", enum=["csv", "pdf"]),
    current_user: dict = Depends(get_current_user)
):
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db(request)
    leaves = await db.leaves.find().sort("created_at", -1).to_list(length=None)
    
    filename = f"leaves_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    if format == "pdf":
        pdf_bytes = pdf_generator.generate_leaves_pdf(leaves)
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}.pdf"}
        )
    
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "User", "Type", "Reason", "Start Date", "End Date", "Status", "Applied On"])
    
    for l in leaves:
        created_at = l.get("created_at", "")
        if isinstance(created_at, datetime):
            created_at = created_at.strftime("%Y-%m-%d %H:%M")
            
        writer.writerow([
            str(l["_id"]),
            l.get("user_name", ""),
            l.get("leave_type", ""),
            l.get("reason", ""),
            l.get("start_date", ""),
            l.get("end_date", ""),
            l.get("status", "pending"),
            created_at
        ])
    
    output.seek(0)
    return StreamingResponse(
        io.BytesIO(output.getvalue().encode()),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
    )

@router.get("/export/tasks")
async def export_tasks(
    request: Request, 
    format: str = Query("csv", enum=["csv", "pdf"]),
    current_user: dict = Depends(get_current_user)
):
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db(request)
    tasks = await db.tasks.find().sort("created_at", -1).to_list(length=None)
    
    filename = f"tasks_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    if format == "pdf":
        pdf_bytes = pdf_generator.generate_tasks_pdf(tasks)
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}.pdf"}
        )
    
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "Assigned To", "Title", "Priority", "Status", "Due Date", "Created At"])
    
    for t in tasks:
        created_at = t.get("created_at", "")
        if isinstance(created_at, datetime):
            created_at = created_at.strftime("%Y-%m-%d %H:%M")
        
        due_date = t.get("due_date", "")
        if isinstance(due_date, datetime):
            due_date = due_date.strftime("%Y-%m-%d")
            
        writer.writerow([
            str(t["_id"]),
            t.get("user_name", t.get("user_id", "")),
            t.get("title", ""),
            t.get("priority", "medium"),
            t.get("status", "pending"),
            due_date,
            created_at
        ])
    
    output.seek(0)
    return StreamingResponse(
        io.BytesIO(output.getvalue().encode()),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
    )

@router.get("/export/users")
async def export_users(
    request: Request, 
    format: str = Query("csv", enum=["csv", "pdf"]),
    current_user: dict = Depends(get_current_user)
):
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    db = get_db(request)
    users = await db.users.find().sort("role", 1).to_list(length=None)
    
    filename = f"users_export_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    
    if format == "pdf":
        pdf_bytes = pdf_generator.generate_users_pdf(users)
        return StreamingResponse(
            io.BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename={filename}.pdf"}
        )
    
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["ID", "Name", "Email", "Role", "Department", "Location", "Created At"])
    
    for u in users:
        created_at = u.get("created_at", "")
        if isinstance(created_at, datetime):
            created_at = created_at.strftime("%Y-%m-%d %H:%M")
            
        writer.writerow([
            str(u["_id"]),
            u.get("full_name", ""),
            u.get("email", ""),
            u.get("role", "employee"),
            u.get("department", ""),
            u.get("location", ""),
            created_at
        ])
    
    output.seek(0)
    return StreamingResponse(
        io.BytesIO(output.getvalue().encode()),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}.csv"}
    )
