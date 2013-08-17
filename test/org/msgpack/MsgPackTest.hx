package org.msgpack;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

class MsgPackTest 
{

	private function encodingAndDecodingAreEqual(d : Dynamic)
	{
		var e = MsgPack.encode(d);
		Assert.areEqual(MsgPack.decode(e), d);
	}

	@Test
	public function recoverDataWithNull():Void
	{
		encodingAndDecodingAreEqual(null);
	}

	@Test
	public function recoverDataWithBool():Void
	{
		encodingAndDecodingAreEqual(true);
		encodingAndDecodingAreEqual(false);
	}

	@Test
	public function recoverDataWithInt():Void
	{
		encodingAndDecodingAreEqual(0);
		encodingAndDecodingAreEqual(1);
		encodingAndDecodingAreEqual(2147483647);
		encodingAndDecodingAreEqual(-2147483648);
	}

	@Test
	public function recoverDataWithFloat():Void
	{
		encodingAndDecodingAreEqual(0.0);
		encodingAndDecodingAreEqual(1.0);
		encodingAndDecodingAreEqual(1.40129846432481706e-45);
		encodingAndDecodingAreEqual(3.40282346638528859e+38);
#if cpp
		encodingAndDecodingAreEqual(4.94065645841246543e-324);
		encodingAndDecodingAreEqual(1.79769313486231569e+308);
#end
	}

	@Test
	public function recoverDataWithString():Void
	{
		encodingAndDecodingAreEqual("");
		encodingAndDecodingAreEqual("a");
		encodingAndDecodingAreEqual("azAZ09");
		encodingAndDecodingAreEqual("\"");
		encodingAndDecodingAreEqual("\t\n\r");
		encodingAndDecodingAreEqual("!/:@[`{~");
	}

	@Test
	public function recoverDataWithStringMap():Void
	{
		var e = MsgPack.encode(["" => "a"]);
		Assert.areEqual(cast(MsgPack.decode(e, false), haxe.ds.StringMap<Dynamic>).get(""), "a");

		e = MsgPack.encode(["a" => "a", "b" => "b"]);
		var actual = cast(MsgPack.decode(e, false), haxe.ds.StringMap<Dynamic>);
		Assert.areEqual(actual.get("a"), "a");
		Assert.areEqual(actual.get("b"), "b");

		e = MsgPack.encode(["a" => ["a" => "a", "b" => "b"]]);
		actual = cast(MsgPack.decode(e, false), haxe.ds.StringMap<Dynamic>);
		var actual_a = cast(actual.get("a"), haxe.ds.StringMap<Dynamic>);
		Assert.areEqual(actual_a.get("a"), "a");
		Assert.areEqual(actual_a.get("b"), "b");
	}

	@Test
	public function recoverDataWithArray():Void
	{
		var e = MsgPack.encode(["a", "b"]);
		var actual = cast(MsgPack.decode(e, false), Array<Dynamic>);
		Assert.areEqual(actual[0], "a");
		Assert.areEqual(actual[1], "b");

		e = MsgPack.encode([["a", "b"], ["c", "d"]]);
		actual = cast(MsgPack.decode(e, false), Array<Dynamic>);
		var actual_0 = cast(actual[0], Array<Dynamic>);
		var actual_1 = cast(actual[1], Array<Dynamic>);
		Assert.areEqual(actual_0[0], "a");
		Assert.areEqual(actual_0[1], "b");
		Assert.areEqual(actual_1[0], "c");
		Assert.areEqual(actual_1[1], "d");
	}

	@Test
	public function recoverDataWithObject():Void
	{
		var cat = {name:"Sara", type:"cat", age:10};
		var e = MsgPack.encode(cat);
		var actual = MsgPack.decode(e, true);
		Assert.areEqual(actual.name, "Sara");
		Assert.areEqual(actual.type, "cat");
		Assert.areEqual(actual.age, 10);
	}
}