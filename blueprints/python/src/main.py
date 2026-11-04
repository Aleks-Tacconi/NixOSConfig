import logging

from logger import Logger
from logger.handlers import LokiHandler

# Create logger
logging.setLoggerClass(Logger)
logger_instance = logging.getLogger("blueprint")
logger_instance.setLevel(logging.DEBUG)
logger_instance.propagate = False

console_handler = logging.StreamHandler()
logger_instance.addHandler(console_handler)

# Loki handler (non-blocking)
loki_handler = LokiHandler(
    loki_url="http://localhost:3100", labels={"app": "fastapi", "env": "dev"}
)
logger_instance.addHandler(loki_handler)

# Example log
logger_instance.info("test")
