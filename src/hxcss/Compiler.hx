package hxcss;
import haxe.ds.StringMap;

/**
 * ...
 * @author Damilare Akinlaja
 */
class Compiler
{
	public var options:StringMap<Dynamic>;
	/**
	 * Initialize a compiler.
	 */
	public function new(options:StringMap<Dynamic>)
	{
		this.options = options != null ? options : new StringMap<Dynamic>();
	}

	/**
	 * Emit `str`
	 */
	public function emit(str:String):String
	{
		return str;
	}

	/**
	 * Visit `node`.
	 */

	public function visit(node:StringMap):Dynamic
	{
		return null;
	}

	/**
	 * Map visit over array of `nodes`, optionally using a `delim`
	 */
	public function mapVisit(nodes:Array<StringMap<Dynamic>>, ?delim:String):String
	{
	  var buf = '';
	  delim = delim != null ? delim : '';

	  for (i in 0...nodes.length) {
		buf += this.visit(nodes[i]);
		if (delim.length > 0 && i < length - 1) buf += this.emit(delim);
	  }

	  return buf;		
	}

}