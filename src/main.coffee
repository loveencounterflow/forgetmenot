


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FORGETMENOT/MAIN'
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
# TC                        = require './main'
# LTSORT                    = require 'ltsort'
PATH                      = require 'path'
FS                        = require 'fs'
D                         = require 'pipedreams'
{ $, $async, }            = D
{ step, }                 = require 'coffeenode-suspend'
Crc32                     = require 'sse4_crc32'
do_glob                   = require 'glob'
@DATE                     = require './date'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@new_cache = ( settings, handler ) ->
  switch arity = arguments.length
    when 1
      if CND.isa_function settings
        handler   = settings
        settings  = null
      else
        handler   = null
    when 2 then null
    else throw new Error "expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  if settings?
    throw new Error "expected a POD, got a #{CND.type_of settings}" unless CND.isa_pod settings
  #.........................................................................................................
  globs     = settings?[ 'globs'    ] ? []
  cache     = settings?[ 'cache'    ] ? null
  autosave  = settings?[ 'autosave' ] ? null
  ### ??? `ref` will hold reference point of globs ??? ###
  ref       = settings?[ 'ref'      ] ? null
  path      =                           null
  #.........................................................................................................
  switch type_of_globs = CND.type_of globs
    when 'null' then null
    when 'list' then null
    when 'text' then globs = [ globs, ]
    else throw new Error "expected a text or a list for globs, got a #{type_of_globs}"
  #.........................................................................................................
  switch type_of_cache = CND.type_of cache
    when 'FORGETMENOT/cache' then throw new Error "### MEH ### not implemented"
    when 'null' then null
    when 'text'
      path  = cache
      R     = @_new_cache_from_path path, settings
    else throw new Error "expected a text or an object of type 'FORGETMENOT/cache', got a #{type_of_cache}"
  #.........................................................................................................
  R ?=
    '~isa':         'FORGETMENOT/cache'
    globs:          []
    path:           path
    files:          {}
    autosave:       no
  #.........................................................................................................
  for glob in globs
    continue if glob in R[ 'globs' ]
    R[ 'globs' ].push glob
  debug '44000', path
  R[ 'autosave' ] = if autosave? then autosave else path?
  #.........................................................................................................
  return @update R, handler if handler?
  return R

#-----------------------------------------------------------------------------------------------------------
@_new_cache_from_path  = ( path, settings ) ->
  ### Try to load cache object from file; return `null` if not found ###
  try
    json = FS.readFileSync path, { encoding: 'utf-8', }
  catch error
    return null if ( error[ 'code' ] is 'ENOENT' ) or json.length is 0
    throw error
  ### TAINT perform sanity check on object structure ###
  return null if json.length is 0
  return JSON.parse json


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@update = ( me, handler ) ->
  ### TAINT update timestamp only where checksum is new ###
  { files, autosave, } = me
  step ( resume ) =>
    for glob in me[ 'globs' ]
      paths = yield do_glob glob, resume
      for path in paths
        path_checksum           = @checksum_from_text         me, path, null
        new_checksum            = yield @checksum_from_path   me, path, resume
        new_timestamp           = yield @timestamp_from_path  me, path, resume
        old_checksum            = files[ path_checksum ]?[ 'checksum'   ] ? null
        old_timestamp           = files[ path_checksum ]?[ 'timestamp'  ] ? null
        # debug '33322', 'path', path
        # debug '33322', 'old_timestamp', old_timestamp
        # debug '33322', 'new_timestamp', new_timestamp
        #...................................................................................................
        if old_checksum is new_checksum
          status    = 'same'
          checksum  = old_checksum
          timestamp = if old_timestamp < new_timestamp then old_timestamp else new_timestamp
          throw new Error "### MEH ###" unless old_timestamp?
        #...................................................................................................
        else
          status    = 'changed'
          checksum  = new_checksum
          timestamp = new_timestamp
        #...................................................................................................
        ###
        if files[ path_checksum ]?
          files[ path_checksum ][ 'previous-checksum'  ] = files[ path_checksum ][ 'checksum'  ]
          files[ path_checksum ][ 'previous-timestamp' ] = files[ path_checksum ][ 'timestamp' ]
        ###
        #...................................................................................................
        target = files[ path_checksum ] ?= {}
        Object.assign target, { path, checksum, timestamp, status, }
    return if autosave then ( @save me, handler ) else handler null, me
  return null

#-----------------------------------------------------------------------------------------------------------
@save = ( me, handler ) ->
  step ( resume ) =>
    return handler new Error "unable to save without path given" unless ( path = me[ 'path' ] )?
    yield FS.writeFile path, ( JSON.stringify me, null, ' ' ), resume
    handler null, me
  return null


#===========================================================================================================
# SET AND GET, PLAIN AND CACHE
#-----------------------------------------------------------------------------------------------------------


#===========================================================================================================
# CHECKSUMS AND MTIMES
#-----------------------------------------------------------------------------------------------------------
@checksum_from_path = ( me, path, fallback, handler ) ->
  switch arity = arguments.length
    when 3
      handler   = fallback
      fallback  = undefined
    when 4
      null
    else throw new Error "expect 3 or 4 arguments, got #{arity}"
  crc32     = new Crc32.CRC32()
  finished  = no
  # input     = ( require 'fs' ).createReadStream path
  input = D.new_stream { path, }
  #.........................................................................................................
  input.on 'error', ( error ) ->
    throw error if finished
    finished = yes
    return handler null, fallback unless fallback is undefined
    handler error
  #.........................................................................................................
  input
    .pipe $ ( data, send ) -> crc32.update data
    .pipe $ 'finish', =>
      return if finished
      finished = yes
      handler null, crc32.crc()
  return null

#-----------------------------------------------------------------------------------------------------------
@checksum_from_text = ( me, text, handler = null ) ->
  R = Crc32.calculate text
  handler null, R if handler?
  return R

#-----------------------------------------------------------------------------------------------------------
@timestamp_from_path = ( me, path, handler ) ->
  step ( resume ) =>
    try
      stat  = yield ( require 'fs' ).stat path, resume
    catch error
      throw error unless error[ 'code' ] is 'ENOENT'
      return handler null, null
    handler null, @DATE.as_timestamp stat[ 'timestamp' ]
  return null




