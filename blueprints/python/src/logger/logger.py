import json
import logging
from datetime import datetime, timezone


class JsonFormatter(logging.Formatter):
    def format(self, record):
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
        }
        return json.dumps(log_entry, default=str, ensure_ascii=False)


class Logger(logging.Logger):
    def __init__(self, name, level=logging.NOTSET):
        super().__init__(name, level)

        self.__formatter = JsonFormatter()

    def addHandler(self, hdlr: logging.Handler) -> None:
        super().addHandler(hdlr)
        hdlr.setFormatter(self.__formatter)
