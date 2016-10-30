


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
      [{},{"~isa":"FORGETMENOT/memo","globs":[],"ref":".","name":".forgetmenot-memo.json","autosave":false,"files":{},"cache":{}}]
      [{"ref":"test-data"},{"~isa":"FORGETMENOT/memo","globs":[],"ref":"test-data","name":".forgetmenot-memo.json","autosave":false,"files":{},"cache":{}}]
      [{"name":"some-name.json"},{"~isa":"FORGETMENOT/memo","globs":[],"ref":".","name":"some-name.json","autosave":false,"files":{},"cache":{}}]
      ]
    for [ probe, matcher, ] in probes_and_matchers
      result = yield FMN.create_memo probe, resume
      # debug '22022', JSON.stringify [ probe, result, ]
      T.eq result, matcher
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "create memo object (2)" ] = ( T, done ) ->
  step ( resume ) =>
    settings    = { ref: 'test-data', name: 'create memo object (2).json', globs: 'test-1/*.txt', }
    result      = yield FMN.create_memo settings, resume
    debug '22022', result
    { files, }  = result
    T.eq result[ 'globs'    ], [ 'test-1/*.txt' ],
    T.eq result[ 'ref'      ], 'test-data',
    T.eq result[ 'name'     ], 'create memo object (2).json',
    T.eq result[ 'autosave' ], true,
    T.eq result[ 'cache'    ], {}
    #.......................................................................................................
    T.eq files[ '84d84b2199bf' ][ 'path' ], 'test-1/bar.txt'
    T.eq files[ '425b46fcc178' ][ 'path' ], 'test-1/baz.txt'
    T.eq files[ '7a803a2b46f6' ][ 'path' ], 'test-1/foo.txt'
    #.......................................................................................................
    T.eq files[ '84d84b2199bf' ][ 'checksum' ], '6690442d583d'
    T.eq files[ '425b46fcc178' ][ 'checksum' ], '5e066f2c5453'
    T.eq files[ '7a803a2b46f6' ][ 'checksum' ], 'd6375ba60848'
    #.......................................................................................................
    T.eq files[ '84d84b2199bf' ][ 'status' ], 'same'
    T.eq files[ '425b46fcc178' ][ 'status' ], 'same'
    T.eq files[ '7a803a2b46f6' ][ 'status' ], 'same'
    #.......................................................................................................
    T.ok FMN.DATE._looks_like_timestamp files[ '84d84b2199bf' ][ 'timestamp' ]
    T.ok FMN.DATE._looks_like_timestamp files[ '425b46fcc178' ][ 'timestamp' ]
    T.ok FMN.DATE._looks_like_timestamp files[ '7a803a2b46f6' ][ 'timestamp' ]
    #.......................................................................................................
    done()
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "set and get to and from cache" ] = ( T, done ) ->
  step ( resume ) =>
    settings    = { ref: 'test-data', name: 'cache-example.json' }
    memo        = yield FMN.create_memo settings, resume
    FMN.set memo, 'bar', 42
    key         = FMN.checksum_from_text memo, 'bar'
    { cache, }  = memo
    T.eq ( Object.keys cache ), [ key, ]
    entry       = cache[ key ]
    T.ok CND.is_subset ( Object.keys entry ), [ 'path', 'checksum', 'timestamp', 'status', 'value', ]
    T.eq ( Object.keys entry ).length, 5
    debug '90988', memo
    debug '90988', entry
    T.eq ( FMN.get memo, 'bar' ), 42
    done()
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "memo itself gets checksummed" ] = ( T, done ) ->
  ### when the memo file is included by one of the globs, the entry for the memo will keep updating, but
  no bad things happen. ###
  step ( resume ) =>
    settings    = { ref: 'test-data/test-2', name: 'no checksum for this memo.json', globs: './*', }
    result      = yield FMN.create_memo settings, resume
    debug '22022', result
    #.......................................................................................................
    done()
  #.........................................................................................................
  return null

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
    "create memo object (2)"
    "set and get to and from cache"
    "memo itself gets checksummed"
    "warn about missing features"
    ]
  @_prune()
  @_main()

  # CND.run => @[ "create memo object (1)" ] { eq: ( -> ), ok: ( -> ), }, ->

  # f = ->
  #   step ( resume ) ->
  #     settings =
  #       ref:    'test-data'
  #       name:   '.foobar.json'
  #       globs:  '../src/*.coffee'
  #     memo = yield FMN.create_memo settings, resume
  #     urge memo
  # f()

  # d = { y: 108, }
  # d[ Symbol.for 'x' ] = 42
  # help CND.truth CND.equals d, { y: 108, }

# debug timestamp = @DATE.as_timestamp new Date 2001, 0, 1, 12, 0, 0, 0
# debug @DATE.from_timestamp timestamp
# date = new Date()
# debug d date







