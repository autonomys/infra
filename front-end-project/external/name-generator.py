import json, time

fixed_name = "dev-front-end"
result = {
  "name": f"{fixed_name}-{int(time.time())}",
}

print(json.dumps(result))