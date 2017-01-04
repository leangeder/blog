from flask import (Flask, render_template,
                   redirect, url_for, session, request, flash)
from functools import wraps
from flask.ext.sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
# app.config.from_pyfile('conf/test.cfg')

db = SQLAlchemy(app)


def login_required(fn):
    @functools.wraps(fn)
    def inner(*args, **kwargs):
        if session.get('logged_in'):
            return fn(*args, **kwargs)
        return redirect(url_for('login', next=request.path))
    return inner


def cached(timeout=5 * 60, key='view/%s'):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            cache_key = key % request.path
            rv = cache.get(cache_key)
            if rv is not None:
                return rv
            rv = f(*args, **kwargs)
            cache.set(cache_key, rv, timeout=timeout)
            return rv
        return decorated_function
    return decorator


@app.route('/', defaults={'page': 'index'})
@app.route('/home')
# @login_required
def show(page):
    # try:
    return render_template('%s.html' % page)
    # except TemplateNotFound:
        # abort(404)
