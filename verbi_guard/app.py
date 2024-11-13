from flask import Flask, request, jsonify
import os
import google.generativeai as genai
os.environ["API_KEY"] = "AIzaSyCpOsksMlrXhUMkBAHehVmVVP4qjBG9RqM"

genai.configure(api_key=os.environ["API_KEY"])
model = genai.GenerativeModel('models/gemini-1.5-flash')

app = Flask(__name__)

# Ensure the uploads directory exists
UPLOAD_FOLDER = '/storage/emulated/0/Android/data/com.example.verbi_guard/files/'
#os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/process', methods=['POST'])
def process_audio():
    # Check if a file is in the request
    if 'file' not in request.files:
        return jsonify({'error': 'No file provided'}), 400

    # Retrieve the file from the request
    file = request.files['file']

    # Save the file temporarily
    file_path = os.path.join(UPLOAD_FOLDER, file.filename)
    print(file_path)
    file.save(file_path)

    audio_file = genai.upload_file(path=file_path)
    prompt = "convert the text to speech in the audio"
    response = model.generate_content([prompt, audio_file])

    # Here you can add your logic to process the audio file
    # For example, transcribe, analyze, or transform it
    # For demonstration, we just return a placeholder response

    # Example: process and return a success response
    # processed_text = some_audio_processing_function(file_path)
    try:
        processed_text = response.text
    except:
        processed_text = "generation failed"

    # Clean up by deleting the file after processing, if needed
    os.remove(file_path)
    
    genai.delete_file(audio_file.name)
    print(f'Deleted file {audio_file.uri}')
    print("server end finished")

    # Send back the result
    return jsonify({'result': processed_text})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
