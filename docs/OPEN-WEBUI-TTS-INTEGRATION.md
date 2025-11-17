# Open-WebUI Fifth Symphony TTS Integration

Complete guide for integrating fifth-symphony AudioTTS with Open-WebUI for environment-aware voice synthesis.

## Overview

Instead of using Open-WebUI's built-in TTS providers, this integration creates a FastAPI server that exposes fifth-symphony's AudioTTS as an OpenAI-compatible TTS API endpoint.

**Benefits**:
- ✅ Environment-aware voice selection (Albedo v1 on VM, v2 on Main Machine)
- ✅ Full ElevenLabs customization (stability, similarity boost, speed)
- ✅ Consistent audio across all Open-WebUI instances
- ✅ ADHD productivity support via verbal feedback
- ✅ 1Password credential management (already configured)

## Architecture

```
Open-WebUI (Docker Container)
    ↓
TTS API Request: POST /v1/audio/speech
    ↓
Fifth Symphony TTS Server (http://host.docker.internal:5050)
    ↓
AudioTTS Module (fifth-symphony)
    ↓
ElevenLabs API (with auto-selected Albedo voice)
    ↓
MP3 Audio Response → Open-WebUI → User
```

## Installation

### Step 1: Start TTS Server

The TTS server is located at `/internal/repos/fifth-symphony/tts_server.py`

**On Main Machine**:
```bash
cd ~/git/internal/repos/fifth-symphony
uv run python tts_server.py
```

**On VM**:
```bash
cd /Volumes/My\ Shared\ Files/git/internal/repos/fifth-symphony
uv run python tts_server.py
```

**Expected Output**:
```
INFO:root:✓ AudioTTS initialized with voice: Sr4DTtH3Kmyd0sUrsL97
INFO:uvicorn:Uvicorn running on http://0.0.0.0:5050 (Press CTRL+C to quit)
```

### Step 2: Configure Open-WebUI

1. Open Open-WebUI in browser
2. Navigate to **Settings** → **Audio**
3. Under **Text-to-Speech**, configure:
   - **TTS Engine**: `OpenAI`
   - **API Base URL**: `http://host.docker.internal:5050/v1/audio/speech`
   - **API Key**: Leave blank (not required for local server)
   - **Voice**: `albedo` (value doesn't matter - auto-selected)
   - **Model**: `tts-1` (value doesn't matter - uses AudioTTS)

### Step 3: Test

1. Send a message in Open-WebUI
2. Click the speaker icon to play TTS
3. Should hear Albedo voice (v1 or v2 based on environment)

## Running TTS Server Persistently

### Option A: systemd Service (Linux/VM)

Create `/etc/systemd/system/fifth-symphony-tts.service`:

```ini
[Unit]
Description=Fifth Symphony TTS API Server
After=network.target

[Service]
Type=simple
User=fweirvm
WorkingDirectory=/path/to/uservm/git/internal/repos/fifth-symphony
ExecStart=/usr/bin/uv run python tts_server.py
Restart=always
RestartSec=10
Environment="ELEVENLABS_API_KEY=<from-1password>"

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl enable fifth-symphony-tts
sudo systemctl start fifth-symphony-tts
sudo systemctl status fifth-symphony-tts
```

### Option B: launchd Service (macOS/Main Machine)

Create `~/Library/LaunchAgents/com.fweir.fifth-symphony-tts.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.fweir.fifth-symphony-tts</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/uv</string>
        <string>run</string>
        <string>python</string>
        <string>tts_server.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/path/to/fifth-symphony</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/path/to/logs/fifth-symphony-tts.log</string>
    <key>StandardErrorPath</key>
    <string>/path/to/logs/fifth-symphony-tts.error.log</string>
</dict>
</plist>
```

Then:
```bash
launchctl load ~/Library/LaunchAgents/com.fweir.fifth-symphony-tts.plist
launchctl start com.fweir.fifth-symphony-tts
```

### Option C: Docker Container (Future)

Could containerize TTS server for deployment alongside carian-observatory services.

## Voice Selection Logic

The AudioTTS module automatically selects the appropriate Albedo voice based on environment:

**Main Machine** (`$GIT_ROOT`):
- Voice ID: `Sr4DTtH3Kmyd0sUrsL97` (Albedo v2)
- Subtle, primary voice

**VM** (`/path/to/uservm/git` or `/path/to/uservm`):
- Voice ID: `ugizIPhoOxPnNuPGr01h` (Albedo v1)
- Distinct voice for environment awareness

No configuration required - detection happens automatically.

## API Endpoints

### Health Check
```bash
curl http://localhost:5050/health
```

Response:
```json
{
  "status": "healthy",
  "tts_available": true,
  "voice_id": "Sr4DTtH3Kmyd0sUrsL97"
}
```

### Generate Speech (OpenAI-compatible)
```bash
curl -X POST http://localhost:5050/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tts-1",
    "input": "Hello from Albedo",
    "voice": "albedo",
    "speed": 0.85
  }' \
  --output speech.mp3
```

### API Info
```bash
curl http://localhost:5050/
```

Response:
```json
{
  "name": "Fifth Symphony TTS API",
  "version": "1.0.0",
  "description": "OpenAI-compatible TTS using fifth-symphony AudioTTS",
  "endpoints": {
    "health": "/health",
    "tts": "/v1/audio/speech (POST)"
  },
  "voice": {
    "id": "Sr4DTtH3Kmyd0sUrsL97",
    "name": "Albedo (auto-selected based on environment)"
  }
}
```

## Troubleshooting

### TTS Server Won't Start

**Error**: `AudioTTS initialization failed`
- **Check**: ElevenLabs API key configured in environment or 1Password
- **Fix**: Set `ELEVENLABS_API_KEY` environment variable

**Error**: `Address already in use (port 5050)`
- **Check**: Another service using port 5050
- **Fix**: Change port in `tts_server.py` or stop conflicting service

### Open-WebUI Can't Reach TTS Server

**Error**: `Connection refused` or `Network error`
- **Check**: TTS server is running (`curl http://localhost:5050/health`)
- **Check**: Using `host.docker.internal` not `localhost` in Open-WebUI config
- **Fix**: Ensure Docker can reach host network

### Wrong Voice Being Used

**Check**: Environment detection logic
```python
# In tts_server.py - AudioTTS auto-detects environment
tts = AudioTTS()  # Automatically selects voice based on path
print(tts.voice_id)  # Should show Sr4DTtH3Kmyd0sUrsL97 or ugizIPhoOxPnNuPGr01h
```

### Audio Not Playing in Open-WebUI

1. **Check browser console** for errors
2. **Test API directly**: `curl http://localhost:5050/v1/audio/speech` with test request
3. **Verify Open-WebUI TTS settings** point to correct URL
4. **Check audio file permissions** (should be readable by browser)

## Security Notes

- TTS server runs on `0.0.0.0:5050` (accessible from Docker)
- No authentication required (local-only service)
- ElevenLabs API key secured via 1Password/environment
- Consider firewall rules if exposing beyond localhost

## Future Enhancements

- [ ] Add authentication for TTS API
- [ ] Docker containerization of TTS server
- [ ] Multiple voice support (beyond Albedo v1/v2)
- [ ] Speech speed customization via API
- [ ] Caching frequently-used phrases
- [ ] Metrics and monitoring (Prometheus/Grafana)

---

**Status**: Ready for deployment
**Dependencies**: fifth-symphony, fastapi, uvicorn, elevenlabs
**Estimated Setup Time**: 10-15 minutes
