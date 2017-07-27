package hxcss;
import haxe.Json;
import haxe.ds.StringMap;
using StringTools;
/**
 * ...
 * @author Damilare Akinlaja
 */
class Parser
{
	public var css:String;
	public var options:StringMap<Dynamic>;
	
	public static var commentre:EReg = ~/\/\*[^*]*\*+([^\/*][^*]*\*+)*\//g;

	/**
	 * Positional.
	 */

	public var lineno:Int = 1;
	public var column:Int = 1;

	public function new(css:String, options:StringMap<Dynamic>)
	{
		this.css = css;
		if (options != null)
		{
			this.options = options;
		}
		else
		{
			this.options = new StringMap();
		}

	}
	/**
	 * Match `re` and return captures.
	 */
	private function match(re:EReg):String
	{
		var m = re.match(css);
		if (!m)
		{
			return null;
		}

		var str = re.matched(0);
		updatePosition(str);
        
		css = css.split("").slice(str.length).join("");
		return re.matched(0);
	}

	/**
	 * Mark position and patch `node.position`.
	 */

	private function position():StringMap<Dynamic>
	{
		var start:StringMap<Dynamic> = [ "line" => lineno, "column" => column ];

		
		return start;
	}
	
	private function pos(node:StringMap<Dynamic>, start:StringMap<Dynamic>):StringMap<Dynamic>
	{
		
		node.set("position",  (new Position(start, this)).toMap());
		whitespace();
		return node;
	}	
	
	
	

	/**
	 * Parse whitespace.
	 */

	private function whitespace():Void
	{
		match(~/\s*/);
	}

	/**
	 * Parse comment.
	 */

	private function comment():StringMap<Dynamic>
	{
		var start = position();
		if ('/' != css.charAt(0) || '*' != css.charAt(1)) return null;

		var i = 2;
		while ("" != css.charAt(i) && ('*' != css.charAt(i) || '/' != css.charAt(i + 1))) ++i;
		i += 2;

		if ("" == css.charAt(i-1))
		{
			throw error('End of comment missing');
		}

		var str = css.split("").slice(2, i - 2).join("");
		column += 2;
		updatePosition(str);
		css = css.split("").slice(i).join("");
		column += 2;

		return pos(
			[
				"type" => 'comment',
				"comment" => str
			], start);
	}

	/**
	 * Parse comments;
	 */

	private function comments(?rules:Array<StringMap<Dynamic>>):Array<StringMap<Dynamic>>
	{
		var c = comment();
		var _rules = [];
		if (rules != null)
		{
			_rules = rules;
		}
		if (c != null)
		{
			_rules.push(c);
		}
		
		return _rules;
	}
	
	/**
	 * Parse declaration.
	 */

	private function declaration():StringMap<Dynamic> 
	{
		var start = position();

		// prop
		var prop = match(~/^(\*?[-#\/\*\\\w]+(\[[0-9a-z_-]+\])?)\s*/);
		if (prop == null) return null;
		prop = trim(prop);
		

		// :
		if (match(~/:\s*/) == null) throw error("property missing ':'");

		// val
		var val = match(~/^((?:'(?:\\'|.)*?'|"(?:\\"|.)*?"|\([^\)]*?\)|[^};])+)/);
        var _val = '';
        
        if(val != null){
            _val = Parser.commentre.replace(trim(val), '');
        }

		var ret = pos([
		  "type" => 'declaration',
		  "property" => Parser.commentre.replace(prop, ''),
		  "value" => _val
		], start);

		// ;
		match(~/^[;\s]*/);

		return ret;
	}
	
	  /**
	   * Parse declarations.
	   */

	private function declarations():Array<StringMap<Dynamic>> {
		var decls:Array<StringMap<Dynamic>> = [];

		if (open() == null) throw error("missing '{'");
		comments(decls);
		

		// declarations
		var decl = declaration();
		
	
		
			for (v in decl.keys()){
				if(decl.get(v) != null){
					decls.push(decl);
					comments(decls);
					break;
				}
			}
		

		if (close() == null) throw error("missing '}'");
		
		return decls;
	}
	
	  /**
	   * Parse selector.
	   */

	private function selector():Array<String> {
		var m = match(~/^([^{]+)/);
		if (m == null) return null;
		
		/*Todo: @fix Remove all comments from selectors
		 * http://ostermiller.org/findcomment.html */		
		
        var patt1:EReg = ~/"(?:\\"|[^"])*"|'(?:\\'|[^'])*'/g;
        var patt2:EReg = ~/\/\*[^*]*\*+([^\/*][^*]*\*+)*\//g;
		
		var rem1 = patt1.replace(trim(m), '');
		var rem2:String = '';
		if(patt2.match(rem1)){
			var _rem2 = patt2.matched(0);
			rem2 = ~/,/g.replace(_rem2, '\x200C');
		}else{
			rem2 = rem1;
		}
		
		var rem:Array<String> = ~/\s*(?![^(]*\)),\s*/.split(rem2);
		var fin:Array<String> = rem.map(function(s){
			return ~/\x200C/g.replace(s, ',');
		});
		return fin;
	}	
	
	  /**
	   * Parse keyframe.
	   */

	private function keyframe():StringMap<Dynamic> {
		var m = match(~/^((\d+\.\d+|\.\d+|\d+)%?|[a-z]+)\s*/);
		var vals = [];
		var start = position();

		while(m != null) {
		  vals.push(m.charAt(1));
		  match(~/^,\s*/);
		}

		if (vals.length == 0) return null;

		return pos([
		  "type" => 'keyframe',
		  "values" => vals,
		  "declarations" => declarations()
		], start);
	}
	
  /**
   * Parse keyframes.
   */

	private function atkeyframes():StringMap<Dynamic> {
		var start = position();
		var m = match(~/^@([-\w]+)?keyframes\s*/);

		if (m == null) return null;
		var vendor = m.charAt(1);

		// identifier
		var m = match(~/^([-\w]+)\s*/);
		if (m == null) throw error("@keyframes missing name");
		var name = m.charAt(1);

		if (open() == null) throw error("@keyframes missing '{'");

		var frame = keyframe();
		var frames = comments();
		for (f in frame.keys()) {
			if(frame.get(f) != null){
			  frames.push(frame);
			  frames = frames.concat(comments());
			  break;
			}
		}

		if (close() == null) throw error("@keyframes missing '}'");

		return pos([
		  "type"=> 'keyframes',
		  "name"=> name,
		  "vendor"=> vendor,
		  "keyframes"=> frames
		], start);
	}
	
  /**
   * Parse supports.
   */

	private function atsupports():StringMap<Dynamic> {
		var start = position();
		var m = match(~/^@supports *([^{]+)/);

		if (m == null) return null;
		var supports = trim(m.charAt(1));

		if (open() == null) throw error("@supports missing '{'");

		var style = comments().concat(rules());

		if (close() == null) throw error("@supports missing '}'");

		return pos([
		  "type" => 'supports',
		  "supports" => supports,
		  "rules" => style
		], start);
	}
	
  /**
   * Parse host.
   */

	private function athost():StringMap<Dynamic> {
		var start = position();
		var m = match(~/^@host\s*/);

		if (m == null) return null;

		if (open() == null) throw error("@host missing '{'");

		var style = comments().concat(rules());

		if (close() == null) throw error("@host missing '}'");

		return pos([
		  "type" => 'host',
		  "rules" => style
		], start);
	}
	
  /**
   * Parse media.
   */

	private function atmedia():StringMap<Dynamic> {
		var start = position();
		var m = match(~/^@media *([^{]+)/);

		if (m == null) return null;
		var media = trim(m.charAt(1));

		if (open() == null) throw error("@media missing '{'");

		var style = comments().concat(rules());

		if (close() == null) throw error("@media missing '}'");

		return pos([
		  "type" => 'media',
		  "media" => media,
		  "rules" => style
		], start);
	}
	
	  /**
	   * Parse custom-media.
	   */

	private function atcustommedia():StringMap<Dynamic> {
		var start = position();
		var m = match(~/^@custom-media\s+(--[^\s]+)\s*([^{;]+);/);
		if (m == null) return null;

		return pos([
		  "type" => 'custom-media',
		  "name" => trim(m.charAt(1)),
		  "media" => trim(m.charAt(2))
		], start);
	}
	
	  /**
	   * Parse paged media.
	   */

	private function atpage():StringMap<Dynamic> {
		var start = position();
		var m = match(~/^@page */);
		if (m == null) return null;

		var sel = selector();
		if(selector() == null){
			sel = [];
		}
		

		if (open() == null) throw error("@page missing '{'");
		var decls = comments();

		// declarations
		var decl:StringMap<Dynamic> = declaration();
		
		for(v in decl.keys()){
			if(decl.get(v) != null){
				  decls.push(decl);
				  decls = decls.concat(comments());	
				  break;
			}			
		}

				

		if (close() == null) throw error("@page missing '}'");

		return pos([
		  "type" => 'page',
		  "selectors" => sel,
		  "declarations"=> decls
		], start);
	 }
	 
	  /**
	   * Parse document.
	   */

	 private function atdocument():StringMap<Dynamic> {
		var start = position();
		var m = match(~/^@([-\w]+)?document *([^{]+)/);
		if (m == null) return null;

		var vendor = trim(m.charAt(1));
		var doc = trim(m.charAt(2));

		if (open() == null) throw error("@document missing '{'");

		var style = comments().concat(rules());

		if (close() == null) throw error("@document missing '}'");

		return pos([
		  "type" => 'document',
		  "document" => doc,
		  "vendor" => vendor,
		  "rules" => style
		], start);
	  }
	  
	  /**
	   * Parse font-face.
	   */

	  private function atfontface():StringMap<Dynamic> {
		var start = position();
		var m = match(~/^@font-face\s*/);
		if (m == null) return null;

		if (open() == null) throw error("@font-face missing '{'");
		var decls = comments();

		// declarations
		var decl = declaration();
		for(v in decl.keys()){
			if(decl.get(v) != null){
				  decls.push(decl);
				  decls = decls.concat(comments());	
				  break;
			}			
		}

		if (close() == null) throw error("@font-face missing '}'");

		return pos([
		  "type" => 'font-face',
		  "declarations" => decls
		], start);
	  }
	  /**
	   * Parse non-block at-rules
	   */	  
	  private function _compileAtrule(name):StringMap<Dynamic> {
		var re = new EReg('^@' + name + '\\s*([^;]+);', "");
		  var start = position();
		  var m = match(re);
		  if (m == null) return null;
		  var ret:StringMap<Dynamic> = [ "type" => name ];
		  ret.set(name, m.charAt(1).trim());
		  
		  return pos(ret, start);
	  }	
	  
	  /**
	   * Parse import
	   */

	private function atimport():StringMap<Dynamic> { return _compileAtrule('import'); };

	  /**
	   * Parse charset
	   */

	private function atcharset():StringMap<Dynamic> { return _compileAtrule('charset'); };

	  /**
	   * Parse namespace
	   */

	private function atnamespace():StringMap<Dynamic> { return _compileAtrule('namespace'); };	
	
	  /**
	   * Parse at rule.
	   */

	private function atrule():StringMap<Dynamic> {
		if (css.charAt(0) != '@') return null;
        
        var ret = null;
        
        if(atkeyframes() != null){
            ret = atkeyframes();
        }else if(atmedia() != null){
            ret =atmedia();
        }else if(atcustommedia() != null){
            ret =atcustommedia();
        }else if(atsupports() != null){
            ret =atsupports();
        }else if(atimport() != null){
            ret =atimport();
        }else if(atcharset() != null){
            ret =atcharset();
        }else if(atnamespace() != null){
            ret =atnamespace();
        }else if(atdocument() != null){
            ret =atdocument();
        }else if(atpage() != null){
            ret =atpage();
        }else if(athost() != null){
            ret =athost();
        }else if(atfontface() != null){
            ret = atfontface();
        }else{
            return null;
        }
        
		return ret;
	  }	
	  
	  /**
	   * Parse rule.
	   */

	  private function rule():StringMap<Dynamic> 
    {
		var start = position();
		var sel = selector();

		if (sel ==null) throw error('selector missing');
		comments();
		var ret = pos([
		  "type" => 'rule',
		  "selectors" => sel,
		  "declarations" => declarations()
		], start);
		
		return ret;
	  }	  

	/**
	 * Error `msg`.
	 */

	var errorsList:Array<String> = [];

	private function error(msg):String
	{
		var err = options.get("source") + ':' + lineno + ':' + column + ': ' + msg;
		if (options.get("silent"))
		{
			errorsList.push(err);
            return null;
		}
		else
		{
			return err;
		}
	}

	/**
	 * Parse stylesheet.
	 */

	private function stylesheet():StringMap<Dynamic>
	{
		var rulesList:Array<StringMap<Dynamic>> = rules();
        
        var _stylesheet:StringMap<Dynamic> = [
				"rules" => rulesList,
				"parsingErrors" => errorsList	
			];
		var ret:StringMap<Dynamic> =[
			"type" => 'stylesheet',
			"stylesheet" => _stylesheet
		];
		
		return ret;
	}

	/**
	* Opening brace.
	*/

	private function open():String
	{
		return match(~/{\s*/);
	}

	/**
	 * Closing brace.
	 */

	private function close():String
	{
		return match(~/}/);
	}

	/**
	 * Parse ruleset.
	 */

	private function rules():Array<StringMap<Dynamic>>
	{
		var node:StringMap<Dynamic> = atrule();

		if(atrule() == null){
			node = rule();
		}
		
		var rules:Array<StringMap<Dynamic>> = [];
		whitespace();
		comments(rules);
		if (css.charAt(0) != '}')
		{
			if (node != null){
				
				rules.push(node);
				comments(rules);
			}
		}
		return rules;
	}

	/**
	 * Update lineno and column based on `str`.
	 */
	private function updatePosition(str:String)
	{
		var re = ~/\n/g;
		var lines:String = null;
		if (re.match(str))
		{
			lines = re.matched(0);
		}
		if (lines != null)
		{
			lineno += lines.length;

		};
		var i = str.lastIndexOf('\n');
		column = ~i !=0 ? str.length - i : column + str.length;
	}
	
	/**
	 * Trim `str`.
	 */

	private function trim(str:String):String 
	{
		return ~/^\s+|\s+$/g.replace(str, '');
	}
	
	
	public static function addParent(obj:Dynamic, ?parent:StringMap<Dynamic>):Dynamic{

		var isNode:Bool = obj != null;
		if (Std.is(obj, StringMap) == false){
			isNode = false;
		}else if (obj != null && Std.is(obj, StringMap)){
			var obj = cast(obj, StringMap<Dynamic>);
			if(obj.exists("type"))
				isNode = true;
				if (obj.get("type") == "stylesheet"){
					return obj;
				}
		}

		var childParent = isNode != false ? obj : parent;
		if (Std.is(obj, StringMap)){
			var obj = cast(obj, StringMap<Dynamic>);
			for (key in obj.iterator()){
							
					var value = obj.get(key);
					
					if(Std.is(value, Array)){
						var _value:Array<Dynamic> = value;
						
						for (i in 0..._value.length){
							var v = _value[i];
							Parser.addParent(v, childParent);	
						}
					}else if(value != null && Std.is(value, StringMap)){
						Parser.addParent(value, childParent);
					}
					//trace(obj);
			}
			
			if(isNode == true && parent != null){
				obj.set("parent", parent);
			}
		}
		
		
	  	return obj;
            
	}
	
	public static function parse(css: String, options: StringMap<Dynamic>):StringMap<Dynamic> 
	{
		var _css:StringMap<Dynamic> = Parser.addParent((new Parser(css, options)).stylesheet());
		return _css;

	}
	
	
	

}

class Position
{
	public var start:Dynamic;
	public var end:StringMap<Dynamic>;
	public var source:Dynamic;

	/**
	* Non-enumerable source string
	*/
	public var content:String;

	public function new(start:Dynamic, css:Parser)
	{
		this.end = new StringMap<Dynamic>();
		this.start = start;
		this.end.set("line", css.lineno);
		this.end.set("column", css.column);
		this.source = css.options.get("source");
		this.content = css.css;
	}
	
	public function toMap():StringMap<Dynamic>
	{
		var map:StringMap<Dynamic> = new StringMap<Dynamic>();
		map.set("source", this.source);
		map.set("start", this.start);
		map.set("end", this.end);
		
		return map;
	}
}