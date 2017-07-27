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
		var cssString = "body {background: #eee;color: #888;}"; //"foo,bar,baz{color:'black';}";
		var AST = Parser.parse(cssString, ["source" => 'foobar.css']);
		trace(AST);
	}

}