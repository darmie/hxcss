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
	public var source:String;
	public var options:StringMap<Dynamic>;
	
    private var importStatements:Array<Dynamic> = [];
    private var keyframeStatements:Array<Dynamic> = [];	
	
	private var cssRegex:EReg = ~/([\s\S]*?){([\s\S]*?)*}/ig;
	private var mediaQueryRegex:String = "@media([\\s\\S]*?){([\\s\\S]*?}\\s*?)}";
	private var keyframeRegex:String = "((@.*?keyframes [\\s\\S]*?){([\\s\\S]*?}\\s*?)})";
	private var combinedCSSRegex:String = "(((\\s*?(?:\\/\\*[\\s\\S]*?\\*\\/)?\\s*?@media[\\s\\S]*?){([\\s\\S]*?)}\\s*?})|(([\\s\\S]*?){([\\s\\S]*?)*}))";
	private var commentRegex:String = "\\/\\*[\\s\\S]*?\\*\\/";
	private var importRegex:EReg = new EReg('@import .*?;', 'ig');
	

	public function new(source:String, options:StringMap<Dynamic>)
	{
		this.source = source;
		if (options != null)
		{
			this.options = options;
		}
		else
		{
			this.options = new StringMap<Dynamic>();
		}

	}
	
  /*
    Strip outs css comments and returns cleaned css string
    @param css, the original css string to be stipped out of comments
    @return cleanedCSS contains no css comments
  */
	
	public function stripComments(css:String):String
	{
		var regex = new EReg(this.commentRegex, 'ig');
		
		return regex.replace(css, '');
	}
	
  /*
    parses given string containing css directives
    and returns an array of objects containing ruleName:ruleValue pairs
    @param rules, css directive string example
        \n\ncolor:white;\n    font-size:18px;\n
  */
		
	public function parseRules(rules:String):Array<StringMap<Dynamic>>
	{
		//convert all windows style line endings to unix style line endings
		rules = rules.split('\r\n', '\n');
		var ret:Array<StringMap<Dynamic>> = [];
		
		
		rules = rules.split(';');
		
		//proccess rules line by line
		
		for (i in 0...rules.length){
			
			var line = rules.charAt(i);
			
			//determine if line is a valid css directive, ie color:white;
			line = line.trim();
			if (line.indexOf(':') != -1) {
				//line contains :
				line = line.split(':');
				var directive:String = line.charAt(0).trim();
				var value = line.split("").slice(1).join(':').trim();
				
				//more checks
				if(directive.length < 1 || value.length < 1){
					continue; //there is no css directive or value that is of length 1 or 0
					// PLAIN WRONG WHAT ABOUT margin:0; ?
				}
				
				//push rule
				ret.push([
					"directive" => directive,
					"value" => value
				]);
			}else{
				//if there is no ':', but what if it was mis splitted value which starts with base64
				 if (line.trim().substr(0, 7) == 'base64,') { //hack :)
					 var _line += line.trim();
					 ret[ret.length -1].set("value", _line);
				 }else{
					 //add rule, even if it is defective
					 if (line.length > 0) {
						 ret.push([
							"directive" => '',
							"value" => line,
							"defective" => true
						 ]);
					 }
				 }
			}
		}
		
		return ret; //we are done !
	}
	
  /*
    just returns the rule having given directive
    if not found returns false;
  */
	public function findCorrespondingRule(rules:Array<StringMap<Dynamic>>, directive:String, value:Dynamic = null):StringMap<Dynamic>
	{

		var ret = null;
		for(i in 0...rules.length){
			if(rules[i].get("directive") == directive){
				ret = rules[i];
				if(value == rules[i].get("value")){
					break;
				}
			}
		}
		
		return ret;
	}
	
  /*
      Finds styles that have given selector, compress them,
      and returns them
  */
	public function findBySelector(objectArray:Array<StringMap<Dynamic>>, selector:String, contains:Bool == false):Array<StringMap<Dynamic>>
	{
		
		var found:Array<StringMap<Dynamic>> = [];
		
		for(i in 0...objectArray.length){
			if(contains == false){
				if(objectArray[i].get("selector") == selector){
					found.push(objectArray[i]);
				}
			}else{
				if(cast(objectArray[i].get("selector"), String).indexOf(selector) != -1){
					found.push(objectArray[i]);
				}
			}
		}
		
		if (selector == '@imports' || found.length < 2){
			return found;
			
		}else{
			var base = found[0];
			for (i in 0...found.length){
				
				this.intelligentCSSPush([base], found[i]);
			}
			
			return [base]; //we are done!! all properties merged into base!
		}
	}
	
  /*
    deletes cssObjects having given selector, and returns new array
  */
	
	public function deleteBySelector(objectArray:Array<StringMap<Dynamic>>, selector:String):Array<StringMap<Dynamic>>
	{
		var ret:Array<StringMap<Dynamic>> = [];
		for(i in 0...objectArray.length){
			if(objectArray[i].get("selector") != selector){
				ret.push(objectArray[i]);
			}
		}
		return ret;
	}
	
  /*
      Compresses given cssObjectArray and tries to minimize
      selector redundence.
  */
	  
	
	public function compress(objectArray:Array<StringMap<Dynamic>>):Array<StringMap<Dynamic>>
	{
		var compressed:Array<StringMap<Dynamic>> = [];
		var done:StringMap<Dynamic> = new StringMap<Dynamic>();
		
		for(i in 0...objectArray.length){
			var obj = objectArray[i];
			
			if(done.get(obj.get("selector")) == true){
				continue;
			}
			
			var found = this.findBySelector(objectArray, obj.get("selector")); //found compressed
			if (found.length != 0) {
				compressed = compressed.concat(found);
				done.set("selector", true);
			}
		}
		
		return compressed;
		
	}
	
  /*
    Received 2 css objects with following structure
      [
        rules => [[directive =>"", value =>""], [directive =>"", value =>""], ...]
        selector => "SOMESELECTOR"
      ]
    returns the changed(new,removed,updated) values on css1 parameter, on same structure
    if two css objects are the same, then returns false
      if a css directive exists in css1 and     css2, and its value is different, it is included in diff
      if a css directive exists in css1 and not css2, it is then included in diff
      if a css directive exists in css2 but not css1, then it is deleted in css1, it would be included in diff but will be marked as type='DELETED'
      @object css1 css object
      @object css2 css object
      @return diff css object contains changed values in css1 in regards to css2 see test input output in /test/data/css.js
  */
	  
    public function diff(object1:StringMap<Dynamic>, object2:StringMap<Dynamic>):StringMap<Dynamic> 
	{
		if(object1.get("selector") == object2.get("selector")){
			return null;
		}
		
		//if one of them is media query return false, because diff function can not operate on media queries
		if ((object1.get("type") == 'media' || object2.get("type") == 'media')) {
			return null;
		}
		
		var diff:StringMap<Dynamic> = [
			"selector" => object1.get("selector"),
			"rules" => new Array<StringMap<Dynamic>>()
		];
		
		var rule1:StringMap<Dynamic> = new StringMap<Dynamic>();
		var rule2:StringMap<Dynamic> = new StringMap<Dynamic>();
		
		var _length:Int = cast(object1.get("rules"), Array<Dynamic>).length;
		var _length2:Int = cast(object2.get("rules"), Array<Dynamic>).length;
		
		for(i in 0..._length){
			rule1 = cast(object1.get("rules"), Array<Dynamic>)[1];
			 //find rule2 which has the same directive as rule1
			rule2 = cast this.findCorrespondingRule(object2.get(rules), object1.get("directive"), object1.get("value"));
			
			if(rule2 == null){
				//rule1 is a new rule in css1
				cast(diff.get("rules"), Array<Dynamic>)).push(rule1);
			}else{
				//rule2 was found only push if its value is different too
				if (rule1.get("value") !== rule2.get("value")) {
				  cast(diff.get("rules"), Array<Dynamic>)).push(rule1);
				}
			}
		}
		
		//now for rules exists in css2 but not in css1, which means deleted rules
		
		for(i in 0..._length2){
			rule2 = cast(object1.get("rules"), Array<Dynamic>)[1];
			//find rule1 which has the same directive as rule1
			rule1 = this.findCorrespondingRule(object1.get(rules), object2.get("directive"));
			
			  if (rule1 == null) {
				//rule1 is a new rule
				rule2.set("type", 'DELETED'); //mark it as a deleted rule, so that other merge operations could be true
				cast(diff.get("rules"), Array<Dynamic>)).push(rule2);
			  }			
		}
		
		if (cast(diff.get("rules"), Array<Dynamic>)).length == 0) {
		  return null;
		}
		return diff;		
		
	}
	
	
  /*
      Merges 2 different css objects together
      using intelligentCSSPush,
      @param cssObjectArray, target css object array
      @param newArray, source array that will be pushed into cssObjectArray parameter
      @param reverse, [optional], if given true, first parameter will be traversed on reversed order
              effectively giving priority to the styles in newArray
  */
			  
	public function intelligentMerge(objectArray:Array<StringMap<Dynamic>>, newArray:Array<StringMap<Dynamic>>, reverse:Bool = false):Void
	{
		for (i in 0...newArray.length) {
		  this.intelligentCSSPush(objectArray, newArray[i], reverse);
		}
		for (i in 0...objectArray.length) {
		  var cobj:StringMap<Dynamic> = objectArray[i];
		  if (cobj.get("type") == 'media' || (cobj.get("type") == 'keyframes')) {
			continue;
		  }
		  cobj.set("rules", this.compactRules(cobj.get("rules")));
		}		
	}
	
	
  /*
    inserts new css objects into a bigger css object
    with same selectors grouped together
    @param cssObjectArray, array of bigger css object to be pushed into
    @param minimalObject, single css object
    @param reverse [optional] default is false, if given, cssObjectArray will be reversly traversed
            resulting more priority in minimalObject's styles
  */
	
	public function intelligentCSSPush(objectArray:Array<StringMap<Dynamic>>, minimalObject:StringMap<Dynamic>, reverse:Bool = false):Void
	{
		var pushSelector = minimalObject.get("selector");
		//find correct selector if not found just push minimalObject into cssObject
		var cssObject:StringMap<Dynamic> = null;
		if (reverse == false) {
		  for (i in 0...objectArray.length) {
			if (objectArray[i].get("selector") == minimalObject.get("selector")) {
			  cssObject = objectArray[i];
			  break;
			}
		  }
		} else {
		  var j = objectArray.length - 1;	
		  while (j > -1) {
			if (cssObjectArray[j].get("selector") == minimalObject.get("selector")) {
			  cssObject = objectArray[j];
			  break;
			}
			j--;
		  }
		}
		if (cssObject == null) {
		  objectArray.push(minimalObject); //just push, because cssSelector is new
		} else {
		  if (minimalObject.get("type") != 'media') {
			var mRules:Array<StringMap<Dynamic>> = cast minimalObject.get("rules");  
			for (i in 0...length) {
			  var rule:StringMap<Dynamic> = mRules[i];
			  //find rule inside cssObject
			  var oldRule = this.findCorrespondingRule(cssObject.get("rules"), rule.get("directive"));
			  if (oldRule == null) {
				var cRules:Array<StringMap<Dynamic>> = cssObject.get("rules");
				cRules.push(rule);
			  } else if (rule.get("type") == 'DELETED') {
				oldRule.set("type", 'DELETED');
			  } else {
				//rule found just update value

				oldRule.set("value", rule.get("value"));
			  }
			}
		  } else {
			cssObject.set("value",  cast(cssObject.get("subStyles"), Array<Dynamic>).concat(minimalObject.get("subStyles"))); //TODO, make this intelligent too
		  }

		}		
	}
	
  /*
    filter outs rule objects whose type param equal to DELETED
    @param rules, array of rules
    @returns rules array, compacted by deleting all unnecessary rules
  */
	public function compactRules(rules:Array<StringMap<Dynamic>>):Array<StringMap<Dynamic>>
	{
		var newRules:Array<StringMap<Dynamic>> = [];
		for(i in 0...rules.length){
		  if (rules[i].get("type") != 'DELETED') {
			newRules.push(rules[i]);
		  }			
		}
		
		return newRules;
		
	}
	
		/**
		 * Get Imports
		 * 
		 */
	public function getImports(objectArray:Array<StringMap<Dynamic>>):Array<Dynamic>{
		var imps = [];
		for (i in 0...objectArray.length) {
		  if (objectArray[i].get("type") == 'imports') {
			imps.push(objectArray[i].get("styles"));
		  }
		}
		return imps;		
	}
  
  /*
    Parses given css string, and returns css object
    keys as selectors and values are css rules
    eliminates all css comments before parsing
    @param source css string to be parsed
    @return object css
  */  
	public function parse():StringMap<Dynamic> 
	{
		if (this.source == null) {
		  return null;
		}	
		
		var css = new StringMap<Dynamic>();
		//get import statements
		
		while (true) {
			var m:Bool = this.importRegex.match(this.source);
			var val:String = null;
			if(m){
				val = this.importRegex.matched(0);
			}
			var imports = val;
			if (imports != null) {
				this.importStatements.push(imports);
				css.push([
				  "selector" => '@imports',
				  "type" => 'imports',
				  "styles" => imports
				]);
			} else {
				break;
			}
		}
		
		this.source = importRegex.replace(this.source, '');
		
		//get keyframe statements
		
		var keyframesRegex = new EReg(this.keyframeRegex, 'gi');
		
		var arr;
		
		//var _css:StringMap<Dynamic> = Parser.addParent((new Parser(css.trim(), options)).stylesheet());
		return css;
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
		//map.set("content", this.content.trim());
		
		return map;
	}
}