package com.emibap.textureAtlas{
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	public class TextureItem extends Sprite{
		
		private var _graphic:BitmapData;
		private var _textureName:String = "";
		private var _frameName:String = "";
		private var _frameOffsetX:Number;
		private var _frameOffsetY:Number;
		
		public function TextureItem(graphic:BitmapData, textureName:String, frameName:String, frameOffsetX:Number = 0, frameOffsetY:Number = 0){
			super();
			
			_graphic = graphic;
			_textureName = textureName;
			_frameName = frameName;
			_frameOffsetX = frameOffsetX;
			_frameOffsetY = frameOffsetY;
			
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
			return _frameOffsetX;
		}

		public function get frameOffsetY():Number {
			return _frameOffsetY;
		}


	}
}