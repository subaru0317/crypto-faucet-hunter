import speech_recognition as sr

sample_audio = sr.AudioFile("audio.wav")

r = sr.Recognizer()
with sample_audio as source:
    audio = r.record(source)
key = r.recognize_google(audio)
print(key)