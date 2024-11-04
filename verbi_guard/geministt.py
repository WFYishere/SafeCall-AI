import google.generativeai as genai
import os
os.environ["API_KEY"] = "AIzaSyCpOsksMlrXhUMkBAHehVmVVP4qjBG9RqM"

genai.configure(api_key=os.environ["API_KEY"])

# Initialize a Gemini model appropriate for your use case.
model = genai.GenerativeModel('models/gemini-1.5-flash')

# Upload the file. The file name is temporary here.
audio_file = genai.upload_file(path='test.mp3')

# Create the prompt.
prompt = "Generate a transcript of the speech."

# Pass the prompt and the audio file to Gemini.
response = model.generate_content([prompt, audio_file])

# Print the response.
print(response.text)

# Delete an uploaded file to avoid exceed storage limit
genai.delete_file(audio_file.name)
print(f'Deleted file {audio_file.uri}')