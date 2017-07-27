# hxcss
CSS2 and CSS3 parser written in Haxe (for cross-platform compatibility)

_Based on [Rework's css parser](https://github.com/reworkcss/css)_

### Usage
Parse a css string:
```hx
import haxe.ds.StringMap;
import hxcss.Parser;

class Main
{

	static function main()
	{
		var cssString = "body {background: #eee;color: #888;}"; //"foo,bar,baz{color:'black';}";
		var AST = Parser.parse(cssString, ["source" => 'foobar.css']);
		trace(AST);
	}

}
```
AST:
This parser returns a valid haxe data Map as the Abstract syntax tree.
```hx
[
	type => stylesheet, 
	stylesheet => 
		[
			parsingErrors => [], 
			rules => [
				[
					position => [
						source => foobar.css, 
						start => [line => 1, column => 1],
						end => [line => 1, column => 25]
					], 
					selectors => [body], 
					type => rule, 
					declarations => [
						[
							position => [
								source => foobar.css, 
								start => [line => 1, column => 7], 
								end => [line => 1, column => 23]
							], 
							type => declaration, 
							property => background, 
							value => #eee
						]
					]
				]
			]
		]
]
```

### API
### hxcss.parse(code, [options])

Accepts a CSS string and returns an AST `Map<String, T>`.

`options`:

- silent: silently fail on parse errors.
- source: the path to the file containing `css`. Makes errors and source
  maps more helpful, by letting them know where code comes from.

### Example

```hx
var ast = hxcss.Parser.parse('body { font-size: 12px; }', [ "source" => 'source.css' ]);

```


## AST Structure

### Common properties

All nodes have the following properties.

#### position

Information about the position in the source string that corresponds to
the node.

`Map<String, T>` =>

- start => `Map<String, T>`
  - line => `Number`.
  - column => `Number`.
- end => `Map<String, T>`:
  - line => `Number`.
  - column => `Number`.
- source: `String` or `null`. The value of `options.source` if passed to
  `hxcss.Parser.parse`. Otherwise `null`.
- content: `String`. The full source string passed to `hxcss.Parser.parse`.

The line and column numbers are 1-based: The first line is 1 and the first
column of a line is 1 (not 0).

The `position` property lets you know from which source file the node comes
from (if available), what that file contains, and what part of that file was
parsed into the node.

#### type

`String`. The possible values are the ones listed in the Types section below.

#### parent

A reference to the parent node, or `null` if the node has no parent.

### Types

The available values of `node.get("type")` are listed below, as well as the available
properties of each node (other than the common properties listed above.)

#### stylesheet

The root node returned by `hxcss.Parser.parse`.

- stylesheet: `Map<String, T>`:
  - rules: `Array` of nodes with the types `rule`, `comment` and any of the
    at-rule types.

#### rule

- selectors: `Array` of `String`s. The list of selectors of the rule, split
  on commas. Each selector is trimmed from whitespace and comments.
- declarations: `Array` of nodes with the types `declaration` and `comment`.

#### declaration

- property: `String`. The property name, trimmed from whitespace and
  comments. May not be empty.
- value: `String`. The value of the property, trimmed from whitespace and
  comments. Empty values are allowed.

#### comment

A rule-level or declaration-level comment. Comments inside selectors,
properties and values etc. are lost.

- comment: `String`. The part between the starting `/*` and the ending `*/`
  of the comment, including whitespace.

#### charset

The `@charset` at-rule.

- charset: `String`. The part following `@charset `.

#### custom-media

The `@custom-media` at-rule.

- name: `String`. The `--`-prefixed name.
- media: `String`. The part following the name.

#### document

The `@document` at-rule.

- document: `String`. The part following `@document `.
- vendor: `String` or `null`. The vendor prefix in `@document`, or
  `undefined` if there is none.
- rules: `Array` of nodes with the types `rule`, `comment` and any of the
  at-rule types.

#### font-face

The `@font-face` at-rule.

- declarations: `Array` of nodes with the types `declaration` and `comment`.

#### host

The `@host` at-rule.

- rules: `Array` of nodes with the types `rule`, `comment` and any of the
  at-rule types.

#### import

The `@import` at-rule.

- import: `String`. The part following `@import `.

#### keyframes

The `@keyframes` at-rule.

- name: `String`. The name of the keyframes rule.
- vendor: `String` or `undefined`. The vendor prefix in `@keyframes`, or
  `undefined` if there is none.
- keyframes: `Array` of nodes with the types `keyframe` and `comment`.

#### keyframe

- values: `Array` of `String`s. The list of “selectors” of the keyframe rule,
  split on commas. Each “selector” is trimmed from whitespace.
- declarations: `Array` of nodes with the types `declaration` and `comment`.

#### media

The `@media` at-rule.

- media: `String`. The part following `@media `.
- rules: `Array` of nodes with the types `rule`, `comment` and any of the
  at-rule types.

#### namespace

The `@namespace` at-rule.

- namespace: `String`. The part following `@namespace `.

#### page

The `@page` at-rule.

- selectors: `Array` of `String`s. The list of selectors of the rule, split
  on commas. Each selector is trimmed from whitespace and comments.
- declarations: `Array` of nodes with the types `declaration` and `comment`.

#### supports

The `@supports` at-rule.

- supports: `String`. The part following `@supports `.
- rules: `Array` of nodes with the types `rule`, `comment` and any of the
  at-rule types.

