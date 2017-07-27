package hxcss;
using StringTools;
import haxe.ds.StringMap;

/**
 * Inherits a compiler
 * ...
 * @author Damilare Akinlaja
 */

class Compress extends Compiler
{
	private var buf:StringBuf;
	/**
	 * Initialize a new `Compiler`.
	 */
	public function new(options:StringMap<Dynamic>)
	{
		this.buf = new StringBuf();
		buf.add('');
		super(options);

	}

	/**
	 * Compile `node`.
	 */

	public function Compile(node:StringMap<Dynamic>):String
	{
		return cast(node.get("rules"), Array).map(this.visit).join('');
	}

	/**
	 * Visit comment node.
	 */

	public function Comment(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);
		var str = buf.addSub('', cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString());
	}

	/**
	 * Visit import node.
	 */

	public function Import(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);

		buf.addSub('@import ' + node.get('import') + ';', cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString());
	}
	
	/**
	 * Visit media node.
	 */	
	
	public function Media(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);

		buf.addSub('@media ' + node.get('media'), cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString())
					+ this.emit('{')
					+ this.mapVisit(node.get("rules"))
					+ this.emit('}');
	}
	
	/**
	 * Visit document node.
	 */	
	public function Media(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);

		buf.addSub('@' + node.get('vendor') != '' ? node.get('vendor') : '' + 'document ' + node.get("document"), cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString())
					+ this.emit('{')
					+ this.mapVisit(node.get("rules"))
					+ this.emit('}');
	}
	
	/**
	 * Visit charset node.
	 */

	public function Charset(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);

		buf.addSub('@charset ' + node.get('charset') + ';', cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString());
	}
	
	/**
	 * Visit charset node.
	 */

	public function Namespace(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);

		buf.addSub('@charset ' + node.get('namespace') + ';', cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString());
	}
	
	/**
	 * Visit supports node.
	 */	
	
	public function Supports(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);

		buf.addSub('@supports ' + node.get('supports'), cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString())
					+ this.emit('{')
					+ this.mapVisit(node.get("rules"))
					+ this.emit('}');
	}	
	
	/**
	 * Visit keyframes node.
	 */	
	
	public function Keyframes(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);

		buf.addSub('@' + node.get('vendor') != '' ? node.get('vendor') : ''+'keyframes '+ node.get("name"), cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString())
					+ this.emit('{')
					+ this.mapVisit(node.get("keyframes"))
					+ this.emit('}');
	}	
	
	
	/**
	 * Visit keyframe node.
	 */	
	public function Keyframe(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);
		var decls:Array<StringMap<Dynamic>> = node.get("declarations");
	
		buf.addSub(cast(node.get('values'), Array).join(''), cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString())
					+ this.emit('{')
					+ this.mapVisit(decls)
					+ this.emit('}');
	}
	
	/**
	 * Visit font-face node.
	 */	
	
	public function FontFace(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);
		var decls:Array<StringMap<Dynamic>> = node.get("declarations");
	
		buf.addSub('@font-face', cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString())
					+ this.emit('{')
					+ this.mapVisit(decls)
					+ this.emit('}');
	}	
	
	/**
	 * Visit host node.
	 */	
	
	public function Host(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);
		var rules:Array<StringMap<Dynamic>> = node.get("rules");
	
		buf.addSub('@host', cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString())
					+ this.emit('{')
					+ this.mapVisit(rules)
					+ this.emit('}');
	}
	
	/**
	 * Visit custom-media node.
	 */	
	
	public function CustomMedia(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);
		var rules:Array<StringMap<Dynamic>> = node.get("rules");
	
		buf.addSub('@custom-media ', cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString());
	}
	
	/**
	 * Visit Rule node.
	 */	
	
	public function Rule(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);
		var decls:Array<StringMap<Dynamic>> = node.get("declarations");
		if (decls.length == 0) return ''; 
	
		buf.addSub(cast(node.get("selectors"), Array).join(','), cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString())
					+ this.emit('{')
					+ this.mapVisit(rules)
					+ this.emit('}');
	}
	
	/**
	 * Visit declaration node.
	 */	
	
	public function Declaration(node:StringMap<Dynamic>):String
	{
		var position = cast(node.get('position'), StringMap);
		var rules:Array<StringMap<Dynamic>> = node.get("rules");
	
		buf.addSub(node.get("property") + ':' + node.get("value"), cast(position.get("start"), StringMap).get('column'), cast(position.get("end"), StringMap).get('column'));
		return this.emit(buf.toString());
	}	
}