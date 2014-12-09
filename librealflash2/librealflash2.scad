// Things you probably shouldn't change
resolution = 0.5;

module rounded_rect(size, radius) 
{
	x = size[0];
	y = size[1];
	z = size[2];

	linear_extrude(height=z)
	hull()
	{
		translate([radius, radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);

		translate([x - radius, radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);

		translate([x - radius, y - radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);

		translate([radius, y - radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);
	}
}

module fine_cylinder(dia, length)
{
	cylinder(length, dia/2, dia/2, $fs = resolution, $fa = resolution);
}

module fine_cone(dia, dia2, length)
{
	cylinder(length, dia/2, dia2/2, $fs = resolution, $fa = resolution);
}

module doughnut(dia, thickness)
{
	rotate_extrude(convexity = 1,$fn=100)
	{
		translate([dia/2,0,0])
			circle(r=thickness/2,$fn=100);
	}

}

module square_pyramid(size)
{
	x = size[0];
	y = size[1];
	z = size[2];

	polyhedron(points=[ [x/2,y/2,0],[x/2,-y/2,0],[-x/2,-y/2,0],[-x/2,y/2,0],	// the four points at base
      							[0,0,z]  ],                 	// the apex point 
  		triangles=[ [0,1,4],[1,2,4],[2,3,4],[3,0,4],    			// each triangle side
      					[1,0,3],[2,1,3] ],                  		// two triangles for square base
  		sides=[ [0,1,4],[1,2,4],[2,3,4],[3,0,4],    				// same again for alter versions of OpenSCAD
      					[1,0,3],[2,1,3] ]                  		
 		);
}

module rounded_tab(size, radius) 
{
	x = size[0];
	y = size[1];
	z = size[2];

	linear_extrude(height=z)
	hull()
	{
		square([x/10,y]);

		translate([x - radius, radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);

		translate([x - radius, y - radius, 0])
		circle(r=radius, $fa=resolution, $fs=resolution);
	}
}

/**
 * pie.scad
 *
 * Use this module to generate a pie- or pizza- slice shape, which is particularly useful
 * in combination with `difference()` and `intersection()` to render shapes that extend a
 * certain number of degrees around or within a circle.
 *
 * This openSCAD library is part of the [dotscad](https://github.com/dotscad/dotscad)
 * project.
 *
 * @copyright  Chris Petersen, 2013
 * @license    http://creativecommons.org/licenses/LGPL/2.1/
 * @license    http://creativecommons.org/licenses/by-sa/3.0/
 *
 * @see        http://www.thingiverse.com/thing:109467
 * @source     https://github.com/dotscad/dotscad/blob/master/pie.scad
 *
 * @param float radius Radius of the pie
 * @param float angle  Angle (size) of the pie to slice
 * @param float height Height (thickness) of the pie
 * @param float spin   Angle to spin the slice on the Z axis
 */
module pie(radius, angle, height, spin=0) {
    // Negative angles shift direction of rotation
    clockwise = (angle < 0) ? true : false;
    // Support angles < 0 and > 360
    normalized_angle = abs((angle % 360 != 0) ? angle % 360 : angle % 360 + 360);
    // Select rotation direction
    rotation = clockwise ? [0, 180 - normalized_angle] : [180, normalized_angle];
    // Render
    if (angle != 0) {
        rotate([0,0,spin]) linear_extrude(height=height)
            difference() {
                circle(radius, $fn=100);
                if (normalized_angle < 180) {
                    union() for(a = rotation)
                        rotate(a) translate([-radius, 0, 0]) square(radius * 2);
                }
                else if (normalized_angle != 360) {
                    intersection_for(a = rotation)
                        rotate(a) translate([-radius, 0, 0]) square(radius * 2);
                }
            }
    }
}

module nut_capture(dia, thickness)
{
	cylinder(h=thickness,r=dia/2, $fn=6);
}

module knob(nut_od, nut_height, bolt_od,)
{
	// Adapted from and with thanks to http://www.thingiverse.com/thing:7979/#files	
	num_dents = 6;
	dent_offset = 2;
	nut_wall_thickness = 1.2;
	knob_height = nut_height+nut_wall_thickness;
	nut_hole_radius = bolt_od/2; 
	nut_size_radius = nut_od/2; 
	knob_radius = nut_size_radius*2.5;
	dent_radius = knob_radius*0.35;

	translate([0, 0, 0]) {
		difference() {
		cylinder(h = knob_height, r = knob_radius);
		for (i = [0:(num_dents - 1)]) {
			translate([sin(360*i/num_dents)*(knob_radius+dent_offset), cos(360*i/num_dents)*(knob_radius+dent_offset), -5 ])
			cylinder(h = knob_height+10, r=dent_radius);
			}
		translate([0,0,-5]) cylinder(h = knob_height+10, r=nut_hole_radius,$fa=10);
		translate([0,0,nut_wall_thickness]) cylinder(h = knob_height+10, r=nut_size_radius,$fa=60);
		}
	}
}

module trapezium(base,top,height,thickness)
{
	top_offset = (base-top)/2;
	linear_extrude(height=thickness) 
		polygon(points=[[0,0],[base,0],[base-top_offset,height],[top_offset,height]]);
}

module rounded_top_trapezium(base, top, height, thickness, corner_diameter)
{
	top_offset = (base-top)/2;
	corner_rad = corner_diameter/2;
	unrounded_dia = 0.1;
	translate([0,unrounded_dia/2,0]) hull()
	{
		fine_cylinder(unrounded_dia, thickness);
		translate([base-unrounded_dia,0,0])
			fine_cylinder(unrounded_dia, thickness);
		translate([base-top_offset-corner_rad,height-corner_rad,0])
			fine_cylinder(corner_diameter, thickness);
		translate([top_offset+corner_rad,height-corner_rad,0])
			fine_cylinder(corner_diameter, thickness);
	}
}

