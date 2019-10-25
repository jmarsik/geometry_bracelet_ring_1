inner_dia = 62;
thickness = 4;
width = 40;
direction_changes = 3;
segments = 8;
start_angle = 5;
end_angle = 305;
twist = 20;
round_corner_radius = 5;
cut_degrees = 5;

start_cutting_tool_top_factor = 3.1;
start_cutting_tool_bottom_factor = -2;
end_cutting_tool_top_factor = -2;
end_cutting_tool_bottom_factor = 5;

// =========================================

// https://github.com/Irev-Dev/Round-Anything
use <polyround.scad>;

// outer radius
r1 = (inner_dia + 2 * thickness) / 2;

row_width = width / direction_changes;
cutting_tool_extrude = thickness * 3;

function len3(v) = len(v) > 1 ? sqrt(addl([for(i = [0 : len(v) - 1]) pow(v[i], 2)])) : len(v) == 1 ? v[0] : v; 
function addl(l, c = 0) = len(l) -1 > c ? l[c] + addl(l, c + 1) : l[c];

function point_on_circle(r, a) = [r * cos(a), r * sin(a), 0];

module regular_polygon(order = 4, r = 1) {
    angles = [ for (i = [0:order - 1]) i * (360 / order) ];
    coords = [ for (th = angles) [r * cos(th), r * sin(th)] ];
    polygon(coords);
}
 
module sector(angle1, angle2, r) {
    points = [
        for(a = [angle1 : 1 : angle2]) [r * cos(a), r * sin(a)]
    ];
    polygon(concat([[0, 0]], points));
}

module raw_bracelet() { 
    for (step = [0 : direction_changes - 1])
        let (dir = step % 2 == 0 ? -1 : 1) {
        translate([0, 0, step * row_width]) {
            rotate(twist / 2 * dir) {
                linear_extrude(width / direction_changes, center = false, twist = twist * dir, slices = 100, convexity = 10) {
                    intersection() {
                        difference() {
                            regular_polygon(segments, r = r1);
                            regular_polygon(segments, r = r1 - thickness);
                        }
                        sector(start_angle, end_angle, r1 + 5);
                    }
                }
            }
        }
    }
}

module cutting_tool(extend_x_by, top_factor, bottom_factor) {
    single_dir_change_len = len3(point_on_circle(r1, 0) - point_on_circle(r1, twist / 2));
    // zigzag polyline covering all the rows of the bracelet
    points1 = [ for (step = [0 : direction_changes]) let (dir = step % 2 == 0 ? -1 : 1) [dir * single_dir_change_len, step * row_width, round_corner_radius] ];
    // extension (continuation of the shape) - bottom and top
    points1b = concat([[bottom_factor * points1[0][0], -1 * row_width, round_corner_radius]], points1, [[top_factor * points1[len(points1) - 1][0], (direction_changes + 1) * row_width, round_corner_radius]]);
    // another polyline a little bit shifted from the previous one
    points2 = [ for (i = [len(points1b) - 1 : -1 : 0]) [points1b[i][0] + extend_x_by, points1b[i][1], points1b[i][2]] ];
    points = concat(points1b, points2);
    echo(points);

    // polygon from all the points, with rounded corners
    polygon(polyRound(points, 20));
}

module cutting_tool_rotated(angle, extend_x_by, top_factor, bottom_factor) {
    translate(point_on_circle(r1 - cutting_tool_extrude / 2 - thickness / 2, angle))
    rotate(90 + angle, [0, 0, 1])
    rotate(90, [1, 0, 0])
    linear_extrude(cutting_tool_extrude)
    cutting_tool(extend_x_by, top_factor, bottom_factor);
}

difference() {
    raw_bracelet();
    
    #cutting_tool_rotated(start_angle + cut_degrees, -10, start_cutting_tool_top_factor, start_cutting_tool_bottom_factor);
    
    #cutting_tool_rotated(end_angle - cut_degrees, +10, end_cutting_tool_top_factor, end_cutting_tool_bottom_factor);
}
