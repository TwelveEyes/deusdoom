class UI_DDMultiLineLabel : UI_DDLabel
{
	ui double line_gap; // vertical gap between lines

	override void drawOverlay(RenderEvent e)
	{
		// We don't account for wrapping lines yet
		array<string> lines;
		text.split(lines, "\n");
		double sx = x;
		double sy = y;
		for(uint i = 0; i < lines.size(); ++i)
		{
			if(lines[i].length() > 0){
				UI_Draw.str(text_font, lines[i], text_color, sx, sy,
						text_w, text_h);
			}
			sy += UI_Draw.strHeight(text_font, lines[i], text_w, text_h) + line_gap;
		}
	}
}
