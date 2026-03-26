# Activate the virtual environment
if (Test-Path "venv\Scripts\Activate.ps1") {
    . .\venv\Scripts\Activate.ps1
} else {
    Write-Warning "Virtual environment not found. Please run 'python -m venv venv' first."
    exit 1
}

# Run the FastAPI server
# .env is handled automatically by python-dotenv in main.py
Write-Host "Starting KeyNote Chat API..." -ForegroundColor Cyan
uvicorn main:app --reload
