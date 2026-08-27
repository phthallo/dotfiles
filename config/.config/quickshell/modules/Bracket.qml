import "root:/"

// waybar's custom/openbracket and custom/closebracket: a literal "[" or "]"
// wrapped around a group.
//
// It takes its height from the group and centres the glyph inside that, rather
// than being sized to the glyph and then anchored. "[" and "]" have taller ink
// than lowercase text and sit differently on the baseline, so centring the box
// instead of the text left them visibly off from the label beside them.
BarText {}
