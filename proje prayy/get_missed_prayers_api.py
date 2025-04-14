from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector

app = Flask(__name__)
CORS(app)

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="021155ys",
    database="worship_db"
)
cursor = conn.cursor(dictionary=True)

@app.route('/missed_prayers', methods=['GET', 'POST'])
def missed_prayers():
    if request.method == 'GET':
        email = request.args.get('email')
        try:
            cursor.execute("""
                SELECT prayer_name, date 
                FROM missed_prayers 
                WHERE email = %s AND completed = FALSE
                ORDER BY date DESC
            """, (email,))
            results = cursor.fetchall()
            return jsonify({"missed_prayers": results})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)})

    elif request.method == 'POST':
        email = request.form.get('email')
        prayer_name = request.form.get('prayer_name')
        date = request.form.get('date')

        print("--- Gelen Veri ---")
        print("email:", email)
        print("prayer:", prayer_name)
        print("date:", date)

        try:
            cursor.execute("""
                UPDATE missed_prayers 
                SET completed = TRUE 
                WHERE email = %s AND prayer_name = %s AND date = %s
            """, (email, prayer_name, date))
            conn.commit()
            rows = cursor.rowcount
            print(f"{rows} row(s) updated.")
            return jsonify({"status": "success", "message": "Marked as completed."})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)})

if __name__ == '__main__':
    app.run(port=5000, debug=True)