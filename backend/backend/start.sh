#!/bin/bash
export PYTHONPATH=/Users/Kaisar/Library/Python/3.9/lib/python/site-packages:$PYTHONPATH
/Users/Kaisar/Library/Python/3.9/bin/uvicorn main:app --reload --host 0.0.0.0 --port 8000
