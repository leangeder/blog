""" sdfsf """
from flask import Flask


app = Flask(__name__)

""" sdfsf """
@app.route('/')
@app.route('/index')
def index():
    return "Hello, World!"


if __name__ == '__main__':
    app.run()
