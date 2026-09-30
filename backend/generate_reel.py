"""
Generate AI Voiceover & Assemble Video Reel for JOB SeArCh
"""

import asyncio
import os
import subprocess
import edge_tts
import imageio_ffmpeg

VOICE = "en-US-ChristopherNeural"
NARRATION_TEXT = (
    "Welcome to JOB SeArCh — the autonomous AI career discovery and intelligent matching engine. "
    "Traditional job boards are broken — flooded with generic spam, opaque ATS keyword filters, and repetitive forms. "
    "JOB SeArCh re-imagines career hunting from the ground up with deep semantic vector search, an adaptive reinforcement learning loop, and a Zero-Knowledge local credential vault. "
    "Our reactive Flutter Web dashboard delivers a bespoke Marine Glassmorphism Bento Grid, presenting real-time market salary telemetry and competitive candidate percentile metrics. "
    "Instead of relying on simple keyword matching, candidate profiles and live job listings are projected into a shared 768-dimensional latent space using FastEmbed and pgvector HNSW indexing. "
    "With our interactive 2D Latent Space Constellation, you can explore celestial job clusters, examine cosine similarity fit, and generate instant recruiter outreach pitches. "
    "Need to source roles from anywhere? Our multi-source ATS scraper extracts listings from Greenhouse, Lever, Ashby, or any custom careers URL in seconds. "
    "And when it comes to privacy, our Zero-Knowledge Credential Vault keeps your passwords strictly in browser RAM. No passwords ever touch the server, giving you one-click auto-fill application power. "
    "JOB SeArCh: Autonomous, intelligent, and private career discovery for modern engineers."
)

OUTPUT_AUDIO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs", "assets", "voiceover_demo.mp3"))
OUTPUT_VIDEO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs", "assets", "demo_reel.mp4"))
IMG_HERO = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs", "assets", "hero_dashboard.jpg"))
IMG_VAULT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs", "assets", "vault_scraper.jpg"))


async def generate_voiceover():
    print(f"Generating AI voiceover with voice: {VOICE}...")
    communicate = edge_tts.Communicate(NARRATION_TEXT, VOICE)
    await communicate.save(OUTPUT_AUDIO)
    print(f"Voiceover saved to {OUTPUT_AUDIO}")


def get_audio_duration(audio_path, ffmpeg_exe):
    # Use ffmpeg to detect duration
    cmd = [ffmpeg_exe, "-i", audio_path]
    res = subprocess.run(cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    for line in res.stderr.splitlines():
        if "Duration:" in line:
            # Duration: 00:01:05.40, start: ...
            part = line.split("Duration:")[1].split(",")[0].strip()
            h, m, s = part.split(":")
            total_seconds = float(h) * 3600 + float(m) * 60 + float(s)
            return total_seconds
    return 65.0  # fallback


def assemble_video_reel():
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
    duration = get_audio_duration(OUTPUT_AUDIO, ffmpeg_exe)
    print(f"Audio duration: {duration:.2f} seconds")

    half_duration = duration / 2.0

    # Create high-quality video using ffmpeg:
    # First half shows IMG_HERO with gentle zoom
    # Second half shows IMG_VAULT with smooth crossfade
    print("Muxing visuals and AI voiceover into high-definition demo_reel.mp4...")
    
    # Filter complex to display image 1 then image 2, sized 1920x1080
    filter_complex = (
        f"[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,trim=duration={half_duration}[v0]; "
        f"[1:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1,trim=duration={half_duration + 1}[v1]; "
        f"[v0][v1]concat=n=2:v=1:a=0[v]"
    )

    cmd = [
        ffmpeg_exe,
        "-y",
        "-loop", "1", "-t", str(half_duration), "-i", IMG_HERO,
        "-loop", "1", "-t", str(half_duration + 1), "-i", IMG_VAULT,
        "-i", OUTPUT_AUDIO,
        "-filter_complex", filter_complex,
        "-map", "[v]",
        "-map", "2:a",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-c:a", "aac",
        "-b:a", "192k",
        "-shortest",
        OUTPUT_VIDEO,
    ]

    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print("Error during video assembly:")
        print(res.stderr)
        raise RuntimeError(f"FFmpeg error: {res.stderr[-500:]}")

    print(f"Demo reel successfully assembled at: {OUTPUT_VIDEO}")
    print(f"File size: {os.path.getsize(OUTPUT_VIDEO) / (1024 * 1024):.2f} MB")


async def main():
    await generate_voiceover()
    assemble_video_reel()


if __name__ == "__main__":
    asyncio.run(main())
