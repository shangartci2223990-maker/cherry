# This file handles all doctor related endpoints.
# Only two endpoints — get all doctors and create a doctor.

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models
import schemas

# This creates a router — think of it as a mini app for doctor routes.
router = APIRouter(
    prefix="/doctors",
    tags=["doctors"]
)

# GET /doctors — returns list of all doctors.
# The patient uses this to see who they can book.
@router.get("/", response_model=list[schemas.DoctorResponse])
def get_doctors(db: Session = Depends(get_db)):
    doctors = db.query(models.Doctor).all()
    return doctors


# POST /doctors — admin creates a new doctor.
# No authentication for now — just pass the wallet address in the body.
@router.post("/", response_model=schemas.DoctorResponse)
def create_doctor(doctor: schemas.DoctorCreate, db: Session = Depends(get_db)):
    
    # Check if a doctor with this wallet already exists.
    existing = db.query(models.Doctor).filter(
        models.Doctor.wallet_address == doctor.wallet_address
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Doctor with this wallet already exists")
    
    # Create the new doctor record.
    new_doctor = models.Doctor(
        name=doctor.name,
        specialty=doctor.specialty,
        wallet_address=doctor.wallet_address
    )
    
    db.add(new_doctor)
    db.commit()
    db.refresh(new_doctor)
    
    return new_doctor
