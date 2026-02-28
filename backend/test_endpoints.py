"""
Comprehensive API Endpoint Testing Script
Tests all endpoints with proper authentication and error handling
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000/api"

# Colors for terminal output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_success(message):
    print(f"{Colors.GREEN}✓ {message}{Colors.END}")

def print_error(message):
    print(f"{Colors.RED}✗ {message}{Colors.END}")

def print_info(message):
    print(f"{Colors.BLUE}ℹ {message}{Colors.END}")

def print_warning(message):
    print(f"{Colors.YELLOW}⚠ {message}{Colors.END}")

# Test data
admin_user = {
    "full_name": "Test Admin",
    "email": f"admin.test.{datetime.now().timestamp()}@molecule.com",
    "password": "admin123",
    "role": "admin"
}

employee_user = {
    "full_name": "Test Employee",
    "email": f"employee.test.{datetime.now().timestamp()}@molecule.com",
    "password": "employee123",
    "role": "employee"
}

# Store tokens
admin_token = None
employee_token = None
test_report_id = None
test_task_id = None

def test_health_check():
    """Test health check endpoint"""
    print_info("Testing health check endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print_success("Health check passed")
            return True
        else:
            print_error(f"Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Health check error: {str(e)}")
        return False

def test_signup(user_data, user_type):
    """Test user signup"""
    print_info(f"Testing {user_type} signup...")
    try:
        response = requests.post(
            f"{BASE_URL}/auth/signup",
            json=user_data
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print_success(f"{user_type} signup successful")
                return True
            else:
                print_error(f"{user_type} signup failed: {data.get('message')}")
                return False
        else:
            print_error(f"{user_type} signup failed: {response.status_code}")
            print_error(f"Response: {response.text}")
            return False
    except Exception as e:
        print_error(f"{user_type} signup error: {str(e)}")
        return False

def test_login(email, password, user_type):
    """Test user login"""
    print_info(f"Testing {user_type} login...")
    try:
        response = requests.post(
            f"{BASE_URL}/auth/login",
            json={"email": email, "password": password}
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                token = data['data']['token']
                user = data['data']['user']
                print_success(f"{user_type} login successful")
                print_info(f"User: {user['full_name']} ({user['role']})")
                return token
            else:
                print_error(f"{user_type} login failed: {data.get('message')}")
                return None
        else:
            print_error(f"{user_type} login failed: {response.status_code}")
            return None
    except Exception as e:
        print_error(f"{user_type} login error: {str(e)}")
        return None

def test_get_current_user(token, user_type):
    """Test get current user endpoint"""
    print_info(f"Testing get current user for {user_type}...")
    try:
        response = requests.get(
            f"{BASE_URL}/users/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                user = data['data']
                print_success(f"Got user info: {user['full_name']}")
                return True
            else:
                print_error(f"Failed to get user info")
                return False
        else:
            print_error(f"Get user failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Get user error: {str(e)}")
        return False

def test_create_report(token, user_type):
    """Test create report endpoint"""
    print_info(f"Testing create report for {user_type}...")
    try:
        report_data = {
            "title": f"Test Report from {user_type}",
            "description": "This is a test report created by automated testing",
            "priority": "high",
            "category": "testing"
        }
        response = requests.post(
            f"{BASE_URL}/reports",
            headers={"Authorization": f"Bearer {token}"},
            json=report_data
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                report_id = data['data']['report_id']
                print_success(f"Report created: {report_id}")
                return report_id
            else:
                print_error(f"Failed to create report")
                return None
        else:
            print_error(f"Create report failed: {response.status_code}")
            print_error(f"Response: {response.text}")
            return None
    except Exception as e:
        print_error(f"Create report error: {str(e)}")
        return None

def test_get_reports(token, user_type):
    """Test get reports endpoint"""
    print_info(f"Testing get reports for {user_type}...")
    try:
        response = requests.get(
            f"{BASE_URL}/reports",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                reports = data['data']['reports']
                print_success(f"Got {len(reports)} reports")
                return True
            else:
                print_error(f"Failed to get reports")
                return False
        else:
            print_error(f"Get reports failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Get reports error: {str(e)}")
        return False

def test_update_report(token, report_id, user_type):
    """Test update report endpoint"""
    print_info(f"Testing update report for {user_type}...")
    try:
        update_data = {
            "status": "approved",
            "priority": "medium"
        }
        response = requests.put(
            f"{BASE_URL}/reports/{report_id}",
            headers={"Authorization": f"Bearer {token}"},
            json=update_data
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print_success(f"Report updated successfully")
                return True
            else:
                print_error(f"Failed to update report")
                return False
        else:
            print_error(f"Update report failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Update report error: {str(e)}")
        return False

def test_create_task(token, user_id):
    """Test create task endpoint (admin only)"""
    print_info("Testing create task (admin only)...")
    try:
        task_data = {
            "user_id": user_id,
            "title": "Test Task",
            "description": "This is a test task",
            "priority": "high"
        }
        response = requests.post(
            f"{BASE_URL}/tasks",
            headers={"Authorization": f"Bearer {token}"},
            json=task_data
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                task_id = data['data']['task_id']
                print_success(f"Task created: {task_id}")
                return task_id
            else:
                print_error(f"Failed to create task")
                return None
        else:
            print_error(f"Create task failed: {response.status_code}")
            print_error(f"Response: {response.text}")
            return None
    except Exception as e:
        print_error(f"Create task error: {str(e)}")
        return None

def test_get_tasks(token, user_type):
    """Test get tasks endpoint"""
    print_info(f"Testing get tasks for {user_type}...")
    try:
        response = requests.get(
            f"{BASE_URL}/tasks",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                tasks = data['data']['tasks']
                print_success(f"Got {len(tasks)} tasks")
                return True
            else:
                print_error(f"Failed to get tasks")
                return False
        else:
            print_error(f"Get tasks failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Get tasks error: {str(e)}")
        return False

def test_update_task(token, task_id, user_type):
    """Test update task endpoint"""
    print_info(f"Testing update task for {user_type}...")
    try:
        update_data = {
            "status": "completed"
        }
        response = requests.put(
            f"{BASE_URL}/tasks/{task_id}",
            headers={"Authorization": f"Bearer {token}"},
            json=update_data
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print_success(f"Task updated successfully")
                return True
            else:
                print_error(f"Failed to update task")
                return False
        else:
            print_error(f"Update task failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Update task error: {str(e)}")
        return False

def test_get_dashboard_stats(token, user_type):
    """Test get dashboard stats endpoint"""
    print_info(f"Testing dashboard stats for {user_type}...")
    try:
        response = requests.get(
            f"{BASE_URL}/dashboard/stats",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                stats = data['data']
                print_success(f"Got dashboard stats: {stats}")
                return True
            else:
                print_error(f"Failed to get dashboard stats")
                return False
        else:
            print_error(f"Get dashboard stats failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Get dashboard stats error: {str(e)}")
        return False

def test_get_analytics(token, user_type):
    """Test get analytics endpoint"""
    print_info(f"Testing analytics for {user_type}...")
    try:
        response = requests.get(
            f"{BASE_URL}/dashboard/analytics",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                analytics = data['data']
                print_success(f"Got analytics data")
                return True
            else:
                print_error(f"Failed to get analytics")
                return False
        else:
            print_error(f"Get analytics failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Get analytics error: {str(e)}")
        return False

def test_get_users(token):
    """Test get all users endpoint (admin only)"""
    print_info("Testing get all users (admin only)...")
    try:
        response = requests.get(
            f"{BASE_URL}/users",
            headers={"Authorization": f"Bearer {token}"}
        )
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                users = data['data']['users']
                print_success(f"Got {len(users)} users")
                return users
            else:
                print_error(f"Failed to get users")
                return None
        else:
            print_error(f"Get users failed: {response.status_code}")
            return None
    except Exception as e:
        print_error(f"Get users error: {str(e)}")
        return None

def test_unauthorized_access():
    """Test unauthorized access"""
    print_info("Testing unauthorized access...")
    try:
        response = requests.get(f"{BASE_URL}/users/me")
        if response.status_code == 401:
            print_success("Unauthorized access properly blocked")
            return True
        else:
            print_error(f"Unauthorized access not blocked: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Unauthorized access test error: {str(e)}")
        return False

def run_all_tests():
    """Run all tests"""
    global admin_token, employee_token, test_report_id, test_task_id
    
    print("\n" + "="*60)
    print("MOLECULE WORKFLOW PRO - API ENDPOINT TESTING")
    print("="*60 + "\n")
    
    results = {
        "passed": 0,
        "failed": 0,
        "total": 0
    }
    
    # Test 1: Health Check
    results["total"] += 1
    if test_health_check():
        results["passed"] += 1
    else:
        results["failed"] += 1
        print_error("Backend is not running! Please start the backend server.")
        return results
    
    print("\n" + "-"*60)
    print("AUTHENTICATION TESTS")
    print("-"*60 + "\n")
    
    # Test 2: Admin Signup
    results["total"] += 1
    if test_signup(admin_user, "Admin"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 3: Employee Signup
    results["total"] += 1
    if test_signup(employee_user, "Employee"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 4: Admin Login
    results["total"] += 1
    admin_token = test_login(admin_user["email"], admin_user["password"], "Admin")
    if admin_token:
        results["passed"] += 1
    else:
        results["failed"] += 1
        print_error("Cannot continue without admin token")
        return results
    
    # Test 5: Employee Login
    results["total"] += 1
    employee_token = test_login(employee_user["email"], employee_user["password"], "Employee")
    if employee_token:
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 6: Unauthorized Access
    results["total"] += 1
    if test_unauthorized_access():
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    print("\n" + "-"*60)
    print("USER TESTS")
    print("-"*60 + "\n")
    
    # Test 7: Get Current User (Admin)
    results["total"] += 1
    if test_get_current_user(admin_token, "Admin"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 8: Get Current User (Employee)
    results["total"] += 1
    if test_get_current_user(employee_token, "Employee"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 9: Get All Users (Admin)
    results["total"] += 1
    users = test_get_users(admin_token)
    if users:
        results["passed"] += 1
        employee_id = next((u['_id'] for u in users if u['email'] == employee_user["email"]), None)
    else:
        results["failed"] += 1
        employee_id = None
    
    print("\n" + "-"*60)
    print("REPORT TESTS")
    print("-"*60 + "\n")
    
    # Test 10: Create Report (Employee)
    results["total"] += 1
    test_report_id = test_create_report(employee_token, "Employee")
    if test_report_id:
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 11: Get Reports (Employee)
    results["total"] += 1
    if test_get_reports(employee_token, "Employee"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 12: Get Reports (Admin)
    results["total"] += 1
    if test_get_reports(admin_token, "Admin"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 13: Update Report (Admin)
    if test_report_id:
        results["total"] += 1
        if test_update_report(admin_token, test_report_id, "Admin"):
            results["passed"] += 1
        else:
            results["failed"] += 1
    
    print("\n" + "-"*60)
    print("TASK TESTS")
    print("-"*60 + "\n")
    
    # Test 14: Create Task (Admin)
    if employee_id:
        results["total"] += 1
        test_task_id = test_create_task(admin_token, employee_id)
        if test_task_id:
            results["passed"] += 1
        else:
            results["failed"] += 1
    
    # Test 15: Get Tasks (Employee)
    results["total"] += 1
    if test_get_tasks(employee_token, "Employee"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 16: Get Tasks (Admin)
    results["total"] += 1
    if test_get_tasks(admin_token, "Admin"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 17: Update Task (Employee)
    if test_task_id:
        results["total"] += 1
        if test_update_task(employee_token, test_task_id, "Employee"):
            results["passed"] += 1
        else:
            results["failed"] += 1
    
    print("\n" + "-"*60)
    print("DASHBOARD TESTS")
    print("-"*60 + "\n")
    
    # Test 18: Dashboard Stats (Admin)
    results["total"] += 1
    if test_get_dashboard_stats(admin_token, "Admin"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 19: Dashboard Stats (Employee)
    results["total"] += 1
    if test_get_dashboard_stats(employee_token, "Employee"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 20: Analytics (Admin)
    results["total"] += 1
    if test_get_analytics(admin_token, "Admin"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    # Test 21: Analytics (Employee)
    results["total"] += 1
    if test_get_analytics(employee_token, "Employee"):
        results["passed"] += 1
    else:
        results["failed"] += 1
    
    return results

if __name__ == "__main__":
    results = run_all_tests()
    
    print("\n" + "="*60)
    print("TEST RESULTS SUMMARY")
    print("="*60)
    print(f"\nTotal Tests: {results['total']}")
    print(f"{Colors.GREEN}Passed: {results['passed']}{Colors.END}")
    print(f"{Colors.RED}Failed: {results['failed']}{Colors.END}")
    
    success_rate = (results['passed'] / results['total'] * 100) if results['total'] > 0 else 0
    print(f"\nSuccess Rate: {success_rate:.1f}%")
    
    if results['failed'] == 0:
        print(f"\n{Colors.GREEN}🎉 ALL TESTS PASSED! 🎉{Colors.END}")
    else:
        print(f"\n{Colors.YELLOW}⚠ Some tests failed. Please review the errors above.{Colors.END}")
    
    print("\n" + "="*60 + "\n")
