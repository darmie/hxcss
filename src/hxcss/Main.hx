package hxcss;
import haxe.ds.StringMap;

//import cpp.Lib;

/**
 * ...
 * @author Damilare Akinlaja
 */
class Main
{

	static function main()
	{
		var cssString = 'body{
							name:"tobi";
							age: 2;
							
						}
						loki{
							name: "loki";
							age: 1; 
						}';
		
		var css = new Parser(["source" => 'foobar.css']);
		var AST = css.parse(cssString);
		trace(AST);
	}

}