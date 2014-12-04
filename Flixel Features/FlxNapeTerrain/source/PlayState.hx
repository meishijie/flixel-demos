package;

import flixel.addons.nape.FlxNapeSpace;
import flixel.addons.nape.FlxNapeSprite;
import flixel.addons.nape.FlxNapeTilemap;
import flixel.FlxG;
import flixel.FlxState;
import nape.constraint.PivotJoint;
import nape.geom.AABB;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyList;
import nape.phys.BodyType;
import nape.shape.Circle;
import nape.shape.Polygon;
import openfl.Assets;
import openfl.geom.Matrix;
import openfl.display.Sprite;
import openfl.display.BlendMode;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;

class PlayState extends FlxState
{
	private var bodyList:BodyList = null;
	private var terrain:Terrain;
	private var bomb:Sprite;
	private var hand:PivotJoint;
	
	override public function create():Void
	{
		init();
		
		super.create();
	}
	
	private function init():Void 
	{
		FlxNapeSpace.init();
		
		FlxNapeSpace.space.gravity = new Vec2(0, 600);
		
		FlxNapeSpace.createWalls();
		
		FlxNapeSpace.drawDebug = true;
		
		hand = new PivotJoint(FlxNapeSpace.space.world, null, Vec2.weak(), Vec2.weak());
		hand.active = false;
		hand.stiff = false;
		hand.maxForce = 1e5;
		hand.space = FlxNapeSpace.space;
		
		var w:Int = FlxG.width;
		var h:Int = FlxG.height;
		
		// Initialise terrain bitmap.
		var bit = new BitmapData(w, h, true, 0);
		bit.perlinNoise(200, 200, 2, 0x3ed, false, true, BitmapDataChannel.ALPHA, false);
		
		// Create initial terrain state, invalidating the whole screen.
		terrain = new Terrain(bit, 30, 5);
		terrain.invalidate(new AABB(0, 0, w, h), this);
		
		add(terrain.megaStrip);
		
		// Create bomb sprite for destruction
		bomb = new Sprite();
		bomb.graphics.beginFill(0xffffff, 1);
		bomb.graphics.drawCircle(0, 0, 40);
	}
	
	function explosion(pos:Vec2) 
	{
		// Erase bomb graphic out of terrain.
		terrain.bitmap.draw(bomb, new Matrix(1, 0, 0, 1, pos.x, pos.y), null, BlendMode.ERASE);
		
		// Invalidate region of terrain effected.
		var region = AABB.fromRect(bomb.getBounds(bomb));
		region.x += pos.x;
		region.y += pos.y;
		terrain.invalidate(region, this);
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (FlxG.mouse.justPressed)
		{
			var mp = Vec2.get(FlxG.mouse.x, FlxG.mouse.y);
			
			bodyList = FlxNapeSpace.space.bodiesUnderPoint(mp, null, bodyList);
			
			for (body in bodyList) 
			{
                if (body.isDynamic()) 
				{
                    hand.body2 = body;
                    hand.anchor2 = body.worldPointToLocal(mp, true);
                    hand.active = true;
                    break;
                }
            }

            if (bodyList.empty()) 
			{
                createObject(mp);
            }
            else if (!hand.active) 
			{
                explosion(mp);
            }

            // recycle nodes.
            bodyList.clear();
			
			mp.dispose();
		}
		else if (FlxG.mouse.justReleased)
		{
			hand.active = false;
		}
		
		if (hand.active) 
		{
            hand.anchor1.setxy(FlxG.mouse.x, FlxG.mouse.y);
            hand.body2.angularVel *= 0.9;
        }
		
		super.update(elapsed);
	}
	
	function createObject(pos:Vec2) 
	{
		var sprite:FlxNapeSprite = new FlxNapeSprite(pos.x, pos.y, null, false);
		
		if (Math.random() < 0.333) 
		{
			sprite.createCircularBody(10 + Math.random() * 20);
		}
		else {
			sprite.createRectangularBody(10 + Math.random() * 20, 10 + Math.random() * 20);
		}
		
		sprite.body.space = FlxNapeSpace.space;
		add(sprite);
	}
}