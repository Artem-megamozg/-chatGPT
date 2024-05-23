from flask import Flask, render_template, request, jsonify
import os.path
import tkinter as tk
from tkinter import filedialog
import g4f

app = Flask(__name__)

def ask_gpt(promt: str) -> str:
    # подгружаем первую часть промта
    f_prom0 = open('promt0.txt', encoding="utf-8")
    f_prom0 = f_prom0.read()

    # подгружаем вторую часть промта
    f_history = open('history.txt', encoding="utf-8")
    f_history = f_history.read()

    # подгружаем третью часть промта
    f_prom1 = open('promt1.txt', encoding="utf-8")
    f_prom1 = f_prom1.read()

    # обьеденяем промты и добавляем последний запрос
    itog = f_prom0 + "\n" + f_history + "\n" + f_prom1 + "\n" + promt

    # настройки для GPT
    response = g4f.ChatCompletion.create(model=g4f.models.gpt_4, provider=g4f.Provider.You,
                                         messages=[{"role": "user", "content": itog}])
    return response

    return "Bot: Placeholder response"

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/send_message', methods=['POST'])
def send_message():
    user_input = request.form['user_input']

    if user_input.lower() in ["выход"]:
        return jsonify({'bot_response': 'До свидания!'})

    if "запомни" in user_input.lower():
        with open('history.txt', 'a', encoding="utf-8") as f:
            f.write("\n" + user_input.lower())

    if "забудь" in user_input.lower():
        with open('history.txt', 'w', encoding="utf-8") as f:
            f.write("")

    if user_input.lower() in ["экспорт"]:
        with open('history.txt', 'r', encoding="utf-8") as f:
            chat_history = f.read()
        root = tk.Tk()
        root.title("Выбор директории")
        file_path = filedialog.askdirectory()
        completeName = os.path.join(file_path, "history.txt")
        with open(completeName, "w") as file1:
            file1.write(chat_history)
        return jsonify({'bot_response': f"Файл установки сохранен в: {file_path}"})

    if user_input.lower() in ["импорт"]:
        with open('history.txt', 'w', encoding="utf-8") as f:
            root = tk.Tk()
            root.title("Выбор файла")
            file_path = filedialog.askopenfilename(filetypes=[("Text files", "*.txt")])
            file1 = open(file_path, "r")
            file1 = file1.read()
            f.write(file1)
        return jsonify({'bot_response': f"Файл установки сохранен в: {file_path}"})

    response = ask_gpt(user_input)
    return jsonify({'bot_response': response})

if __name__ == "__main__":
    app.run(debug=True)
