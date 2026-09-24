"""Local SuperBook image-to-video engine.

Backend: Wan2.1 VACE 1.3B via Diffusers.

The engine uses the SuperBook scene image as a reference image and the
scene's semantic motion description as the prompt. This is the actual
VACE reference-to-video path, not a still-frame slideshow.
"""

from __future__ import annotations

from pathlib import Path
import os

import torch
from PIL import Image
from diffusers import AutoencoderKLWan, WanVACEPipeline
from diffusers.schedulers.scheduling_unipc_multistep import UniPCMultistepScheduler
from diffusers.utils import export_to_video

MODEL_ID = os.getenv("SUPERBOOK_VIDEO_MODEL", "Wan-AI/Wan2.1-VACE-1.3B-diffusers")
DEFAULT_FPS = 16
DEFAULT_FRAMES = 81
DEFAULT_STEPS = 20
DEFAULT_HEIGHT = 480
DEFAULT_WIDTH = 832


class LocalVideoEngine:
    def __init__(self, model_id: str = MODEL_ID) -> None:
        self.model_id = model_id
        self.pipe: WanVACEPipeline | None = None

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

        if self.device != "cuda":
            raise RuntimeError(
                "No CUDA GPU is available. Wan2.1 VACE video generation "
                "requires a practical GPU backend."
            )

        vae = AutoencoderKLWan.from_pretrained(
            self.model_id,
            subfolder="vae",
            torch_dtype=torch.float32,
        )
        self.pipe = WanVACEPipeline.from_pretrained(
            self.model_id,
            vae=vae,
            torch_dtype=torch.bfloat16,
        )
        self.pipe.scheduler = UniPCMultistepScheduler.from_config(
            self.pipe.scheduler.config,
            flow_shift=3.0,
        )
        self.pipe.enable_model_cpu_offload()
        self.pipe.vae.enable_tiling()

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
        height: int = DEFAULT_HEIGHT,
        width: int = DEFAULT_WIDTH,
    ) -> Path:
        self._load()

        image = Image.open(image_path).convert("RGB")
        generator = torch.Generator(device="cuda").manual_seed(seed)

        negative_prompt = (
            "static image, frozen pose, scene change, camera cut, "
            "new characters, duplicated characters, extra limbs, "
            "deformed hands, deformed face, morphing, text, subtitles, "
            "watermark, low quality, blurry, flicker"
        )

        result = self.pipe(
            prompt=prompt,
            negative_prompt=negative_prompt,
            reference_images=[image],
            height=height,
            width=width,
            num_frames=num_frames,
            num_inference_steps=num_inference_steps,
            guidance_scale=5.0,
            generator=generator,
        )

        frames = result.frames[0]
        output = Path(output_path)
        output.parent.mkdir(parents=True, exist_ok=True)
        export_to_video(frames, str(output), fps=fps)
        return output
