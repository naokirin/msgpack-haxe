package org.msgpack;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.ds.StringMap;
using Reflect;

class Encoder {

	static private inline var FLOAT_SINGLE_MIN:Float = 1.40129846432481707e-45;
	static private inline var FLOAT_SINGLE_MAX:Float = 3.40282346638528860e+38;

	static private inline var FLOAT_DOUBLE_MIN:Float = 4.94065645841246544e-324;
	static private inline var FLOAT_DOUBLE_MAX:Float = 1.79769313486231570e+308;

	var o:BytesOutput;

	public function new(d:Dynamic) {
		o = new BytesOutput();
		o.bigEndian = true;

		encode(d);
	}

	function encode(d:Dynamic) {
		switch (Type.typeof(d)) {
			case TNull    : o.writeByte(0xc0);
			case TBool    : o.writeByte(d ? 0xc3 : 0xc2);
			case TInt     : writeInt(d);
			case TFloat   : writeFloat(d);
			case TClass(c): {
				switch (Type.getClassName(c)) {
					case "String" : writeRaw(Bytes.ofString(d));
					case "Array"  : writeArray(d);
					case "haxe.ds.StringMap" : writeMap(d);
					// TODO: implement IntMap and ObjectMap
					case "haxe.ds.IntMap" : throw "Error: IntMap not supported";
					case "haxe.ds.ObjectMap" : throw "Error: ObjectMap not supported";
				}
			}

			case TObject  : writeObjectMap(d);
			case TEnum(e) : throw "Error: Enum not supported";
			case TFunction: throw "Error: Function not supported";
			case TUnknown : throw "Error: Unknown Data Type";
		}
	}

	inline function writeInt(d:Int) {
		if (d < -(1 << 5)) {
			// less than negative fixnum ?
			if (d < -(1 << 15)) {
				// signed int 32
				o.writeByte(0xd2);
				o.writeInt32(d);
			} else
			if (d < -(1 << 7)) {
				// signed int 16
				o.writeByte(0xd1);
				o.writeInt16(d);
			} else {
				// signed int 8
				o.writeByte(0xd0);
				o.writeInt8(d);
			}
		} else
		if (d < (1 << 7)) {
			// negative fixnum < d < positive fixnum [fixnum]
			o.writeByte(d & 0x000000ff);
		} else {
			// unsigned land
			if (d < (1 << 8)) {
				// unsigned int 8
				o.writeByte(0xcc);
				o.writeByte(d);
			} else 
			if (d < (1 << 16)) {
				// unsigned int 16
				o.writeByte(0xcd);
				o.writeUInt16(d);
			} else {
				// unsigned int 32 
				// TODO: HaXe writeUInt32 ?
				o.writeByte(0xce);
				o.writeInt32(d);
			}
		}
	}

	inline function writeFloat(d:Float) {		
			var a = Math.abs(d);
			if (a > FLOAT_SINGLE_MIN && a < FLOAT_SINGLE_MAX) {
				// Single Precision Floating
				o.writeByte(0xca);
				o.writeFloat(d);
			} else {
				// Double Precision Floating
				o.writeByte(0xcb);
				o.writeDouble(d);
			}
	}

	inline function writeRaw(b:Bytes) {
		var length = b.length;
		if (length < 0x20) {
			// fix raw
			o.writeByte(0xa0 | length);
		} else 
		if (length < 0x10000) {
			// raw 16
			o.writeByte(0xda);
			o.writeUInt16(length);
		} else {
			// raw 32
			o.writeByte(0xdb);
			o.writeInt32(length);
		}
		o.write(b);
	}

	inline function writeArray(d:Array<Dynamic>) {
		var length = d.length;
		if (length < 0x10) {
			// fix array
			o.writeByte(0x90 | length);
		} else 
		if (length < 0x10000) {
			// array 16
			o.writeByte(0xdc);
			o.writeUInt16(length);
		} else {
			// array 32
			o.writeByte(0xdd);
			o.writeInt32(length);
		}

		for (e in d) {
			encode(e);
		}
	}

	inline function writeMapLength(length:Int) {
		if (length < 0x10) {
			// fix map
			o.writeByte(0x80 | length);
		} else 
		if (length < 0x10000) {
			// map 16
			o.writeByte(0xde);
			o.writeUInt16(length);
		} else {
			// map 32
			o.writeByte(0xdf);
			o.writeInt32(length);
		}		
	}

	inline function writeMap(d:StringMap<Dynamic>) {
		writeMapLength(Lambda.count(d));
		for (k in d.keys()) { 
			writeRaw(Bytes.ofString(k));
			encode(d.get(k));
		}
	}

	inline function writeObjectMap(d:Dynamic) {
		var f = d.fields();
		writeMapLength(Lambda.count(f));
		for (k in f) {
			writeRaw(Bytes.ofString(k));
			encode(d.field(k));
		}
	}

	public inline function getBytes():Bytes {
		return o.getBytes();
	}
}
