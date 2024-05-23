import g4f

while True:
    user_input = input("You: ")
    # подгружаем первую часть промта
    f_prom0 = open('promt0.txt', encoding="utf-8")
    f_prom0 = f_prom0.read()
    itog = f_prom0 + user_input
    # настройки для GPT
    response = g4f.ChatCompletion.create(model=g4f.models.gpt_4, provider=g4f.Provider.You, messages=[{"role": "user", "content": itog}])

    print("chatbot: ", response)
