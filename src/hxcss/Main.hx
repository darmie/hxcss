package hxcss;

import cpp.Lib;

/**
 * ...
 * @author Damilare Akinlaja
 */
class Main 
{
	
	static function main() 
	{
        var cssString = "foo,bar,baz{color:'black';}";
        
        trace(Parser.parse(cssString, ["source"=>'foobar.css']));		
	}
	
}