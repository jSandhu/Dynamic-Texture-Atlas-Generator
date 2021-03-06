package com.emibap.textureAtlas
{

	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.Font;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getQualifiedClassName;
	
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	/**
	 * DynamicAtlas.as
	 * https://github.com/emibap/Dynamic-Texture-Atlas-Generator
	 * @author Emibap (Emiliano Angelini) - http://www.emibap.com
		 * Contribution by Thomas Haselwanter - https://github.com/thomashaselwanter
	 * Most of this comes thanks to the inspiration (and code) of Thibault Imbert (http://www.bytearray.org) and Nicolas Gans (http://www.flashxpress.net/)
	 * 
	 * Dynamic Texture Atlas and Bitmap Font Generator (Starling framework Extension)
	 * ========
	 *
	 * This tool will convert any MovieClip containing Other MovieClips, Sprites or Graphics into a starling Texture Atlas, all in runtime.
	 * It can also register bitmap Fonts from system or embedded regular fonts.
	 * By using it, you won't have to statically create your spritesheets or fonts. For instance, you can just take a regular MovieClip containing all the display objects you wish to put into your Altas, and convert everything from vectors to bitmap textures.
	 * Or you can select which font (specifying characters) you'd like to register as a Bitmap Font, using a string or passing a Regular TextField as a parameter.
	 * This extension could save you a lot of time specially if you'll be coding mobile apps with the [starling framework](http://www.starling-framework.org/).
	 *
	 * # version 0.9.5 #
	 * - Added the fromClassVector static function. Thank you Thomas Haselwanter
	 *
	 * ### Features ###
	 *
	 * * Dynamic creation of a Texture Atlas from a MovieClip (flash.display.MovieClip) container that could act as a sprite sheet, or from a Vector of Classes
	 * * Filters made to the objects are captured
	 * * Color transforms (tint, alpha) are optionally captured
	 * * Scales the objects (and also the filters) to a specified value
	 * * Automatically detects the objects bounds so you don't necessarily have to set the registration points to TOP LEFT
	 * * Registers Bitmap Fonts based on system or embedded fonts from strings or from good old Flash TextFields
	 * 
	 * ### TODO List ###
	 *
	 * * Further code optimization
	 * * A better implementation of the Bitmap Font creation process
	 * * Documentation (?)
	 *
	 * ### Whish List ###
	 * * Optional division of the process into small intervals (for smooth performance of the app)
	 * 
	 * ### Usage ###
	 * 
	 * 	You can use the following static methods (examples at the gitHub Repo):
	 *	
	 * 	[Texture Atlas creation]
	 * 	- DynamicAtlas.fromMovieClipContainer(swf:flash.display.MovieClip, scaleFactor:Number = 1, margin:uint=0, preserveColor:Boolean = true):starling.textures.TextureAtlas
	 * 	- DynamicAtlas.fromClassVector(assets:Vector.<Class>, scaleFactor:Number = 1, margin:uint=0, preserveColor:Boolean = true):starling.textures.TextureAtlas
	 *
	 * [Bitmap Font registration]
	 * - DynamicAtlas.bitmapFontFromString(chars:String, fontFamily:String, fontSize:Number = 12, bold:Boolean = false, italic:Boolean = false, charMarginX:int=0):void
	 * - DynamicAtlas.bitmapFontFromTextField(tf:flash.text.TextField, charMarginX:int=0):void
	 *
	 * 	Enclose inside a try/catch for error handling:
	 * 		try {
	 * 				var atlas:TextureAtlas = DynamicAtlas.fromMovieClipContainer(mc);
	 * 			} catch (e:Error) {
	 * 				trace("There was an error in the creation of the texture Atlas. Please check if the dimensions of your clip exceeded the maximun allowed texture size. -", e.message);
	 * 			}
	 *
	 *  History:
	 *  -------
	 * # version 0.9 #
	 * - Added Bitmap Font creation support
	 * - Added the 
	 * - Scaling also applies to filters.
	 * - Added Margin and PreserveColor Properties
	 * 
	 * # version 0.8 #
	 * - Added the scaleFactor constructor parameter. Now you can define a custom scale to the final result.
	 * - Scaling also applies to filters.
	 * - Added Margin and PreserveColor Properties
	 * 
	 * # version 0.7 #
	 * First Public version
	 **/
	
	public class DynamicAtlas
	{
		static public const MAX_CANVAS_DIMENSION:Number = 2048;
		
		static protected var _items:Array;
		static protected var _canvas:Sprite;
		
		static protected var _currentLab:String;
		
		static protected var _bData:BitmapData;
		static protected var _mat:Matrix;
		static protected var _margin:Number;
		static protected var _preserveColor:Boolean;
		
		static protected var _scaleFactor:Number = 1;
		
		// Will not be used - Only using one static method
		public function DynamicAtlas()
		{
		
		}
		
		// Private methods
		
		static protected function appendIntToString(num:int, numOfPlaces:int):String
		{
			var numString:String = num.toString();
			var outString:String = "";
			for (var i:int = 0; i < numOfPlaces - numString.length; i++)
			{
				outString += "0";
			}
			return outString + numString;
		}
		
		static protected function layoutChildren():void
		{
			var xPos:Number = 0;
			var yPos:Number = 0;
			var maxY:Number = 0;
			var len:int = _items.length;
			
			var itm:TextureItem;
			
			for (var i:uint = 0; i < len; i++)
			{
				itm = _items[i];
				if ((xPos + itm.width) > MAX_CANVAS_DIMENSION)
				{
					xPos = 0;
					yPos += maxY;
					maxY = 0;
				}
				if (itm.height + 1 > maxY)
				{
					maxY = itm.height + 1;
				}
				itm.x = xPos;
				itm.y = yPos;
				xPos += itm.width + 1;
			}
		}
	
		/**
		* isEmbedded
		* 
		* @param	fontFamily:Boolean - The name of the Font
		* @return Boolean - True if the font is an embedded one
		*/
		static protected function isEmbedded(fontFamily:String):Boolean 
		{
		   var embeddedFonts:Vector.<Font> = Vector.<Font>(Font.enumerateFonts());
		   
		   for (var i:int = embeddedFonts.length - 1; i > -1 && embeddedFonts[i].fontName != fontFamily; i--) { }
		   
		   return (i > -1);
		}
		
		/**
		 * drawItem - This will actually rasterize the display object passed as a parameter
		 * @param	clip
		 * @param	name
		 * @param	baseName
		 * @param	clipColorTransform
		 * @return TextureItem
		 */
		static protected function drawItem(clip:DisplayObject, name:String = "", baseName:String = "", clipColorTransform:ColorTransform = null):TextureItem
		{
			var bounds:Rectangle = clip.getBounds(clip.parent);
			bounds.x = Math.floor(bounds.x);
			bounds.y = Math.floor(bounds.y);
			bounds.height = Math.ceil(bounds.height);
			bounds.width = Math.ceil(bounds.width);
			
			bounds.width = bounds.width > 0 ? bounds.width : 1;
			bounds.height = bounds.height > 0 ? bounds.height : 1;
			
			var realBounds:Rectangle = new Rectangle(0, 0, bounds.width + _margin * 2, bounds.height + _margin * 2);
			
			// Checking filters in case we need to expand the outer bounds
			if (clip.filters.length > 0)
			{
				// filters
				var j:int = 0;
				//var clipFilters:Array = clipChild.filters.concat();
				var clipFilters:Array = clip.filters;
				var clipFiltersLength:int = clipFilters.length;
				var tmpBData:BitmapData;
				var filterRect:Rectangle;
				
				tmpBData = new BitmapData(realBounds.width, realBounds.height, false);
				filterRect = tmpBData.generateFilterRect(tmpBData.rect, clipFilters[j]);
				tmpBData.dispose();
				
				while (++j < clipFiltersLength)
				{
					tmpBData = new BitmapData(filterRect.width, filterRect.height, true, 0);
					filterRect = tmpBData.generateFilterRect(tmpBData.rect, clipFilters[j]);
					realBounds = realBounds.union(filterRect);
					tmpBData.dispose();
				}
			}
			
			realBounds.offset(bounds.x, bounds.y);
			realBounds.width = Math.max(realBounds.width, 1);
			realBounds.height = Math.max(realBounds.height, 1);
			
			_bData = new BitmapData(realBounds.width, realBounds.height, true, 0);
			_mat = clip.transform.matrix;
			_mat.translate(-realBounds.x + _margin, -realBounds.y + _margin);
			
			advanceChildren(clip);
			_bData.draw(clip, _mat, _preserveColor ? clipColorTransform : null);
			
			//realBounds.offset(-_x - _margin, -_y - _margin);
			
			var label:String = "";
			if (clip is MovieClip) {
				if (clip["currentLabel"] != _currentLab && clip["currentLabel"] != null)
				{
					_currentLab = clip["currentLabel"];
					label = _currentLab;
				}
			}

			var item:TextureItem = new TextureItem(_bData, name, label, _mat.tx - clip.x * _scaleFactor, _mat.ty - clip.y * _scaleFactor, _bData.width, _bData.height);
			_items.push(item);
			_canvas.addChild(item);
			
			tmpBData = null;
			_bData = null;
			
			return item;
		}
		
		private static function advanceChildren(clip:DisplayObject):void {
			var doc:DisplayObjectContainer = clip as DisplayObjectContainer;
			if (!doc) return;
			
			for (var i:uint = 0; i < doc.numChildren; i++) {
				var child:MovieClip = doc.getChildAt(i) as MovieClip;
				if (!child) continue;
				
				var curChildFrame:uint = child.currentFrame;
				if (curChildFrame < child.totalFrames) {
					child.gotoAndStop(++curChildFrame);
				} else {
					child.gotoAndStop(1);
				}
			}
		}
		
		// Public methods

        /**
         * This method takes a vector of MovieClip class and converts it into a Texture Atlas.
		 *
         * @param	assets:Vector.<Class> - The MovieClip classes you wish to convert into a TextureAtlas. Must contain classes whose instances are of type MovieClip that will be rasterized and become the subtextures of your Atlas.
         * @param	scaleFactor:Number - The scaling factor to apply to every object. Default value is 1 (no scaling).
         * @param	margin:uint - The amount of pixels that should be used as the resulting image margin (for each side of the image). Default value is 0 (no margin).
         * @param	preserveColor:Boolean - A Flag which indicates if the color transforms should be captured or not. Default value is true (capture color transform).
         * @return  TextureAtlas - The dynamically generated Texture Atlas.
         * @return
         */
        static public function fromClassVector(assets:Vector.<Class>, scaleFactor:Number = 1, margin:uint=0, preserveColor:Boolean = true):TextureAtlas
        {
            var container:MovieClip = new MovieClip();
            for each (var assetClass:Class in assets) {
                var assetInstance:MovieClip = new assetClass();
                assetInstance.name = getQualifiedClassName(assetClass);
                container.addChild(assetInstance);
            }
            return fromMovieClipContainer(container, scaleFactor, margin, preserveColor);
        }

        /** Retrieves all textures for a class. Returns <code>null</code> if it is not found.
         * This method can be used if TextureAtlass doesn't support classes.
         */
        static public function getTexturesByClass(textureAtlas:TextureAtlas, assetClass:Class):Vector.<Texture> {
            return textureAtlas.getTextures(getQualifiedClassName(assetClass));
        }
		
		/**
		 * This method will take a MovieClip sprite sheet (containing other display objects) and convert it into a Texture Atlas.
		 * 
		 * @param	swf:MovieClip - The MovieClip sprite sheet you wish to convert into a TextureAtlas. I must contain named instances of every display object that will be rasterized and become the subtextures of your Atlas.
		 * @param	scaleFactor:Number - The scaling factor to apply to every object. Default value is 1 (no scaling).
		 * @param	margin:uint - The amount of pixels that should be used as the resulting image margin (for each side of the image). Default value is 0 (no margin).
		 * @param	preserveColor:Boolean - A Flag which indicates if the color transforms should be captured or not. Default value is true (capture color transform).
		 * @param	fromFrameLabel:String - Only draw frames between specified frameLabel and the next one (fromFrameLabel frame inclusive).  
		 * @return  TextureAtlas - The dynamically generated Texture Atlas.
		 */
		static public function fromMovieClipContainer(swf:DisplayObjectContainer, scaleFactor:Number = 1, 
													  margin:uint=0, preserveColor:Boolean = true, fromFrameLabel:String = null):TextureAtlas
		{
			_scaleFactor = scaleFactor;
			
			var parseFrame:Boolean = false;
			var selected:DisplayObject;
			var selectedTotalFrames:int;
			var selectedColorTransform:ColorTransform;
			
			var children:uint = swf.numChildren;
			
			var canvasData:BitmapData;
			
			var texture:Texture;
			var xml:XML;
			var subText:XML;
			var atlas:TextureAtlas;
			
			var itemsLen:int;
			var itm:TextureItem;
			
			var m:uint;
			
			_margin = margin;
			_preserveColor = preserveColor;
			
			_items = [];
			
			if (!_canvas)
				_canvas = new Sprite();
			if (swf is MovieClip)
				MovieClip(swf).gotoAndStop(1);
			
			applyScale(swf, scaleFactor);
			
			for (var i:uint = 0; i < children; i++)
			{
				selected = swf.getChildAt(i);
				selectedColorTransform = selected.transform.colorTransform;
				
				if (selected is MovieClip) {
					// Draw every frame
					var selectedMovie:MovieClip = MovieClip(selected);
					if (fromFrameLabel) {
						selectedMovie.gotoAndStop(fromFrameLabel);
						m = selectedMovie.currentFrame;
					} else {
						m = 1;	
					}
					selectedTotalFrames = selectedMovie.totalFrames;
					while (m <= selectedTotalFrames) {
						selectedMovie.gotoAndStop(m);
						
						// if we are copying frames from a label, and we have reached the next label, break;
						if (fromFrameLabel && selectedMovie.currentFrameLabel != null  && selectedMovie.currentFrameLabel != fromFrameLabel) break;

						drawItem(selected, selectedMovie.name + "_" + appendIntToString(m - 1, 5), selectedMovie.name, selectedColorTransform);
						m++;
					}
				} else {
					drawItem(selected, selected.name + "_" + appendIntToString(0, 5), selected.name, selectedColorTransform);
				}
			}
			
			_currentLab = "";
			
			layoutChildren();
			
			var maxDimension:Number = _canvas.width > _canvas.height ? _canvas.width : _canvas.height;
			
			// If frame dimensions are too large suggest a scale that will 
			// guarantee that all frames will fit within the max sprite sheet dimensions.
			if (maxDimension > MAX_CANVAS_DIMENSION) {
				var suggestedScale:Number = getSuggestedScale();
				
				// undo scale changes and clean up
				applyScale(swf, 1/scaleFactor);
				cleanUp();	
				
				throw new ScaleFactorTooLargeError(suggestedScale);
			}
			
			canvasData = new BitmapData(_canvas.width, _canvas.height, true, 0x000000);
			canvasData.draw(_canvas);
			
			xml = new XML(<TextureAtlas></TextureAtlas>);
			xml.@imagePath = "atlas.png";
			
			itemsLen = _items.length;
			
			for (var k:uint = 0; k < itemsLen; k++)
			{
				itm = _items[k];
				
				itm.graphic.dispose();
				
				// xml
				subText = new XML(<SubTexture />); 
				subText.@x = itm.x;
				subText.@y = itm.y;
				subText.@width = itm.width;
				subText.@height = itm.height;
				subText.@name = itm.textureName;
				subText.@frameWidth = TextureItem.frameWidth;
				subText.@frameHeight = TextureItem.frameHeight;
				subText.@frameX = itm.frameOffsetX;
				subText.@frameY = itm.frameOffsetY;
				
				if (itm.frameName != "")
					subText.@frameLabel = itm.frameName;
				xml.appendChild(subText);
			}
			texture = Texture.fromBitmapData(canvasData);
			atlas = new TextureAtlas(texture, xml);
			xml = null;
			
			applyScale(swf, 1/scaleFactor);
			cleanUp();
			
			return atlas;
		}
		
		private static function cleanUp():void {
			_items.length = 0;
			_canvas.removeChildren();
			
			_items = null;
			_canvas = null;
			_currentLab = null;
			
			TextureItem.frameWidth = 0;
			TextureItem.frameHeight = 0;
			
			//_x = _y = _margin = null;
		}
		
		private static function applyScale(swf:DisplayObjectContainer, scaleFactor:Number):void {
			var selected:DisplayObject;
			var selectedTotalFrames:int;
			var selectedColorTransform:ColorTransform;			
			
			var children:uint = swf.numChildren;
			for (var i:uint = 0; i < children; i++)
			{
				selected = swf.getChildAt(i);
				selectedColorTransform = selected.transform.colorTransform;
				
				// Scaling if needed (including filters)
				if (scaleFactor != 1)
				{
					selected.scaleX *= scaleFactor;
					selected.scaleY *= scaleFactor;
					
					if (selected.filters.length > 0)
					{
						var filters:Array = selected.filters;
						var filtersLen:int = selected.filters.length;
						var filter:Object;
						for (var j:uint = 0; j < filtersLen; j++)
						{
							filter = filters[j];
							
							if (filter.hasOwnProperty("blurX"))
							{
								filter.blurX *= scaleFactor;
								filter.blurY *= scaleFactor;
							}
							if (filter.hasOwnProperty("distance"))
							{
								filter.distance *= scaleFactor;
							}
						}
						selected.filters = filters;
					}
				}
			}
			
		}
		/**
		 * Returns a scale that will guarantee that all frames will
		 * fit within max spritesheet dimensions.
		 */
		private static function getSuggestedScale():Number {
			var unscaledWidth:Number = TextureItem.frameWidth / _scaleFactor;
			var unscaledHeight:Number = TextureItem.frameHeight / _scaleFactor;
			var whRatio:Number = unscaledWidth / unscaledHeight;
			
			var i:uint = 1;
			var found:Boolean = false;
			var newFWidth:Number;
			var newFHeight:Number;
			while(!found) {
				newFWidth = 2048/i - i * _margin * 2;
				newFHeight = newFWidth / whRatio;
				var numRows:Number = Math.ceil(_items.length / i);
				var totalHeight:Number = numRows * (newFHeight + 2 * _margin);
				if (totalHeight < 2048) {
					found = true;
				}
				i++
			}
			
			var suggestedScale:Number = newFHeight/unscaledHeight;
			if (suggestedScale > 1)
				suggestedScale = 1;	
			
			return suggestedScale;
		}
		
		/**
		 * This method will register a Bitmap Font based on each char that belongs to a String.
		 * 
		 * @param	chars:String - The collection of chars which will become the Bitmap Font
		 * @param	fontFamily:String - The name of the Font that will be converted to a Bitmap Font
		 * @param	fontSize:Number - The size in pixels of the font.
		 * @param	bold:Boolean - A flag indicating if the font will be rasterized as bold.
		 * @param	italic:Boolean - A flag indicating if the font will be rasterized as italic.
		 * @param	charMarginX:int - The number of pixels that each character should have as horizontal margin (negative values are allowed). Default value is 0.
		 */
		static public function bitmapFontFromString(chars:String, fontFamily:String, fontSize:Number = 12, bold:Boolean = false, italic:Boolean = false, charMarginX:int=0):void {
			var format:TextFormat = new TextFormat(fontFamily, fontSize, 0xFFFFFF, bold, italic);
			var tf:flash.text.TextField = new flash.text.TextField();
			
			tf.autoSize = TextFieldAutoSize.LEFT;
			
			
			// If the font is an embedded one (I couldn't get to work the Array.indexOf method) :(
			if (isEmbedded(fontFamily)) {
				tf.antiAliasType = AntiAliasType.ADVANCED;
				tf.embedFonts = true;
			}
			
			tf.defaultTextFormat = format;
			tf.text = chars;
			
			bitmapFontFromTextField(tf, charMarginX);
		}
		
		/**
		 * This method will register a Bitmap Font based on each char that belongs to a regular flash TextField, rasterizing filters and color transforms as well.
		 * 
		 * @param	tf:flash.text.TextField - The textfield that will be used to rasterize every char of the text property
		 * @param	charMarginX:int - The number of pixels that each character should have as horizontal margin (negative values are allowed). Default value is 0.
		 */
		static public function bitmapFontFromTextField(tf:flash.text.TextField, charMarginX:int=0):void {
			var charCol:Vector.<String> = Vector.<String>(tf.text.split(""));
			var format:TextFormat = tf.defaultTextFormat;
			var fontFamily:String = format.font;
			var fontSize:Object = format.size;
			
			var oldAutoSize:String = tf.autoSize;
			tf.autoSize = TextFieldAutoSize.LEFT;
			
			var canvasData:BitmapData;
			var texture:Texture;
			var xml:XML;
			
			var myChar:String;
			
			_margin = 0;
			_preserveColor = true;
			
			_items = [];
			var itm:TextureItem;
			var itemsLen:int;
			
			if (!_canvas) _canvas = new Sprite();
			
			// Add the blank space char if not present;
			if (charCol.indexOf(" ") == -1) charCol.push(" ");
				
			for (var i:int = charCol.length - 1; i > -1; i--) {
				myChar = tf.text = charCol[i];
				drawItem(tf, myChar.charCodeAt().toString());
			}
			
			_currentLab = "";
			
			layoutChildren();
			
			canvasData = new BitmapData(_canvas.width, _canvas.height, true, 0x000000);
			canvasData.draw(_canvas);
			
			itemsLen = _items.length;
			
			xml = new XML(<font></font>);
			var infoNode:XML = new XML(<info />);
			infoNode.@face = fontFamily;
			infoNode.@size = fontSize;
			xml.appendChild(infoNode);
			//var commonNode:XML = new XML(<common alphaChnl="1" redChnl="0" greenChnl="0" blueChnl="0" />);
			var commonNode:XML = new XML(<common />);
			commonNode.@lineHeight = fontSize;
			xml.appendChild(commonNode);
			xml.appendChild(new XML(<pages><page id="0" file="texture.png" /></pages>));
			var charsNode:XML = new XML(<chars> </chars>);
			charsNode.@count = itemsLen;
			var charNode:XML;
			
			for (var k:uint = 0; k < itemsLen; k++)
			{
				itm = _items[k];
				
				itm.graphic.dispose();
				
				// xml
				charNode = new XML(<char page="0" xoffset="0" yoffset="0"/>); 
				charNode.@id = itm.textureName;
				charNode.@x = itm.x;
				charNode.@y = itm.y;
				charNode.@width = itm.width;
				charNode.@height = itm.height;
				charNode.@xadvance = itm.width + 2*charMarginX;
				charsNode.appendChild(charNode);
			}
			
			xml.appendChild(charsNode);
			
			texture = Texture.fromBitmapData(canvasData);
			TextField.registerBitmapFont(new BitmapFont(texture, xml));
			
			_items.length = 0;
			_canvas.removeChildren();
			
			tf.autoSize = oldAutoSize;
			tf.text = charCol.join();
			
			_items = null;
			xml = null;
			_canvas = null;
			_currentLab = null;
		}
	}
}