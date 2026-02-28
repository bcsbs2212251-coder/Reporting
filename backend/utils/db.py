from fastapi import HTTPException, Request, status

def get_db(request: Request):
    db = request.app.database
    if db is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database connection failed. Please ensure your database is accessible."
        )
    return db
