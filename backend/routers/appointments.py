# This file handles all appointment related endpoints.

import os
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session
from database import get_db
import models
import schemas
from config import UPLOAD_DIR

router = APIRouter(
    prefix="/appointments",
    tags=["appointments"]
)

# GET /appointments/ — get every appointment in the system.
# Only the admin uses this — patients and doctors use the wallet-filtered route below.
@router.get("/", response_model=list[schemas.AppointmentResponse])
def get_all_appointments(db: Session = Depends(get_db)):
    return db.query(models.Appointment).order_by(models.Appointment.id.desc()).all()


# GET /appointments/{wallet} — get all appointments for a specific wallet.
# Both patients and doctors use this to see their appointments.
@router.get("/{wallet}", response_model=list[schemas.AppointmentResponse])
def get_appointments(wallet: str, db: Session = Depends(get_db)):
    
    # Find appointments where this wallet is either the patient or the doctor.
    appointments = db.query(models.Appointment).filter(
        (func.lower(models.Appointment.patient_wallet) == wallet.lower()) |
        (func.lower(models.Appointment.doctor_wallet) == wallet.lower())
    ).all()
    
    return appointments


# POST /appointments — save appointment record after blockchain confirms.
# App calls this right after the blockchain transaction is confirmed.
@router.post("/", response_model=schemas.AppointmentResponse)
def create_appointment(appointment: schemas.AppointmentCreate, db: Session = Depends(get_db)):
    
    new_appointment = models.Appointment(
        patient_wallet=appointment.patient_wallet.lower(),
        doctor_wallet=appointment.doctor_wallet.lower(),
        blockchain_tx_id=appointment.blockchain_tx_id,
        blockchain_appointment_id=appointment.blockchain_appointment_id,
        scheduled_time=appointment.scheduled_time
    )
    
    db.add(new_appointment)
    db.commit()
    db.refresh(new_appointment)
    
    return new_appointment


# PATCH /appointments/{id} — update appointment status.
# Called when meeting starts, ends, or is cancelled.
@router.patch("/{id}", response_model=schemas.AppointmentResponse)
def update_appointment(id: int, update: schemas.AppointmentUpdate, db: Session = Depends(get_db)):
    
    # Find the appointment.
    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == id
    ).first()
    
    # If not found return 404.
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Update the status.
    appointment.status = update.status

    # If meeting is ending — delete all messages and audio files for this appointment.
    # This preserves anonymity — no chat history kept after session ends.
    if update.status in ['completed', 'cancelled']:
        voice_messages = db.query(models.Message).filter(
            models.Message.appointment_id == id,
            models.Message.media_type == "voice",
        ).all()

        for msg in voice_messages:
            if msg.file_url:
                file_path = os.path.join(UPLOAD_DIR, os.path.basename(msg.file_url))
                if os.path.exists(file_path):
                    os.remove(file_path)

        db.query(models.Message).filter(
            models.Message.appointment_id == id
        ).delete()

    db.commit()
    db.refresh(appointment)

    return appointment
