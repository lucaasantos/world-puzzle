"""Offline provider extension contract. The production path is CodexJobs.

A synchronous Python method cannot call Codex tools. The agent uses image_gen
and imports its output; this protocol is retained for local adapters and tests.
"""
from dataclasses import dataclass
from typing import Protocol


@dataclass
class GenerationResult:
    image: bytes
    usage: dict | None = None


class ImageGenerationProvider(Protocol):
    name: str
    model: str

    def generate(self, prompt: str, settings: dict) -> GenerationResult: ...
