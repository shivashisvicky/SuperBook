"""HTTP wrapper for the SuperBook local Wan VACE video engine."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path
import uuid

from fastapi import FastAPI, File, Form, Request, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse

from engine import LocalVideoEngine

app = FastAPI(title="SuperBook Local Video Engine")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = LocalVideoEngine()
OUTPUT_DIR = Path(tempfile.gettempdir()) / "superbook-video"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
PUBLIC_BASE_URL = os.getenv("SUPERBOOK_LOCAL_PUBLIC_URL", "").rstrip("/")


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
    request: Request,
    image: UploadFile = File(...),
    prompt: str = Form(...),
    num_frames: int = Form(81),
    num_inference_steps: int = Form(20),
    seed: int = Form(42),
) -> dict | JSONResponse:
    suffix = Path(image.filename or "scene.png").suffix or ".png"
    image_path = OUTPUT_DIR / f"input-{uuid.uuid4().hex}{suffix}"
    output_path = OUTPUT_DIR / f"scene-{uuid.uuid4().hex}.mp4"

    image_path.write_bytes(await image.read())

    frames = max(17, min(num_frames, 81))
    steps = max(4, min(num_inference_steps, 30))
    fps = 16

    try:
        engine.generate(
            image_path,
            prompt,
            output_path,
            num_frames=frames,
            num_inference_steps=steps,
            seed=seed,
            fps=fps,
        )
    except Exception as error:
        return JSONResponse(
            status_code=500,
            content={
                "error": "Video generation failed.",
                "detail": str(error),
            },
        )

    base_url = PUBLIC_BASE_URL or str(request.base_url).rstrip("/")
    return {
        "video": {
            "url": f"{base_url}/video/{output_path.name}",
            "durationSeconds": max(1, round(frames / fps)),
        }
    }


@app.get("/video/{filename}")
def video_file(filename: str) -> FileResponse | JSONResponse:
    path = OUTPUT_DIR / filename
    if not path.is_file() or path.parent != OUTPUT_DIR:
        return JSONResponse(
            status_code=404,
            content={"error": "Video not found."},
        )
    return FileResponse(path, media_type="video/mp4", filename=path.name)
