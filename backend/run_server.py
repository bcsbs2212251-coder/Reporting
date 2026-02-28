#!/usr/bin/env python3
"""
Alternative server startup script
Run this if 'uvicorn' command is not found
"""

import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def find_available_port(start_port=8000, max_attempts=10):
    """Find an available port starting from start_port"""
    import socket
    for port in range(start_port, start_port + max_attempts):
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('', port))
                return port
        except OSError:
            continue
    return None

if __name__ == "__main__":
    try:
        import uvicorn
        
        # Find available port
        port = find_available_port(8000)
        
        if port is None:
            print("=" * 60)
            print("ERROR: No available ports found")
            print("=" * 60)
            print("\nPorts 8000-8009 are all in use.")
            print("\nTo free up port 8000, run:")
            print("  netstat -ano | findstr :8000")
            print("  taskkill /PID <PID> /F")
            print("\nOr manually specify a different port in this script.")
            print("=" * 60)
            sys.exit(1)
        
        print("=" * 60)
        print("Starting Molecule WorkFlow Pro Backend Server")
        print("=" * 60)
        
        if port != 8000:
            print(f"\n⚠️  Port 8000 is in use, using port {port} instead")
            print("\nTo use port 8000, kill the process using it:")
            print("  netstat -ano | findstr :8000")
            print("  taskkill /PID <PID> /F")
        
        print(f"\nServer will be available at:")
        print(f"  - http://localhost:{port}")
        print(f"  - http://127.0.0.1:{port}")
        print(f"\nAPI Documentation:")
        print(f"  - http://localhost:{port}/docs")
        print(f"\nPress CTRL+C to stop the server")
        print("=" * 60)
        print()
        
        uvicorn.run(
            "main:app",
            host="0.0.0.0",
            port=port,
            reload=True,
            log_level="info"
        )
    except ImportError:
        print("=" * 60)
        print("ERROR: uvicorn is not installed")
        print("=" * 60)
        print("\nPlease install dependencies first:")
        print("  pip install -r requirements.txt")
        print("\nOr install uvicorn specifically:")
        print("  pip install uvicorn[standard]")
        print("=" * 60)
        sys.exit(1)
    except Exception as e:
        print(f"\nERROR: {e}")
        sys.exit(1)
