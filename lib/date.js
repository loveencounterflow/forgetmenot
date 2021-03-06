// Generated by CoffeeScript 1.11.1
(function() {
  var CND, badge, rpr;

  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'FORGETMENOT/DATE';

  this.as_timestamp = function(date) {
    var dy, hr, mi, mo, ms, sc, yr;
    if (date == null) {
      date = null;
    }

    /* TAINT code duplication (also used in kleinbild) */

    /* TAINT consider to incorporate TopoCache's monotimestamp */
    if (date == null) {
      date = new Date();
    }
    yr = date.getUTCFullYear().toString();
    mo = (date.getUTCMonth() + 1).toString();
    dy = date.getUTCDate().toString();
    hr = date.getUTCHours().toString();
    mi = date.getUTCMinutes().toString();
    sc = date.getUTCSeconds().toString();
    ms = date.getUTCMilliseconds().toString();
    if (mo.length < 2) {
      mo = '0' + mo;
    }
    if (dy.length < 2) {
      dy = '0' + dy;
    }
    if (hr.length < 2) {
      hr = '0' + hr;
    }
    if (mi.length < 2) {
      mi = '0' + mi;
    }
    if (sc.length < 2) {
      sc = '0' + sc;
    }
    while (ms.length < 3) {
      ms = '0' + ms;
    }
    return "" + yr + mo + dy + "-" + hr + mi + sc + "." + ms;
  };

  this.from_timestamp = function(timestamp) {

    /*
      20161026-110905.754
     */
    var R, day, hours, milliseconds, minutes, month, ref, seconds, year;
    ref = this.parse_timestamp(timestamp), year = ref[0], month = ref[1], day = ref[2], hours = ref[3], minutes = ref[4], seconds = ref[5], milliseconds = ref[6];
    R = new Date();
    R.setUTCFullYear(year);
    R.setUTCMonth(month);
    R.setUTCDate(day);
    R.setUTCHours(hours);
    R.setUTCMinutes(minutes);
    R.setUTCSeconds(seconds);
    R.setUTCMilliseconds(milliseconds);
    return R;
  };

  this.parse_timestamp = function(timestamp) {
    var _, day, hours, match, milliseconds, minutes, month0, seconds, year;
    match = timestamp.match(/^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})\.(\d{3})$/);
    if ((match == null) || (!CND.isa_text(timestamp))) {
      throw new Error("not a valid timestamp: " + (rpr(timestamp)));
    }
    _ = match[0], year = match[1], month0 = match[2], day = match[3], hours = match[4], minutes = match[5], seconds = match[6], milliseconds = match[7];
    return [parseInt(year, 10), (parseInt(month0, 10)) - 1, parseInt(day, 10), parseInt(hours, 10), parseInt(minutes, 10), parseInt(seconds, 10), parseInt(milliseconds, 10)];
  };

  this._looks_like_timestamp = function(x) {

    /* TAINT a more serious method should check number ranges */
    this.parse_timestamp(x);
    return true;
  };

}).call(this);

//# sourceMappingURL=date.js.map
