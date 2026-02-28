#!/usr/bin/env python3
"""
MongoDB Connection Test Script
Tests various connection strategies to MongoDB Atlas
"""

import os
import sys
from dotenv import load_dotenv

load_dotenv()

def test_mongodb_connection():
    """Test MongoDB connection with multiple strategies"""
    
    uri = os.getenv("MONGODB_URI")
    
    if not uri:
        print("=" * 60)
        print("ERROR: MONGODB_URI not found in .env file")
        print("=" * 60)
        return False
    
    print("=" * 60)
    print("MongoDB Connection Test")
    print("=" * 60)
    print(f"\nConnection string: {uri[:50]}...")
    print()
    
    # Test strategies
    strategies = [
        {
            "name": "Standard connection with SSL",
            "params": {"tlsAllowInvalidCertificates": False, "serverSelectionTimeoutMS": 5000}
        },
        {
            "name": "Connection without certificate verification",
            "params": {"tlsAllowInvalidCertificates": True, "serverSelectionTimeoutMS": 5000}
        },
        {
            "name": "Connection with TLS insecure mode",
            "params": {"tlsInsecure": True, "serverSelectionTimeoutMS": 5000}
        }
    ]
    
    for i, strategy in enumerate(strategies, 1):
        print(f"[{i}/{len(strategies)}] Testing: {strategy['name']}")
        try:
            from pymongo import MongoClient
            client = MongoClient(uri, **strategy['params'])
            info = client.server_info()
            
            print(f"  ✓ SUCCESS!")
            print(f"  ✓ MongoDB version: {info['version']}")
            print(f"  ✓ Databases: {', '.join(client.list_database_names()[:5])}")
            print()
            print("=" * 60)
            print("✓ MongoDB connection is working!")
            print("=" * 60)
            print(f"\nRecommended connection parameters:")
            print(f"  {strategy['params']}")
            print()
            return True
            
        except Exception as e:
            print(f"  ✗ Failed: {str(e)[:80]}...")
            print()
    
    # All strategies failed
    print("=" * 60)
    print("✗ All connection attempts failed")
    print("=" * 60)
    print("\nPossible issues:")
    print("1. MongoDB Atlas cluster is paused")
    print("2. IP address not whitelisted")
    print("3. Incorrect credentials")
    print("4. Network/firewall blocking connection")
    print("\nSolutions:")
    print("1. Check MongoDB Atlas dashboard")
    print("2. Add your IP to Network Access")
    print("3. Verify MONGODB_URI in .env")
    print("4. See MONGODB_FIX.md for detailed help")
    print("=" * 60)
    return False

if __name__ == "__main__":
    success = test_mongodb_connection()
    sys.exit(0 if success else 1)
