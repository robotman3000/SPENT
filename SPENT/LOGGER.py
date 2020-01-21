import logging
#%(relativeCreated)6d _
#%(processName)-10s
#%(asctime)s

def initLogger(level=logging.DEBUG, format='%(threadName)s - %(levelname)s[%(name)s] @ %(module)s.%(funcName)s: %(message)s'):
    logging.basicConfig(level=level, format=format)

def getLogger(name):
    return logging.getLogger(name)