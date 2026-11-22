# Server nhận SOS từ ESP32: lưu ảnh + ghi âm, báo người thân qua Telegram.
# pip install fastapi uvicorn python-multipart requests
# Chạy: TG_TOKEN=... TG_CHAT=... uvicorn server:app --host 0.0.0.0 --port 8000
import os, time, requests
from fastapi import FastAPI, File, Form, UploadFile

app = FastAPI()
TG = f"https://api.telegram.org/bot{os.environ.get('TG_TOKEN', '')}"
CHAT = os.environ.get("TG_CHAT", "")
os.makedirs("events", exist_ok=True)

@app.post("/sos")
async def sos(reason: str = Form(...), photo: UploadFile = File(...), voice: UploadFile = File(...)):
    ts = time.strftime("%Y%m%d-%H%M%S")
    jpg, wav = await photo.read(), await voice.read()
    open(f"events/{ts}.jpg", "wb").write(jpg)
    open(f"events/{ts}.wav", "wb").write(wav)
    if CHAT:
        msg = "🚨 SOS: bấm nút" if reason == "button" else "🚨 Phát hiện té ngã"
        requests.post(f"{TG}/sendPhoto", data={"chat_id": CHAT, "caption": f"{msg} lúc {ts}"}, files={"photo": jpg}, timeout=15)
        requests.post(f"{TG}/sendAudio", data={"chat_id": CHAT}, files={"audio": (f"{ts}.wav", wav)}, timeout=15)
    return {"ok": True}
