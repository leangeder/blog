from blog import blog

if __name__ == '__main__':
    use_debugger = app.config.from_envvar('DEBUG')
    if use_debugger:
        app.logger.debug('Debug Mode Activate')
    try:
        app.run(use_debugger=use_debugger, debug=app.debug,
        use_reloader=use_debugger)
    except Exception as error:
        app.logger.debug(error)
