# This file handles all message related endpoints.
# Supports text messages (via WebSocket) and voice messages (via file upload).

import os
import uuid
import shutil
import json

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, UploadFile, File, Form
from sqlalchemy.orm import Session
from database import get_db, SessionLocal
import models
import schemas
from config import UPLOAD_DIR


class ConnectionManager:
    def __init__(self):
        # appointment_id -> list of active WebSocket connections
        self.active: dict[int, list[WebSocket]] = {}

    async def connect(self, appointment_id: int, websocket: WebSocket):
        await websocket.accept()
        self.active.setdefault(appointment_id, []).append(websocket)

    def disconnect(self, appointment_id: int, websocket: WebSocket):
        if appointment_id in self.active:
            self.active[appointment_id].remove(websocket)

    async def broadcast(self, appointment_id: int, message: dict):
        for connection in self.active.get(appointment_id, []):
            await connection.send_text(json.dumps(message))


manager = ConnectionManager()

router = APIRouter(
    prefix="/messages",
    tags=["messages"]
)


def _serialize(msg: models.Message) -> dict:
    return {
        "id": msg.id,
        "appointment_id": msg.appointment_id,
        "sender_wallet": msg.sender_wallet,
        "content": msg.content,
        "media_type": msg.media_type,
        "file_url": msg.file_url,
        "sent_at": msg.sent_at.isoformat() + "Z",
    }


# GET /messages/{appointment_id} — get all messages for an appointment.
@router.get("/{appointment_id}", response_model=list[schemas.MessageResponse])
def get_messages(appointment_id: int, db: Session = Depends(get_db)):

    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    messages = db.query(models.Message).filter(
        models.Message.appointment_id == appointment_id
    ).order_by(models.Message.sent_at).all()

    return messages


# POST /messages — send a text message.
@router.post("/", response_model=schemas.MessageResponse)
def send_message(message: schemas.MessageCreate, db: Session = Depends(get_db)):

    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == message.appointment_id
    ).first()

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if appointment.status != "active":
        raise HTTPException(status_code=400, detail="Can only send messages in active appointments")

    new_message = models.Message(
        appointment_id=message.appointment_id,
        sender_wallet=message.sender_wallet,
        content=message.content,
        media_type="text",
    )

    db.add(new_message)
    db.commit()
    db.refresh(new_message)

    return new_message


# POST /messages/upload-audio — send a voice message.
# Saves the audio file to disk and broadcasts it via WebSocket.
@router.post("/upload-audio", response_model=schemas.MessageResponse)
async def upload_audio(
    appointment_id: int = Form(...),
    sender_wallet: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    appointment = db.query(models.Appointment).filter(
        models.Appointment.id == appointment_id
    ).first()

    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")

    if appointment.status != "active":
        raise HTTPException(status_code=400, detail="Can only send messages in active appointments")

    if not file.content_type or not file.content_type.startswith("audio/"):
        raise HTTPException(status_code=400, detail="File must be an audio file")

    # Save with a unique filename to avoid collisions.
    ext = os.path.splitext(file.filename)[1] if file.filename else ".m4a"
    filename = f"{uuid.uuid4()}{ext}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    with open(file_path, "wb") as f:
        shutil.copyfileobj(file.file, f)

    file_url = f"/uploads/{filename}"

    new_message = models.Message(
        appointment_id=appointment_id,
        sender_wallet=sender_wallet,
        content=None,
        media_type="voice",
        file_url=file_url,
    )

    db.add(new_message)
    db.commit()
    db.refresh(new_message)

    # Broadcast to both participants so they see it in real time.
    await manager.broadcast(appointment_id, _serialize(new_message))

    return new_message


# WS /messages/ws/{appointment_id} — real-time chat channel.
# On connect: sends full message history, then stays open.
# On receive: saves the text message to DB and broadcasts it to both participants.
@router.websocket("/ws/{appointment_id}")
async def chat_websocket(websocket: WebSocket, appointment_id: int):
    db = SessionLocal()
    try:
        appointment = db.query(models.Appointment).filter(
            models.Appointment.id == appointment_id
        ).first()

        if not appointment:
            await websocket.close(code=4004)
            return

        await manager.connect(appointment_id, websocket)

        # Send full message history on connect.
        history = db.query(models.Message).filter(
            models.Message.appointment_id == appointment_id
        ).order_by(models.Message.sent_at).all()

        for msg in history:
            await websocket.send_text(json.dumps(_serialize(msg)))

        # Listen for incoming text messages.
        while True:
            data = await websocket.receive_text()
            payload = json.loads(data)

            db.refresh(appointment)
            if appointment.status != "active":
                await websocket.send_text(json.dumps({"error": "Appointment is not active"}))
                continue

            new_message = models.Message(
                appointment_id=appointment_id,
                sender_wallet=payload["sender_wallet"],
                content=payload["content"],
                media_type="text",
            )
            db.add(new_message)
            db.commit()
            db.refresh(new_message)

            await manager.broadcast(appointment_id, _serialize(new_message))

    except WebSocketDisconnect:
        manager.disconnect(appointment_id, websocket)
    finally:
        db.close()
