"""HTTP wrapper for the SuperBook local Wan VACE video engine."""

from __future__ import annotations

import tempfile
from pathlib import Path
import uuid

from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import FileResponse, JSONResponse

from engine import LocalVideoEngine

app = FastAPI(title="SuperBook Local Video Engine")
engine = LocalVideoEngine()
OUTPUT_DIR = Path(tempfile.gettempdir()) / "superbook-video"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


@app.get("/health")
def health() -> dict:
    return {
        "ok": True,
        "engine": "wan2.1-vace-1.3b",
        "model": engine.model_id,
        "device": engine.device,
    }


@app.post("/video")
async def video(
    image: UploadFile = File(...),
    prompt: str = Form(...),
    num_frames: int = Form(81),
    num_inference_steps: int = Form(20),
    seed: int = Form(42),
) -> FileResponse | JSONResponse:
    suffix = Path(image.filename or "scene.png").suffix or ".png"
    image_path = OUTPUT_DIR / f"input-{uuid.uuid4().hex}{suffix}"
    output_path = OUTPUT_DIR / f"scene-{uuid.uuid4().hex}.mp4"

    image_path.write_bytes(await image.read())

    try:
        engine.generate(
            image_path,
            prompt,
            output_path,
            num_frames=max(17, min(num_frames, 81)),
            num_inference_steps=max(4, min(num_inference_steps, 30)),
            seed=seed,
        )
    except Exception as error:
        return JSONResponse(
            status_code=500,
            content={
                "error": "Video generation failed.",
                "detail": str(error),
            },
        )

    return FileResponse(output_path, media_type="video/mp4", filename=output_path.name)
