from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        "service": "vulnerable-app",
        "status": "running",
        "description": "Harbor Trivy zafiyet taramasi testi icin ornek uygulama"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
