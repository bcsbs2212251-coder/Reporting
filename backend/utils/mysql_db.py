from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool
import os
from dotenv import load_dotenv

load_dotenv()

Base = declarative_base()

# Global variables for lazy initialization
_engine = None
_SessionLocal = None

def get_engine():
    """Lazy initialization of database engine"""
    global _engine
    if _engine is None:
        # MySQL Database URL
        MYSQL_HOST = os.getenv("MYSQL_HOST", "localhost")
        MYSQL_PORT = os.getenv("MYSQL_PORT", "3306")
        MYSQL_USER = os.getenv("MYSQL_USER", "root")
        MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
        MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "reporting_db")
        
        DATABASE_URL = f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}"
        
        # Create engine with connection pool settings
        _engine = create_engine(
            DATABASE_URL,
            echo=True,
            pool_pre_ping=True,  # Enable connection health checks
            pool_recycle=3600,   # Recycle connections after 1 hour
            pool_size=10,        # Maximum number of connections
            max_overflow=20,     # Maximum overflow connections
            connect_args={
                "connect_timeout": 10
            }
        )
    return _engine

def get_session_local():
    """Lazy initialization of session maker"""
    global _SessionLocal
    if _SessionLocal is None:
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=get_engine())
    return _SessionLocal

# For backward compatibility
@property
def engine():
    return get_engine()

@property
def SessionLocal():
    return get_session_local()

def get_db():
    SessionLocal = get_session_local()
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_db():
    """Initialize database tables"""
    Base.metadata.create_all(bind=get_engine())
