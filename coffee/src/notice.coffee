goog.provide 'notice'

class Notice
  constructor: (@options = {}) ->
    @stackInfo = @options.stackInfo || (@options.error && TraceKit.computeStackTrace(@options.error))
    @trace = @_parseBacktrace(@stackInfo?.stack)
    @class = @stackInfo?.name
    @message = @stackInfo?.message
    @source = @stackInfo && @_extractSource(@stackInfo.stack)
    @url = document.URL
    @project_root = Honeybadger.configuration.project_root
    @environment = Honeybadger.configuration.environment
    @component = Honeybadger.configuration.component
    @action = Honeybadger.configuration.action

    @context = {}
    for k,v of Honeybadger.context
      @context[k] = v
    if @options.context
      for k,v of @options.context
        @context[k] = v

  toJSON: ->
    JSON.stringify
      notifier:
        name: 'honeybadger.js'
        url: 'https://github.com/honeybadger-io/honeybadger-js'
        version: Honeybadger.version
        language: 'javascript'
      error:
        class: @class
        message: @message
        backtrace: @trace
        source: @source
      request:
        url: @url
        component: @component
        action: @action
        context: @context
        cgi_data: @_cgiData()
      server:
        project_root: @project_root
        environment_name: @environment

  _parseBacktrace: (stack = []) ->
    backtrace = []
    for trace in stack
      continue if trace.url?.match /honeybadger(?:\.min)?\.js/
      backtrace.push
        file: trace.url?.replace(Honeybadger.configuration.project_root, '[PROJECT_ROOT]') || 'unknown',
        number: trace.line,
        method: trace.func
    backtrace

  _extractSource: (stack = []) ->
    source = {}
    for line, i in (stack[0]?.context ? [])
      source[i] = line
    source

  _cgiData: () ->
    data = {}
    for k,v of navigator
      unless typeof v == 'object'
        data[k.split(/(?=[A-Z][a-z]*)/).join('_').toUpperCase()] = v
    data['HTTP_USER_AGENT'] = data['USER_AGENT']
    delete data['USER_AGENT']
    data['HTTP_REFERER'] = document.referrer if document.referrer.match /\S/
    data
