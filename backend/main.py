import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from database import engine, Base
import models
from routers import doctors, appointments, messages
from config import UPLOAD_DIR

app = FastAPI(
    title="Anonymous Doctor API",
    description="Backend for the anonymous doctor patient appointment app",
    version="1.0.0"
)

# Allow requests from Flutter app.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

# Create upload folder if it doesn't exist, then serve it as static files.
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

app.include_router(doctors.router)
app.include_router(appointments.router)
app.include_router(messages.router)

@app.get("/")
def root():
    return {"message": "Anonymous Doctor API is running"}
