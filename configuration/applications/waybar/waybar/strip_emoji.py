#!/usr/bin/env python3

import sys
import json
import regex

def strip(v):
    if isinstance(v, str):
        return regex.sub(r"\p{Extended_Pictographic}", "", v)
    if isinstance(v, list):
        return [strip(x) for x in v]
    if isinstance(v, dict):
        return {k: strip(x) for k, x in v.items()}
    return v

data = json.load(sys.stdin)
json.dump(strip(data), sys.stdout)
