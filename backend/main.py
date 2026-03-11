from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import os
from dotenv import load_dotenv

from utils.mysql_db import Base, get_engine, init_db
from models_mysql.user import User
from models_mysql.report import Report
from models_mysql.task import Task
from models_mysql.leave import Leave

# Import MySQL routes
from routes_mysql import auth, users, reports, tasks, dashboard, leaves, password_reset, upload, export

load_dotenv()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    try:
        print("[INFO] Initializing MySQL database connection...")
        # Create all tables if they don't exist
        Base.metadata.create_all(bind=get_engine())
        print("[SUCCESS] MySQL database connected and tables initialized")
        print("[INFO] Database tables: users, reports, tasks, leaves")
    except Exception as e:
        print(f"[ERROR] Database initialization error: {e}")
        print("[WARNING] Server starting without database connection")
    
    yield
    
    # Shutdown
    print("[INFO] Shutting down application")

app = FastAPI(title="Molecule WorkFlow Pro API", lifespan=lifespan, redirect_slashes=False)

# CORS middleware - Allow your production domain
origins = [
    "https://reporting.webconferencesolutions.com",
    "http://localhost:3000",
    "http://localhost:8000",
    "*"  # Allow all for development
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(reports.router, prefix="/api/reports", tags=["Reports"])
app.include_router(tasks.router, prefix="/api/tasks", tags=["Tasks"])
app.include_router(dashboard.router, prefix="/api/dashboard", tags=["Dashboard"])
app.include_router(leaves.router, prefix="/api", tags=["Leaves"])
app.include_router(upload.router, prefix="/api", tags=["Upload"])
app.include_router(password_reset.router, prefix="/api/auth", tags=["Password Reset"])
app.include_router(export.router, prefix="/api", tags=["Export"])

@app.get("/")
async def root():
    return {"message": "Molecule WorkFlow Pro API - MySQL", "status": "running"}

@app.get("/api/health")
async def health_check():
    return {"status": "ok", "message": "Server is running with MySQL"}

@app.get("/health")
async def health_check_root():
    """Health check endpoint for Railway"""
    return {"status": "ok", "message": "Server is running with MySQL"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8001))
    uvicorn.run(app, host="0.0.0.0", port=port)
