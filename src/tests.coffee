


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
  test @, 'timeout': 2500

# #-----------------------------------------------------------------------------------------------------------
# f = ->
# f.apply TC = {}


#===========================================================================================================
# TESTS
#-----------------------------------------------------------------------------------------------------------
@[ "create memo object (1)" ] = ( T, done ) ->
  step ( resume ) =>
    probes_and_matchers = [
      [{},{"~isa":"FORGETMENOT/memo","globs":[],"path":null,"files":{},"cache":{}}]
      [{},{"~isa":"FORGETMENOT/memo","globs":[],"path":null,"files":{},"cache":{}}]
      [{"ref":"test-data"},{"~isa":"FORGETMENOT/memo","globs":[],"path":"test-data/memo-1.json","files":{},"cache":{}}]
      [{"globs":"src/*"},{"~isa":"FORGETMENOT/memo","globs":["src/*"],"path":null,"files":{},"cache":{}}]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = yield FMN.create_memo probe, resume
      debug '22022', JSON.stringify [ probe, result, ]
      T.eq result, matcher
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "create memo object (2)" ] = ( T, done ) ->
  step ( resume ) =>
    settings    = { globs: 'src/*', }
    result      = yield FMN.create_memo settings, resume
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
@[ "create memo object with path" ] = ( T, done ) ->
  step ( resume ) =>
    settings    = { globs: 'src/*', ref: 'test-data/example-1.json' }
    result      = yield FMN.create_memo settings, resume
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
    settings    = { ref: 'test-data', name: 'cache-example.json' }
    fmn         = yield FMN.create_memo settings, resume
    FMN.set fmn, 'bar', 42
    debug '90988', fmn
    debug '22230', FMN.get fmn, 'bar'
    done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "new memo with reference point" ] = ( T, done ) ->
  settings = { ref: 'cwd', }
  settings = { ref: 'memo', }
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "warn about missing features" ] = ( T, done ) ->
  warn "reference point for globs: memo location"
  warn "cache absolute paths; make sure memo is skipped when doing checksums"
  # `path` is reference point
  # `path` must be path to directory
  # `path` defaults to CWD
  done()


############################################################################################################
unless module.parent?
  include = [
    "create memo object (1)"
    # "create memo object (2)"
    # "create memo object with path"
    # "set and get to and from cache"
    # "warn about missing features"
    ]
  @_prune()
  @_main()

  # CND.run => @[ "create memo object (1)" ] { eq: ( -> ), ok: ( -> ), }, ->



# debug timestamp = @DATE.as_timestamp new Date 2001, 0, 1, 12, 0, 0, 0
# debug @DATE.from_timestamp timestamp
# date = new Date()
# debug d date







