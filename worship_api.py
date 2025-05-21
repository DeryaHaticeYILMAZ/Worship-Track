from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
from datetime import datetime
import hashlib
 
app = Flask(__name__)
CORS(app)

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Berat184321",
    database="worship_db",
    use_pure=True
)
cursor = conn.cursor(dictionary=True)

# ---------------------------------------------
# Kullanıcı Kaydı (Register)
# ---------------------------------------------
@app.route('/register', methods=['POST'])
def register():
    name = request.form.get('name')
    email = request.form.get('email')
    password = request.form.get('password')
    hashed_password = hashlib.md5(password.encode()).hexdigest()
    try:
        cursor.execute("INSERT INTO users (name, email, password) VALUES (%s, %s, %s)", (name, email, hashed_password))
        conn.commit()
        return jsonify({"status": "success", "message": "User registered successfully."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ---------------------------------------------
# Kullanıcı Giriş (Login)
# ---------------------------------------------
@app.route('/login', methods=['POST'])
def login():
    email = request.form.get('email')
    password = request.form.get('password')
    hashed_password = hashlib.md5(password.encode()).hexdigest()

    cursor.execute("SELECT * FROM users WHERE email = %s AND password = %s", (email, hashed_password))
    user = cursor.fetchone()

    if user:
        return jsonify({"status": "success", "message": "Login successful."})
    else:
        return jsonify({"status": "error", "message": "Invalid email or password."})

# ---------------------------------------------
# Missed Prayers - GET (listele), POST (ekle)
# ---------------------------------------------
@app.route('/missed_prayers', methods=['GET', 'POST'])
def missed_prayers():
    if request.method == 'GET':
        email = request.args.get('email')
        try:
            cursor.execute("""
                SELECT prayer_name, date, completed 
                FROM missed_prayers 
                WHERE email = %s
                ORDER BY created_at DESC
            """, (email,))
            results = cursor.fetchall()
            return jsonify({"missed_prayers": results or []})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)})

    elif request.method == 'POST':
        email = request.form.get('email')
        prayer_name = request.form.get('prayer_name')
        date = request.form.get('date')

        try:
            cursor.execute("""
                INSERT INTO missed_prayers (email, prayer_name, date) 
                VALUES (%s, %s, %s)
            """, (email, prayer_name, date))
            conn.commit()
            return jsonify({"status": "success", "message": "Missed prayer saved."})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)})

# ---------------------------------------------
# Kaza Namazı Tamamlandı (complete = TRUE)
# ---------------------------------------------
@app.route('/complete_missed_prayer', methods=['POST'])
def complete_missed_prayer():
    email = request.form.get('email')
    prayer_name = request.form.get('prayer_name')
    date = request.form.get('date')

    try:
        cursor.execute("""
            UPDATE missed_prayers 
            SET completed = TRUE 
            WHERE email = %s AND prayer_name = %s AND date = %s
        """, (email, prayer_name, date))
        conn.commit()
        rows = cursor.rowcount
        return jsonify({"status": "success", "message": f"{rows} row(s) updated."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ---------------------------------------------
# Günlük hedefi al
@app.route('/quran_goal', methods=['GET'])
def get_quran_goal():
    email = request.args.get('email')
    try:
        cursor.execute("SELECT daily_goal FROM quran_goal WHERE email = %s", (email,))
        result = cursor.fetchone()
        goal = result['daily_goal'] if result else 1
        return jsonify({"daily_goal": goal})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# Günlük hedef belirle/güncelle
@app.route('/quran_goal', methods=['POST'])
def set_quran_goal():
    email = request.form.get('email')
    daily_goal = request.form.get('daily_goal')
    date = request.form.get('date')

    from datetime import datetime
    try:
        date = datetime.strptime(date, '%Y-%m-%d').date()
    except Exception as e:
        return jsonify({"status": "error", "message": f"Tarih formatı hatalı: {e}"})

    try:
        cursor.execute("SELECT id FROM quran_goal WHERE email = %s AND date = %s", (email, date))
        if cursor.fetchone():
            cursor.execute("UPDATE quran_goal SET daily_goal = %s WHERE email = %s AND date = %s", (daily_goal, email, date))
        else:
            cursor.execute("INSERT INTO quran_goal (email, date, daily_goal) VALUES (%s, %s, %s)", (email, date, daily_goal))
        cursor.execute("SELECT id FROM quran_reading WHERE email = %s AND date = %s", (email, date))
        if not cursor.fetchone():
            cursor.execute("INSERT INTO quran_reading (email, date, pages_read, daily_goal) VALUES (%s, %s, %s, %s)", (email, date, 0, daily_goal))
        conn.commit()
        return jsonify({"status": "success", "message": "Daily goal saved."})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# Okuma kayıtlarını getir
@app.route('/quran_reading', methods=['GET'])
def get_quran_reading():
    email = request.args.get('email')
    try:
        cursor.execute("""
            SELECT qr.date, qr.pages_read, 
                   COALESCE(qg.daily_goal, 1) AS daily_goal
            FROM quran_reading qr
            LEFT JOIN quran_goal qg 
              ON qr.email = qg.email AND qr.date = qg.date
            WHERE qr.email = %s
            ORDER BY qr.date DESC
        """, (email,))
        results = cursor.fetchall()
        return jsonify({"reading_records": results})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# Okunan sayfa ve hedefi kaydet
@app.route('/quran_reading', methods=['POST'])
def set_quran_reading():
    email = request.form.get('email')
    date = request.form.get('date')
    pages_read = request.form.get('pages_read')
    daily_goal = request.form.get('daily_goal')

    from datetime import datetime
    try:
        date = datetime.strptime(date, '%Y-%m-%d').date()
    except Exception as e:
        print(f"Tarih formatı hatalı: {e}, gelen date: {date}")
        return jsonify({"status": "error", "message": f"Tarih formatı hatalı: {e}"})

    try:
        cursor.execute("SELECT id FROM quran_reading WHERE email = %s AND date = %s", (email, date))
        if cursor.fetchone():
            cursor.execute("""
                UPDATE quran_reading 
                SET pages_read = %s, daily_goal = %s 
                WHERE email = %s AND date = %s
            """, (pages_read, daily_goal, email, date))
        else:
            cursor.execute("""
                INSERT INTO quran_reading (email, date, pages_read, daily_goal) 
                VALUES (%s, %s, %s, %s)
            """, (email, date, pages_read, daily_goal))
        conn.commit()
        print(f"Başarıyla kayıt eklendi/güncellendi: {email}, {date}, {pages_read}, {daily_goal}")
        return jsonify({"status": "success", "message": "Quran reading record updated."})
    except Exception as e:
        print(f"Veritabanı hatası: {e}")
        return jsonify({"status": "error", "message": str(e)})

#------------------------------------------
# Fasting - GET (listele), POST (ekle/güncelle)
# ---------------------------------------------
@app.route('/fasting', methods=['GET', 'POST'])
def fasting():
    if request.method == 'GET':
        email = request.args.get('email')
        try:
            cursor.execute("""
                SELECT date, completed 
                FROM fasting 
                WHERE email = %s
                ORDER BY date DESC
            """, (email,))
            results = cursor.fetchall()
            return jsonify({"fasting_days": results or []})
        except Exception as e:
            return jsonify({"fasting_days": [], "status": "error", "message": str(e)})

    elif request.method == 'POST':
        email = request.form.get('email')
        date = request.form.get('date')
        completed = request.form.get('completed', '0')  # '1' or '0'

        try:
            # Eğer kayıt varsa güncelle, yoksa ekle
            cursor.execute("""
                SELECT id FROM fasting WHERE email = %s AND date = %s
            """, (email, date))
            existing = cursor.fetchone()
            if existing:
                cursor.execute("""
                    UPDATE fasting SET completed = %s WHERE email = %s AND date = %s
                """, (completed, email, date))
            else:
                cursor.execute("""
                    INSERT INTO fasting (email, date, completed) VALUES (%s, %s, %s)
                """, (email, date, completed))
            conn.commit()
            return jsonify({"status": "success", "message": "Fasting day saved."})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)})

# ---------------------------------------------
if __name__ == '__main__':
    app.run(port=5000, debug=True)