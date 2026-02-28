#!/usr/bin/env python3
"""
Backend Test Script
Tests all backend imports and basic functionality
"""

import sys
import traceback

def test_imports():
    """Test all critical imports"""
    print("=" * 60)
    print("TESTING BACKEND IMPORTS")
    print("=" * 60)
    
    tests = [
        ("FastAPI", "import fastapi"),
        ("Motor (MongoDB)", "import motor"),
        ("PyMongo", "import pymongo"),
        ("Pydantic", "import pydantic"),
        ("Python-JOSE", "from jose import jwt"),
        ("Passlib", "from passlib.context import CryptContext"),
        ("Cloudinary", "import cloudinary"),
        ("Certifi", "import certifi"),
        ("Main App", "from main import app"),
        ("Auth Routes", "from routes import auth"),
        ("User Routes", "from routes import users"),
        ("Report Routes", "from routes import reports"),
        ("Task Routes", "from routes import tasks"),
        ("Dashboard Routes", "from routes import dashboard"),
        ("Leave Routes", "from routes import leaves"),
        ("Password Reset Routes", "from routes import password_reset"),
        ("Upload Routes", "from routes import upload"),
        ("User Model", "from models.user import UserCreate, UserLogin"),
        ("Report Model", "from models.report import ReportCreate"),
        ("Task Model", "from models.task import TaskCreate"),
        ("Leave Model", "from models.leave import Leave"),
        ("Auth Utils", "from utils.auth import get_password_hash, verify_password"),
        ("Email Service", "from utils.email_service import email_service"),
        ("Cloudinary Utils", "from utils.cloudinary_utils import upload_file"),
    ]
    
    passed = 0
    failed = 0
    
    for name, import_stmt in tests:
        try:
            exec(import_stmt)
            print(f"✓ {name:<30} OK")
            passed += 1
        except Exception as e:
            print(f"✗ {name:<30} FAILED: {str(e)}")
            failed += 1
    
    print("\n" + "=" * 60)
    print(f"RESULTS: {passed} passed, {failed} failed")
    print("=" * 60)
    
    return failed == 0

def test_environment():
    """Test environment configuration"""
    print("\n" + "=" * 60)
    print("TESTING ENVIRONMENT CONFIGURATION")
    print("=" * 60)
    
    import os
    from dotenv import load_dotenv
    
    load_dotenv()
    
    required_vars = [
        "MONGODB_URI",
        "JWT_SECRET",
        "JWT_ALGORITHM",
        "ACCESS_TOKEN_EXPIRE_MINUTES"
    ]
    
    optional_vars = [
        "GMAIL_EMAIL",
        "GMAIL_APP_PASSWORD",
        "CLOUDINARY_CLOUD_NAME",
        "CLOUDINARY_API_KEY",
        "CLOUDINARY_API_SECRET"
    ]
    
    print("\nRequired Variables:")
    all_present = True
    for var in required_vars:
        value = os.getenv(var)
        if value:
            print(f"✓ {var:<35} SET")
        else:
            print(f"✗ {var:<35} MISSING")
            all_present = False
    
    print("\nOptional Variables (for email & file upload):")
    for var in optional_vars:
        value = os.getenv(var)
        if value and not value.startswith("your-"):
            print(f"✓ {var:<35} SET")
        else:
            print(f"⚠ {var:<35} NOT CONFIGURED")
    
    print("\n" + "=" * 60)
    return all_present

def test_app_structure():
    """Test FastAPI app structure"""
    print("\n" + "=" * 60)
    print("TESTING APP STRUCTURE")
    print("=" * 60)
    
    try:
        from main import app
        
        print(f"✓ App Title: {app.title}")
        print(f"✓ Routes registered: {len(app.routes)}")
        
        # List all routes
        print("\nRegistered Routes:")
        for route in app.routes:
            if hasattr(route, 'path') and hasattr(route, 'methods'):
                methods = ', '.join(route.methods) if route.methods else 'N/A'
                print(f"  {methods:<10} {route.path}")
        
        print("\n" + "=" * 60)
        return True
    except Exception as e:
        print(f"✗ Failed to load app: {e}")
        traceback.print_exc()
        return False

def main():
    """Run all tests"""
    print("\n" + "=" * 60)
    print("MOLECULE WORKFLOW PRO - BACKEND TEST SUITE")
    print("=" * 60)
    
    print(f"\nPython Version: {sys.version}")
    
    results = []
    
    # Run tests
    results.append(("Imports", test_imports()))
    results.append(("Environment", test_environment()))
    results.append(("App Structure", test_app_structure()))
    
    # Final summary
    print("\n" + "=" * 60)
    print("FINAL SUMMARY")
    print("=" * 60)
    
    all_passed = True
    for test_name, passed in results:
        status = "✓ PASSED" if passed else "✗ FAILED"
        print(f"{test_name:<20} {status}")
        if not passed:
            all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("✓ ALL TESTS PASSED - Backend is ready!")
        print("\nTo start the backend server, run:")
        print("  uvicorn main:app --reload --host 0.0.0.0 --port 8000")
    else:
        print("✗ SOME TESTS FAILED - Please fix the issues above")
    print("=" * 60 + "\n")
    
    return 0 if all_passed else 1

if __name__ == "__main__":
    sys.exit(main())
