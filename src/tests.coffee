


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
@_looks_like_digest = ( x ) -> ( CND.isa_text x ) and ( /^[0-9a-f]{12}$/ ).test x

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
    [{"update":false},{"~isa":"FORGETMENOT/cache","globs":[],"path":null,"files":{},"autosave":false,"cache":{}}]
    [{"update":true},{"~isa":"FORGETMENOT/cache","globs":[],"path":null,"files":{},"autosave":false,"cache":{}}]
    [{"autosave":true,"cache":"test-data/cache-1.json"},{"~isa":"FORGETMENOT/cache","globs":[],"path":"test-data/cache-1.json","files":{},"autosave":true,"cache":{}}]
    [{"globs":"src/*"},{"~isa":"FORGETMENOT/cache","globs":["src/*"],"path":null,"files":{},"autosave":false,"cache":{}}]
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
    T.eq files[ 'c19a9d5b001f' ][ 'path' ], 'src/main.coffee'
    T.eq files[ '0e4cf94eac84' ][ 'path' ], 'src/tests.coffee'
    T.ok @_looks_like_digest files[ 'c19a9d5b001f' ][ 'checksum' ]
    T.ok @_looks_like_digest files[ '0e4cf94eac84' ][ 'checksum' ]
    T.ok FMN.DATE._looks_like_timestamp files[ 'c19a9d5b001f' ][ 'timestamp' ]
    T.ok FMN.DATE._looks_like_timestamp files[ '0e4cf94eac84' ][ 'timestamp' ]
    done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "create cache object with path" ] = ( T, done ) ->
  step ( resume ) =>
    settings    = { globs: 'src/*', cache: 'test-data/example-1.json' }
    result      = yield FMN.new_cache settings, resume
    debug '90988', result
    { files, }  = result
    T.eq files[ 'c19a9d5b001f' ][ 'path' ], 'src/main.coffee'
    T.eq files[ '0e4cf94eac84' ][ 'path' ], 'src/tests.coffee'
    T.ok @_looks_like_digest files[ 'c19a9d5b001f' ][ 'checksum' ]
    T.ok @_looks_like_digest files[ '0e4cf94eac84' ][ 'checksum' ]
    T.ok FMN.DATE._looks_like_timestamp files[ 'c19a9d5b001f' ][ 'timestamp' ]
    T.ok FMN.DATE._looks_like_timestamp files[ '0e4cf94eac84' ][ 'timestamp' ]
    done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "set and get to and from cache" ] = ( T, done ) ->
  step ( resume ) =>
    settings    = { globs: 'src/*', cache: 'test-data/example-1.json' }
    fmn         = yield FMN.new_cache settings, resume
    FMN.set fmn, 'bar', 42
    debug '90988', fmn
    debug '22230', FMN.get fmn, 'bar'
    done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "warn about missing features" ] = ( T, done ) ->
  warn "implement symbolic reference point for path resolution: CWD or *.json location"
  done()


############################################################################################################
unless module.parent?
  include = [
    "create cache object (1)"
    "create cache object (2)"
    "create cache object with path"
    "set and get to and from cache"
    "warn about missing features"
    ]
  @_prune()
  @_main()

  # CND.run => @[ "create cache object with path" ] { eq: ( -> ), ok: ( -> ), }, ->



# debug timestamp = @DATE.as_timestamp new Date 2001, 0, 1, 12, 0, 0, 0
# debug @DATE.from_timestamp timestamp
# date = new Date()
# debug d date







