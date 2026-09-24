"""Local SuperBook image-to-video engine.

Backend: Wan2.1 VACE 1.3B via Diffusers.
The engine accepts a scene image plus semantic motion text and writes an MP4.

The model is loaded lazily so the HTTP server can start without a GPU.
For a GPU machine, CPU offload is used to reduce peak VRAM.
"""

from __future__ import annotations

from pathlib import Path
import os

import torch
from PIL import Image
from diffusers import DiffusionPipeline
from diffusers.utils import export_to_video, load_image

MODEL_ID = os.getenv("SUPERBOOK_VIDEO_MODEL", "Wan-AI/Wan2.1-VACE-1.3B")
DEFAULT_FPS = 16
DEFAULT_FRAMES = 49
DEFAULT_STEPS = 20


class LocalVideoEngine:
    def __init__(self, model_id: str = MODEL_ID) -> None:
        self.model_id = model_id
        self.pipe = None

    @property
    def device(self) -> str:
        if torch.cuda.is_available():
            return "cuda"
        if getattr(torch.backends, "mps", None) and torch.backends.mps.is_available():
            return "mps"
        return "cpu"

    def _load(self) -> None:
        if self.pipe is not None:
            return
        if self.device == "cpu":
            raise RuntimeError(
                "No GPU backend is available. Wan video generation is not practical "
                "on a normal CPU-only machine. Use a GPU host such as Kaggle for the test."
            )

        dtype = torch.bfloat16 if self.device == "cuda" else torch.float32
        self.pipe = DiffusionPipeline.from_pretrained(
            self.model_id,
            torch_dtype=dtype,
        )

        if self.device == "cuda":
            # Keep large model components on CPU until needed.
            self.pipe.enable_model_cpu_offload()
        else:
            self.pipe.to(self.device)

    def generate(
        self,
        image_path: str | Path,
        prompt: str,
        output_path: str | Path,
        *,
        num_frames: int = DEFAULT_FRAMES,
        num_inference_steps: int = DEFAULT_STEPS,
        seed: int = 42,
        fps: int = DEFAULT_FPS,
    ) -> Path:
        self._load()

        image = load_image(str(image_path)).convert("RGB")
        generator = torch.Generator(device=self.device).manual_seed(seed)

        result = self.pipe(
            image=image,
            prompt=prompt,
            num_frames=num_frames,
            num_inference_steps=num_inference_steps,
            generator=generator,
        )

        frames = result.frames[0]
        output = Path(output_path)
        output.parent.mkdir(parents=True, exist_ok=True)
        export_to_video(frames, str(output), fps=fps)
        return output
