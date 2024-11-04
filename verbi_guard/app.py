from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/process', methods=['POST'])
def process_text():
    data = request.json
    text = data['text']
    # push the data to stt and process, just putting stucture in here yet
    processed_text = f"Processed: {text}" 
    return jsonify({"result": processed_text})

if __name__ == '__main__':
    app.run(debug=True)
