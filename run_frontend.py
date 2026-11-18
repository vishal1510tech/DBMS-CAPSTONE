#!/usr/bin/env python3
"""
Convenience launcher to run the ILDRMS Interactive Frontend & Schema Explorer
Usage:
    python run_frontend.py
"""
import sys
import os

# Add workspace directory to python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.server import run_server

if __name__ == "__main__":
    run_server()
