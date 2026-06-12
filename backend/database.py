# This file handles the connection between our backend and PostgreSQL database.

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

# Load the .env file so we can read the DATABASE_URL we defined there.
load_dotenv()

# Grab the database URL from the .env file.
DATABASE_URL = os.getenv("DATABASE_URL")

# Create the engine — this is the actual connection to PostgreSQL.
engine = create_engine(DATABASE_URL)

# This is a factory that creates database sessions.
# Every request gets its own session to talk to the database.
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# This is the base class that all our database models will inherit from.
# Think of it as the parent of all your tables.
Base = declarative_base()

# This function gives us a database session for each request.
# It automatically closes the session when the request is done.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
