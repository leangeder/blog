from flask import (Flask, render_template,
                   redirect, url_for, session, request, flash)
from functools import wraps


app = Flask(__name__)
# app.config.from_pyfile('conf/test.cfg')


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


def main():
    use_debugger = app.config.from_envvar('DEBUG')
    if use_debugger:
        app.logger.debug('Debug Mode Activate')
    try:
        app.run(use_debugger=use_debugger, debug=app.debug,
        use_reloader=use_debugger)
    except Exception as error:
        app.logger.debug(error)


if __name__ == '__main__':
    main()
