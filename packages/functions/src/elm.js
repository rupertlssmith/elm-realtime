(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}

console.warn('Compiled in DEV mode. Follow the advice at https://elm-lang.org/0.19.1/optimize for better performance and smaller assets.');


var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log_UNUSED = F2(function(tag, value)
{
	return value;
});

var _Debug_log = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString_UNUSED(value)
{
	return '<internals>';
}

function _Debug_toString(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash_UNUSED(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.start.line === region.end.line)
	{
		return 'on line ' + region.start.line;
	}
	return 'on lines ' + region.start.line + ' through ' + region.end.line;
}



// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**_UNUSED/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**_UNUSED/
	if (typeof x.$ === 'undefined')
	//*/
	/**/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0_UNUSED = 0;
var _Utils_Tuple0 = { $: '#0' };

function _Utils_Tuple2_UNUSED(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3_UNUSED(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr_UNUSED(c) { return c; }
function _Utils_chr(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil_UNUSED = { $: 0 };
var _List_Nil = { $: '[]' };

function _List_Cons_UNUSED(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap(value) { return { $: 0, a: value }; }
function _Json_unwrap(value) { return value.a; }

function _Json_wrap_UNUSED(value) { return value; }
function _Json_unwrap_UNUSED(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}



var _Bitwise_and = F2(function(a, b)
{
	return a & b;
});

var _Bitwise_or = F2(function(a, b)
{
	return a | b;
});

var _Bitwise_xor = F2(function(a, b)
{
	return a ^ b;
});

function _Bitwise_complement(a)
{
	return ~a;
};

var _Bitwise_shiftLeftBy = F2(function(offset, a)
{
	return a << offset;
});

var _Bitwise_shiftRightBy = F2(function(offset, a)
{
	return a >> offset;
});

var _Bitwise_shiftRightZfBy = F2(function(offset, a)
{
	return a >>> offset;
});



function _Time_now(millisToPosix)
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(millisToPosix(Date.now())));
	});
}

var _Time_setInterval = F2(function(interval, task)
{
	return _Scheduler_binding(function(callback)
	{
		var id = setInterval(function() { _Scheduler_rawSpawn(task); }, interval);
		return function() { clearInterval(id); };
	});
});

function _Time_here()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(
			A2($elm$time$Time$customZone, -(new Date().getTimezoneOffset()), _List_Nil)
		));
	});
}


function _Time_getZoneName()
{
	return _Scheduler_binding(function(callback)
	{
		try
		{
			var name = $elm$time$Time$Name(Intl.DateTimeFormat().resolvedOptions().timeZone);
		}
		catch (e)
		{
			var name = $elm$time$Time$Offset(new Date().getTimezoneOffset());
		}
		callback(_Scheduler_succeed(name));
	});
}


function _Url_percentEncode(string)
{
	return encodeURIComponent(string);
}

function _Url_percentDecode(string)
{
	try
	{
		return $elm$core$Maybe$Just(decodeURIComponent(string));
	}
	catch (e)
	{
		return $elm$core$Maybe$Nothing;
	}
}var $elm$core$List$cons = _List_cons;
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (node.$ === 'SubTree') {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0.a;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Basics$EQ = {$: 'EQ'};
var $elm$core$Basics$GT = {$: 'GT'};
var $elm$core$Basics$LT = {$: 'LT'};
var $elm$core$Result$Err = function (a) {
	return {$: 'Err', a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 'Failure', a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 'Field', a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 'Index', a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 'Ok', a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 'OneOf', a: a};
};
var $elm$core$Basics$False = {$: 'False'};
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 'Just', a: a};
};
var $elm$core$Maybe$Nothing = {$: 'Nothing'};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 'Field':
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 'Nothing') {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'Index':
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'OneOf':
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 'Array_elm_builtin', a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 'Leaf', a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 'SubTree', a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.nodeListSize) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.tail);
		} else {
			var treeLen = builder.nodeListSize * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.nodeList) : builder.nodeList;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.nodeListSize);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.tail);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{nodeList: nodeList, nodeListSize: (len / $elm$core$Array$branchFactor) | 0, tail: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = {$: 'True'};
var $elm$core$Result$isOk = function (result) {
	if (result.$ === 'Ok') {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $author$project$API$EventLogMsg = function (a) {
	return {$: 'EventLogMsg', a: a};
};
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $author$project$EventLog$Component$ModelStart = function (a) {
	return {$: 'ModelStart', a: a};
};
var $the_sett$elm_update_helper$Update2$andMap = F2(
	function (fn, _v0) {
		var model = _v0.a;
		var cmd = _v0.b;
		var _v1 = fn(model);
		var nextModel = _v1.a;
		var nextCmd = _v1.b;
		return _Utils_Tuple2(
			nextModel,
			$elm$core$Platform$Cmd$batch(
				_List_fromArray(
					[cmd, nextCmd])));
	});
var $elm$core$Platform$Cmd$map = _Platform_map;
var $elm$core$Tuple$mapSecond = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			x,
			func(y));
	});
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $the_sett$elm_update_helper$Update2$pure = function (model) {
	return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
};
var $author$project$EventLog$Component$RandomSeed = function (a) {
	return {$: 'RandomSeed', a: a};
};
var $elm$random$Random$Generate = function (a) {
	return {$: 'Generate', a: a};
};
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$random$Random$Seed = F2(
	function (a, b) {
		return {$: 'Seed', a: a, b: b};
	});
var $elm$core$Bitwise$shiftRightZfBy = _Bitwise_shiftRightZfBy;
var $elm$random$Random$next = function (_v0) {
	var state0 = _v0.a;
	var incr = _v0.b;
	return A2($elm$random$Random$Seed, ((state0 * 1664525) + incr) >>> 0, incr);
};
var $elm$random$Random$initialSeed = function (x) {
	var _v0 = $elm$random$Random$next(
		A2($elm$random$Random$Seed, 0, 1013904223));
	var state1 = _v0.a;
	var incr = _v0.b;
	var state2 = (state1 + x) >>> 0;
	return $elm$random$Random$next(
		A2($elm$random$Random$Seed, state2, incr));
};
var $elm$time$Time$Name = function (a) {
	return {$: 'Name', a: a};
};
var $elm$time$Time$Offset = function (a) {
	return {$: 'Offset', a: a};
};
var $elm$time$Time$Zone = F2(
	function (a, b) {
		return {$: 'Zone', a: a, b: b};
	});
var $elm$time$Time$customZone = $elm$time$Time$Zone;
var $elm$time$Time$Posix = function (a) {
	return {$: 'Posix', a: a};
};
var $elm$time$Time$millisToPosix = $elm$time$Time$Posix;
var $elm$time$Time$now = _Time_now($elm$time$Time$millisToPosix);
var $elm$time$Time$posixToMillis = function (_v0) {
	var millis = _v0.a;
	return millis;
};
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$random$Random$init = A2(
	$elm$core$Task$andThen,
	function (time) {
		return $elm$core$Task$succeed(
			$elm$random$Random$initialSeed(
				$elm$time$Time$posixToMillis(time)));
	},
	$elm$time$Time$now);
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$random$Random$step = F2(
	function (_v0, seed) {
		var generator = _v0.a;
		return generator(seed);
	});
var $elm$random$Random$onEffects = F3(
	function (router, commands, seed) {
		if (!commands.b) {
			return $elm$core$Task$succeed(seed);
		} else {
			var generator = commands.a.a;
			var rest = commands.b;
			var _v1 = A2($elm$random$Random$step, generator, seed);
			var value = _v1.a;
			var newSeed = _v1.b;
			return A2(
				$elm$core$Task$andThen,
				function (_v2) {
					return A3($elm$random$Random$onEffects, router, rest, newSeed);
				},
				A2($elm$core$Platform$sendToApp, router, value));
		}
	});
var $elm$random$Random$onSelfMsg = F3(
	function (_v0, _v1, seed) {
		return $elm$core$Task$succeed(seed);
	});
var $elm$random$Random$Generator = function (a) {
	return {$: 'Generator', a: a};
};
var $elm$random$Random$map = F2(
	function (func, _v0) {
		var genA = _v0.a;
		return $elm$random$Random$Generator(
			function (seed0) {
				var _v1 = genA(seed0);
				var a = _v1.a;
				var seed1 = _v1.b;
				return _Utils_Tuple2(
					func(a),
					seed1);
			});
	});
var $elm$random$Random$cmdMap = F2(
	function (func, _v0) {
		var generator = _v0.a;
		return $elm$random$Random$Generate(
			A2($elm$random$Random$map, func, generator));
	});
_Platform_effectManagers['Random'] = _Platform_createManager($elm$random$Random$init, $elm$random$Random$onEffects, $elm$random$Random$onSelfMsg, $elm$random$Random$cmdMap);
var $elm$random$Random$command = _Platform_leaf('Random');
var $elm$random$Random$generate = F2(
	function (tagger, generator) {
		return $elm$random$Random$command(
			$elm$random$Random$Generate(
				A2($elm$random$Random$map, tagger, generator)));
	});
var $elm$core$Bitwise$and = _Bitwise_and;
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $elm$core$Bitwise$xor = _Bitwise_xor;
var $elm$random$Random$peel = function (_v0) {
	var state = _v0.a;
	var word = (state ^ (state >>> ((state >>> 28) + 4))) * 277803737;
	return ((word >>> 22) ^ word) >>> 0;
};
var $elm$random$Random$int = F2(
	function (a, b) {
		return $elm$random$Random$Generator(
			function (seed0) {
				var _v0 = (_Utils_cmp(a, b) < 0) ? _Utils_Tuple2(a, b) : _Utils_Tuple2(b, a);
				var lo = _v0.a;
				var hi = _v0.b;
				var range = (hi - lo) + 1;
				if (!((range - 1) & range)) {
					return _Utils_Tuple2(
						(((range - 1) & $elm$random$Random$peel(seed0)) >>> 0) + lo,
						$elm$random$Random$next(seed0));
				} else {
					var threshhold = (((-range) >>> 0) % range) >>> 0;
					var accountForBias = function (seed) {
						accountForBias:
						while (true) {
							var x = $elm$random$Random$peel(seed);
							var seedN = $elm$random$Random$next(seed);
							if (_Utils_cmp(x, threshhold) < 0) {
								var $temp$seed = seedN;
								seed = $temp$seed;
								continue accountForBias;
							} else {
								return _Utils_Tuple2((x % range) + lo, seedN);
							}
						}
					};
					return accountForBias(seed0);
				}
			});
	});
var $elm$random$Random$map3 = F4(
	function (func, _v0, _v1, _v2) {
		var genA = _v0.a;
		var genB = _v1.a;
		var genC = _v2.a;
		return $elm$random$Random$Generator(
			function (seed0) {
				var _v3 = genA(seed0);
				var a = _v3.a;
				var seed1 = _v3.b;
				var _v4 = genB(seed1);
				var b = _v4.a;
				var seed2 = _v4.b;
				var _v5 = genC(seed2);
				var c = _v5.a;
				var seed3 = _v5.b;
				return _Utils_Tuple2(
					A3(func, a, b, c),
					seed3);
			});
	});
var $elm$core$Bitwise$or = _Bitwise_or;
var $elm$random$Random$independentSeed = $elm$random$Random$Generator(
	function (seed0) {
		var makeIndependentSeed = F3(
			function (state, b, c) {
				return $elm$random$Random$next(
					A2($elm$random$Random$Seed, state, (1 | (b ^ c)) >>> 0));
			});
		var gen = A2($elm$random$Random$int, 0, 4294967295);
		return A2(
			$elm$random$Random$step,
			A4($elm$random$Random$map3, makeIndependentSeed, gen, gen, gen),
			seed0);
	});
var $author$project$EventLog$Component$randomize = function (model) {
	return _Utils_Tuple2(
		model,
		A2($elm$random$Random$generate, $author$project$EventLog$Component$RandomSeed, $elm$random$Random$independentSeed));
};
var $author$project$EventLog$Component$switchState = F2(
	function (cons, state) {
		return _Utils_Tuple2(
			cons(state),
			$elm$core$Platform$Cmd$none);
	});
var $author$project$EventLog$Component$init = function (toMsg) {
	return A2(
		$elm$core$Tuple$mapSecond,
		$elm$core$Platform$Cmd$map(toMsg),
		A2(
			$the_sett$elm_update_helper$Update2$andMap,
			$author$project$EventLog$Component$switchState($author$project$EventLog$Component$ModelStart),
			A2(
				$the_sett$elm_update_helper$Update2$andMap,
				$author$project$EventLog$Component$randomize,
				$the_sett$elm_update_helper$Update2$pure(
					{}))));
};
var $author$project$API$init = function (flags) {
	var _v0 = $author$project$EventLog$Component$init($author$project$API$EventLogMsg);
	var eventLogMdl = _v0.a;
	var eventLogCmds = _v0.b;
	return _Utils_Tuple2(
		{channelApiUrl: flags.channelApiUrl, channelTable: flags.channelTable, eventLog: eventLogMdl, eventLogTable: flags.eventLogTable, momentoApiKey: flags.momentoSecret.apiKey},
		$elm$core$Platform$Cmd$batch(
			_List_fromArray(
				[eventLogCmds])));
};
var $elm$json$Json$Decode$string = _Json_decodeString;
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $author$project$API$eventLogProtocol = {onUpdate: $elm$core$Basics$identity, toMsg: $author$project$API$EventLogMsg};
var $author$project$EventLog$Component$HttpRequest = F2(
	function (a, b) {
		return {$: 'HttpRequest', a: a, b: b};
	});
var $author$project$EventLog$Component$MomentoError = function (a) {
	return {$: 'MomentoError', a: a};
};
var $author$project$Serverless$HttpServer$HttpSessionKey = function (a) {
	return {$: 'HttpSessionKey', a: a};
};
var $author$project$Serverless$HttpServer$InvalidRequestFormat = function (a) {
	return {$: 'InvalidRequestFormat', a: a};
};
var $author$project$Serverless$HttpServer$NoMatchingRoute = function (a) {
	return {$: 'NoMatchingRoute', a: a};
};
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (maybeValue.$ === 'Just') {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm$core$Result$andThen = F2(
	function (callback, result) {
		if (result.$ === 'Ok') {
			var value = result.a;
			return callback(value);
		} else {
			var msg = result.a;
			return $elm$core$Result$Err(msg);
		}
	});
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $author$project$Serverless$Request$HeadersOnly = function (headers) {
	return {headers: headers};
};
var $author$project$Serverless$Request$Request = function (a) {
	return {$: 'Request', a: a};
};
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $elm$json$Json$Decode$keyValuePairs = _Json_decodeKeyValuePairs;
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$null = _Json_decodeNull;
var $elm$json$Json$Decode$oneOf = _Json_oneOf;
var $elm$json$Json$Decode$nullable = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				$elm$json$Json$Decode$null($elm$core$Maybe$Nothing),
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder)
			]));
};
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $author$project$Serverless$KeyValueList$decoder = A2(
	$elm$json$Json$Decode$andThen,
	function (maybeParams) {
		if (maybeParams.$ === 'Just') {
			var params = maybeParams.a;
			return $elm$json$Json$Decode$succeed(params);
		} else {
			return $elm$json$Json$Decode$succeed(_List_Nil);
		}
	},
	$elm$json$Json$Decode$nullable(
		$elm$json$Json$Decode$keyValuePairs($elm$json$Json$Decode$string)));
var $elm$core$Dict$RBEmpty_elm_builtin = {$: 'RBEmpty_elm_builtin'};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$core$Dict$Black = {$: 'Black'};
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: 'RBNode_elm_builtin', a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$Red = {$: 'Red'};
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Red')) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) && (left.d.$ === 'RBNode_elm_builtin')) && (left.d.a.$ === 'Red')) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1.$) {
				case 'LT':
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 'EQ':
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $author$project$Serverless$Body$Empty = {$: 'Empty'};
var $author$project$Serverless$Body$Error = function (a) {
	return {$: 'Error', a: a};
};
var $author$project$Serverless$Body$Json = function (a) {
	return {$: 'Json', a: a};
};
var $author$project$Serverless$Body$Text = function (a) {
	return {$: 'Text', a: a};
};
var $elm$json$Json$Decode$decodeString = _Json_runOnString;
var $elm$json$Json$Decode$maybe = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder),
				$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
			]));
};
var $elm$core$String$startsWith = _String_startsWith;
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$Serverless$Body$decoder = function (maybeType) {
	return A2(
		$elm$json$Json$Decode$andThen,
		function (maybeString) {
			if (maybeString.$ === 'Just') {
				var w = maybeString.a;
				if (A2(
					$elm$core$String$startsWith,
					'application/json',
					A2($elm$core$Maybe$withDefault, '', maybeType))) {
					var _v1 = A2($elm$json$Json$Decode$decodeString, $elm$json$Json$Decode$value, w);
					if (_v1.$ === 'Ok') {
						var val = _v1.a;
						return $elm$json$Json$Decode$succeed(
							$author$project$Serverless$Body$Json(val));
					} else {
						var err = _v1.a;
						return $elm$json$Json$Decode$succeed(
							$author$project$Serverless$Body$Error(
								$elm$json$Json$Decode$errorToString(err)));
					}
				} else {
					return $elm$json$Json$Decode$succeed(
						$author$project$Serverless$Body$Text(w));
				}
			} else {
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Body$Empty);
			}
		},
		$elm$json$Json$Decode$maybe($elm$json$Json$Decode$string));
};
var $author$project$Serverless$IpAddress$Ip4 = F4(
	function (a, b, c, d) {
		return {$: 'Ip4', a: a, b: b, c: c, d: d};
	});
var $elm$json$Json$Decode$fail = _Json_fail;
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Basics$ge = _Utils_ge;
var $elm$core$String$toInt = _String_toInt;
var $author$project$Serverless$IpAddress$toNonNegativeInt = function (val) {
	return A2(
		$elm$core$Maybe$andThen,
		function (i) {
			return (i >= 0) ? $elm$core$Maybe$Just(i) : $elm$core$Maybe$Nothing;
		},
		$elm$core$String$toInt(val));
};
var $author$project$Serverless$IpAddress$decoder = A2(
	$elm$json$Json$Decode$andThen,
	function (w) {
		var list = A2(
			$elm$core$List$map,
			$author$project$Serverless$IpAddress$toNonNegativeInt,
			A2($elm$core$String$split, '.', w));
		if ((((((((list.b && (list.a.$ === 'Just')) && list.b.b) && (list.b.a.$ === 'Just')) && list.b.b.b) && (list.b.b.a.$ === 'Just')) && list.b.b.b.b) && (list.b.b.b.a.$ === 'Just')) && (!list.b.b.b.b.b)) {
			var a = list.a.a;
			var _v1 = list.b;
			var b = _v1.a.a;
			var _v2 = _v1.b;
			var c = _v2.a.a;
			var _v3 = _v2.b;
			var d = _v3.a.a;
			return $elm$json$Json$Decode$succeed(
				A4($author$project$Serverless$IpAddress$Ip4, a, b, c, d));
		} else {
			return $elm$json$Json$Decode$fail('Unsupported IP address: ' + w);
		}
	},
	$elm$json$Json$Decode$string);
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1.$) {
					case 'LT':
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 'EQ':
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $elm$json$Json$Decode$map2 = _Json_map2;
var $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$custom = $elm$json$Json$Decode$map2($elm$core$Basics$apR);
var $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded = A2($elm$core$Basics$composeR, $elm$json$Json$Decode$succeed, $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$custom);
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $author$project$Serverless$Request$CONNECT = {$: 'CONNECT'};
var $author$project$Serverless$Request$DELETE = {$: 'DELETE'};
var $author$project$Serverless$Request$GET = {$: 'GET'};
var $author$project$Serverless$Request$HEAD = {$: 'HEAD'};
var $author$project$Serverless$Request$OPTIONS = {$: 'OPTIONS'};
var $author$project$Serverless$Request$PATCH = {$: 'PATCH'};
var $author$project$Serverless$Request$POST = {$: 'POST'};
var $author$project$Serverless$Request$PUT = {$: 'PUT'};
var $author$project$Serverless$Request$TRACE = {$: 'TRACE'};
var $elm$core$String$toLower = _String_toLower;
var $author$project$Serverless$Request$methodDecoder = A2(
	$elm$json$Json$Decode$andThen,
	function (w) {
		var _v0 = $elm$core$String$toLower(w);
		switch (_v0) {
			case 'connect':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$CONNECT);
			case 'delete':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$DELETE);
			case 'get':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$GET);
			case 'head':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$HEAD);
			case 'options':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$OPTIONS);
			case 'patch':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$PATCH);
			case 'post':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$POST);
			case 'put':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$PUT);
			case 'trace':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$TRACE);
			default:
				return $elm$json$Json$Decode$fail('Unsupported method: ' + w);
		}
	},
	$elm$json$Json$Decode$string);
var $NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required = F3(
	function (key, valDecoder, decoder) {
		return A2(
			$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$custom,
			A2($elm$json$Json$Decode$field, key, valDecoder),
			decoder);
	});
var $author$project$Serverless$Request$Http = {$: 'Http'};
var $author$project$Serverless$Request$Https = {$: 'Https'};
var $author$project$Serverless$Request$schemeDecoder = A2(
	$elm$json$Json$Decode$andThen,
	function (w) {
		var _v0 = $elm$core$String$toLower(w);
		switch (_v0) {
			case 'http':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$Http);
			case 'https':
				return $elm$json$Json$Decode$succeed($author$project$Serverless$Request$Https);
			default:
				return $elm$json$Json$Decode$fail('Unsupported scheme: ' + w);
		}
	},
	$elm$json$Json$Decode$string);
var $author$project$Serverless$Request$schemeToString = function (scheme) {
	if (scheme.$ === 'Http') {
		return 'http:';
	} else {
		return 'https:';
	}
};
var $author$project$Serverless$Request$modelDecoder = function (_v0) {
	var headers = _v0.headers;
	return A3(
		$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
		'queryString',
		$elm$json$Json$Decode$string,
		A3(
			$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
			'queryParams',
			A2($elm$json$Json$Decode$map, $elm$core$Dict$fromList, $author$project$Serverless$KeyValueList$decoder),
			A3(
				$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
				'stage',
				$elm$json$Json$Decode$string,
				A3(
					$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
					'scheme',
					$author$project$Serverless$Request$schemeDecoder,
					A3(
						$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
						'remoteIp',
						$author$project$Serverless$IpAddress$decoder,
						A3(
							$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
							'port',
							$elm$json$Json$Decode$int,
							A3(
								$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
								'path',
								$elm$json$Json$Decode$string,
								A3(
									$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
									'method',
									$author$project$Serverless$Request$methodDecoder,
									A3(
										$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
										'host',
										$elm$json$Json$Decode$string,
										A2(
											$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$hardcoded,
											headers,
											A3(
												$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
												'body',
												$author$project$Serverless$Body$decoder(
													A2($elm$core$Dict$get, 'content-type', headers)),
												$elm$json$Json$Decode$succeed(
													function (bodyVal) {
														return function (headersVal) {
															return function (hostVal) {
																return function (methodVal) {
																	return function (pathVal) {
																		return function (portVal) {
																			return function (remoteIpVal) {
																				return function (schemeVal) {
																					return function (stageVal) {
																						return function (queryParamsVal) {
																							return function (queryStringVal) {
																								return {
																									body: bodyVal,
																									headers: headersVal,
																									host: hostVal,
																									method: methodVal,
																									path: pathVal,
																									port_: portVal,
																									queryParams: queryParamsVal,
																									queryString: queryStringVal,
																									remoteIp: remoteIpVal,
																									scheme: schemeVal,
																									stage: stageVal,
																									url: $author$project$Serverless$Request$schemeToString(schemeVal) + ('//' + (hostVal + (':' + ($elm$core$String$fromInt(portVal) + (pathVal + queryStringVal)))))
																								};
																							};
																						};
																					};
																				};
																			};
																		};
																	};
																};
															};
														};
													}))))))))))));
};
var $author$project$Serverless$Request$decoder = A2(
	$elm$json$Json$Decode$andThen,
	A2(
		$elm$core$Basics$composeL,
		$elm$json$Json$Decode$map($author$project$Serverless$Request$Request),
		$author$project$Serverless$Request$modelDecoder),
	A3(
		$NoRedInk$elm_json_decode_pipeline$Json$Decode$Pipeline$required,
		'headers',
		A2($elm$json$Json$Decode$map, $elm$core$Dict$fromList, $author$project$Serverless$KeyValueList$decoder),
		$elm$json$Json$Decode$succeed($author$project$Serverless$Request$HeadersOnly)));
var $elm$url$Url$Http = {$: 'Http'};
var $elm$url$Url$Https = {$: 'Https'};
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {fragment: fragment, host: host, path: path, port_: port_, protocol: protocol, query: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 'Nothing') {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Http,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Https,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Result$mapError = F2(
	function (f, result) {
		if (result.$ === 'Ok') {
			var v = result.a;
			return $elm$core$Result$Ok(v);
		} else {
			var e = result.a;
			return $elm$core$Result$Err(
				f(e));
		}
	});
var $author$project$Serverless$Request$url = function (_v0) {
	var request = _v0.a;
	return request.url;
};
var $author$project$Serverless$HttpServer$decodeRequestAndRoute = F2(
	function (rawRequest, parseRoute) {
		return A2(
			$elm$core$Result$andThen,
			function (req) {
				return function (maybeRoute) {
					if (maybeRoute.$ === 'Nothing') {
						return $elm$core$Result$Err(
							$author$project$Serverless$HttpServer$NoMatchingRoute(
								$author$project$Serverless$Request$url(req)));
					} else {
						var route = maybeRoute.a;
						return $elm$core$Result$Ok(
							_Utils_Tuple2(req, route));
					}
				}(
					A2(
						$elm$core$Maybe$andThen,
						parseRoute,
						$elm$url$Url$fromString(
							$author$project$Serverless$Request$url(req))));
			},
			A2(
				$elm$core$Result$mapError,
				$author$project$Serverless$HttpServer$InvalidRequestFormat,
				A2($elm$json$Json$Decode$decodeValue, $author$project$Serverless$Request$decoder, rawRequest)));
	});
var $elm$core$Platform$Sub$map = _Platform_map;
var $elm$core$Result$map = F2(
	function (func, ra) {
		if (ra.$ === 'Ok') {
			var a = ra.a;
			return $elm$core$Result$Ok(
				func(a));
		} else {
			var e = ra.a;
			return $elm$core$Result$Err(e);
		}
	});
var $author$project$Serverless$HttpServer$requestSub = F2(
	function (protocol, requestFn) {
		var fn = function (_v1) {
			var session = _v1.session;
			var req = _v1.req;
			return A2(
				requestFn,
				$author$project$Serverless$HttpServer$HttpSessionKey(session),
				A2(
					$elm$core$Result$map,
					function (_v0) {
						var request = _v0.a;
						var route = _v0.b;
						return {request: request, route: route};
					},
					A2($author$project$Serverless$HttpServer$decodeRequestAndRoute, req, protocol.parseRoute)));
		};
		return A2(
			$elm$core$Platform$Sub$map,
			$elm$core$Basics$identity,
			protocol.ports.request(fn));
	});
var $elm$json$Json$Encode$bool = _Json_wrap;
var $author$project$Serverless$Body$contentType = function (body) {
	switch (body.$) {
		case 'Json':
			return 'application/json';
		case 'Binary':
			var binType = body.a;
			return binType;
		default:
			return 'text/text';
	}
};
var $author$project$Serverless$Charset$toString = function (charset) {
	return 'utf-8';
};
var $author$project$Serverless$Response$contentType = function (_v0) {
	var body = _v0.body;
	var charset = _v0.charset;
	return $author$project$Serverless$Body$contentType(body) + ('; charset=' + $author$project$Serverless$Charset$toString(charset));
};
var $elm$json$Json$Encode$null = _Json_encodeNull;
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$Serverless$Body$encode = function (body) {
	switch (body.$) {
		case 'Empty':
			return $elm$json$Json$Encode$null;
		case 'Error':
			var err = body.a;
			return $elm$json$Json$Encode$string(err);
		case 'Text':
			var w = body.a;
			return $elm$json$Json$Encode$string(w);
		case 'Json':
			var j = body.a;
			return j;
		default:
			var v = body.b;
			return $elm$json$Json$Encode$string(v);
	}
};
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(_Utils_Tuple0),
			pairs));
};
var $author$project$Serverless$KeyValueList$encode = function (params) {
	return $elm$json$Json$Encode$object(
		A2(
			$elm$core$List$map,
			function (_v0) {
				var a = _v0.a;
				var b = _v0.b;
				return _Utils_Tuple2(
					a,
					$elm$json$Json$Encode$string(b));
			},
			$elm$core$List$reverse(params)));
};
var $elm$json$Json$Encode$int = _Json_wrap;
var $author$project$Serverless$Body$isBase64Encoded = function (body) {
	if (body.$ === 'Binary') {
		return true;
	} else {
		return false;
	}
};
var $author$project$Serverless$Response$encode = function (_v0) {
	var res = _v0.a;
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'body',
				$author$project$Serverless$Body$encode(res.body)),
				_Utils_Tuple2(
				'headers',
				$author$project$Serverless$KeyValueList$encode(
					_Utils_ap(
						res.headers,
						_List_fromArray(
							[
								_Utils_Tuple2(
								'content-type',
								$author$project$Serverless$Response$contentType(res))
							])))),
				_Utils_Tuple2(
				'statusCode',
				$elm$json$Json$Encode$int(res.status)),
				_Utils_Tuple2(
				'isBase64Encoded',
				$elm$json$Json$Encode$bool(
					$author$project$Serverless$Body$isBase64Encoded(res.body)))
			]));
};
var $author$project$Serverless$HttpServer$responseCmd = F3(
	function (protocol, _v0, response) {
		var session = _v0.a;
		return protocol.ports.response(
			{
				res: $author$project$Serverless$Response$encode(response),
				session: session
			});
	});
var $author$project$Serverless$HttpServer$httpServerApi = function (protocol) {
	return {
		request: $author$project$Serverless$HttpServer$requestSub(protocol),
		response: $author$project$Serverless$HttpServer$responseCmd(protocol)
	};
};
var $author$project$Ports$requestPort = _Platform_incomingPort(
	'requestPort',
	A2(
		$elm$json$Json$Decode$andThen,
		function (session) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (req) {
					return $elm$json$Json$Decode$succeed(
						{req: req, session: session});
				},
				A2($elm$json$Json$Decode$field, 'req', $elm$json$Json$Decode$value));
		},
		A2($elm$json$Json$Decode$field, 'session', $elm$json$Json$Decode$value)));
var $author$project$Ports$responsePort = _Platform_outgoingPort(
	'responsePort',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'res',
					$elm$core$Basics$identity($.res)),
					_Utils_Tuple2(
					'session',
					$elm$core$Basics$identity($.session))
				]));
	});
var $author$project$EventLog$Component$Channel = function (a) {
	return {$: 'Channel', a: a};
};
var $author$project$EventLog$Component$ChannelRoot = {$: 'ChannelRoot'};
var $elm$url$Url$Parser$Parser = function (a) {
	return {$: 'Parser', a: a};
};
var $elm$url$Url$Parser$State = F5(
	function (visited, unvisited, params, frag, value) {
		return {frag: frag, params: params, unvisited: unvisited, value: value, visited: visited};
	});
var $elm$url$Url$Parser$mapState = F2(
	function (func, _v0) {
		var visited = _v0.visited;
		var unvisited = _v0.unvisited;
		var params = _v0.params;
		var frag = _v0.frag;
		var value = _v0.value;
		return A5(
			$elm$url$Url$Parser$State,
			visited,
			unvisited,
			params,
			frag,
			func(value));
	});
var $elm$url$Url$Parser$map = F2(
	function (subValue, _v0) {
		var parseArg = _v0.a;
		return $elm$url$Url$Parser$Parser(
			function (_v1) {
				var visited = _v1.visited;
				var unvisited = _v1.unvisited;
				var params = _v1.params;
				var frag = _v1.frag;
				var value = _v1.value;
				return A2(
					$elm$core$List$map,
					$elm$url$Url$Parser$mapState(value),
					parseArg(
						A5($elm$url$Url$Parser$State, visited, unvisited, params, frag, subValue)));
			});
	});
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $elm$url$Url$Parser$oneOf = function (parsers) {
	return $elm$url$Url$Parser$Parser(
		function (state) {
			return A2(
				$elm$core$List$concatMap,
				function (_v0) {
					var parser = _v0.a;
					return parser(state);
				},
				parsers);
		});
};
var $elm$url$Url$Parser$getFirstMatch = function (states) {
	getFirstMatch:
	while (true) {
		if (!states.b) {
			return $elm$core$Maybe$Nothing;
		} else {
			var state = states.a;
			var rest = states.b;
			var _v1 = state.unvisited;
			if (!_v1.b) {
				return $elm$core$Maybe$Just(state.value);
			} else {
				if ((_v1.a === '') && (!_v1.b.b)) {
					return $elm$core$Maybe$Just(state.value);
				} else {
					var $temp$states = rest;
					states = $temp$states;
					continue getFirstMatch;
				}
			}
		}
	}
};
var $elm$url$Url$Parser$removeFinalEmpty = function (segments) {
	if (!segments.b) {
		return _List_Nil;
	} else {
		if ((segments.a === '') && (!segments.b.b)) {
			return _List_Nil;
		} else {
			var segment = segments.a;
			var rest = segments.b;
			return A2(
				$elm$core$List$cons,
				segment,
				$elm$url$Url$Parser$removeFinalEmpty(rest));
		}
	}
};
var $elm$url$Url$Parser$preparePath = function (path) {
	var _v0 = A2($elm$core$String$split, '/', path);
	if (_v0.b && (_v0.a === '')) {
		var segments = _v0.b;
		return $elm$url$Url$Parser$removeFinalEmpty(segments);
	} else {
		var segments = _v0;
		return $elm$url$Url$Parser$removeFinalEmpty(segments);
	}
};
var $elm$url$Url$Parser$addToParametersHelp = F2(
	function (value, maybeList) {
		if (maybeList.$ === 'Nothing') {
			return $elm$core$Maybe$Just(
				_List_fromArray(
					[value]));
		} else {
			var list = maybeList.a;
			return $elm$core$Maybe$Just(
				A2($elm$core$List$cons, value, list));
		}
	});
var $elm$url$Url$percentDecode = _Url_percentDecode;
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.e.d.$ === 'RBNode_elm_builtin') && (dict.e.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.d.d.$ === 'RBNode_elm_builtin') && (dict.d.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Black')) {
					if (right.d.$ === 'RBNode_elm_builtin') {
						if (right.d.a.$ === 'Black') {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor.$ === 'Black') {
			if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === 'RBNode_elm_builtin') {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Black')) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === 'RBNode_elm_builtin') {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBNode_elm_builtin') {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === 'RBNode_elm_builtin') {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$update = F3(
	function (targetKey, alter, dictionary) {
		var _v0 = alter(
			A2($elm$core$Dict$get, targetKey, dictionary));
		if (_v0.$ === 'Just') {
			var value = _v0.a;
			return A3($elm$core$Dict$insert, targetKey, value, dictionary);
		} else {
			return A2($elm$core$Dict$remove, targetKey, dictionary);
		}
	});
var $elm$url$Url$Parser$addParam = F2(
	function (segment, dict) {
		var _v0 = A2($elm$core$String$split, '=', segment);
		if ((_v0.b && _v0.b.b) && (!_v0.b.b.b)) {
			var rawKey = _v0.a;
			var _v1 = _v0.b;
			var rawValue = _v1.a;
			var _v2 = $elm$url$Url$percentDecode(rawKey);
			if (_v2.$ === 'Nothing') {
				return dict;
			} else {
				var key = _v2.a;
				var _v3 = $elm$url$Url$percentDecode(rawValue);
				if (_v3.$ === 'Nothing') {
					return dict;
				} else {
					var value = _v3.a;
					return A3(
						$elm$core$Dict$update,
						key,
						$elm$url$Url$Parser$addToParametersHelp(value),
						dict);
				}
			}
		} else {
			return dict;
		}
	});
var $elm$url$Url$Parser$prepareQuery = function (maybeQuery) {
	if (maybeQuery.$ === 'Nothing') {
		return $elm$core$Dict$empty;
	} else {
		var qry = maybeQuery.a;
		return A3(
			$elm$core$List$foldr,
			$elm$url$Url$Parser$addParam,
			$elm$core$Dict$empty,
			A2($elm$core$String$split, '&', qry));
	}
};
var $elm$url$Url$Parser$parse = F2(
	function (_v0, url) {
		var parser = _v0.a;
		return $elm$url$Url$Parser$getFirstMatch(
			parser(
				A5(
					$elm$url$Url$Parser$State,
					_List_Nil,
					$elm$url$Url$Parser$preparePath(url.path),
					$elm$url$Url$Parser$prepareQuery(url.query),
					url.fragment,
					$elm$core$Basics$identity)));
	});
var $elm$url$Url$Parser$s = function (str) {
	return $elm$url$Url$Parser$Parser(
		function (_v0) {
			var visited = _v0.visited;
			var unvisited = _v0.unvisited;
			var params = _v0.params;
			var frag = _v0.frag;
			var value = _v0.value;
			if (!unvisited.b) {
				return _List_Nil;
			} else {
				var next = unvisited.a;
				var rest = unvisited.b;
				return _Utils_eq(next, str) ? _List_fromArray(
					[
						A5(
						$elm$url$Url$Parser$State,
						A2($elm$core$List$cons, next, visited),
						rest,
						params,
						frag,
						value)
					]) : _List_Nil;
			}
		});
};
var $elm$url$Url$Parser$slash = F2(
	function (_v0, _v1) {
		var parseBefore = _v0.a;
		var parseAfter = _v1.a;
		return $elm$url$Url$Parser$Parser(
			function (state) {
				return A2(
					$elm$core$List$concatMap,
					parseAfter,
					parseBefore(state));
			});
	});
var $elm$url$Url$Parser$custom = F2(
	function (tipe, stringToSomething) {
		return $elm$url$Url$Parser$Parser(
			function (_v0) {
				var visited = _v0.visited;
				var unvisited = _v0.unvisited;
				var params = _v0.params;
				var frag = _v0.frag;
				var value = _v0.value;
				if (!unvisited.b) {
					return _List_Nil;
				} else {
					var next = unvisited.a;
					var rest = unvisited.b;
					var _v2 = stringToSomething(next);
					if (_v2.$ === 'Just') {
						var nextValue = _v2.a;
						return _List_fromArray(
							[
								A5(
								$elm$url$Url$Parser$State,
								A2($elm$core$List$cons, next, visited),
								rest,
								params,
								frag,
								value(nextValue))
							]);
					} else {
						return _List_Nil;
					}
				}
			});
	});
var $elm$url$Url$Parser$string = A2($elm$url$Url$Parser$custom, 'STRING', $elm$core$Maybe$Just);
var $author$project$EventLog$Component$routeParser = $elm$url$Url$Parser$parse(
	$elm$url$Url$Parser$oneOf(
		_List_fromArray(
			[
				A2(
				$elm$url$Url$Parser$map,
				$author$project$EventLog$Component$ChannelRoot,
				$elm$url$Url$Parser$s('channel')),
				A2(
				$elm$url$Url$Parser$map,
				$author$project$EventLog$Component$Channel,
				A2(
					$elm$url$Url$Parser$slash,
					$elm$url$Url$Parser$s('channel'),
					$elm$url$Url$Parser$string))
			])));
var $author$project$EventLog$Component$httpServerApi = $author$project$Serverless$HttpServer$httpServerApi(
	{
		parseRoute: $author$project$EventLog$Component$routeParser,
		ports: {request: $author$project$Ports$requestPort, response: $author$project$Ports$responsePort}
	});
var $author$project$EventLog$Component$ProcedureMsg = function (a) {
	return {$: 'ProcedureMsg', a: a};
};
var $author$project$Ports$mmAsyncError = _Platform_incomingPort(
	'mmAsyncError',
	A2(
		$elm$json$Json$Decode$andThen,
		function (id) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (error) {
					return $elm$json$Json$Decode$succeed(
						{error: error, id: id});
				},
				A2($elm$json$Json$Decode$field, 'error', $elm$json$Json$Decode$value));
		},
		A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string)));
var $author$project$Ports$mmClose = _Platform_outgoingPort(
	'mmClose',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'session',
					$elm$core$Basics$identity($.session))
				]));
	});
var $author$project$Ports$mmCreateWebhook = _Platform_outgoingPort(
	'mmCreateWebhook',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'name',
					$elm$json$Json$Encode$string($.name)),
					_Utils_Tuple2(
					'session',
					$elm$core$Basics$identity($.session)),
					_Utils_Tuple2(
					'topic',
					$elm$json$Json$Encode$string($.topic)),
					_Utils_Tuple2(
					'url',
					$elm$json$Json$Encode$string($.url))
				]));
	});
var $author$project$Ports$mmOnMessage = _Platform_incomingPort(
	'mmOnMessage',
	A2(
		$elm$json$Json$Decode$andThen,
		function (session) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (payload) {
					return A2(
						$elm$json$Json$Decode$andThen,
						function (id) {
							return $elm$json$Json$Decode$succeed(
								{id: id, payload: payload, session: session});
						},
						A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string));
				},
				A2($elm$json$Json$Decode$field, 'payload', $elm$json$Json$Decode$value));
		},
		A2($elm$json$Json$Decode$field, 'session', $elm$json$Json$Decode$value)));
var $author$project$Ports$mmOpen = _Platform_outgoingPort(
	'mmOpen',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'apiKey',
					$elm$json$Json$Encode$string($.apiKey)),
					_Utils_Tuple2(
					'cache',
					$elm$json$Json$Encode$string($.cache)),
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id))
				]));
	});
var $author$project$Ports$mmPopList = _Platform_outgoingPort(
	'mmPopList',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'list',
					$elm$json$Json$Encode$string($.list)),
					_Utils_Tuple2(
					'session',
					$elm$core$Basics$identity($.session))
				]));
	});
var $author$project$Ports$mmPublish = _Platform_outgoingPort(
	'mmPublish',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'payload',
					$elm$core$Basics$identity($.payload)),
					_Utils_Tuple2(
					'session',
					$elm$core$Basics$identity($.session)),
					_Utils_Tuple2(
					'topic',
					$elm$json$Json$Encode$string($.topic))
				]));
	});
var $author$project$Ports$mmPushList = _Platform_outgoingPort(
	'mmPushList',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'list',
					$elm$json$Json$Encode$string($.list)),
					_Utils_Tuple2(
					'payload',
					$elm$core$Basics$identity($.payload)),
					_Utils_Tuple2(
					'session',
					$elm$core$Basics$identity($.session))
				]));
	});
var $author$project$Ports$mmResponse = _Platform_incomingPort(
	'mmResponse',
	A2(
		$elm$json$Json$Decode$andThen,
		function (type_) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (response) {
					return A2(
						$elm$json$Json$Decode$andThen,
						function (id) {
							return $elm$json$Json$Decode$succeed(
								{id: id, response: response, type_: type_});
						},
						A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string));
				},
				A2($elm$json$Json$Decode$field, 'response', $elm$json$Json$Decode$value));
		},
		A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string)));
var $author$project$Ports$mmSubscribe = _Platform_outgoingPort(
	'mmSubscribe',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'session',
					$elm$core$Basics$identity($.session)),
					_Utils_Tuple2(
					'topic',
					$elm$json$Json$Encode$string($.topic))
				]));
	});
var $author$project$Momento$MomentoError = function (a) {
	return {$: 'MomentoError', a: a};
};
var $author$project$Momento$asyncError = F2(
	function (ports, dt) {
		return ports.asyncError(
			function (_v0) {
				var error = _v0.error;
				return dt(
					$author$project$Momento$MomentoError(
						{details: error, message: 'MomentoPorts Async Error'}));
			});
	});
var $author$project$Momento$MomentoSessionKey = function (a) {
	return {$: 'MomentoSessionKey', a: a};
};
var $elm$core$Debug$log = _Debug_log;
var $author$project$Momento$onMessage = F2(
	function (ports, dt) {
		return ports.onMessage(
			function (_v0) {
				var session = _v0.session;
				var payload = _v0.payload;
				var _v1 = A2($elm$core$Debug$log, 'Momento.onMessage', 'called');
				return A2(
					dt,
					$author$project$Momento$MomentoSessionKey(session),
					payload);
			});
	});
var $brian_watkins$elm_procedure$Procedure$Internal$Continue = {$: 'Continue'};
var $brian_watkins$elm_procedure$Procedure$Internal$Execute = F2(
	function (a, b) {
		return {$: 'Execute', a: a, b: b};
	});
var $brian_watkins$elm_procedure$Procedure$Internal$Procedure = function (a) {
	return {$: 'Procedure', a: a};
};
var $brian_watkins$elm_procedure$Procedure$Internal$Subscribe = F3(
	function (a, b, c) {
		return {$: 'Subscribe', a: a, b: b, c: c};
	});
var $brian_watkins$elm_procedure$Procedure$Internal$Unsubscribe = F3(
	function (a, b, c) {
		return {$: 'Unsubscribe', a: a, b: b, c: c};
	});
var $brian_watkins$elm_procedure$Procedure$Channel$channelKey = function (channelId) {
	return 'Channel-' + $elm$core$String$fromInt(channelId);
};
var $elm$core$Task$Perform = function (a) {
	return {$: 'Perform', a: a};
};
var $elm$core$Task$init = $elm$core$Task$succeed(_Utils_Tuple0);
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0.a;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return _Utils_Tuple0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(_Utils_Tuple0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0.a;
		return $elm$core$Task$Perform(
			A2($elm$core$Task$map, tagger, task));
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			$elm$core$Task$Perform(
				A2($elm$core$Task$map, toMessage, task)));
	});
var $brian_watkins$elm_procedure$Procedure$Channel$acceptUntil = F2(
	function (shouldUnsubscribe, _v0) {
		var channel = _v0.a;
		return $brian_watkins$elm_procedure$Procedure$Internal$Procedure(
			F3(
				function (procId, msgTagger, resultTagger) {
					var requestCommandMsg = function (channelId) {
						return A3(
							$elm$core$Basics$composeL,
							msgTagger,
							$brian_watkins$elm_procedure$Procedure$Internal$Execute(procId),
							channel.request(
								$brian_watkins$elm_procedure$Procedure$Channel$channelKey(channelId)));
					};
					var generateMsg = F2(
						function (channelId, aData) {
							return shouldUnsubscribe(aData) ? A3(
								$elm$core$Basics$composeL,
								msgTagger,
								A2($brian_watkins$elm_procedure$Procedure$Internal$Unsubscribe, procId, channelId),
								resultTagger(
									$elm$core$Result$Ok(aData))) : resultTagger(
								$elm$core$Result$Ok(aData));
						});
					var subGenerator = function (channelId) {
						return channel.subscription(
							function (aData) {
								return A2(
									channel.shouldAccept,
									$brian_watkins$elm_procedure$Procedure$Channel$channelKey(channelId),
									aData) ? A2(generateMsg, channelId, aData) : msgTagger($brian_watkins$elm_procedure$Procedure$Internal$Continue);
							});
					};
					return A2(
						$elm$core$Task$perform,
						A2(
							$elm$core$Basics$composeL,
							msgTagger,
							A2($brian_watkins$elm_procedure$Procedure$Internal$Subscribe, procId, requestCommandMsg)),
						$elm$core$Task$succeed(subGenerator));
				}));
	});
var $elm$core$Basics$always = F2(
	function (a, _v0) {
		return a;
	});
var $brian_watkins$elm_procedure$Procedure$Channel$acceptOne = $brian_watkins$elm_procedure$Procedure$Channel$acceptUntil(
	$elm$core$Basics$always(true));
var $brian_watkins$elm_procedure$Procedure$Channel$Channel = function (a) {
	return {$: 'Channel', a: a};
};
var $brian_watkins$elm_procedure$Procedure$Channel$defaultPredicate = F2(
	function (_v0, _v1) {
		return true;
	});
var $brian_watkins$elm_procedure$Procedure$Channel$connect = F2(
	function (generator, _v0) {
		var requestGenerator = _v0.a;
		return $brian_watkins$elm_procedure$Procedure$Channel$Channel(
			{request: requestGenerator, shouldAccept: $brian_watkins$elm_procedure$Procedure$Channel$defaultPredicate, subscription: generator});
	});
var $author$project$Momento$decodeResponse = function (res) {
	var _v0 = res.type_;
	switch (_v0) {
		case 'Ok':
			return $elm$core$Result$Ok(
				$author$project$Momento$MomentoSessionKey(res.response));
		case 'Error':
			return $elm$core$Result$Err(
				$author$project$Momento$MomentoError(
					{details: res.response, message: 'MomentoError'}));
		default:
			return $elm$core$Result$Err(
				$author$project$Momento$MomentoError(
					{details: $elm$json$Json$Encode$null, message: 'Momento Unknown response type: ' + res.type_}));
	}
};
var $brian_watkins$elm_procedure$Procedure$Channel$filter = F2(
	function (predicate, _v0) {
		var channel = _v0.a;
		return $brian_watkins$elm_procedure$Procedure$Channel$Channel(
			_Utils_update(
				channel,
				{shouldAccept: predicate}));
	});
var $brian_watkins$elm_procedure$Procedure$Channel$ChannelRequest = function (a) {
	return {$: 'ChannelRequest', a: a};
};
var $brian_watkins$elm_procedure$Procedure$Channel$open = $brian_watkins$elm_procedure$Procedure$Channel$ChannelRequest;
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0.a;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $brian_watkins$elm_procedure$Procedure$Internal$Initiate = function (a) {
	return {$: 'Initiate', a: a};
};
var $brian_watkins$elm_procedure$Procedure$try = F3(
	function (msgTagger, tagger, _v0) {
		var procedure = _v0.a;
		return A2(
			$elm$core$Task$perform,
			A2($elm$core$Basics$composeL, msgTagger, $brian_watkins$elm_procedure$Procedure$Internal$Initiate),
			$elm$core$Task$succeed(
				function (procId) {
					return A3(procedure, procId, msgTagger, tagger);
				}));
	});
var $brian_watkins$elm_procedure$Procedure$run = F2(
	function (msgTagger, tagger) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$try,
			msgTagger,
			function (result) {
				if (result.$ === 'Ok') {
					var data = result.a;
					return tagger(data);
				} else {
					var e = result.a;
					return $elm$core$Basics$never(e);
				}
			});
	});
var $author$project$Momento$open = F4(
	function (pt, ports, openParams, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (res) {
				return dt(
					$author$project$Momento$decodeResponse(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.open(
									{apiKey: openParams.apiKey, cache: openParams.cache, id: key});
							})))));
	});
var $author$project$Momento$decodeItemResponse = function (res) {
	var _v0 = res.type_;
	switch (_v0) {
		case 'Item':
			return $elm$core$Result$Ok(
				$elm$core$Maybe$Just(
					{payload: res.response}));
		case 'ItemNotFound':
			return $elm$core$Result$Ok($elm$core$Maybe$Nothing);
		case 'Error':
			return $elm$core$Result$Err(
				$author$project$Momento$MomentoError(
					{details: res.response, message: 'MomentoError'}));
		default:
			return $elm$core$Result$Err(
				$author$project$Momento$MomentoError(
					{details: $elm$json$Json$Encode$null, message: 'Momento Unknown response type: ' + res.type_}));
	}
};
var $author$project$Momento$popList = F5(
	function (pt, ports, _v0, _v1, dt) {
		var sessionKey = _v0.a;
		var list = _v1.list;
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (res) {
				return dt(
					$author$project$Momento$decodeItemResponse(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v2) {
							var id = _v2.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.popList(
									{id: key, list: list, session: sessionKey});
							})))));
	});
var $author$project$Momento$publish = F5(
	function (pt, ports, _v0, _v1, dt) {
		var sessionKey = _v0.a;
		var topic = _v1.topic;
		var payload = _v1.payload;
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (res) {
				return dt(
					$author$project$Momento$decodeResponse(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v2) {
							var id = _v2.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.publish(
									{id: key, payload: payload, session: sessionKey, topic: topic});
							})))));
	});
var $author$project$Momento$pushList = F5(
	function (pt, ports, _v0, _v1, dt) {
		var sessionKey = _v0.a;
		var list = _v1.list;
		var payload = _v1.payload;
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (res) {
				return dt(
					$author$project$Momento$decodeResponse(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v2) {
							var id = _v2.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.pushList(
									{id: key, list: list, payload: payload, session: sessionKey});
							})))));
	});
var $author$project$Momento$subscribe = F5(
	function (pt, ports, _v0, subscribeParams, dt) {
		var sessionKey = _v0.a;
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (res) {
				return dt(
					$author$project$Momento$decodeResponse(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v1) {
							var id = _v1.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.subscribe(
									{id: key, session: sessionKey, topic: subscribeParams.topic});
							})))));
	});
var $author$project$Momento$webhook = F5(
	function (pt, ports, _v0, _v1, dt) {
		var sessionKey = _v0.a;
		var name = _v1.name;
		var topic = _v1.topic;
		var url = _v1.url;
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (res) {
				return dt(
					$author$project$Momento$decodeResponse(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v2) {
							var id = _v2.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.createWebhook(
									{id: key, name: name, session: sessionKey, topic: topic, url: url});
							})))));
	});
var $author$project$Momento$momentoApi = F2(
	function (pt, ports) {
		return {
			asyncError: $author$project$Momento$asyncError(ports),
			onMessage: $author$project$Momento$onMessage(ports),
			open: A2($author$project$Momento$open, pt, ports),
			popList: A2($author$project$Momento$popList, pt, ports),
			publish: A2($author$project$Momento$publish, pt, ports),
			pushList: A2($author$project$Momento$pushList, pt, ports),
			subscribe: A2($author$project$Momento$subscribe, pt, ports),
			webhook: A2($author$project$Momento$webhook, pt, ports)
		};
	});
var $author$project$EventLog$Component$momentoApi = A2(
	$author$project$Momento$momentoApi,
	$author$project$EventLog$Component$ProcedureMsg,
	{asyncError: $author$project$Ports$mmAsyncError, close: $author$project$Ports$mmClose, createWebhook: $author$project$Ports$mmCreateWebhook, onMessage: $author$project$Ports$mmOnMessage, open: $author$project$Ports$mmOpen, popList: $author$project$Ports$mmPopList, publish: $author$project$Ports$mmPublish, pushList: $author$project$Ports$mmPushList, response: $author$project$Ports$mmResponse, subscribe: $author$project$Ports$mmSubscribe});
var $elm$core$Platform$Sub$none = $elm$core$Platform$Sub$batch(_List_Nil);
var $elm$core$Dict$values = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, valueList) {
				return A2($elm$core$List$cons, value, valueList);
			}),
		_List_Nil,
		dict);
};
var $brian_watkins$elm_procedure$Procedure$Program$subscriptions = function (_v0) {
	var registry = _v0.a;
	return $elm$core$Platform$Sub$batch(
		$elm$core$Dict$values(registry.channels));
};
var $author$project$EventLog$Component$subscriptions = F2(
	function (protocol, component) {
		var model = component.eventLog;
		if (model.$ === 'ModelReady') {
			var state = model.a;
			return A2(
				$elm$core$Platform$Sub$map,
				protocol.toMsg,
				$elm$core$Platform$Sub$batch(
					_List_fromArray(
						[
							$brian_watkins$elm_procedure$Procedure$Program$subscriptions(state.procedure),
							$author$project$EventLog$Component$httpServerApi.request($author$project$EventLog$Component$HttpRequest),
							$author$project$EventLog$Component$momentoApi.asyncError($author$project$EventLog$Component$MomentoError)
						])));
		} else {
			return $elm$core$Platform$Sub$none;
		}
	});
var $author$project$API$subscriptions = function (model) {
	return $elm$core$Platform$Sub$batch(
		_List_fromArray(
			[
				A2($author$project$EventLog$Component$subscriptions, $author$project$API$eventLogProtocol, model)
			]));
};
var $author$project$EventLog$Component$ModelReady = function (a) {
	return {$: 'ModelReady', a: a};
};
var $author$project$Serverless$Response$Model = F4(
	function (body, charset, headers, status) {
		return {body: body, charset: charset, headers: headers, status: status};
	});
var $author$project$Serverless$Response$Response = function (a) {
	return {$: 'Response', a: a};
};
var $author$project$Serverless$Body$empty = $author$project$Serverless$Body$Empty;
var $author$project$Serverless$Charset$Utf8 = {$: 'Utf8'};
var $author$project$Serverless$Charset$utf8 = $author$project$Serverless$Charset$Utf8;
var $author$project$Serverless$Response$init = $author$project$Serverless$Response$Response(
	A4(
		$author$project$Serverless$Response$Model,
		$author$project$Serverless$Body$empty,
		$author$project$Serverless$Charset$utf8,
		_List_fromArray(
			[
				_Utils_Tuple2('cache-control', 'max-age=0, private, must-revalidate')
			]),
		200));
var $author$project$Serverless$Response$setBody = F2(
	function (body, _v0) {
		var res = _v0.a;
		return $author$project$Serverless$Response$Response(
			_Utils_update(
				res,
				{body: body}));
	});
var $author$project$Serverless$Response$setStatus = F2(
	function (value, _v0) {
		var res = _v0.a;
		return $author$project$Serverless$Response$Response(
			_Utils_update(
				res,
				{status: value}));
	});
var $author$project$Serverless$Body$text = $author$project$Serverless$Body$Text;
var $author$project$Serverless$Response$err500 = function (err) {
	return A2(
		$author$project$Serverless$Response$setStatus,
		500,
		A2(
			$author$project$Serverless$Response$setBody,
			$author$project$Serverless$Body$text(err),
			$author$project$Serverless$Response$init));
};
var $author$project$Serverless$HttpServer$errorToString = function (error) {
	if (error.$ === 'NoMatchingRoute') {
		var url = error.a;
		return 'No matching route for: ' + url;
	} else {
		var decodeError = error.a;
		return 'Problem decoding the request: ' + $elm$json$Json$Decode$errorToString(decodeError);
	}
};
var $brian_watkins$elm_procedure$Procedure$Program$Model = function (a) {
	return {$: 'Model', a: a};
};
var $brian_watkins$elm_procedure$Procedure$Program$init = $brian_watkins$elm_procedure$Procedure$Program$Model(
	{channels: $elm$core$Dict$empty, nextId: 0});
var $elm$core$Tuple$mapFirst = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			func(x),
			y);
	});
var $elm_community$result_extra$Result$Extra$merge = function (r) {
	if (r.$ === 'Ok') {
		var rr = r.a;
		return rr;
	} else {
		var rr = r.a;
		return rr;
	}
};
var $author$project$EventLog$Component$HttpResponse = F2(
	function (a, b) {
		return {$: 'HttpResponse', a: a, b: b};
	});
var $elm$core$Task$fail = _Scheduler_fail;
var $elm$core$Task$onError = _Scheduler_onError;
var $elm$core$Task$attempt = F2(
	function (resultToMessage, task) {
		return $elm$core$Task$command(
			$elm$core$Task$Perform(
				A2(
					$elm$core$Task$onError,
					A2(
						$elm$core$Basics$composeL,
						A2($elm$core$Basics$composeL, $elm$core$Task$succeed, resultToMessage),
						$elm$core$Result$Err),
					A2(
						$elm$core$Task$andThen,
						A2(
							$elm$core$Basics$composeL,
							A2($elm$core$Basics$composeL, $elm$core$Task$succeed, resultToMessage),
							$elm$core$Result$Ok),
						task))));
	});
var $brian_watkins$elm_procedure$Procedure$fromTask = function (task) {
	return $brian_watkins$elm_procedure$Procedure$Internal$Procedure(
		F3(
			function (_v0, _v1, resultTagger) {
				return A2($elm$core$Task$attempt, resultTagger, task);
			}));
};
var $brian_watkins$elm_procedure$Procedure$break = A2($elm$core$Basics$composeL, $brian_watkins$elm_procedure$Procedure$fromTask, $elm$core$Task$fail);
var $brian_watkins$elm_procedure$Procedure$next = F2(
	function (_v0, resultMapper) {
		var procedure = _v0.a;
		return $brian_watkins$elm_procedure$Procedure$Internal$Procedure(
			F3(
				function (procId, msgTagger, tagger) {
					return A3(
						procedure,
						procId,
						msgTagger,
						function (aResult) {
							var _v1 = resultMapper(aResult);
							var nextProcedure = _v1.a;
							return A3(
								$elm$core$Basics$composeL,
								msgTagger,
								$brian_watkins$elm_procedure$Procedure$Internal$Execute(procId),
								A3(nextProcedure, procId, msgTagger, tagger));
						});
				}));
	});
var $brian_watkins$elm_procedure$Procedure$andThen = F2(
	function (generator, procedure) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$next,
			procedure,
			function (aResult) {
				if (aResult.$ === 'Ok') {
					var aData = aResult.a;
					return generator(aData);
				} else {
					var eData = aResult.a;
					return $brian_watkins$elm_procedure$Procedure$break(eData);
				}
			});
	});
var $author$project$EventLog$Component$encodeErrorFormat = function (error) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'message',
				$elm$json$Json$Encode$string(error.message)),
				_Utils_Tuple2('details', error.details)
			]));
};
var $miniBill$elm_codec$Codec$encoder = function (_v0) {
	var m = _v0.a;
	return m.encoder;
};
var $author$project$Serverless$Body$json = $author$project$Serverless$Body$Json;
var $author$project$Serverless$Response$err500json = function (err) {
	return A2(
		$author$project$Serverless$Response$setStatus,
		500,
		A2(
			$author$project$Serverless$Response$setBody,
			$author$project$Serverless$Body$json(err),
			$author$project$Serverless$Response$init));
};
var $brian_watkins$elm_procedure$Procedure$provide = A2($elm$core$Basics$composeL, $brian_watkins$elm_procedure$Procedure$fromTask, $elm$core$Task$succeed);
var $brian_watkins$elm_procedure$Procedure$map = function (mapper) {
	return $brian_watkins$elm_procedure$Procedure$andThen(
		A2($elm$core$Basics$composeL, $brian_watkins$elm_procedure$Procedure$provide, mapper));
};
var $brian_watkins$elm_procedure$Procedure$mapError = F2(
	function (mapper, procedure) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$next,
			procedure,
			function (aResult) {
				if (aResult.$ === 'Ok') {
					var aData = aResult.a;
					return $brian_watkins$elm_procedure$Procedure$provide(aData);
				} else {
					var eData = aResult.a;
					return $brian_watkins$elm_procedure$Procedure$break(
						mapper(eData));
				}
			});
	});
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $elm$random$Random$andThen = F2(
	function (callback, _v0) {
		var genA = _v0.a;
		return $elm$random$Random$Generator(
			function (seed) {
				var _v1 = genA(seed);
				var result = _v1.a;
				var newSeed = _v1.b;
				var _v2 = callback(result);
				var genB = _v2.a;
				return genB(newSeed);
			});
	});
var $elm$random$Random$float = F2(
	function (a, b) {
		return $elm$random$Random$Generator(
			function (seed0) {
				var seed1 = $elm$random$Random$next(seed0);
				var range = $elm$core$Basics$abs(b - a);
				var n1 = $elm$random$Random$peel(seed1);
				var n0 = $elm$random$Random$peel(seed0);
				var lo = (134217727 & n1) * 1.0;
				var hi = (67108863 & n0) * 1.0;
				var val = ((hi * 134217728.0) + lo) / 9007199254740992.0;
				var scaled = (val * range) + a;
				return _Utils_Tuple2(
					scaled,
					$elm$random$Random$next(seed1));
			});
	});
var $elm$core$Tuple$second = function (_v0) {
	var y = _v0.b;
	return y;
};
var $elm$core$List$sum = function (numbers) {
	return A3($elm$core$List$foldl, $elm$core$Basics$add, 0, numbers);
};
var $elm_community$random_extra$Random$Extra$frequency = F2(
	function (head, pairs) {
		var total = $elm$core$List$sum(
			A2(
				$elm$core$List$map,
				A2($elm$core$Basics$composeL, $elm$core$Basics$abs, $elm$core$Tuple$first),
				A2($elm$core$List$cons, head, pairs)));
		var pick = F2(
			function (someChoices, n) {
				pick:
				while (true) {
					if (someChoices.b) {
						var _v1 = someChoices.a;
						var k = _v1.a;
						var g = _v1.b;
						var rest = someChoices.b;
						if (_Utils_cmp(n, k) < 1) {
							return g;
						} else {
							var $temp$someChoices = rest,
								$temp$n = n - k;
							someChoices = $temp$someChoices;
							n = $temp$n;
							continue pick;
						}
					} else {
						return head.b;
					}
				}
			});
		return A2(
			$elm$random$Random$andThen,
			pick(
				A2($elm$core$List$cons, head, pairs)),
			A2($elm$random$Random$float, 0, total));
	});
var $elm_community$random_extra$Random$Extra$choices = F2(
	function (hd, gens) {
		return A2(
			$elm_community$random_extra$Random$Extra$frequency,
			_Utils_Tuple2(1, hd),
			A2(
				$elm$core$List$map,
				function (g) {
					return _Utils_Tuple2(1, g);
				},
				gens));
	});
var $elm$core$Char$fromCode = _Char_fromCode;
var $elm_community$random_extra$Random$Char$char = F2(
	function (start, end) {
		return A2(
			$elm$random$Random$map,
			$elm$core$Char$fromCode,
			A2($elm$random$Random$int, start, end));
	});
var $elm_community$random_extra$Random$Char$lowerCaseLatin = A2($elm_community$random_extra$Random$Char$char, 97, 122);
var $elm_community$random_extra$Random$Char$upperCaseLatin = A2($elm_community$random_extra$Random$Char$char, 65, 90);
var $elm_community$random_extra$Random$Char$latin = A2(
	$elm_community$random_extra$Random$Extra$choices,
	$elm_community$random_extra$Random$Char$lowerCaseLatin,
	_List_fromArray(
		[$elm_community$random_extra$Random$Char$upperCaseLatin]));
var $elm_community$random_extra$Random$Char$english = $elm_community$random_extra$Random$Char$latin;
var $elm$core$String$fromList = _String_fromList;
var $elm$random$Random$listHelp = F4(
	function (revList, n, gen, seed) {
		listHelp:
		while (true) {
			if (n < 1) {
				return _Utils_Tuple2(revList, seed);
			} else {
				var _v0 = gen(seed);
				var value = _v0.a;
				var newSeed = _v0.b;
				var $temp$revList = A2($elm$core$List$cons, value, revList),
					$temp$n = n - 1,
					$temp$gen = gen,
					$temp$seed = newSeed;
				revList = $temp$revList;
				n = $temp$n;
				gen = $temp$gen;
				seed = $temp$seed;
				continue listHelp;
			}
		}
	});
var $elm$random$Random$list = F2(
	function (n, _v0) {
		var gen = _v0.a;
		return $elm$random$Random$Generator(
			function (seed) {
				return A4($elm$random$Random$listHelp, _List_Nil, n, gen, seed);
			});
	});
var $elm_community$random_extra$Random$String$string = F2(
	function (stringLength, charGenerator) {
		return A2(
			$elm$random$Random$map,
			$elm$core$String$fromList,
			A2($elm$random$Random$list, stringLength, charGenerator));
	});
var $author$project$EventLog$Component$nameGenerator = A2($elm_community$random_extra$Random$String$string, 10, $elm_community$random_extra$Random$Char$english);
var $author$project$Serverless$Response$ok200json = function (msg) {
	return A2(
		$author$project$Serverless$Response$setBody,
		$author$project$Serverless$Body$json(msg),
		$author$project$Serverless$Response$init);
};
var $author$project$EventLog$Component$cacheName = function (channel) {
	return 'elm-realtime' + '-cache';
};
var $author$project$Momento$errorToDetails = function (_v0) {
	var err = _v0.a;
	return err;
};
var $brian_watkins$elm_procedure$Procedure$fetchResult = function (generator) {
	return $brian_watkins$elm_procedure$Procedure$Internal$Procedure(
		F3(
			function (_v0, _v1, tagger) {
				return generator(tagger);
			}));
};
var $author$project$EventLog$Component$openMomentoCache = F2(
	function (component, channelName) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$mapError,
			$author$project$Momento$errorToDetails,
			$brian_watkins$elm_procedure$Procedure$fetchResult(
				$author$project$EventLog$Component$momentoApi.open(
					{
						apiKey: component.momentoApiKey,
						cache: $author$project$EventLog$Component$cacheName(channelName)
					})));
	});
var $author$project$Ports$dynamoBatchGet = _Platform_outgoingPort(
	'dynamoBatchGet',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$Ports$dynamoBatchWrite = _Platform_outgoingPort(
	'dynamoBatchWrite',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$Ports$dynamoDelete = _Platform_outgoingPort(
	'dynamoDelete',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$Ports$dynamoGet = _Platform_outgoingPort(
	'dynamoGet',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$Ports$dynamoPut = _Platform_outgoingPort(
	'dynamoPut',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$Ports$dynamoQuery = _Platform_outgoingPort(
	'dynamoQuery',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$Ports$dynamoResponse = _Platform_incomingPort(
	'dynamoResponse',
	A2(
		$elm$json$Json$Decode$andThen,
		function (res) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (id) {
					return $elm$json$Json$Decode$succeed(
						{id: id, res: res});
				},
				A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string));
		},
		A2($elm$json$Json$Decode$field, 'res', $elm$json$Json$Decode$value)));
var $author$project$Ports$dynamoScan = _Platform_outgoingPort(
	'dynamoScan',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$Ports$dynamoUpdate = _Platform_outgoingPort(
	'dynamoUpdate',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$Ports$dynamoWriteTx = _Platform_outgoingPort(
	'dynamoWriteTx',
	function ($) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'id',
					$elm$json$Json$Encode$string($.id)),
					_Utils_Tuple2(
					'req',
					$elm$core$Basics$identity($.req))
				]));
	});
var $author$project$EventLog$Component$dynamoPorts = {batchGet: $author$project$Ports$dynamoBatchGet, batchWrite: $author$project$Ports$dynamoBatchWrite, _delete: $author$project$Ports$dynamoDelete, get: $author$project$Ports$dynamoGet, put: $author$project$Ports$dynamoPut, query: $author$project$Ports$dynamoQuery, response: $author$project$Ports$dynamoResponse, scan: $author$project$Ports$dynamoScan, update: $author$project$Ports$dynamoUpdate, writeTx: $author$project$Ports$dynamoWriteTx};
var $miniBill$elm_codec$Codec$decoder = function (_v0) {
	var m = _v0.a;
	return m.decoder;
};
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(_Utils_Tuple0),
				entries));
	});
var $author$project$AWS$Dynamo$batchGetEncoder = F2(
	function (encoder, getOp) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'RequestItems',
					$elm$json$Json$Encode$object(
						_List_fromArray(
							[
								_Utils_Tuple2(
								getOp.tableName,
								$elm$json$Json$Encode$object(
									_List_fromArray(
										[
											_Utils_Tuple2(
											'Keys',
											A2($elm$json$Json$Encode$list, encoder, getOp.keys))
										])))
							])))
				]));
	});
var $author$project$AWS$Dynamo$DecodeError = function (a) {
	return {$: 'DecodeError', a: a};
};
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $author$project$AWS$Dynamo$ConditionCheckFailed = function (a) {
	return {$: 'ConditionCheckFailed', a: a};
};
var $author$project$AWS$Dynamo$Error = function (a) {
	return {$: 'Error', a: a};
};
var $elm_community$json_extra$Json$Decode$Extra$andMap = $elm$json$Json$Decode$map2($elm$core$Basics$apR);
var $author$project$AWS$Dynamo$errorDecoder = A2(
	$elm$json$Json$Decode$andThen,
	function (details) {
		return A2(
			$elm$json$Json$Decode$andThen,
			function (type_) {
				if (type_ === 'ConditionCheckFailed') {
					return $elm$json$Json$Decode$succeed(
						$elm$core$Result$Err(
							$author$project$AWS$Dynamo$ConditionCheckFailed(details)));
				} else {
					return $elm$json$Json$Decode$succeed(
						$elm$core$Result$Err(
							$author$project$AWS$Dynamo$Error(details)));
				}
			},
			A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
	},
	A2(
		$elm_community$json_extra$Json$Decode$Extra$andMap,
		A2($elm$json$Json$Decode$field, 'details', $elm$json$Json$Decode$value),
		A2(
			$elm_community$json_extra$Json$Decode$Extra$andMap,
			A2($elm$json$Json$Decode$field, 'message', $elm$json$Json$Decode$string),
			$elm$json$Json$Decode$succeed(
				F2(
					function (message, details) {
						return {details: details, message: message};
					})))));
var $elm$json$Json$Decode$list = _Json_decodeList;
var $author$project$AWS$Dynamo$batchGetResponseDecoder = F3(
	function (valDecoder, tableName, val) {
		var decoder = A2(
			$elm$json$Json$Decode$andThen,
			function (type_) {
				if (type_ === 'Item') {
					return A2(
						$elm$json$Json$Decode$map,
						$elm$core$Result$Ok,
						A2(
							$elm$json$Json$Decode$at,
							_List_fromArray(
								['item', 'Responses', tableName]),
							$elm$json$Json$Decode$list(valDecoder)));
				} else {
					return $author$project$AWS$Dynamo$errorDecoder;
				}
			},
			A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
		return $elm_community$result_extra$Result$Extra$merge(
			A2(
				$elm$core$Result$mapError,
				A2($elm$core$Basics$composeR, $author$project$AWS$Dynamo$DecodeError, $elm$core$Result$Err),
				A2($elm$json$Json$Decode$decodeValue, decoder, val)));
	});
var $author$project$AWS$Dynamo$batchGet = F6(
	function (pt, ports, encoder, decoder, batchGetProps, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v1) {
				var res = _v1.res;
				return dt(
					A3($author$project$AWS$Dynamo$batchGetResponseDecoder, decoder, batchGetProps.tableName, res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.batchWrite(
									{
										id: key,
										req: A2(
											$author$project$AWS$Dynamo$batchGetEncoder,
											encoder,
											{keys: batchGetProps.keys, tableName: batchGetProps.tableName})
									});
							})))));
	});
var $author$project$AWS$Dynamo$batchPutEncoder = F2(
	function (encoder, putOp) {
		var encodeItem = function (item) {
			return $elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'PutRequest',
						$elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'Item',
									encoder(item))
								])))
					]));
		};
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'RequestItems',
					$elm$json$Json$Encode$object(
						_List_fromArray(
							[
								_Utils_Tuple2(
								putOp.tableName,
								A2($elm$json$Json$Encode$list, encodeItem, putOp.items))
							])))
				]));
	});
var $author$project$AWS$Dynamo$batchPutResponseDecoder = function (val) {
	var decoder = A2(
		$elm$json$Json$Decode$andThen,
		function (type_) {
			if (type_ === 'Ok') {
				return $elm$json$Json$Decode$succeed(
					$elm$core$Result$Ok(_Utils_Tuple0));
			} else {
				return $author$project$AWS$Dynamo$errorDecoder;
			}
		},
		A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
	return $elm_community$result_extra$Result$Extra$merge(
		A2(
			$elm$core$Result$mapError,
			A2($elm$core$Basics$composeR, $author$project$AWS$Dynamo$DecodeError, $elm$core$Result$Err),
			A2($elm$json$Json$Decode$decodeValue, decoder, val)));
};
var $elm$core$List$drop = F2(
	function (n, list) {
		drop:
		while (true) {
			if (n <= 0) {
				return list;
			} else {
				if (!list.b) {
					return list;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs;
					n = $temp$n;
					list = $temp$list;
					continue drop;
				}
			}
		}
	});
var $elm$core$List$takeReverse = F3(
	function (n, list, kept) {
		takeReverse:
		while (true) {
			if (n <= 0) {
				return kept;
			} else {
				if (!list.b) {
					return kept;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs,
						$temp$kept = A2($elm$core$List$cons, x, kept);
					n = $temp$n;
					list = $temp$list;
					kept = $temp$kept;
					continue takeReverse;
				}
			}
		}
	});
var $elm$core$List$takeTailRec = F2(
	function (n, list) {
		return $elm$core$List$reverse(
			A3($elm$core$List$takeReverse, n, list, _List_Nil));
	});
var $elm$core$List$takeFast = F3(
	function (ctr, n, list) {
		if (n <= 0) {
			return _List_Nil;
		} else {
			var _v0 = _Utils_Tuple2(n, list);
			_v0$1:
			while (true) {
				_v0$5:
				while (true) {
					if (!_v0.b.b) {
						return list;
					} else {
						if (_v0.b.b.b) {
							switch (_v0.a) {
								case 1:
									break _v0$1;
								case 2:
									var _v2 = _v0.b;
									var x = _v2.a;
									var _v3 = _v2.b;
									var y = _v3.a;
									return _List_fromArray(
										[x, y]);
								case 3:
									if (_v0.b.b.b.b) {
										var _v4 = _v0.b;
										var x = _v4.a;
										var _v5 = _v4.b;
										var y = _v5.a;
										var _v6 = _v5.b;
										var z = _v6.a;
										return _List_fromArray(
											[x, y, z]);
									} else {
										break _v0$5;
									}
								default:
									if (_v0.b.b.b.b && _v0.b.b.b.b.b) {
										var _v7 = _v0.b;
										var x = _v7.a;
										var _v8 = _v7.b;
										var y = _v8.a;
										var _v9 = _v8.b;
										var z = _v9.a;
										var _v10 = _v9.b;
										var w = _v10.a;
										var tl = _v10.b;
										return (ctr > 1000) ? A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A2($elm$core$List$takeTailRec, n - 4, tl))))) : A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A3($elm$core$List$takeFast, ctr + 1, n - 4, tl)))));
									} else {
										break _v0$5;
									}
							}
						} else {
							if (_v0.a === 1) {
								break _v0$1;
							} else {
								break _v0$5;
							}
						}
					}
				}
				return list;
			}
			var _v1 = _v0.b;
			var x = _v1.a;
			return _List_fromArray(
				[x]);
		}
	});
var $elm$core$List$take = F2(
	function (n, list) {
		return A3($elm$core$List$takeFast, 0, n, list);
	});
var $author$project$AWS$Dynamo$batchPutInner = F4(
	function (ports, encoder, table, vals) {
		var remainder = A2($elm$core$List$drop, 25, vals);
		var firstBatch = A2($elm$core$List$take, 25, vals);
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (_v1) {
				var id = _v1.id;
				var res = _v1.res;
				var _v2 = $author$project$AWS$Dynamo$batchPutResponseDecoder(res);
				if (_v2.$ === 'Ok') {
					if (!remainder.b) {
						return $brian_watkins$elm_procedure$Procedure$provide(
							_Utils_Tuple2(
								id,
								$elm$core$Result$Ok(_Utils_Tuple0)));
					} else {
						var moreItems = remainder;
						return A4($author$project$AWS$Dynamo$batchPutInner, ports, encoder, table, moreItems);
					}
				} else {
					var err = _v2.a;
					return $brian_watkins$elm_procedure$Procedure$provide(
						_Utils_Tuple2(
							id,
							$elm$core$Result$Err(err)));
				}
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.batchWrite(
									{
										id: key,
										req: A2(
											$author$project$AWS$Dynamo$batchPutEncoder,
											encoder,
											{items: firstBatch, tableName: table})
									});
							})))));
	});
var $author$project$AWS$Dynamo$batchPut = F5(
	function (pt, ports, encoder, batchPutProps, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v0) {
				var res = _v0.b;
				return dt(res);
			},
			A4($author$project$AWS$Dynamo$batchPutInner, ports, encoder, batchPutProps.tableName, batchPutProps.items));
	});
var $author$project$AWS$Dynamo$deleteEncoder = F2(
	function (encoder, deleteOp) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'TableName',
					$elm$json$Json$Encode$string(deleteOp.tableName)),
					_Utils_Tuple2(
					'Key',
					encoder(deleteOp.key))
				]));
	});
var $author$project$AWS$Dynamo$deleteResponseDecoder = function (val) {
	var decoder = A2(
		$elm$json$Json$Decode$andThen,
		function (type_) {
			if (type_ === 'Ok') {
				return $elm$json$Json$Decode$succeed(
					$elm$core$Result$Ok(_Utils_Tuple0));
			} else {
				return $author$project$AWS$Dynamo$errorDecoder;
			}
		},
		A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
	return $elm_community$result_extra$Result$Extra$merge(
		A2(
			$elm$core$Result$mapError,
			A2($elm$core$Basics$composeR, $author$project$AWS$Dynamo$DecodeError, $elm$core$Result$Err),
			A2($elm$json$Json$Decode$decodeValue, decoder, val)));
};
var $author$project$AWS$Dynamo$delete = F5(
	function (pt, ports, encoder, deleteProps, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v1) {
				var res = _v1.res;
				return dt(
					$author$project$AWS$Dynamo$deleteResponseDecoder(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports._delete(
									{
										id: key,
										req: A2($author$project$AWS$Dynamo$deleteEncoder, encoder, deleteProps)
									});
							})))));
	});
var $author$project$AWS$Dynamo$getEncoder = F2(
	function (encoder, getOp) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'TableName',
					$elm$json$Json$Encode$string(getOp.tableName)),
					_Utils_Tuple2(
					'Key',
					encoder(getOp.key))
				]));
	});
var $author$project$AWS$Dynamo$getResponseDecoder = F2(
	function (valDecoder, val) {
		var decoder = A2(
			$elm$json$Json$Decode$andThen,
			function (type_) {
				switch (type_) {
					case 'Item':
						return A2(
							$elm$json$Json$Decode$map,
							A2($elm$core$Basics$composeR, $elm$core$Maybe$Just, $elm$core$Result$Ok),
							A2(
								$elm$json$Json$Decode$at,
								_List_fromArray(
									['item', 'Item']),
								valDecoder));
					case 'ItemNotFound':
						return $elm$json$Json$Decode$succeed(
							$elm$core$Result$Ok($elm$core$Maybe$Nothing));
					default:
						return $author$project$AWS$Dynamo$errorDecoder;
				}
			},
			A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
		return $elm_community$result_extra$Result$Extra$merge(
			A2(
				$elm$core$Result$mapError,
				A2($elm$core$Basics$composeR, $author$project$AWS$Dynamo$DecodeError, $elm$core$Result$Err),
				A2($elm$json$Json$Decode$decodeValue, decoder, val)));
	});
var $author$project$AWS$Dynamo$get = F6(
	function (pt, ports, encoder, decoder, getProps, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v1) {
				var res = _v1.res;
				return dt(
					A2($author$project$AWS$Dynamo$getResponseDecoder, decoder, res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.get(
									{
										id: key,
										req: A2($author$project$AWS$Dynamo$getEncoder, encoder, getProps)
									});
							})))));
	});
var $author$project$AWS$Dynamo$putEncoder = F2(
	function (encoder, putOp) {
		return $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'TableName',
					$elm$json$Json$Encode$string(putOp.tableName)),
					_Utils_Tuple2(
					'Item',
					encoder(putOp.item))
				]));
	});
var $author$project$AWS$Dynamo$putResponseDecoder = function (val) {
	var decoder = A2(
		$elm$json$Json$Decode$andThen,
		function (type_) {
			if (type_ === 'Ok') {
				return $elm$json$Json$Decode$succeed(
					$elm$core$Result$Ok(_Utils_Tuple0));
			} else {
				return $author$project$AWS$Dynamo$errorDecoder;
			}
		},
		A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
	return $elm_community$result_extra$Result$Extra$merge(
		A2(
			$elm$core$Result$mapError,
			A2($elm$core$Basics$composeR, $author$project$AWS$Dynamo$DecodeError, $elm$core$Result$Err),
			A2($elm$json$Json$Decode$decodeValue, decoder, val)));
};
var $author$project$AWS$Dynamo$put = F5(
	function (pt, ports, encoder, putProps, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v1) {
				var res = _v1.res;
				return dt(
					$author$project$AWS$Dynamo$putResponseDecoder(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.put(
									{
										id: key,
										req: A2($author$project$AWS$Dynamo$putEncoder, encoder, putProps)
									});
							})))));
	});
var $author$project$AWS$Dynamo$nextPage = F2(
	function (lastEvalKey, q) {
		return _Utils_update(
			q,
			{
				exclusiveStartKey: $elm$core$Maybe$Just(lastEvalKey)
			});
	});
var $author$project$AWS$Dynamo$Equals = F2(
	function (a, b) {
		return {$: 'Equals', a: a, b: b};
	});
var $author$project$AWS$Dynamo$encodeAttr = function (attr) {
	if (attr.$ === 'StringAttr') {
		var val = attr.a;
		return $elm$json$Json$Encode$string(val);
	} else {
		var val = attr.a;
		return $elm$json$Json$Encode$int(val);
	}
};
var $elm$core$List$unzip = function (pairs) {
	var step = F2(
		function (_v0, _v1) {
			var x = _v0.a;
			var y = _v0.b;
			var xs = _v1.a;
			var ys = _v1.b;
			return _Utils_Tuple2(
				A2($elm$core$List$cons, x, xs),
				A2($elm$core$List$cons, y, ys));
		});
	return A3(
		$elm$core$List$foldr,
		step,
		_Utils_Tuple2(_List_Nil, _List_Nil),
		pairs);
};
var $author$project$AWS$Dynamo$keyConditionAsStringAndAttrs = function (keyConditions) {
	var encodeKeyConditions = F2(
		function (index, keyCondition) {
			var attrName = ':attr' + $elm$core$String$fromInt(index);
			switch (keyCondition.$) {
				case 'Equals':
					var field = keyCondition.a;
					var attr = keyCondition.b;
					return _Utils_Tuple2(
						field + (' = ' + attrName),
						_List_fromArray(
							[
								_Utils_Tuple2(
								attrName,
								$author$project$AWS$Dynamo$encodeAttr(attr))
							]));
				case 'LessThan':
					var field = keyCondition.a;
					var attr = keyCondition.b;
					return _Utils_Tuple2(
						field + (' < ' + attrName),
						_List_fromArray(
							[
								_Utils_Tuple2(
								attrName,
								$author$project$AWS$Dynamo$encodeAttr(attr))
							]));
				case 'LessThenOrEqual':
					var field = keyCondition.a;
					var attr = keyCondition.b;
					return _Utils_Tuple2(
						field + (' <= ' + attrName),
						_List_fromArray(
							[
								_Utils_Tuple2(
								attrName,
								$author$project$AWS$Dynamo$encodeAttr(attr))
							]));
				case 'GreaterThan':
					var field = keyCondition.a;
					var attr = keyCondition.b;
					return _Utils_Tuple2(
						field + (' > ' + attrName),
						_List_fromArray(
							[
								_Utils_Tuple2(
								attrName,
								$author$project$AWS$Dynamo$encodeAttr(attr))
							]));
				case 'GreaterThanOrEqual':
					var field = keyCondition.a;
					var attr = keyCondition.b;
					return _Utils_Tuple2(
						field + (' >= ' + attrName),
						_List_fromArray(
							[
								_Utils_Tuple2(
								attrName,
								$author$project$AWS$Dynamo$encodeAttr(attr))
							]));
				default:
					var field = keyCondition.a;
					var lowAttr = keyCondition.b;
					var highAttr = keyCondition.c;
					var lowAttrName = ':lowattr' + $elm$core$String$fromInt(index);
					var highAttrName = ':highattr' + $elm$core$String$fromInt(index);
					return _Utils_Tuple2(
						field + (' BETWEEN ' + (lowAttrName + (' AND ' + highAttrName))),
						_List_fromArray(
							[
								_Utils_Tuple2(
								lowAttrName,
								$author$project$AWS$Dynamo$encodeAttr(lowAttr)),
								_Utils_Tuple2(
								highAttrName,
								$author$project$AWS$Dynamo$encodeAttr(highAttr))
							]));
			}
		});
	return A2(
		$elm$core$Tuple$mapSecond,
		$elm$core$List$concat,
		A2(
			$elm$core$Tuple$mapFirst,
			$elm$core$String$join(' AND '),
			$elm$core$List$unzip(
				A2($elm$core$List$indexedMap, encodeKeyConditions, keyConditions))));
};
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm_community$maybe_extra$Maybe$Extra$cons = F2(
	function (item, list) {
		if (item.$ === 'Just') {
			var v = item.a;
			return A2($elm$core$List$cons, v, list);
		} else {
			return list;
		}
	});
var $elm_community$maybe_extra$Maybe$Extra$values = A2($elm$core$List$foldr, $elm_community$maybe_extra$Maybe$Extra$cons, _List_Nil);
var $author$project$AWS$Dynamo$queryEncoder = F3(
	function (table, maybeIndex, q) {
		var _v0 = $author$project$AWS$Dynamo$keyConditionAsStringAndAttrs(
			$elm_community$maybe_extra$Maybe$Extra$values(
				_List_fromArray(
					[
						$elm$core$Maybe$Just(
						A2($author$project$AWS$Dynamo$Equals, q.partitionKeyName, q.partitionKeyValue)),
						q.rangeKeyCondition
					])));
		var keyExpressionsString = _v0.a;
		var attrVals = _v0.b;
		var encodedAttrVals = $elm$json$Json$Encode$object(attrVals);
		return $elm$json$Json$Encode$object(
			$elm_community$maybe_extra$Maybe$Extra$values(
				_List_fromArray(
					[
						$elm$core$Maybe$Just(
						_Utils_Tuple2(
							'TableName',
							$elm$json$Json$Encode$string(table))),
						A2(
						$elm$core$Maybe$map,
						function (index) {
							return _Utils_Tuple2(
								'IndexName',
								$elm$json$Json$Encode$string(index));
						},
						maybeIndex),
						$elm$core$Maybe$Just(
						_Utils_Tuple2(
							'KeyConditionExpression',
							$elm$json$Json$Encode$string(keyExpressionsString))),
						$elm$core$Maybe$Just(
						_Utils_Tuple2('ExpressionAttributeValues', encodedAttrVals)),
						function () {
						var _v1 = q.order;
						if (_v1.$ === 'Forward') {
							return $elm$core$Maybe$Just(
								_Utils_Tuple2(
									'ScanIndexForward',
									$elm$json$Json$Encode$bool(true)));
						} else {
							return $elm$core$Maybe$Just(
								_Utils_Tuple2(
									'ScanIndexForward',
									$elm$json$Json$Encode$bool(false)));
						}
					}(),
						A2(
						$elm$core$Maybe$map,
						function (limit) {
							return _Utils_Tuple2(
								'Limit',
								$elm$json$Json$Encode$int(limit));
						},
						q.limit),
						A2(
						$elm$core$Maybe$map,
						function (exclusiveStartKey) {
							return _Utils_Tuple2('ExclusiveStartKey', exclusiveStartKey);
						},
						q.exclusiveStartKey)
					])));
	});
var $elm$core$Tuple$pair = F2(
	function (a, b) {
		return _Utils_Tuple2(a, b);
	});
var $author$project$AWS$Dynamo$queryResponseDecoder = F2(
	function (valDecoder, val) {
		var decoder = A2(
			$elm$json$Json$Decode$andThen,
			function (type_) {
				if (type_ === 'Items') {
					return A3(
						$elm$json$Json$Decode$map2,
						F2(
							function (lastKey, vals) {
								return $elm$core$Result$Ok(
									A2($elm$core$Tuple$pair, lastKey, vals));
							}),
						$elm$json$Json$Decode$maybe(
							A2($elm$json$Json$Decode$field, 'lastEvaluatedKey', $elm$json$Json$Decode$value)),
						A2(
							$elm$json$Json$Decode$field,
							'items',
							$elm$json$Json$Decode$list(valDecoder)));
				} else {
					return $author$project$AWS$Dynamo$errorDecoder;
				}
			},
			A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
		return $elm_community$result_extra$Result$Extra$merge(
			A2(
				$elm$core$Result$mapError,
				A2($elm$core$Basics$composeR, $author$project$AWS$Dynamo$DecodeError, $elm$core$Result$Err),
				A2($elm$json$Json$Decode$decodeValue, decoder, val)));
	});
var $author$project$AWS$Dynamo$queryInner = F6(
	function (ports, decoder, table, maybeIndex, q, accum) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (_v1) {
				var id = _v1.id;
				var res = _v1.res;
				var _v2 = A2($author$project$AWS$Dynamo$queryResponseDecoder, decoder, res);
				if (_v2.$ === 'Ok') {
					if (_v2.a.a.$ === 'Nothing') {
						var _v3 = _v2.a;
						var _v4 = _v3.a;
						var items = _v3.b;
						return $brian_watkins$elm_procedure$Procedure$provide(
							_Utils_Tuple2(
								id,
								$elm$core$Result$Ok(items)));
					} else {
						var _v5 = _v2.a;
						var lastEvaluatedKey = _v5.a.a;
						var items = _v5.b;
						return A6(
							$author$project$AWS$Dynamo$queryInner,
							ports,
							decoder,
							table,
							maybeIndex,
							A2($author$project$AWS$Dynamo$nextPage, lastEvaluatedKey, q),
							_Utils_ap(accum, items));
					}
				} else {
					var err = _v2.a;
					return $brian_watkins$elm_procedure$Procedure$provide(
						_Utils_Tuple2(
							id,
							$elm$core$Result$Err(err)));
				}
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.query(
									{
										id: key,
										req: A3($author$project$AWS$Dynamo$queryEncoder, table, maybeIndex, q)
									});
							})))));
	});
var $author$project$AWS$Dynamo$query = F5(
	function (pt, ports, decoder, qry, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v0) {
				var res = _v0.b;
				return dt(res);
			},
			A6($author$project$AWS$Dynamo$queryInner, ports, decoder, qry.tableName, $elm$core$Maybe$Nothing, qry.match, _List_Nil));
	});
var $author$project$AWS$Dynamo$queryIndex = F5(
	function (pt, ports, decoder, qry, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v0) {
				var res = _v0.b;
				return dt(res);
			},
			A6(
				$author$project$AWS$Dynamo$queryInner,
				ports,
				decoder,
				qry.tableName,
				$elm$core$Maybe$Just(qry.indexName),
				qry.match,
				_List_Nil));
	});
var $author$project$AWS$Dynamo$scanEncoder = function (scanProps) {
	return $elm$json$Json$Encode$object(
		$elm_community$maybe_extra$Maybe$Extra$values(
			_List_fromArray(
				[
					$elm$core$Maybe$Just(
					_Utils_Tuple2(
						'TableName',
						$elm$json$Json$Encode$string(scanProps.tableName))),
					A2(
					$elm$core$Maybe$map,
					function (exclusiveStartKey) {
						return _Utils_Tuple2('ExclusiveStartKey', exclusiveStartKey);
					},
					scanProps.exclusiveStartKey)
				])));
};
var $author$project$AWS$Dynamo$scanInner = F4(
	function (ports, decoder, scanProps, accum) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (_v1) {
				var id = _v1.id;
				var res = _v1.res;
				var _v2 = A2($author$project$AWS$Dynamo$queryResponseDecoder, decoder, res);
				if (_v2.$ === 'Ok') {
					if (_v2.a.a.$ === 'Nothing') {
						var _v3 = _v2.a;
						var _v4 = _v3.a;
						var items = _v3.b;
						return $brian_watkins$elm_procedure$Procedure$provide(
							_Utils_Tuple2(
								id,
								$elm$core$Result$Ok(items)));
					} else {
						var _v5 = _v2.a;
						var lastEvaluatedKey = _v5.a.a;
						var items = _v5.b;
						return A4(
							$author$project$AWS$Dynamo$scanInner,
							ports,
							decoder,
							A2($author$project$AWS$Dynamo$nextPage, lastEvaluatedKey, scanProps),
							_Utils_ap(accum, items));
					}
				} else {
					var err = _v2.a;
					return $brian_watkins$elm_procedure$Procedure$provide(
						_Utils_Tuple2(
							id,
							$elm$core$Result$Err(err)));
				}
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.scan(
									{
										id: key,
										req: $author$project$AWS$Dynamo$scanEncoder(scanProps)
									});
							})))));
	});
var $author$project$AWS$Dynamo$scan = F5(
	function (pt, ports, decoder, scanProps, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v0) {
				var res = _v0.b;
				return dt(res);
			},
			A4($author$project$AWS$Dynamo$scanInner, ports, decoder, scanProps, _List_Nil));
	});
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$json$Json$Encode$dict = F3(
	function (toKey, toValue, dictionary) {
		return _Json_wrap(
			A3(
				$elm$core$Dict$foldl,
				F3(
					function (key, value, obj) {
						return A3(
							_Json_addField,
							toKey(key),
							toValue(value),
							obj);
					}),
				_Json_emptyObject(_Utils_Tuple0),
				dictionary));
	});
var $author$project$AWS$Dynamo$encodeReturnConsumedCapacity = function (arg) {
	if (arg.$ === 'CapacityIndexes') {
		return $elm$json$Json$Encode$string('INDEXES');
	} else {
		return $elm$json$Json$Encode$string('TOTAL');
	}
};
var $author$project$AWS$Dynamo$encodeReturnItemCollectionMetrics = function (arg) {
	return $elm$json$Json$Encode$string('SIZE');
};
var $author$project$AWS$Dynamo$encodeReturnValues = function (arg) {
	switch (arg.$) {
		case 'ReturnValuesAllOld':
			return $elm$json$Json$Encode$string('ALL_OLD');
		case 'ReturnValuesUpdatedOld':
			return $elm$json$Json$Encode$string('UPDATED_OLD');
		case 'ReturnValuesAllNew':
			return $elm$json$Json$Encode$string('ALL_NEW');
		default:
			return $elm$json$Json$Encode$string('UPDATED_NEW');
	}
};
var $author$project$AWS$Dynamo$encodeReturnValuesOnConditionCheckFailure = function (arg) {
	return $elm$json$Json$Encode$string('ALL_OLD');
};
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (_v0.$ === 'Just') {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $elm$core$Dict$isEmpty = function (dict) {
	if (dict.$ === 'RBEmpty_elm_builtin') {
		return true;
	} else {
		return false;
	}
};
var $author$project$AWS$Dynamo$updateEncoder = F2(
	function (encoder, putOp) {
		return $elm$json$Json$Encode$object(
			A2(
				$elm$core$List$filterMap,
				$elm$core$Basics$identity,
				_List_fromArray(
					[
						$elm$core$Maybe$Just(
						_Utils_Tuple2(
							'TableName',
							$elm$json$Json$Encode$string(putOp.tableName))),
						$elm$core$Maybe$Just(
						_Utils_Tuple2(
							'Key',
							encoder(putOp.key))),
						$elm$core$Maybe$Just(
						_Utils_Tuple2(
							'UpdateExpression',
							$elm$json$Json$Encode$string(putOp.updateExpression))),
						A2(
						$elm$core$Maybe$map,
						function (ce) {
							return _Utils_Tuple2(
								'ConditionExpression',
								$elm$json$Json$Encode$string(ce));
						},
						putOp.conditionExpression),
						function () {
						var _v0 = $elm$core$Dict$isEmpty(putOp.expressionAttributeNames);
						if (!_v0) {
							return $elm$core$Maybe$Just(
								_Utils_Tuple2(
									'ExpressionAttributeNames',
									A3($elm$json$Json$Encode$dict, $elm$core$Basics$identity, $elm$json$Json$Encode$string, putOp.expressionAttributeNames)));
						} else {
							return $elm$core$Maybe$Nothing;
						}
					}(),
						function () {
						var _v1 = $elm$core$Dict$isEmpty(putOp.expressionAttributeValues);
						if (!_v1) {
							return $elm$core$Maybe$Just(
								_Utils_Tuple2(
									'ExpressionAttributeValues',
									A3($elm$json$Json$Encode$dict, $elm$core$Basics$identity, $author$project$AWS$Dynamo$encodeAttr, putOp.expressionAttributeValues)));
						} else {
							return $elm$core$Maybe$Nothing;
						}
					}(),
						A2(
						$elm$core$Maybe$map,
						function (rcc) {
							return _Utils_Tuple2(
								'ReturnConsumedCapacity',
								$author$project$AWS$Dynamo$encodeReturnConsumedCapacity(rcc));
						},
						putOp.returnConsumedCapacity),
						A2(
						$elm$core$Maybe$map,
						function (rcm) {
							return _Utils_Tuple2(
								'ReturnItemCollectionMetrics',
								$author$project$AWS$Dynamo$encodeReturnItemCollectionMetrics(rcm));
						},
						putOp.returnItemCollectionMetrics),
						A2(
						$elm$core$Maybe$map,
						function (rv) {
							return _Utils_Tuple2(
								'ReturnValues',
								$author$project$AWS$Dynamo$encodeReturnValues(rv));
						},
						putOp.returnValues),
						A2(
						$elm$core$Maybe$map,
						function (rvcf) {
							return _Utils_Tuple2(
								'ReturnValuesOnConditionCheckFailure',
								$author$project$AWS$Dynamo$encodeReturnValuesOnConditionCheckFailure(rvcf));
						},
						putOp.returnValuesOnConditionCheckFailure)
					])));
	});
var $author$project$AWS$Dynamo$updateResponseDecoder = F2(
	function (valDecoder, val) {
		var decoder = A2(
			$elm$json$Json$Decode$andThen,
			function (type_) {
				switch (type_) {
					case 'Ok':
						return $elm$json$Json$Decode$succeed(
							$elm$core$Result$Ok($elm$core$Maybe$Nothing));
					case 'Item':
						return A2(
							$elm$json$Json$Decode$map,
							A2($elm$core$Basics$composeR, $elm$core$Maybe$Just, $elm$core$Result$Ok),
							A2(
								$elm$json$Json$Decode$at,
								_List_fromArray(
									['item', 'Item']),
								valDecoder));
					default:
						return $author$project$AWS$Dynamo$errorDecoder;
				}
			},
			A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
		return $elm_community$result_extra$Result$Extra$merge(
			A2(
				$elm$core$Result$mapError,
				A2($elm$core$Basics$composeR, $author$project$AWS$Dynamo$DecodeError, $elm$core$Result$Err),
				A2($elm$json$Json$Decode$decodeValue, decoder, val)));
	});
var $author$project$AWS$Dynamo$update = F6(
	function (pt, ports, encoder, decoder, updateProps, dt) {
		var _v0 = A2(
			$elm$core$Debug$log,
			'Dynamo.update',
			A2(
				$elm$json$Json$Encode$encode,
				2,
				A2($author$project$AWS$Dynamo$updateEncoder, encoder, updateProps)));
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v2) {
				var res = _v2.res;
				return dt(
					A2($author$project$AWS$Dynamo$updateResponseDecoder, decoder, res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v1) {
							var id = _v1.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.update(
									{
										id: key,
										req: A2($author$project$AWS$Dynamo$updateEncoder, encoder, updateProps)
									});
							})))));
	});
var $author$project$AWS$Dynamo$writeTxEncoder = function (writeTxOp) {
	var encoder = function (writeCommand) {
		switch (writeCommand.$) {
			case 'PutCommand':
				var v = writeCommand.a;
				return $elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2('Put', v)
						]));
			case 'UpdateCommand':
				var v = writeCommand.a;
				return $elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2('Update', v)
						]));
			default:
				var v = writeCommand.a;
				return $elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2('Delete', v)
						]));
		}
	};
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'TableName',
				$elm$json$Json$Encode$string(writeTxOp.tableName)),
				_Utils_Tuple2(
				'TransactItems',
				A2($elm$json$Json$Encode$list, encoder, writeTxOp.commands))
			]));
};
var $author$project$AWS$Dynamo$writeTxResponseDecoder = function (val) {
	var decoder = A2(
		$elm$json$Json$Decode$andThen,
		function (type_) {
			if (type_ === 'Ok') {
				return $elm$json$Json$Decode$succeed(
					$elm$core$Result$Ok(_Utils_Tuple0));
			} else {
				return $author$project$AWS$Dynamo$errorDecoder;
			}
		},
		A2($elm$json$Json$Decode$field, 'type_', $elm$json$Json$Decode$string));
	return $elm_community$result_extra$Result$Extra$merge(
		A2(
			$elm$core$Result$mapError,
			A2($elm$core$Basics$composeR, $author$project$AWS$Dynamo$DecodeError, $elm$core$Result$Err),
			A2($elm$json$Json$Decode$decodeValue, decoder, val)));
};
var $author$project$AWS$Dynamo$writeTx = F4(
	function (pt, ports, writeTxProps, dt) {
		return A3(
			$brian_watkins$elm_procedure$Procedure$run,
			pt,
			function (_v1) {
				var res = _v1.res;
				return dt(
					$author$project$AWS$Dynamo$writeTxResponseDecoder(res));
			},
			$brian_watkins$elm_procedure$Procedure$Channel$acceptOne(
				A2(
					$brian_watkins$elm_procedure$Procedure$Channel$filter,
					F2(
						function (key, _v0) {
							var id = _v0.id;
							return _Utils_eq(id, key);
						}),
					A2(
						$brian_watkins$elm_procedure$Procedure$Channel$connect,
						ports.response,
						$brian_watkins$elm_procedure$Procedure$Channel$open(
							function (key) {
								return ports.writeTx(
									{
										id: key,
										req: $author$project$AWS$Dynamo$writeTxEncoder(writeTxProps)
									});
							})))));
	});
var $author$project$AWS$Dynamo$dynamoTypedApi = F5(
	function (keyEncoder, valEncoder, decoder, pt, ports) {
		return {
			batchGet: A4($author$project$AWS$Dynamo$batchGet, pt, ports, keyEncoder, decoder),
			batchPut: A3($author$project$AWS$Dynamo$batchPut, pt, ports, valEncoder),
			_delete: A3($author$project$AWS$Dynamo$delete, pt, ports, keyEncoder),
			get: A4($author$project$AWS$Dynamo$get, pt, ports, keyEncoder, decoder),
			put: A3($author$project$AWS$Dynamo$put, pt, ports, valEncoder),
			query: A3($author$project$AWS$Dynamo$query, pt, ports, decoder),
			queryIndex: A3($author$project$AWS$Dynamo$queryIndex, pt, ports, decoder),
			scan: A3($author$project$AWS$Dynamo$scan, pt, ports, decoder),
			update: A4($author$project$AWS$Dynamo$update, pt, ports, keyEncoder, decoder),
			writeTx: A2($author$project$AWS$Dynamo$writeTx, pt, ports)
		};
	});
var $author$project$DB$ChannelTable$encodeKey = function (key) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$string(key.id))
			]));
};
var $author$project$DB$ChannelTable$Record = F6(
	function (id, updatedAt, modelTopic, saveTopic, saveList, webhook) {
		return {id: id, modelTopic: modelTopic, saveList: saveList, saveTopic: saveTopic, updatedAt: updatedAt, webhook: webhook};
	});
var $miniBill$elm_codec$Codec$Codec = function (a) {
	return {$: 'Codec', a: a};
};
var $miniBill$elm_codec$Codec$buildObject = function (_v0) {
	var om = _v0.a;
	return $miniBill$elm_codec$Codec$Codec(
		{
			decoder: om.decoder,
			encoder: function (v) {
				return $elm$json$Json$Encode$object(
					$elm$core$List$reverse(
						om.encoder(v)));
			}
		});
};
var $miniBill$elm_codec$Codec$ObjectCodec = function (a) {
	return {$: 'ObjectCodec', a: a};
};
var $miniBill$elm_codec$Codec$field = F4(
	function (name, getter, codec, _v0) {
		var ocodec = _v0.a;
		return $miniBill$elm_codec$Codec$ObjectCodec(
			{
				decoder: A3(
					$elm$json$Json$Decode$map2,
					F2(
						function (f, x) {
							return f(x);
						}),
					ocodec.decoder,
					A2(
						$elm$json$Json$Decode$field,
						name,
						$miniBill$elm_codec$Codec$decoder(codec))),
				encoder: function (v) {
					return A2(
						$elm$core$List$cons,
						_Utils_Tuple2(
							name,
							A2(
								$miniBill$elm_codec$Codec$encoder,
								codec,
								getter(v))),
						ocodec.encoder(v));
				},
				fields: A2($elm$core$List$cons, name, ocodec.fields)
			});
	});
var $miniBill$elm_codec$Codec$object = function (ctor) {
	return $miniBill$elm_codec$Codec$ObjectCodec(
		{
			decoder: $elm$json$Json$Decode$succeed(ctor),
			encoder: function (_v0) {
				return _List_Nil;
			},
			fields: _List_Nil
		});
};
var $miniBill$elm_codec$Codec$build = F2(
	function (encoder_, decoder_) {
		return $miniBill$elm_codec$Codec$Codec(
			{decoder: decoder_, encoder: encoder_});
	});
var $author$project$DB$ChannelTable$posixCodec = A2(
	$miniBill$elm_codec$Codec$build,
	function (timestamp) {
		return $elm$json$Json$Encode$int(
			$elm$time$Time$posixToMillis(timestamp));
	},
	A2($elm$json$Json$Decode$map, $elm$time$Time$millisToPosix, $elm$json$Json$Decode$int));
var $miniBill$elm_codec$Codec$string = A2($miniBill$elm_codec$Codec$build, $elm$json$Json$Encode$string, $elm$json$Json$Decode$string);
var $author$project$DB$ChannelTable$recordCodec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'webhook',
		function ($) {
			return $.webhook;
		},
		$miniBill$elm_codec$Codec$string,
		A4(
			$miniBill$elm_codec$Codec$field,
			'saveList',
			function ($) {
				return $.saveList;
			},
			$miniBill$elm_codec$Codec$string,
			A4(
				$miniBill$elm_codec$Codec$field,
				'saveTopic',
				function ($) {
					return $.saveTopic;
				},
				$miniBill$elm_codec$Codec$string,
				A4(
					$miniBill$elm_codec$Codec$field,
					'modelTopic',
					function ($) {
						return $.modelTopic;
					},
					$miniBill$elm_codec$Codec$string,
					A4(
						$miniBill$elm_codec$Codec$field,
						'updatedAt',
						function ($) {
							return $.updatedAt;
						},
						$author$project$DB$ChannelTable$posixCodec,
						A4(
							$miniBill$elm_codec$Codec$field,
							'id',
							function ($) {
								return $.id;
							},
							$miniBill$elm_codec$Codec$string,
							$miniBill$elm_codec$Codec$object($author$project$DB$ChannelTable$Record))))))));
var $author$project$DB$ChannelTable$operations = A3(
	$author$project$AWS$Dynamo$dynamoTypedApi,
	$author$project$DB$ChannelTable$encodeKey,
	$miniBill$elm_codec$Codec$encoder($author$project$DB$ChannelTable$recordCodec),
	$miniBill$elm_codec$Codec$decoder($author$project$DB$ChannelTable$recordCodec));
var $author$project$EventLog$Component$channelTableApi = A2($author$project$DB$ChannelTable$operations, $author$project$EventLog$Component$ProcedureMsg, $author$project$EventLog$Component$dynamoPorts);
var $author$project$AWS$Dynamo$errorToDetails = function (error) {
	switch (error.$) {
		case 'Error':
			var message = error.a.message;
			var details = error.a.details;
			return {details: details, message: message};
		case 'ConditionCheckFailed':
			var message = error.a.message;
			var details = error.a.details;
			return {details: details, message: message};
		default:
			var err = error.a;
			return {
				details: $elm$json$Json$Encode$null,
				message: $elm$json$Json$Decode$errorToString(err)
			};
	}
};
var $author$project$EventLog$Component$modelTopicName = function (channel) {
	return channel + '-modeltopic';
};
var $author$project$EventLog$Component$notifyTopicName = function (channel) {
	return channel + '-savetopic';
};
var $author$project$EventLog$Component$saveListName = function (channel) {
	return channel + '-savelist';
};
var $author$project$EventLog$Component$webhookName = function (channel) {
	return channel + '-webhook';
};
var $author$project$EventLog$Component$recordChannel = F3(
	function (component, channelName, sessionKey) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (timestamp) {
				var channelRecord = {
					id: channelName,
					modelTopic: $author$project$EventLog$Component$modelTopicName(channelName),
					saveList: $author$project$EventLog$Component$saveListName(channelName),
					saveTopic: $author$project$EventLog$Component$notifyTopicName(channelName),
					updatedAt: timestamp,
					webhook: $author$project$EventLog$Component$webhookName(channelName)
				};
				return A2(
					$brian_watkins$elm_procedure$Procedure$mapError,
					$author$project$AWS$Dynamo$errorToDetails,
					A2(
						$brian_watkins$elm_procedure$Procedure$map,
						$elm$core$Basics$always(channelRecord),
						$brian_watkins$elm_procedure$Procedure$fetchResult(
							$author$project$EventLog$Component$channelTableApi.put(
								{item: channelRecord, tableName: component.channelTable}))));
			},
			$brian_watkins$elm_procedure$Procedure$fromTask($elm$time$Time$now));
	});
var $author$project$DB$EventLogTable$encodeKey = function (key) {
	return $elm$json$Json$Encode$object(
		_List_fromArray(
			[
				_Utils_Tuple2(
				'id',
				$elm$json$Json$Encode$string(key.id)),
				_Utils_Tuple2(
				'seq',
				$elm$json$Json$Encode$int(key.seq))
			]));
};
var $author$project$DB$EventLogTable$MetadataRecord = F4(
	function (id, seq, updatedAt, lastId) {
		return {id: id, lastId: lastId, seq: seq, updatedAt: updatedAt};
	});
var $miniBill$elm_codec$Codec$int = A2($miniBill$elm_codec$Codec$build, $elm$json$Json$Encode$int, $elm$json$Json$Decode$int);
var $author$project$DB$EventLogTable$posixCodec = A2(
	$miniBill$elm_codec$Codec$build,
	function (timestamp) {
		return $elm$json$Json$Encode$int(
			$elm$time$Time$posixToMillis(timestamp));
	},
	A2($elm$json$Json$Decode$map, $elm$time$Time$millisToPosix, $elm$json$Json$Decode$int));
var $author$project$DB$EventLogTable$metadataRecordCodec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'lastId',
		function ($) {
			return $.lastId;
		},
		$miniBill$elm_codec$Codec$int,
		A4(
			$miniBill$elm_codec$Codec$field,
			'updatedAt',
			function ($) {
				return $.updatedAt;
			},
			$author$project$DB$EventLogTable$posixCodec,
			A4(
				$miniBill$elm_codec$Codec$field,
				'seq',
				function ($) {
					return $.seq;
				},
				$miniBill$elm_codec$Codec$int,
				A4(
					$miniBill$elm_codec$Codec$field,
					'id',
					function ($) {
						return $.id;
					},
					$miniBill$elm_codec$Codec$string,
					$miniBill$elm_codec$Codec$object($author$project$DB$EventLogTable$MetadataRecord))))));
var $author$project$DB$EventLogTable$metadataOperations = A3(
	$author$project$AWS$Dynamo$dynamoTypedApi,
	$author$project$DB$EventLogTable$encodeKey,
	$miniBill$elm_codec$Codec$encoder($author$project$DB$EventLogTable$metadataRecordCodec),
	$miniBill$elm_codec$Codec$decoder($author$project$DB$EventLogTable$metadataRecordCodec));
var $author$project$EventLog$Component$eventLogTableMetadataApi = A2($author$project$DB$EventLogTable$metadataOperations, $author$project$EventLog$Component$ProcedureMsg, $author$project$EventLog$Component$dynamoPorts);
var $author$project$EventLog$Component$metadataKeyName = function (channel) {
	return channel + '-metadata';
};
var $author$project$EventLog$Component$recordEventsLogMetaData = F3(
	function (component, channelName, sessionKey) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (timestamp) {
				var metadataRecord = {
					id: $author$project$EventLog$Component$metadataKeyName(channelName),
					lastId: 0,
					seq: 0,
					updatedAt: timestamp
				};
				return A2(
					$brian_watkins$elm_procedure$Procedure$mapError,
					$author$project$AWS$Dynamo$errorToDetails,
					A2(
						$brian_watkins$elm_procedure$Procedure$map,
						$elm$core$Basics$always(sessionKey),
						$brian_watkins$elm_procedure$Procedure$fetchResult(
							$author$project$EventLog$Component$eventLogTableMetadataApi.put(
								{item: metadataRecord, tableName: component.eventLogTable}))));
			},
			$brian_watkins$elm_procedure$Procedure$fromTask($elm$time$Time$now));
	});
var $author$project$EventLog$Component$setModel = F2(
	function (m, x) {
		return _Utils_update(
			m,
			{eventLog: x});
	});
var $author$project$EventLog$Component$setupChannelWebhook = F3(
	function (component, channelName, sessionKey) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$mapError,
			$author$project$Momento$errorToDetails,
			$brian_watkins$elm_procedure$Procedure$fetchResult(
				A2(
					$author$project$EventLog$Component$momentoApi.webhook,
					sessionKey,
					{
						name: $author$project$EventLog$Component$webhookName(channelName),
						topic: $author$project$EventLog$Component$notifyTopicName(channelName),
						url: component.channelApiUrl + ('/v1/channel/' + channelName)
					})));
	});
var $author$project$EventLog$Component$createChannel = F4(
	function (protocol, session, state, component) {
		var _v0 = A2($elm$random$Random$step, $author$project$EventLog$Component$nameGenerator, state.seed);
		var channelName = _v0.a;
		var nextSeed = _v0.b;
		var procedure = A2(
			$brian_watkins$elm_procedure$Procedure$map,
			A2(
				$elm$core$Basics$composeR,
				$miniBill$elm_codec$Codec$encoder($author$project$DB$ChannelTable$recordCodec),
				$author$project$Serverless$Response$ok200json),
			A2(
				$brian_watkins$elm_procedure$Procedure$mapError,
				A2($elm$core$Basics$composeR, $author$project$EventLog$Component$encodeErrorFormat, $author$project$Serverless$Response$err500json),
				A2(
					$brian_watkins$elm_procedure$Procedure$andThen,
					A2($author$project$EventLog$Component$recordChannel, component, channelName),
					A2(
						$brian_watkins$elm_procedure$Procedure$andThen,
						A2($author$project$EventLog$Component$recordEventsLogMetaData, component, channelName),
						A2(
							$brian_watkins$elm_procedure$Procedure$andThen,
							A2($author$project$EventLog$Component$setupChannelWebhook, component, channelName),
							A2(
								$brian_watkins$elm_procedure$Procedure$andThen,
								$author$project$EventLog$Component$openMomentoCache(component),
								$brian_watkins$elm_procedure$Procedure$provide(channelName)))))));
		return protocol.onUpdate(
			A2(
				$elm$core$Tuple$mapSecond,
				$elm$core$Platform$Cmd$map(protocol.toMsg),
				A2(
					$elm$core$Tuple$mapFirst,
					$author$project$EventLog$Component$setModel(component),
					A2(
						$the_sett$elm_update_helper$Update2$andMap,
						$author$project$EventLog$Component$switchState($author$project$EventLog$Component$ModelReady),
						_Utils_Tuple2(
							{procedure: state.procedure, seed: nextSeed},
							A3(
								$brian_watkins$elm_procedure$Procedure$try,
								$author$project$EventLog$Component$ProcedureMsg,
								$author$project$EventLog$Component$HttpResponse(session),
								procedure))))));
	});
var $author$project$Serverless$Request$method = function (_v0) {
	var request = _v0.a;
	return request.method;
};
var $author$project$EventLog$Component$publishEvent = F3(
	function (component, channelName, state) {
		var payload = $elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'rt',
					$elm$json$Json$Encode$string('P')),
					_Utils_Tuple2(
					'client',
					$elm$json$Json$Encode$string(state.unsavedEvent.client)),
					_Utils_Tuple2(
					'seq',
					$elm$json$Json$Encode$int(state.lastSeqNo)),
					_Utils_Tuple2('payload', state.unsavedEvent.payload)
				]));
		return A2(
			$brian_watkins$elm_procedure$Procedure$mapError,
			$author$project$Momento$errorToDetails,
			A2(
				$brian_watkins$elm_procedure$Procedure$map,
				$elm$core$Basics$always(_Utils_Tuple0),
				$brian_watkins$elm_procedure$Procedure$fetchResult(
					A2(
						$author$project$EventLog$Component$momentoApi.publish,
						state.sessionKey,
						{
							payload: payload,
							topic: $author$project$EventLog$Component$modelTopicName(channelName)
						}))));
	});
var $author$project$EventLog$Component$getEventsLogMetaData = F3(
	function (component, channelName, state) {
		var key = {
			id: $author$project$EventLog$Component$metadataKeyName(channelName),
			seq: 0
		};
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (maybeMetaData) {
				if (maybeMetaData.$ === 'Just') {
					var metadata = maybeMetaData.a;
					return $brian_watkins$elm_procedure$Procedure$provide(
						{lastSeqNo: metadata.lastId, sessionKey: state.sessionKey, unsavedEvent: state.unsavedEvent});
				} else {
					return $brian_watkins$elm_procedure$Procedure$break(
						{details: $elm$json$Json$Encode$null, message: 'No EventLog metadata record found for channel: ' + channelName});
				}
			},
			A2(
				$brian_watkins$elm_procedure$Procedure$mapError,
				$author$project$AWS$Dynamo$errorToDetails,
				$brian_watkins$elm_procedure$Procedure$fetchResult(
					$author$project$EventLog$Component$eventLogTableMetadataApi.get(
						{key: key, tableName: component.eventLogTable}))));
	});
var $brian_watkins$elm_procedure$Procedure$catch = F2(
	function (generator, procedure) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$next,
			procedure,
			function (aResult) {
				if (aResult.$ === 'Ok') {
					var aData = aResult.a;
					return $brian_watkins$elm_procedure$Procedure$provide(aData);
				} else {
					var eData = aResult.a;
					return generator(eData);
				}
			});
	});
var $author$project$DB$EventLogTable$Record = F4(
	function (id, seq, updatedAt, event) {
		return {event: event, id: id, seq: seq, updatedAt: updatedAt};
	});
var $miniBill$elm_codec$Codec$value = $miniBill$elm_codec$Codec$Codec(
	{decoder: $elm$json$Json$Decode$value, encoder: $elm$core$Basics$identity});
var $author$project$DB$EventLogTable$recordCodec = $miniBill$elm_codec$Codec$buildObject(
	A4(
		$miniBill$elm_codec$Codec$field,
		'event',
		function ($) {
			return $.event;
		},
		$miniBill$elm_codec$Codec$value,
		A4(
			$miniBill$elm_codec$Codec$field,
			'updatedAt',
			function ($) {
				return $.updatedAt;
			},
			$author$project$DB$EventLogTable$posixCodec,
			A4(
				$miniBill$elm_codec$Codec$field,
				'seq',
				function ($) {
					return $.seq;
				},
				$miniBill$elm_codec$Codec$int,
				A4(
					$miniBill$elm_codec$Codec$field,
					'id',
					function ($) {
						return $.id;
					},
					$miniBill$elm_codec$Codec$string,
					$miniBill$elm_codec$Codec$object($author$project$DB$EventLogTable$Record))))));
var $author$project$DB$EventLogTable$encodeRecord = $miniBill$elm_codec$Codec$encoder($author$project$DB$EventLogTable$recordCodec);
var $author$project$AWS$Dynamo$NumberAttr = function (a) {
	return {$: 'NumberAttr', a: a};
};
var $author$project$AWS$Dynamo$int = function (val) {
	return $author$project$AWS$Dynamo$NumberAttr(val);
};
var $author$project$AWS$Dynamo$PutCommand = function (a) {
	return {$: 'PutCommand', a: a};
};
var $author$project$AWS$Dynamo$putCommand = F2(
	function (encoder, putProps) {
		return $author$project$AWS$Dynamo$PutCommand(
			A2($author$project$AWS$Dynamo$putEncoder, encoder, putProps));
	});
var $author$project$AWS$Dynamo$UpdateCommand = function (a) {
	return {$: 'UpdateCommand', a: a};
};
var $author$project$AWS$Dynamo$updateCommand = F2(
	function (encoder, updateProps) {
		return $author$project$AWS$Dynamo$UpdateCommand(
			A2($author$project$AWS$Dynamo$updateEncoder, encoder, updateProps));
	});
var $author$project$EventLog$Component$recordEventsAndMetadata = F3(
	function (component, channelName, state) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (timestamp) {
				var seqUpdate = A2(
					$author$project$AWS$Dynamo$updateCommand,
					$author$project$DB$EventLogTable$encodeKey,
					{
						conditionExpression: $elm$core$Maybe$Just('lastId = :current_id'),
						expressionAttributeNames: $elm$core$Dict$empty,
						expressionAttributeValues: $elm$core$Dict$fromList(
							_List_fromArray(
								[
									_Utils_Tuple2(
									':incr',
									$author$project$AWS$Dynamo$int(1)),
									_Utils_Tuple2(
									':current_id',
									$author$project$AWS$Dynamo$int(state.lastSeqNo))
								])),
						key: {
							id: $author$project$EventLog$Component$metadataKeyName(channelName),
							seq: 0
						},
						returnConsumedCapacity: $elm$core$Maybe$Nothing,
						returnItemCollectionMetrics: $elm$core$Maybe$Nothing,
						returnValues: $elm$core$Maybe$Nothing,
						returnValuesOnConditionCheckFailure: $elm$core$Maybe$Nothing,
						tableName: component.eventLogTable,
						updateExpression: 'SET lastId = lastId + :incr'
					});
				var assignedSeqNo = state.lastSeqNo + 1;
				var eventRecord = {event: state.unsavedEvent.payload, id: channelName, seq: assignedSeqNo, updatedAt: timestamp};
				var eventPut = A2(
					$author$project$AWS$Dynamo$putCommand,
					$author$project$DB$EventLogTable$encodeRecord,
					{item: eventRecord, tableName: component.eventLogTable});
				return A2(
					$brian_watkins$elm_procedure$Procedure$catch,
					function (error) {
						if (error.$ === 'ConditionCheckFailed') {
							return $brian_watkins$elm_procedure$Procedure$provide(
								{lastSeqNo: assignedSeqNo, sessionKey: state.sessionKey, txSuccess: false, unsavedEvent: state.unsavedEvent});
						} else {
							return $brian_watkins$elm_procedure$Procedure$break(
								$author$project$AWS$Dynamo$errorToDetails(error));
						}
					},
					A2(
						$brian_watkins$elm_procedure$Procedure$map,
						$elm$core$Basics$always(
							{lastSeqNo: assignedSeqNo, sessionKey: state.sessionKey, txSuccess: true, unsavedEvent: state.unsavedEvent}),
						$brian_watkins$elm_procedure$Procedure$fetchResult(
							$author$project$EventLog$Component$eventLogTableMetadataApi.writeTx(
								{
									commands: _List_fromArray(
										[seqUpdate, eventPut]),
									tableName: component.eventLogTable
								}))));
			},
			$brian_watkins$elm_procedure$Procedure$fromTask($elm$time$Time$now));
	});
var $author$project$EventLog$Component$recordEventWithUniqueSeqNo = F3(
	function (component, channelName, state) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (stateAfterTxAttempt) {
				return stateAfterTxAttempt.txSuccess ? $brian_watkins$elm_procedure$Procedure$provide(stateAfterTxAttempt) : A3(
					$author$project$EventLog$Component$recordEventWithUniqueSeqNo,
					component,
					channelName,
					{sessionKey: stateAfterTxAttempt.sessionKey, unsavedEvent: stateAfterTxAttempt.unsavedEvent});
			},
			A2(
				$brian_watkins$elm_procedure$Procedure$andThen,
				A2($author$project$EventLog$Component$recordEventsAndMetadata, component, channelName),
				A2(
					$brian_watkins$elm_procedure$Procedure$andThen,
					A2($author$project$EventLog$Component$getEventsLogMetaData, component, channelName),
					$brian_watkins$elm_procedure$Procedure$provide(state))));
	});
var $author$project$EventLog$Component$UnsavedEvent = F3(
	function (rt, client, payload) {
		return {client: client, payload: payload, rt: rt};
	});
var $author$project$EventLog$Component$decodeNoticeEvent = A2(
	$elm_community$json_extra$Json$Decode$Extra$andMap,
	A2($elm$json$Json$Decode$field, 'payload', $elm$json$Json$Decode$value),
	A2(
		$elm_community$json_extra$Json$Decode$Extra$andMap,
		A2($elm$json$Json$Decode$field, 'client', $elm$json$Json$Decode$string),
		A2(
			$elm_community$json_extra$Json$Decode$Extra$andMap,
			A2($elm$json$Json$Decode$field, 'rt', $elm$json$Json$Decode$string),
			$elm$json$Json$Decode$succeed($author$project$EventLog$Component$UnsavedEvent))));
var $author$project$EventLog$Component$tryReadEvent = F3(
	function (component, channelName, sessionKey) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (maybeCacheItem) {
				if (maybeCacheItem.$ === 'Just') {
					var cacheItem = maybeCacheItem.a;
					var _v1 = A2($elm$json$Json$Decode$decodeValue, $author$project$EventLog$Component$decodeNoticeEvent, cacheItem.payload);
					if (_v1.$ === 'Ok') {
						var unsavedEvent = _v1.a;
						return $brian_watkins$elm_procedure$Procedure$provide(
							{
								sessionKey: sessionKey,
								unsavedEvent: $elm$core$Maybe$Just(unsavedEvent)
							});
					} else {
						var err = _v1.a;
						return $brian_watkins$elm_procedure$Procedure$break(
							{
								details: $elm$json$Json$Encode$null,
								message: $elm$json$Json$Decode$errorToString(err)
							});
					}
				} else {
					return $brian_watkins$elm_procedure$Procedure$provide(
						{sessionKey: sessionKey, unsavedEvent: $elm$core$Maybe$Nothing});
				}
			},
			A2(
				$brian_watkins$elm_procedure$Procedure$mapError,
				$author$project$Momento$errorToDetails,
				$brian_watkins$elm_procedure$Procedure$fetchResult(
					A2(
						$author$project$EventLog$Component$momentoApi.popList,
						sessionKey,
						{
							list: $author$project$EventLog$Component$saveListName(channelName)
						}))));
	});
var $author$project$EventLog$Component$drainSaveList = F3(
	function (component, channelName, sessionKey) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$andThen,
			function (state) {
				var _v0 = state.unsavedEvent;
				if (_v0.$ === 'Nothing') {
					return $brian_watkins$elm_procedure$Procedure$provide(_Utils_Tuple0);
				} else {
					var event = _v0.a;
					return A2(
						$brian_watkins$elm_procedure$Procedure$andThen,
						A2($author$project$EventLog$Component$drainSaveList, component, channelName),
						A2(
							$brian_watkins$elm_procedure$Procedure$map,
							$elm$core$Basics$always(sessionKey),
							A2(
								$brian_watkins$elm_procedure$Procedure$andThen,
								A2($author$project$EventLog$Component$publishEvent, component, channelName),
								A2(
									$brian_watkins$elm_procedure$Procedure$andThen,
									A2($author$project$EventLog$Component$recordEventWithUniqueSeqNo, component, channelName),
									$brian_watkins$elm_procedure$Procedure$provide(
										{sessionKey: sessionKey, unsavedEvent: event})))));
				}
			},
			A2(
				$brian_watkins$elm_procedure$Procedure$andThen,
				A2($author$project$EventLog$Component$tryReadEvent, component, channelName),
				$brian_watkins$elm_procedure$Procedure$provide(sessionKey)));
	});
var $author$project$EventLog$Component$processSaveChannel = F6(
	function (protocol, session, state, apiRequest, channelName, component) {
		var procedure = A2(
			$brian_watkins$elm_procedure$Procedure$map,
			$elm$core$Basics$always(
				$author$project$Serverless$Response$ok200json($elm$json$Json$Encode$null)),
			A2(
				$brian_watkins$elm_procedure$Procedure$mapError,
				A2(
					$elm$core$Basics$composeR,
					$elm$core$Debug$log('error'),
					A2($elm$core$Basics$composeR, $author$project$EventLog$Component$encodeErrorFormat, $author$project$Serverless$Response$err500json)),
				A2(
					$brian_watkins$elm_procedure$Procedure$andThen,
					A2($author$project$EventLog$Component$drainSaveList, component, channelName),
					A2(
						$brian_watkins$elm_procedure$Procedure$andThen,
						$author$project$EventLog$Component$openMomentoCache(component),
						$brian_watkins$elm_procedure$Procedure$provide(channelName)))));
		return protocol.onUpdate(
			A2(
				$elm$core$Tuple$mapSecond,
				$elm$core$Platform$Cmd$map(protocol.toMsg),
				A2(
					$elm$core$Tuple$mapFirst,
					$author$project$EventLog$Component$setModel(component),
					A2(
						$the_sett$elm_update_helper$Update2$andMap,
						$author$project$EventLog$Component$switchState($author$project$EventLog$Component$ModelReady),
						_Utils_Tuple2(
							state,
							A3(
								$brian_watkins$elm_procedure$Procedure$try,
								$author$project$EventLog$Component$ProcedureMsg,
								$author$project$EventLog$Component$HttpResponse(session),
								procedure))))));
	});
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$EventLog$Component$findAvailableChannel = F2(
	function (component, _v0) {
		return A2(
			$brian_watkins$elm_procedure$Procedure$mapError,
			$author$project$AWS$Dynamo$errorToDetails,
			A2(
				$brian_watkins$elm_procedure$Procedure$map,
				$elm$core$List$head,
				$brian_watkins$elm_procedure$Procedure$fetchResult(
					$author$project$EventLog$Component$channelTableApi.scan(
						{exclusiveStartKey: $elm$core$Maybe$Nothing, tableName: component.channelTable}))));
	});
var $author$project$Serverless$Response$notFound400json = function (err) {
	return A2(
		$author$project$Serverless$Response$setStatus,
		400,
		A2(
			$author$project$Serverless$Response$setBody,
			$author$project$Serverless$Body$json(err),
			$author$project$Serverless$Response$init));
};
var $author$project$EventLog$Component$tryGetAvailableChannel = F4(
	function (protocol, session, state, component) {
		var procedure = A2(
			$brian_watkins$elm_procedure$Procedure$map,
			function (maybeChannel) {
				if (maybeChannel.$ === 'Just') {
					var channel = maybeChannel.a;
					return $author$project$Serverless$Response$ok200json(
						A2($miniBill$elm_codec$Codec$encoder, $author$project$DB$ChannelTable$recordCodec, channel));
				} else {
					return $author$project$Serverless$Response$notFound400json($elm$json$Json$Encode$null);
				}
			},
			A2(
				$brian_watkins$elm_procedure$Procedure$mapError,
				A2($elm$core$Basics$composeR, $author$project$EventLog$Component$encodeErrorFormat, $author$project$Serverless$Response$err500json),
				A2(
					$brian_watkins$elm_procedure$Procedure$andThen,
					$author$project$EventLog$Component$findAvailableChannel(component),
					$brian_watkins$elm_procedure$Procedure$provide(_Utils_Tuple0))));
		return protocol.onUpdate(
			A2(
				$elm$core$Tuple$mapSecond,
				$elm$core$Platform$Cmd$map(protocol.toMsg),
				A2(
					$elm$core$Tuple$mapFirst,
					$author$project$EventLog$Component$setModel(component),
					A2(
						$the_sett$elm_update_helper$Update2$andMap,
						$author$project$EventLog$Component$switchState($author$project$EventLog$Component$ModelReady),
						_Utils_Tuple2(
							{procedure: state.procedure, seed: state.seed},
							A3(
								$brian_watkins$elm_procedure$Procedure$try,
								$author$project$EventLog$Component$ProcedureMsg,
								$author$project$EventLog$Component$HttpResponse(session),
								procedure))))));
	});
var $author$project$EventLog$Component$processRoute = F4(
	function (protocol, session, apiRequest, component) {
		var model = component.eventLog;
		var _v0 = _Utils_Tuple3(
			$author$project$Serverless$Request$method(apiRequest.request),
			apiRequest.route,
			model);
		_v0$3:
		while (true) {
			if (_v0.b.$ === 'ChannelRoot') {
				if (_v0.c.$ === 'ModelReady') {
					switch (_v0.a.$) {
						case 'GET':
							var _v1 = _v0.a;
							var _v2 = _v0.b;
							var state = _v0.c.a;
							return A2(
								$the_sett$elm_update_helper$Update2$andMap,
								A3($author$project$EventLog$Component$tryGetAvailableChannel, protocol, session, state),
								$the_sett$elm_update_helper$Update2$pure(component));
						case 'POST':
							var _v3 = _v0.a;
							var _v4 = _v0.b;
							var state = _v0.c.a;
							return A2(
								$the_sett$elm_update_helper$Update2$andMap,
								A3($author$project$EventLog$Component$createChannel, protocol, session, state),
								$the_sett$elm_update_helper$Update2$pure(component));
						default:
							break _v0$3;
					}
				} else {
					break _v0$3;
				}
			} else {
				if ((_v0.a.$ === 'POST') && (_v0.c.$ === 'ModelReady')) {
					var _v5 = _v0.a;
					var channelName = _v0.b.a;
					var state = _v0.c.a;
					return A2(
						$the_sett$elm_update_helper$Update2$andMap,
						A5($author$project$EventLog$Component$processSaveChannel, protocol, session, state, apiRequest, channelName),
						$the_sett$elm_update_helper$Update2$pure(component));
				} else {
					break _v0$3;
				}
			}
		}
		return protocol.onUpdate(
			$the_sett$elm_update_helper$Update2$pure(component));
	});
var $brian_watkins$elm_procedure$Procedure$Program$addChannel = F2(
	function (subGenerator, registry) {
		return _Utils_update(
			registry,
			{
				channels: A3(
					$elm$core$Dict$insert,
					registry.nextId,
					subGenerator(registry.nextId),
					registry.channels),
				nextId: registry.nextId + 1
			});
	});
var $brian_watkins$elm_procedure$Procedure$Program$deleteChannel = F2(
	function (channelId, procModel) {
		return _Utils_update(
			procModel,
			{
				channels: A2($elm$core$Dict$remove, channelId, procModel.channels)
			});
	});
var $brian_watkins$elm_procedure$Procedure$Program$sendMessage = function (msg) {
	return A2(
		$elm$core$Task$perform,
		$elm$core$Basics$always(msg),
		$elm$core$Task$succeed(_Utils_Tuple0));
};
var $brian_watkins$elm_procedure$Procedure$Program$updateProcedures = F2(
	function (msg, registry) {
		switch (msg.$) {
			case 'Initiate':
				var generator = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						registry,
						{nextId: registry.nextId + 1}),
					generator(registry.nextId));
			case 'Execute':
				var cmd = msg.b;
				return _Utils_Tuple2(registry, cmd);
			case 'Subscribe':
				var messageGenerator = msg.b;
				var subGenerator = msg.c;
				return _Utils_Tuple2(
					A2($brian_watkins$elm_procedure$Procedure$Program$addChannel, subGenerator, registry),
					$brian_watkins$elm_procedure$Procedure$Program$sendMessage(
						messageGenerator(registry.nextId)));
			case 'Unsubscribe':
				var channelId = msg.b;
				var nextMessage = msg.c;
				return _Utils_Tuple2(
					A2($brian_watkins$elm_procedure$Procedure$Program$deleteChannel, channelId, registry),
					$brian_watkins$elm_procedure$Procedure$Program$sendMessage(nextMessage));
			default:
				return _Utils_Tuple2(registry, $elm$core$Platform$Cmd$none);
		}
	});
var $brian_watkins$elm_procedure$Procedure$Program$update = F2(
	function (msg, _v0) {
		var registry = _v0.a;
		return A2(
			$elm$core$Tuple$mapFirst,
			$brian_watkins$elm_procedure$Procedure$Program$Model,
			A2($brian_watkins$elm_procedure$Procedure$Program$updateProcedures, msg, registry));
	});
var $author$project$EventLog$Component$update = F3(
	function (protocol, msg, component) {
		var model = component.eventLog;
		var _v0 = _Utils_Tuple2(model, msg);
		_v0$5:
		while (true) {
			switch (_v0.b.$) {
				case 'RandomSeed':
					if (_v0.a.$ === 'ModelStart') {
						var seed = _v0.b.a;
						return protocol.onUpdate(
							A2(
								$elm$core$Tuple$mapSecond,
								$elm$core$Platform$Cmd$map(protocol.toMsg),
								A2(
									$elm$core$Tuple$mapFirst,
									$author$project$EventLog$Component$setModel(component),
									A2(
										$the_sett$elm_update_helper$Update2$andMap,
										$author$project$EventLog$Component$switchState($author$project$EventLog$Component$ModelReady),
										$the_sett$elm_update_helper$Update2$pure(
											{procedure: $brian_watkins$elm_procedure$Procedure$Program$init, seed: seed})))));
					} else {
						break _v0$5;
					}
				case 'ProcedureMsg':
					if (_v0.a.$ === 'ModelReady') {
						var state = _v0.a.a;
						var innerMsg = _v0.b.a;
						var _v1 = A2($brian_watkins$elm_procedure$Procedure$Program$update, innerMsg, state.procedure);
						var procMdl = _v1.a;
						var procMsg = _v1.b;
						return protocol.onUpdate(
							A2(
								$elm$core$Tuple$mapSecond,
								$elm$core$Platform$Cmd$map(protocol.toMsg),
								A2(
									$elm$core$Tuple$mapFirst,
									$author$project$EventLog$Component$setModel(component),
									A2(
										$the_sett$elm_update_helper$Update2$andMap,
										$author$project$EventLog$Component$switchState($author$project$EventLog$Component$ModelReady),
										_Utils_Tuple2(
											_Utils_update(
												state,
												{procedure: procMdl}),
											procMsg)))));
					} else {
						break _v0$5;
					}
				case 'HttpRequest':
					if (_v0.a.$ === 'ModelReady') {
						var state = _v0.a.a;
						var _v2 = _v0.b;
						var session = _v2.a;
						var result = _v2.b;
						if (result.$ === 'Ok') {
							var apiRequest = result.a;
							return A4($author$project$EventLog$Component$processRoute, protocol, session, apiRequest, component);
						} else {
							var httpError = result.a;
							return protocol.onUpdate(
								A2(
									$elm$core$Tuple$mapSecond,
									$elm$core$Platform$Cmd$map(protocol.toMsg),
									A2(
										$elm$core$Tuple$mapFirst,
										$author$project$EventLog$Component$setModel(component),
										_Utils_Tuple2(
											$author$project$EventLog$Component$ModelReady(state),
											A2(
												$author$project$EventLog$Component$httpServerApi.response,
												session,
												$author$project$Serverless$Response$err500(
													$author$project$Serverless$HttpServer$errorToString(httpError)))))));
						}
					} else {
						break _v0$5;
					}
				case 'HttpResponse':
					var _v4 = _v0.b;
					var session = _v4.a;
					var result = _v4.b;
					return protocol.onUpdate(
						A2(
							$elm$core$Tuple$mapSecond,
							$elm$core$Platform$Cmd$map(protocol.toMsg),
							_Utils_Tuple2(
								component,
								A2(
									$author$project$EventLog$Component$httpServerApi.response,
									session,
									$elm_community$result_extra$Result$Extra$merge(result)))));
				default:
					var error = _v0.b.a;
					return protocol.onUpdate(
						$the_sett$elm_update_helper$Update2$pure(component));
			}
		}
		return protocol.onUpdate(
			$the_sett$elm_update_helper$Update2$pure(component));
	});
var $author$project$API$update = F2(
	function (msg, model) {
		var innerMsg = msg.a;
		return A3($author$project$EventLog$Component$update, $author$project$API$eventLogProtocol, innerMsg, model);
	});
var $elm$core$Platform$worker = _Platform_worker;
var $author$project$API$main = $elm$core$Platform$worker(
	{init: $author$project$API$init, subscriptions: $author$project$API$subscriptions, update: $author$project$API$update});
_Platform_export({'API':{'init':$author$project$API$main(
	A2(
		$elm$json$Json$Decode$andThen,
		function (momentoSecret) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (eventLogTable) {
					return A2(
						$elm$json$Json$Decode$andThen,
						function (channelTable) {
							return A2(
								$elm$json$Json$Decode$andThen,
								function (channelApiUrl) {
									return $elm$json$Json$Decode$succeed(
										{channelApiUrl: channelApiUrl, channelTable: channelTable, eventLogTable: eventLogTable, momentoSecret: momentoSecret});
								},
								A2($elm$json$Json$Decode$field, 'channelApiUrl', $elm$json$Json$Decode$string));
						},
						A2($elm$json$Json$Decode$field, 'channelTable', $elm$json$Json$Decode$string));
				},
				A2($elm$json$Json$Decode$field, 'eventLogTable', $elm$json$Json$Decode$string));
		},
		A2(
			$elm$json$Json$Decode$field,
			'momentoSecret',
			A2(
				$elm$json$Json$Decode$andThen,
				function (restEndpoint) {
					return A2(
						$elm$json$Json$Decode$andThen,
						function (refreshToken) {
							return A2(
								$elm$json$Json$Decode$andThen,
								function (apiKey) {
									return $elm$json$Json$Decode$succeed(
										{apiKey: apiKey, refreshToken: refreshToken, restEndpoint: restEndpoint});
								},
								A2($elm$json$Json$Decode$field, 'apiKey', $elm$json$Json$Decode$string));
						},
						A2($elm$json$Json$Decode$field, 'refreshToken', $elm$json$Json$Decode$string));
				},
				A2($elm$json$Json$Decode$field, 'restEndpoint', $elm$json$Json$Decode$string)))))(0)}});}(this));