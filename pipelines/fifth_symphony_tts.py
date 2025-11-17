"""
title: Fifth Symphony Audio TTS Pipeline
author: Master (fweir)
version: 1.0.0
license: MIT
requirements: elevenlabs, pathlib
description: Integrates fifth-symphony AudioTTS modules for environment-aware voice synthesis
"""

from typing import Optional, Dict, Any
import sys
import os
from pathlib import Path

class Pipeline:
    """
    Fifth Symphony TTS Pipeline for Open-WebUI

    Provides environment-aware audio generation using fifth-symphony AudioTTS modules.
    Automatically selects Albedo v1 (VM) or Albedo v2 (Main Machine) voice based on environment.
    """

    def __init__(self):
        self.name = "Fifth Symphony TTS"
        self.tts = None
        self.initialized = False

    async def on_startup(self):
        """Initialize AudioTTS on pipeline startup"""
        try:
            # Determine fifth-symphony path from environment or common locations
            fifth_symphony_env = os.getenv('FIFTH_SYMPHONY_PATH')

            if fifth_symphony_env:
                fifth_symphony_path = Path(fifth_symphony_env)
            else:
                # Try common relative locations from git root
                git_root = Path(os.getenv('GIT_ROOT', Path.home() / 'git'))
                possible_paths = [
                    git_root / 'internal' / 'repos' / 'fifth-symphony',
                    git_root / 'fifth-symphony',
                ]

                fifth_symphony_path = None
                for path in possible_paths:
                    if path.exists():
                        fifth_symphony_path = path
                        break

                if not fifth_symphony_path:
                    print("✗ fifth-symphony not found. Set FIFTH_SYMPHONY_PATH env var or ensure it's in standard git location")
                    return

            # Add to Python path
            sys.path.insert(0, str(fifth_symphony_path))

            # Import AudioTTS
            from modules.audio_tts import AudioTTS, AudioTTSError

            self.tts = AudioTTS()
            self.initialized = True

            print(f"✓ Fifth Symphony TTS initialized")
            print(f"✓ Voice: {self.tts.voice_id}")
            print(f"✓ Environment: {'VM' if 'Volumes' in str(fifth_symphony_path) else 'Main Machine'}")

        except ImportError as e:
            print(f"✗ Failed to import AudioTTS: {e}")
            print(f"✗ Ensure fifth-symphony modules are accessible")
        except Exception as e:
            print(f"✗ Fifth Symphony TTS initialization failed: {e}")
            self.tts = None

    async def on_shutdown(self):
        """Cleanup on pipeline shutdown"""
        self.tts = None
        self.initialized = False

    async def inlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """
        Process incoming user message (before LLM)
        Currently pass-through - could add pre-processing later
        """
        return body

    async def outlet(self, body: dict, user: Optional[dict] = None) -> dict:
        """
        Process outgoing LLM response (before user)

        NOTE: This is a template for future TTS integration.
        Open-WebUI's TTS is configured via Settings > Audio, not pipelines.

        This pipeline demonstrates the integration pattern but won't
        directly provide audio. For full TTS integration, see:
        - Option 1: Configure TTS endpoint in Open-WebUI settings
        - Option 2: Create FastAPI server mimicking OpenAI TTS API
        """
        if not self.initialized:
            return body

        # Log that we're ready for TTS (actual TTS handled by Open-WebUI TTS settings)
        messages = body.get("messages", [])
        if messages:
            last_message = messages[-1]
            content = last_message.get("content", "")
            if content:
                print(f"🎵 Fifth Symphony TTS ready for: {content[:50]}...")

        return body
