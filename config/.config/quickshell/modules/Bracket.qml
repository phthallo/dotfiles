import "root:/"

// waybar's custom/openbracket and custom/closebracket: a literal "[" or "]"
// around a group.
//
// Takes its height from the group and centres the glyph in that box, rather
// than sizing to the glyph and anchoring - "[" and "]" sit on the baseline
// differently than lowercase text, so centring the text directly left them
// visibly off from the label beside them.
BarText {}
