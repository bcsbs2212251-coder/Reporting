#!/usr/bin/env python3
"""Quick check if dependencies are installed"""

import sys

print("Checking Python packages...")
print(f"Python version: {sys.version}\n")

packages = [
    "fastapi",
    "uvicorn", 
    "motor",
    "pymongo",
    "pydantic",
    "jose",
    "passlib",
    "dotenv"
]

missing = []
installed = []

for package in packages:
    try:
        __import__(package)
        installed.append(package)
        print(f"✓ {package}")
    except ImportError:
        missing.append(package)
        print(f"✗ {package} - NOT INSTALLED")

print("\n" + "=" * 50)
if missing:
    print(f"MISSING: {len(missing)} package(s)")
    print("\nTo install missing packages, run:")
    print("  pip install -r requirements.txt")
    print("\nOr install individually:")
    for pkg in missing:
        print(f"  pip install {pkg}")
else:
    print("✓ ALL PACKAGES INSTALLED!")
    print("\nYou can now start the server:")
    print("  python run_server.py")
print("=" * 50)
