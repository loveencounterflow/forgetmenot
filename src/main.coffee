


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
CRYPTO                    = require 'crypto'
D                         = require 'pipedreams'
{ $, $async, }            = D
{ step, }                 = require 'coffeenode-suspend'
do_glob                   = require 'glob'
@DATE                     = require './date'


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@create_memo = ( settings, handler ) ->
  #.........................................................................................................
  ### Check for arity 1 or 2 ###
  switch arity = arguments.length
    when 1
      handler   = settings
      settings  = null
    when 2 then null
    else throw new Error "expected 1 or 2 arguments, got #{arity}"
  #.........................................................................................................
  ### check that we did receive a function for argument handler ###
  unless ( type_of_handler = CND.type_of handler ) is 'function'
    throw new Error "expected a function for handler, got a #{type_of_handler}"
  #.........................................................................................................
  ### return copy of memo when memo was passed in; otherwise, check that `settings` is a POD ###
  if settings?
    unless CND.isa_pod settings
      throw new Error "expected a POD, got a #{CND.type_of settings}"
  #.........................................................................................................
  ### make sure no unknown keys have been passed in ###
  unless CND.is_subset ( keys = Object.keys settings ), @create_memo._keys
    expected  = ( rpr key for key in @create_memo._keys                                  ).join ', '
    got       = ( rpr key for key in keys             when key not in @create_memo._keys ).join ', '
    throw new Error "expected #{expected} as keys of settings, got #{got}"
  #.........................................................................................................
  Z         = null
  autosave  = settings?[ 'name' ]? and settings?[ 'ref' ]?
  name      = settings?[ 'name'     ] ? '.forgetmenot-memo.json'
  globs     = settings?[ 'globs'    ] ? []
  ref       = settings?[ 'ref'      ] ? '.'
  #.........................................................................................................
  switch type_of_name = CND.type_of name
    when 'text' then null
    else throw new Error "expected a text for name, got a #{type_of_name}"
  #.........................................................................................................
  switch type_of_globs = CND.type_of globs
    when 'null' then null
    when 'list' then null
    when 'text' then globs = [ globs, ]
    else throw new Error "expected a text or a list for globs, got a #{type_of_globs}"
  #.........................................................................................................
  switch type_of_ref = CND.type_of ref
    when 'text'
      if autosave
        memo_path = PATH.resolve ref, name
        debug '22901', memo_path
        Z = @_new_memo_from_path memo_path, settings
    else throw new Error "expected a text or an object of type 'FORGETMENOT/memo', got a #{type_of_path}"
  #.........................................................................................................
  Z ?=
    '~isa':         'FORGETMENOT/memo'
    globs:          globs[ .. ]
    ref:            ref
    autosave:       autosave
    files:          {}
    cache:          {}
  #.........................................................................................................
  step ( resume ) =>
    debug '99981', yield @is_folder Z, ref, resume
    #.......................................................................................................
    try
      yield @update Z, resume
    catch error
      return handler error
    handler null, Z if handler?
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@create_memo._keys = [ 'globs', 'ref', 'name', ]

#-----------------------------------------------------------------------------------------------------------
@_new_memo_from_path  = ( path, settings ) ->
  ### Try to load memo object from file; return `null` if not found ###
  try
    json = FS.readFileSync path, { encoding: 'utf-8', }
  catch error
    return null if error[ 'code' ] is 'ENOENT'
    throw error
  ### TAINT perform sanity check on object structure ###
  return null if json.length is 0
  return JSON.parse json


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@update = ( me, handler ) ->
  ### TAINT update timestamp only where checksum is new ###
  { files, } = me
  step ( resume ) =>
    for glob in me[ 'globs' ]
      paths = yield do_glob glob, resume
      for path in paths
        path_checksum           = @checksum_from_text         me, path, null
        new_checksum            = yield @checksum_from_path   me, path, resume
        new_timestamp           = yield @timestamp_from_path  me, path, resume
        old_checksum            = files[ path_checksum ]?[ 'checksum'   ] ? null
        old_timestamp           = files[ path_checksum ]?[ 'timestamp'  ] ? null
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
    return if me[ 'autosave' ] then ( @save me, handler ) else ( handler null, me )
  return null

#-----------------------------------------------------------------------------------------------------------
@save = ( me, handler = null ) ->
  json = JSON.stringify me, null, ' '
  #.........................................................................................................
  if handler?
    step ( resume ) =>
      return handler new Error "unable to save without path given" unless ( path = me[ 'path' ] )?
      yield FS.writeFile path, json, resume
      handler null, me
  #.........................................................................................................
  else
    FS.writeFileSync path, json
  #.........................................................................................................
  return me


#===========================================================================================================
# SET AND GET OF CACHE ENTRIES
#-----------------------------------------------------------------------------------------------------------
@set = ( me, key, value ) ->
  ### serialize, checksum, equality ###
  timestamp = @DATE.as_timestamp()
  target    = me[ 'cache' ][ 'key' ] ?= {}
  Object.assign target, { value, timestamp, }
  return me

#-----------------------------------------------------------------------------------------------------------
@get_entry = ( me, key, fallback ) ->
  unless ( R = me[ 'cache' ][ 'key' ] )?
    return fallback unless fallback is undefined
    throw new Error "no such key: #{rpr key}"
  return R

#-----------------------------------------------------------------------------------------------------------
@get = ( me, key, fallback ) ->
  if ( R = @get_entry me, key, null ) is null
    return fallback unless fallback is undefined
    throw new Error "no such key: #{rpr key}"
  return R[ 'value' ]


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
  #.........................................................................................................
  hash      = CRYPTO.createHash 'sha1'
  Z         = null
  finished  = no
  input     = D.new_stream { path, }
  #.........................................................................................................
  input.on 'error', ( error ) ->
    throw error if finished
    finished = yes
    return handler null, fallback unless fallback is undefined
    handler error
  #.........................................................................................................
  input
    .pipe hash
    .pipe $ ( buffer ) => Z = ( buffer.toString 'hex' )[ ... 12 ]
    .pipe $ 'finish', => handler null, Z
  return null

#-----------------------------------------------------------------------------------------------------------
@checksum_from_text = ( me, text, handler = null ) ->
  R = ( ( ( CRYPTO.createHash 'sha1' ).update text, 'utf8' ).digest 'hex' )[ ... 12 ]
  handler null, R if handler?
  return R

#-----------------------------------------------------------------------------------------------------------
@timestamp_from_path = ( me, path, handler ) ->
  step ( resume ) =>
    try
      stat  = yield FS.stat path, resume
    catch error
      throw error unless error[ 'code' ] is 'ENOENT'
      return handler null, null
    handler null, @DATE.as_timestamp stat[ 'mtime' ]
  return null

#-----------------------------------------------------------------------------------------------------------
@is_folder = ( me, path, handler ) ->
  FS.stat path, ( error, stat ) =>
    if error?
      debug '33091', error
      debug '33091', error[ 'code' ]
    return handler error if error?
    handler null, stat.isDirectory()
  return null




