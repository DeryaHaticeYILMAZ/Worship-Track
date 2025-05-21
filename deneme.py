from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime
import hashlib

app = Flask(__name__)
CORS(app)

print(">>> MySQL'e bağlanmaya çalışılıyor...")

try:
    conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database="worship_db",
    use_pure=True
)

    cursor = conn.cursor(dictionary=True)
    print(">>> MySQL bağlantısı başarılı.")
except Exception as e:
    print(">>> MySQL bağlantı hatası:", e)

print(">>> Flask çalıştırılıyor...")

if __name__ == '__main__':
    app.run(port=5000, debug=True)
