extends Sprite2D

func crack():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.4,2.4), 0.2)
	tween.finished.connect(be_small)
	frame = 1
	
func be_small():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.8,1.8), 0.2)
	
func rebirth():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.4,2.4), 0.2)
	tween.finished.connect(be_original)
	
func be_original():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.0,2.0), 0.2)
	frame = 0
	
