
############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FORGETMENOT/DATE'
# log                       = CND.get_logger 'plain',     badge
# debug                     = CND.get_logger 'debug',     badge
# info                      = CND.get_logger 'info',      badge
# warn                      = CND.get_logger 'warn',      badge
# help                      = CND.get_logger 'help',      badge
# urge                      = CND.get_logger 'urge',      badge
# whisper                   = CND.get_logger 'whisper',   badge


#-----------------------------------------------------------------------------------------------------------
@as_timestamp = ( date = null ) ->
  ### TAINT code duplication (also used in kleinbild) ###
  ### TAINT consider to incorporate TopoCache's monotimestamp ###
  date ?= new Date()
  yr    = date.getUTCFullYear().toString()
  mo    = ( date.getUTCMonth() + 1 ).toString()
  dy    = date.getUTCDate().toString()
  hr    = date.getUTCHours().toString()
  mi    = date.getUTCMinutes().toString()
  sc    = date.getUTCSeconds().toString()
  ms    = date.getUTCMilliseconds().toString()
  mo    = '0' + mo    if mo.length < 2
  dy    = '0' + dy    if dy.length < 2
  hr    = '0' + hr    if hr.length < 2
  mi    = '0' + mi    if mi.length < 2
  sc    = '0' + sc    if sc.length < 2
  ms    = '0' + ms while ms.length < 3
  return "#{yr}#{mo}#{dy}-#{hr}#{mi}#{sc}.#{ms}"

#-----------------------------------------------------------------------------------------------------------
@from_timestamp = ( timestamp ) ->
  ###
    20161026-110905.754
  ###
  [ year
    month
    day
    hours
    minutes
    seconds
    milliseconds ]    = @parse_timestamp timestamp
  R                   = new Date()
  R.setUTCFullYear      year
  R.setUTCMonth         month
  R.setUTCDate          day
  R.setUTCHours         hours
  R.setUTCMinutes       minutes
  R.setUTCSeconds       seconds
  R.setUTCMilliseconds  milliseconds
  return R

#-----------------------------------------------------------------------------------------------------------
@parse_timestamp = ( timestamp ) ->
  match = timestamp.match /^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.(\d{3})$/
  if ( not match? ) or ( not CND.isa_text timestamp )
    throw new Error "not a valid timestamp: #{rpr timestamp}"
  [ _, year, month0, day, hours, minutes, seconds, milliseconds, ] = match
  return [
    ( parseInt year,          10 )
    ( parseInt month0,        10 ) - 1
    ( parseInt day,           10 )
    ( parseInt hours,         10 )
    ( parseInt minutes,       10 )
    ( parseInt seconds,       10 )
    ( parseInt milliseconds,  10 )
    ]

#-----------------------------------------------------------------------------------------------------------
@_looks_like_timestamp = ( x ) ->
  ### TAINT a more serious method should check number ranges ###
  @parse_timestamp x
  return true







