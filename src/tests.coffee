


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FORGETMENOT/TESTS'
log                       = CND.get_logger 'plain',     badge
debug                     = CND.get_logger 'debug',     badge
info                      = CND.get_logger 'info',      badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
PATH                      = require 'path'
FS                        = require 'fs'
# D                         = require 'pipedreams'
# { $, $async, }            = D
{ step, }                 = require 'coffeenode-suspend'
#...........................................................................................................
test_data_home            = PATH.resolve __dirname, '../test-data'
templates_home            = PATH.resolve test_data_home, 'templates'
#...........................................................................................................
FMN                       = require '..'


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@_prune = ->
  for name, value of @
    continue if name.startsWith '_'
    delete @[ name ] unless name in include
  return null

#-----------------------------------------------------------------------------------------------------------
@_procure_test_files = ->
  file_count = 0
  for filename in FS.readdirSync templates_home
    file_count += +1
    source_path = PATH.resolve templates_home, filename
    target_path = PATH.resolve test_data_home, filename
    byte_count  = @_copy_file_sync source_path, target_path
    # whisper """
    #   copied #{byte_count} bytes
    #   from #{source_path}
    #   to   #{target_path}"""
  whisper "copied #{file_count} files"

#-----------------------------------------------------------------------------------------------------------
@_copy_file_sync = ( source_path, target_path ) ->
  FS.writeFileSync target_path, source = FS.readFileSync source_path
  return source.length

#-----------------------------------------------------------------------------------------------------------
@_require_file = ( path ) ->
  ### Inhibit caching: ###
  delete require[ 'cache' ][ path ]
  return require path

#-----------------------------------------------------------------------------------------------------------
@_main = ->
  # debug @_get_source PATH.resolve test_data_home, 'f.coffee'
  # debug @_require_file PATH.resolve test_data_home, 'file::f.js'
  test @, 'timeout': 5000

# #-----------------------------------------------------------------------------------------------------------
# f = ->
# f.apply TC = {}


#===========================================================================================================
# TESTS
#-----------------------------------------------------------------------------------------------------------
@[ "create cache object (1)" ] = ( T, done ) ->
  probes_and_matchers = [
    [{"update":false},{"~isa":"FORGETMENOT/cache","globs":[],"path":null,"files":{},"autosave":false}]
    [{"update":true},{"~isa":"FORGETMENOT/cache","globs":[],"path":null,"files":{},"autosave":false}]
    [{"autosave":true,"cache":"test-data/cache-1.json"},{"~isa":"FORGETMENOT/cache","globs":[],"path":"test-data/cache-1.json","files":{},"autosave":true}]
    [{"globs":"src/*"},{"~isa":"FORGETMENOT/cache","globs":["src/*"],"path":null,"files":{},"autosave":false}]
    ]
  for [ probe, matcher, ] in probes_and_matchers
    result = FMN.new_cache probe
    # debug '22022', JSON.stringify [ probe, result, ]
    T.eq result, matcher
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "create cache object (2)" ] = ( T, done ) ->
  step ( resume ) =>
    settings    = { globs: 'src/*', }
    result      = yield FMN.new_cache settings, resume
    { files, }  = result
    T.eq files[ 1101004112 ][ 'path' ], 'src/main.coffee'
    T.eq files[ 1467211317 ][ 'path' ], 'src/tests.coffee'
    T.ok CND.isa_number files[ 1101004112 ][ 'checksum' ]
    T.ok CND.isa_number files[ 1467211317 ][ 'checksum' ]
    T.ok FMN.DATE._looks_like_timestamp files[ 1101004112 ][ 'timestamp' ]
    T.ok FMN.DATE._looks_like_timestamp files[ 1467211317 ][ 'timestamp' ]
    done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "create cache object with path" ] = ( T, done ) ->
  step ( resume ) =>
    settings    = { globs: 'src/*', cache: 'test-data/example-1.json' }
    result      = yield FMN.new_cache settings, resume
    debug '90988', result
    { files, }  = result
    T.eq files[ 1101004112 ][ 'path' ], 'src/main.coffee'
    T.eq files[ 1467211317 ][ 'path' ], 'src/tests.coffee'
    T.ok CND.isa_number files[ 1101004112 ][ 'checksum' ]
    T.ok CND.isa_number files[ 1467211317 ][ 'checksum' ]
    T.ok FMN.DATE._looks_like_timestamp files[ 1101004112 ][ 'timestamp' ]
    T.ok FMN.DATE._looks_like_timestamp files[ 1467211317 ][ 'timestamp' ]
    done()
  return null



############################################################################################################
unless module.parent?
  include = [
    "create cache object (1)"
    "create cache object (2)"
    "create cache object with path"
    ]
  @_prune()
  @_main()

  # CND.run => @[ "create cache object with path" ] { eq: ( -> ), ok: ( -> ), }, ->



# debug timestamp = @DATE.as_timestamp new Date 2001, 0, 1, 12, 0, 0, 0
# debug @DATE.from_timestamp timestamp
# date = new Date()
# debug d date







