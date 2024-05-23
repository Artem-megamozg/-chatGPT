#!/usr/bin/env python3

import json

from vosk1 import Model, KaldiRecognizer

model = Model(lang="en-us")
rec = KaldiRecognizer(model, 8000)

res = json.loads(rec.FinalResult())
print(res)
