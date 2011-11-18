package com.emibap.textureAtlas
{
	public class ScaleFactorTooLargeError extends Error {
		private static const MSG:String = "Scale Factor to large.";
		private var _suggestedScale:Number;
		
		public function ScaleFactorTooLargeError(suggestedScale:Number) {
			super(MSG + suggestedScale);
			_suggestedScale = suggestedScale;
		}

		public function get suggestedScale():Number{
			return _suggestedScale;
		}

	}
}