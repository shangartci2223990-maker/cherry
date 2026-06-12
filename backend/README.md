mkdir anonymous

# 1. Delete the old venv
Remove-Item -Recurse -Force venv

# 2. Create a new one
python -m venv venv

# 3. Activate it
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\venv\Scripts\Activate.ps1

# 4. Reinstall dependencies
pip install fastapi "uvicorn[standard]" sqlalchemy psycopg2-binary python-dotenv python-multipart

# 5. Run the server
uvicorn main:app --reload

http://127.0.0.1:8000/
http://127.0.0.1:8000/docs
