package com.emibap.textureAtlas{
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	public class TextureItem extends Sprite{
		
		// Maximum frame width is used.
		public static var frameWidth:Number = 0;
		public static var frameHeight:Number = 0;
		
		private var _graphic:BitmapData;
		private var _textureName:String = "";
		private var _frameName:String = "";
		private var _frameX:Number;
		private var _frameY:Number;
		
		public function TextureItem(graphic:BitmapData, textureName:String, frameName:String, 
									frameX:Number = 0, frameY:Number = 0, frameWidth:Number = 0, frameHeight:Number = 0){
			super();
			
			_graphic = graphic;
			_textureName = textureName;
			_frameName = frameName;
			_frameX = frameX;
			_frameY = frameY;
			
			TextureItem.frameWidth = frameWidth > TextureItem.frameWidth ? frameWidth : TextureItem.frameWidth;
			TextureItem.frameHeight = frameHeight > TextureItem.frameHeight ? frameHeight : TextureItem.frameHeight;
			
			var bm:Bitmap = new Bitmap(graphic, "auto", false);
			addChild(bm);
		}
		
		public function get textureName():String{
			return _textureName;
		}
		
		public function get frameName():String{
			return _frameName;
		}
		
		public function get graphic():BitmapData{
			return _graphic;
		}

		public function get frameOffsetX():Number {
			return _frameX;
		}

		public function get frameOffsetY():Number {
			return _frameY;
		}
	}
}