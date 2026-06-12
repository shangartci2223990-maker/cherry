# This file defines our three database tables as Python classes.
# SQLAlchemy will use these to create the actual tables in PostgreSQL.

from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.sql import func
from datetime import datetime, timezone
from database import Base

# This is the doctors table.
# Only the admin can add doctors.
class Doctor(Base):
    __tablename__ = "doctors"

    # Unique ID for each doctor — auto increments.
    id = Column(Integer, primary_key=True, index=True)

    # Doctor's real name — only doctors have real names, patients are anonymous.
    name = Column(String, nullable=False)

    # Doctor's specialty — e.g. therapist, psychiatrist.
    specialty = Column(String, nullable=False)

    # The wallet address linked to this doctor.
    # This is how the app knows if a connecting wallet is a doctor.
    wallet_address = Column(String, unique=True, nullable=False)


# This is the appointments table.
# Created after a successful blockchain transaction.
class Appointment(Base):
    __tablename__ = "appointments"

    # Unique ID for each appointment in our database.
    id = Column(Integer, primary_key=True, index=True)

    # The patient's wallet address — this is their only identity.
    patient_wallet = Column(String, nullable=False)

    # The doctor's wallet address.
    doctor_wallet = Column(String, nullable=False)

    # The transaction ID from the blockchain — links this record to the blockchain.
    blockchain_tx_id = Column(String, nullable=False)

    # The blockchain appointment ID — links to the smart contract appointment.
    blockchain_appointment_id = Column(Integer, nullable=False)

    # Current status — booked, active, completed, cancelled.
    status = Column(String, default="booked")

    # When the appointment is scheduled.
    scheduled_time = Column(DateTime, nullable=False)

    # When this record was created in our database.
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))


# This is the messages table.
# Stores all chat messages between patient and doctor.
class Message(Base):
    __tablename__ = "messages"

    # Unique ID for each message.
    id = Column(Integer, primary_key=True, index=True)

    # Which appointment this message belongs to.
    appointment_id = Column(Integer, ForeignKey("appointments.id"), nullable=False)

    # The wallet address of whoever sent the message.
    # Patient appears as their wallet address — fully anonymous.
    sender_wallet = Column(String, nullable=False)

    # The actual message text — null for voice messages.
    content = Column(String, nullable=True)

    # "text" or "voice".
    media_type = Column(String, default="text", nullable=False)

    # Path to the audio file — only set for voice messages.
    file_url = Column(String, nullable=True)

    # When the message was sent.
    sent_at = Column(DateTime, default=lambda: datetime.now(timezone.utc).replace(tzinfo=None))
