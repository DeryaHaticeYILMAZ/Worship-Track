from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
import hashlib

app = Flask(__name__)
CORS(app)

# MySQL bağlantı ayarları
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="021155ys",
    database="worship_db"
)
cursor = conn.cursor()

@app.route('/register', methods=['POST'])
def register():
    name = request.form.get('name')
    email = request.form.get('email')
    password = request.form.get('password')

    print(f"[Flask] Kayıt isteği alındı: name={name}, email={email}")

    # Şifreyi hashleyelim (MD5 - demo için, gerçek projede bcrypt önerilir)
    hashed_password = hashlib.md5(password.encode()).hexdigest()

    try:
        cursor.execute("INSERT INTO users (name, email, password) VALUES (%s, %s, %s)",
                       (name, email, hashed_password))
        conn.commit()
        print("[Flask] Kayıt veritabanına eklendi.")
        return jsonify({"status": "success", "message": "User registered successfully."})
    except mysql.connector.IntegrityError:
        print("[Flask] Email already exists!")
        return jsonify({"status": "error", "message": "This email is already registered."})
    except Exception as e:
        print(f"[Flask] Kayıt sırasında hata: {str(e)}")
        return jsonify({"status": "error", "message": str(e)})

if __name__ == '__main__':
    app.run(port=5000, debug=True)