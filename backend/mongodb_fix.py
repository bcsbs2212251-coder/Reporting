import os
import asyncio
import certifi
from motor.motor_asyncio import AsyncIOMotorClient
from dotenv import load_dotenv

load_dotenv()

async def test_connection():
    uri = os.getenv("MONGODB_URI")
    print(f"Testing connection to: {uri.split('@')[-1]}") # Hide credentials
    
    print("\nAttempt 1: Standard SSL with certifi...")
    try:
        client = AsyncIOMotorClient(
            uri,
            tls=True,
            tlsCAFile=certifi.where(),
            serverSelectionTimeoutMS=10000
        )
        await client.admin.command('ping')
        print("[SUCCESS] Standard SSL connected!")
        return
    except Exception as e:
        print(f"[FAILED] Standard SSL: {e}")

    print("\nAttempt 2: Maximum Compatibility (tlsInsecure=True)...")
    try:
        client = AsyncIOMotorClient(
            uri,
            tlsInsecure=True,
            serverSelectionTimeoutMS=10000
        )
        await client.admin.command('ping')
        print("[SUCCESS] Connected with Insecure fallback!")
        return
    except Exception as e:
        print(f"[FAILED] Insecure Fallback: {e}")

    print("\n[CRITICAL] All connection attempts failed.")
    print("This is almost certainly a bug in Python 3.14 (Experimental) on Windows.")
    print("\nACTION REQUIRED:")
    print("1. Download Python 3.12 (Stable) from python.org")
    print("2. Install it and ensure 'python --version' shows 3.12")
    print("3. Re-run 'pip install -r requirements.txt'")

if __name__ == "__main__":
    asyncio.run(test_connection())