# This file defines the shape of data coming INTO and going OUT of our API.
# Think of schemas as the contract between the app and the backend.
# Pydantic validates everything automatically — wrong data gets rejected.

from pydantic import BaseModel
from datetime import datetime
from typing import Optional

# ─────────────────────────────────────────
# DOCTOR SCHEMAS
# ─────────────────────────────────────────

# Shape of data when CREATING a doctor — what the admin sends in.
class DoctorCreate(BaseModel):
    name: str
    specialty: str
    wallet_address: str

# Shape of data when RETURNING a doctor — what the API sends back.
class DoctorResponse(BaseModel):
    id: int
    name: str
    specialty: str
    wallet_address: str

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# APPOINTMENT SCHEMAS
# ─────────────────────────────────────────

# Shape of data when CREATING an appointment — sent after blockchain confirms.
class AppointmentCreate(BaseModel):
    patient_wallet: str
    doctor_wallet: str
    blockchain_tx_id: str
    blockchain_appointment_id: int
    scheduled_time: datetime

# Shape of data when UPDATING an appointment — just the status changes.
class AppointmentUpdate(BaseModel):
    status: str

# Shape of data when RETURNING an appointment — what the API sends back.
class AppointmentResponse(BaseModel):
    id: int
    patient_wallet: str
    doctor_wallet: str
    blockchain_tx_id: str
    blockchain_appointment_id: int
    status: str
    scheduled_time: datetime
    created_at: datetime

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# MESSAGE SCHEMAS
# ─────────────────────────────────────────

# Shape of data when SENDING a text message.
class MessageCreate(BaseModel):
    appointment_id: int
    sender_wallet: str
    content: str

# Shape of data when RETURNING a message (text or voice).
class MessageResponse(BaseModel):
    id: int
    appointment_id: int
    sender_wallet: str
    content: Optional[str]
    media_type: str
    file_url: Optional[str]
    sent_at: datetime

    class Config:
        from_attributes = True