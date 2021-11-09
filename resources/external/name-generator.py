import json
from datetime import datetime
dt = datetime.now()
today = f'{dt:%d%m%Y}'

result = {
  "name": f"{today}",
}

print(json.dumps(result))
